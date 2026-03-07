# Anti-Aliasing & Apple Silicon Graphics Acceleration Research

## Purpose

This document consolidates all anti-aliasing and graphics acceleration research for FlatPaint on macOS / Apple Silicon. It is the single source of truth for AA implementation strategy decisions.

Last updated: 2026-03-07

---

## 1. Current FlatPaint Rendering Status

FlatPaint uses a completely hand-rolled, pure-Pascal software rasterizer (`TRasterSurface` in `fpsurface.pas`) with a flat `array of TRGBA32` (BGRA byte order). All drawing primitives are per-pixel Pascal loops. The only external dependency is the LCL package.

| Dimension | Current State | Gap |
|---|---|---|
| Line drawing | Bresenham integer stepping (`fpsurface.pas`) | No sub-pixel precision, hard staircase edges |
| Shape edges | Binary inside/outside test | Ellipse/rect edges are aliased |
| Selection AA | `FSelAntiAlias` UI toggle exists but not wired to core | Selection masks write only 0 or 255 |
| Pixel format | TRGBA32 = BGRA 8-bit/channel, straight alpha | No higher-precision intermediate; CG/vImage require premultiplied |
| Compositing | 8-bit integer `div 255` | Cumulative rounding errors on many layers |
| Brush positioning | Integer coordinates throughout | No sub-pixel brush offset |
| Hardware accel | None — pure CPU scalar Pascal | NEON/Metal/Accelerate all unused |
| Canvas scaling | LCL `StretchDraw` | OS-dependent interpolation quality |
| Display pipeline | `TRasterSurface` → `CopySurfaceToBitmap` (TRawImage BGRA32) → `TCanvas.StretchDraw` | Single StretchDraw, no GPU compositing |
| Cocoa bridge | 4 small ObjC files (pinch-zoom, appearance, alpha, list background) via `{$LINK}` | Proven pattern for Apple framework integration |

---

## 2. Industry AA Approaches (from GIMP source code analysis)

### 2.1 Signed Distance Field (SDF) shape edge AA

Source: `reference/gimp-src/app/gegl/gimp-gegl-mask-combine.cc`

- Computes signed distance `d` from pixel center to shape boundary (in pixel units)
- Coverage = `CLAMP(0.5 + d, 0.0, 1.0)` — 1-pixel-wide smooth transition
- Only costs one extra `sqrt()` per pixel vs. binary test
- Selection masks stored in `"Y float"` (32-bit float) for precision

Applying to FlatPaint — change `DrawEllipse` from:
```pascal
if (NX*NX + NY*NY) <= 1.0 then BlendPixel(X, Y, Color, Opacity)
```
to:
```pascal
Dist := 1.0 - Sqrt(NX*NX + NY*NY);
Coverage := EnsureRange(Round((Dist + 0.5) * 255), 0, 255);
if Coverage > 0 then BlendPixel(X, Y, Color, Coverage * Opacity div 255);
```
Same pattern applies to `DrawRectangle`, `DrawRoundedRectangle`, and `SelectEllipse`.

### 2.2 Brush sub-pixel positioning via subsample kernels

Source: `reference/gimp-src/app/paint/gimpbrushcore-kernels.h`, `gimpbrushcore-loops.cc`

- Pre-computes 5×5 = 25 sets of 3×3 convolution kernels (KERNEL_SUBSAMPLE = 4)
- Fractional pixel offset selects nearest kernel: `index = (int)(frac * 5)`
- Brush mask convolved with selected kernel to shift it sub-pixel
- Kernel values sum to 256 for integer arithmetic (no float)
- Eliminates 1px "jumping" artifacts when brush moves slowly

### 2.3 Float precision for selection/compositing

GIMP promotes to float at critical points:
- Selection masks always in `babl_format("Y float")` (32-bit float)
- Mask combine promotes both operands to float
- Blend mode intermediates use float when GEGL is involved
- 8-bit storage only used for final output

### 2.4 SIMD compositing (SSE2/SSE4.1)

Source: `reference/gimp-src/app/operations/layer-modes/gimpoperationnormal-sse2.c`

- One RGBA pixel per 128-bit vector (`__v4sf`)
- Standard Porter-Duff "over" in SSE: `out = src * src_a + dst * (1 - src_a)`
- Runtime CPU dispatch: scalar → SSE2 → SSE4.1

---

## 3. FPC/Lazarus Native AA Libraries Evaluated

### 3.1 BGRABitmap — NOT recommended (macOS pixel format incompatible)

Most popular FPC/Lazarus 2D library. Pure Pascal, powers LazPaint.

AA capabilities: Wu-style line AA, sub-pixel coverage ellipses/rectangles/polygons, scanline AA, full Canvas2D API with `antialiasing: boolean` property.

**Critical finding — pixel format mismatch on macOS:**

On macOS/Cocoa, `BGRABITMAP_RGBAPIXEL` is defined, so `TBGRAPixel` = (R, G, B, A):

| | FlatPaint `TRGBA32` | BGRABitmap `TBGRAPixel` (macOS) |
|---|---|---|
| Byte 0 | **B** | **R** |
| Byte 1 | G | G |
| Byte 2 | **R** | **B** |
| Byte 3 | A | A |

R↔B channels swapped. Zero-copy integration impossible (BGRABitmap manages its own buffer, no external data pointer constructor). Full-frame R↔B swap ~2-6ms for 1920×1080.

**Verdict:** NOT recommended as primary path. Pixel format incompatibility on macOS, ~150 units dependency (LGPL-3.0-with-linking-exception). Retain as fallback for future cross-platform target (Windows: TBGRAPixel is BGRA = compatible).

### 3.2 AggPas — NOT recommended

Pascal port of Anti-Grain Geometry, bundled with FPC. Excellent 256-level scanline AA but very low-level API (30-50 lines per primitive). Maintenance stale (original author deceased 2013).

### 3.3 FPC built-in graphics (TFPCustomCanvas, TLazCanvas) — NOT useful

Integer-grid Bresenham/midpoint algorithms. Zero AA capability. Same quality as current TRasterSurface.

### 3.4 Cairo for FPC — NOT recommended

FPC provides `cairo` unit with excellent AA. But Cairo is NOT bundled with macOS — must ship `libcairo.2.dylib` + dependencies (5-10MB). Breaks FlatPaint's self-contained app bundle model.

---

## 4. Apple Graphics Frameworks — FPC Bindings Status

All verified against FPC 3.2.2, aarch64-darwin, installed at `/usr/local/lib/fpc/3.2.2/units/aarch64-darwin/`.

### 4.1 Core Graphics (Quartz 2D) — FULLY AVAILABLE, RECOMMENDED

| Unit | Functions | Key APIs |
|---|---|---|
| `CGBitmapContext` | 12 | `CGBitmapContextCreate`, `CGBitmapContextGetData` |
| `CGContext` | 115 | `CGContextSetShouldAntialias`, `CGContextStrokePath`, `CGContextFillPath`, `CGContextAddEllipseInRect`, `CGContextSetBlendMode`, `CGContextDrawImage` |
| `CGColorSpace` | 22 | `CGColorSpaceCreateDeviceRGB` |
| `CGPath` | 35 | `CGPathCreateMutable`, `CGPathAddEllipseInRect`, `CGPathAddLineToPoint`, `CGPathAddCurveToPoint` |
| `CGGeometry` | types | `CGPoint`, `CGSize`, `CGRect` |
| `CGImage` | constants | `kCGImageAlphaPremultipliedFirst`, `kCGBitmapByteOrder32Little` |
| `MacOSAll` | umbrella | Re-exports all CG units (9.2MB, compile-time only) |

**Why Core Graphics is the best AA path:**
1. No external dependencies — built into macOS
2. Hardware-accelerated on Apple Silicon (NEON/AMX internally)
3. Complete FPC headers already exist — `uses MacOSAll` or individual CG units
4. Native AA for all vector primitives (lines, ellipses, rectangles, paths, curves, text)
5. Can operate directly on pixel buffers via `CGBitmapContextCreate(@Surface.Pixels[0], ...)`

**Key integration pattern:**
```pascal
uses MacOSAll;
var
  CG: CGContextRef;
  ColorSpace: CGColorSpaceRef;
begin
  ColorSpace := CGColorSpaceCreateDeviceRGB;
  CG := CGBitmapContextCreate(
    @Surface.Pixels[0],              // point directly at TRasterSurface pixel data
    Surface.Width, Surface.Height,
    8,                                // bits per component
    Surface.Width * 4,                // bytes per row
    ColorSpace,
    kCGImageAlphaPremultipliedFirst or kCGBitmapByteOrder32Little  // BGRA premultiplied
  );
  CGContextSetShouldAntialias(CG, True);
  // Draw AA shapes directly into pixel buffer...
  CGContextRelease(CG);
  CGColorSpaceRelease(ColorSpace);
end;
```

**Pixel format constraint:** CG requires premultiplied alpha. Straight alpha formats are not supported for writable bitmap contexts. Options:
- (a) Premultiply/unpremultiply at boundary per operation — acceptable for one-shot shape tools
- (b) Migrate FlatPaint to premultiplied alpha globally — strongly recommended; GIMP and Krita both use premultiplied internally; aligns with CG, vImage, and Metal

**Display-layer CG access** (for overlay rendering without touching pixels):
```pascal
uses CocoaGDIObjects;
var CocoaCtx: TCocoaContext;
begin
  CocoaCtx := TCocoaContext(Canvas.Handle);
  // CocoaCtx.CGContext returns active CGContextRef
  // Use for AA selection outlines, shape previews, grid lines
end;
```

### 4.2 Accelerate / vDSP — PARTIALLY AVAILABLE

| Unit | Status | Content |
|---|---|---|
| `vDSP` | Available | ~300+ functions: FFT, convolution, vector math |
| `vBLAS` | Available | BLAS linear algebra |
| `vImage` | **NOT available** | No FPC headers — must create custom declarations or C bridge |

**vDSP image-relevant functions:** `vDSP_f3x3` / `vDSP_f5x5` (convolution), `vDSP_imgfir` (arbitrary kernel), `vDSP_vadd`/`vDSP_vmul` (vector math). Require byte→float conversion.

**vImage integration path (requires custom work):**
```pascal
{$linkframework Accelerate}
type
  vImage_Buffer = record
    data: Pointer; height, width, rowBytes: PtrUInt;
  end;
  vImage_Error = PtrInt;
function vImageBoxConvolve_ARGB8888(...): vImage_Error; cdecl; external;
```
Alternative: write thin `fp_accelerate.c` bridge and link via existing build system.

### 4.3 Metal — NO FPC BINDINGS

FPC 3.2.2's `cocoaint` package has ~100 framework bindings but Metal/MetalKit is completely absent.

**Only viable path:** ObjC bridge file approach (proven pattern):
```
src/native/fp_metal_compute.m     — device/queue/pipeline setup + C entry points
src/native/fp_metal_compute.metal — compute shaders → .metallib
src/app/fpmetalbridge.pas         — Pascal cdecl external declarations
```
Build: `clang -c -O2 -arch arm64 -fobjc-arc -framework Metal` + `xcrun metal -O2 -o shaders.metallib`.

### 4.4 OpenGL — NOT recommended

Available (`gl`, `glext`, `macgl`, `CGGLContext`, `GLKit`) but deprecated since macOS 10.14. Runs through Metal translation layer internally. No compute shaders (macOS = OpenGL 4.1 max, compute requires 4.3). Core Graphics and Metal are strictly better.

### 4.5 FPC Objective-C Bridge — MATURE and PROVEN

Multiple mechanisms available:
- `{$modeswitch objectivec1/objectivec2}` — declare ObjC types directly in Pascal
- `CocoaAll` — full AppKit + Foundation bindings
- `MacOSAll` — all C-level framework bindings (CG, CF, CT)
- External `.m`/`.c` file compilation and linking — FlatPaint's 4 existing bridge modules prove this works

**Universal escape hatch:** For any Apple framework without FPC headers (Metal, vImage, Core ML), a bridge file + Pascal `external` declarations works. The `compile_native_modules()` build system function handles compilation.

---

## 5. Strategic Conclusions

### 5.1 Recommended approach hierarchy

| Priority | Approach | What | Why | FPC Integration |
|---|---|---|---|---|
| **P0** | **Core Graphics offscreen** | AA for shape/line/selection stroke rendering | Complete FPC CG headers; zero deps; Apple Silicon HW-accelerated | `uses MacOSAll` + `CGBitmapContextCreate` over `TRasterSurface.Pixels` |
| **P0** | **SDF edge AA (pure Pascal)** | AA for filled shapes and selection masks | No dependency; works in core layer; cross-platform | Pure math in `fpsurface.pas` |
| **P1** | **vImage via C bridge** | Box blur, Gaussian blur, image resize | 10-30× speedup on Apple Silicon; plain C API | `fp_accelerate.c` bridge or manual Pascal `external` declarations |
| **P1** | **CG display overlay** | Selection marching ants, tool preview outlines with AA | Access `TCocoaContext.CGContext` during `Paint` | `uses CocoaGDIObjects, MacOSAll` in mainform |
| **P2** | **vDSP convolution** | Sharpen, emboss, custom kernel effects | FPC `vDSP` unit already available; HW-optimized | `uses vDSP` directly |
| **P2** | **Premultiplied alpha refactor** | Better compositing precision; removes CG boundary conversion | GIMP/Krita use premultiplied; aligns with CG, vImage, Metal | Modify `fpcolor.pas` + `fpdocument.pas` |
| **P3** | **Metal viewport display** | Replace StretchDraw with MTKView texture blit | Instant viewport quality/FPS improvement | ObjC bridge (`fp_metal_display.m`) |
| **P4** | **Metal compute shaders** | Layer compositing, large-image filters | Highest performance ceiling | ObjC bridge + .metallib |

### 5.2 Key strategic decisions

1. **Core Graphics over BGRABitmap** — CG has complete FPC headers, HW-accelerated on Apple Silicon, BGRA-compatible (with premultiplied), zero external deps. BGRABitmap pixel format incompatible on macOS (R↔B swap), no buffer sharing, ~150 units dependency.

2. **SDF AA (pure Pascal) for core primitives** — For filled shapes (ellipse fill, rectangle fill, polygon fill), the SDF approach (`clamp(0.5 + d, 0, 1)`) runs in the core layer with no platform dependency. Use Core Graphics only for stroked outlines and complex paths.

3. **vImage via C bridge for filters** — vDSP operates on float arrays (conversion overhead); vImage operates directly on 8-bit buffers. Write minimal `fp_accelerate.c` with `vImageBoxConvolve_ARGB8888` first.

4. **Premultiplied alpha migration as enabling work** — Both CG and vImage require premultiplied alpha. Migrating globally eliminates per-operation boundary conversion and improves compositing accuracy. Medium-effort refactor, but enables all downstream integrations.

### 5.3 What NOT to use

| Option | Reason |
|---|---|
| BGRABitmap | macOS pixel format incompatible (RGBA vs BGRA); no zero-copy; heavy dependency |
| AggPas | Low-level API; stale maintenance; no advantage over CG or SDF |
| Cairo | Not bundled with macOS; breaks self-contained distribution |
| OpenGL | Deprecated on macOS; no compute shaders; CG/Metal strictly better |
| Hand-written NEON | FPC NEON support sparse; vImage provides same functionality with better maintainability |

---

## 6. Implementation Notes

### 6.1 CGBitmapContext pixel format

CG straight alpha formats do NOT support writable bitmap contexts. The only BGRA-compatible writable format is `kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little`.

### 6.2 MacOSAll compile-time impact

The `MacOSAll` umbrella unit is 9.2MB. Use individual units (`CGContext`, `CGBitmapContext`, `CGColorSpace`, `CGPath`, `CGGeometry`, `CGImage`) to reduce compile-time if needed. Zero runtime cost either way.

### 6.3 SDF transition width

GIMP uses 1.0 pixel (±0.5). Formula: `clamp(0.5 + d, 0, 1)`. No multisampling needed — just one `sqrt()` extra per edge pixel.

### 6.4 vImage pixel layout

Check `_BGRA8888` variant availability in macOS SDK. If only `_ARGB8888` available, may need `vImagePermuteChannels_ARGB8888` or change FlatPaint byte order.

### 6.5 Float intermediate precision

Full pipeline float conversion (like GIMP 3.0) is a massive change. Pragmatic approach: float only for AA edge computation and selection masks; keep pixel storage as 8-bit BGRA.

### 6.6 Metal entry point

Lowest-risk Metal integration: replace viewport display (`StretchDraw` → `MTKView` texture blit). Does not touch pixel processing; gives immediate scaling quality and FPS improvement. Lazarus `TCocoaCustomControl` can host `MTKView` as subview.

### 6.7 Build system for native bridges

Existing `compile_native_modules()` in `scripts/common.sh` handles `.m` files. Extension for `.c` and `.metal`:
```bash
# C bridge (Accelerate)
clang -c -O2 -arch arm64 -mmacosx-version-min=11.0 \
  -framework Accelerate \
  -o "$output_dir/fp_accelerate.o" "$src_dir/fp_accelerate.c"

# Metal shaders
xcrun -sdk macosx metal -O2 \
  -o "$output_dir/shaders.metallib" "$src_dir/fp_metal_compute.metal"
```

### 6.8 Testing strategy

The `{$IFDEF TESTING}` pattern in existing bridge units provides no-op stubs for headless test builds. New bridges follow the same pattern. Core model tests remain unaffected; only performance and visual quality change.
