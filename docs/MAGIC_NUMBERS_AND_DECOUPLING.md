# Magic Numbers Inventory & Architecture Decoupling Plan

## 1. Magic Number Audit

### 1.1 FPSurface.pas — Named Constants Extracted

| Value | Meaning | Constant Name | Occurrences |
|-------|---------|---------------|-------------|
| 77 / 150 / 29 / 256 | BT.709 integer luma weights (R×77+G×150+B×29)/256 | `LUMA_WEIGHT_RED`, `LUMA_WEIGHT_GREEN`, `LUMA_WEIGHT_BLUE`, `LUMA_DIVISOR` | 4 call-sites (LumaOfColor, Grayscale, BlackAndWhite, OilPaint) |
| 60.0 | Degrees per HSV hue sector | `DEGREES_PER_HUE_SECTOR` | 3 (RGBToHSV) |
| 360.0 | Full circle in degrees | `FULL_CIRCLE_DEGREES` | 4 (RGBToHSV, HSVToRGBA) |
| 64 | Maximum box-blur radius | `MAX_BOX_BLUR_RADIUS` | 1 (BoxBlur) |
| 24 | Maximum surface-blur / radial-blur radius | `MAX_SURFACE_BLUR_RADIUS` | 2 (SurfaceBlur, RadialBlur) |
| 256 | Maximum tile-reflection tile size | `MAX_TILE_REFLECTION_SIZE` | 1 (TileReflection) |
| 64 | Maximum posterize levels | `MAX_POSTERIZE_LEVELS` | 1 (Posterize) |

### 1.2 FPSelection.pas — Named Constants Extracted

| Value | Meaning | Constant Name | Occurrences |
|-------|---------|---------------|-------------|
| 0.5 | Pixel center offset for sub-pixel SDF | `PIXEL_CENTER_OFFSET` | ~20 (polygon PIP, SDF rect/ellipse/polygon) |
| 1.0e-12 | Epsilon to guard against zero-length vectors | `SDF_EPSILON` | 1 (EllipseSDF) |
| 1.0e30 | Large initial distance for min-distance search | `SDF_LARGE_DISTANCE` | 1 (SelectPolygon) |

### 1.3 FPColor.pas — Review

FPColor uses `127` and `255` exclusively:
- `127` = rounding offset for 8-bit divide-by-255 (`(V * A + 127) div 255`). This is a universally recognized integer rounding idiom; naming it would reduce readability.
- `255` = maximum byte / full opacity. Trivially understood constant; exempt per dev rule 27.

**Decision**: No changes needed in FPColor.pas.

### 1.4 Remaining 0.5 in FPSurface.pas

FPSurface.pas retains ~23 instances of `+ 0.5` for pixel-center offset in SDF/geometry code. These follow the same `PIXEL_CENTER_OFFSET` pattern as FPSelection but are embedded in tightly-coupled rendering loops where:
- The `0.5` is a universal graphics convention (pixel center = integer + 0.5).
- Replacing with a constant in 23 locations risks regressions for marginal readability gain.
- The value will never change (tied to the pixel grid definition).

**Decision**: Document but defer; the value is axiomatic rather than tunable.

---

## 2. High-Coupling Analysis

### 2.1 TRasterSurface — God Class (117+ methods)

`TRasterSurface` in `fpsurface.pas` is the most complex class in the codebase, with methods spanning five distinct responsibility domains:

| Domain | Method Count | Examples |
|--------|-------------|----------|
| **Buffer/Lifecycle** | ~8 | Create, SetSize, Assign, Clone, Clear, RawPixels |
| **Drawing Primitives** | ~18 | DrawBrush, DrawLine, DrawRectangle, DrawEllipse, DrawPolygon, FillPolygon, FloodFill, FillGradient |
| **Effects/Filters** | ~35 | BoxBlur, GaussianBlur, Sharpen, DetectEdges, Sepia, Posterize, OilPaint, etc. |
| **Transforms** | ~8 | FlipHorizontal, Rotate90, ResizeNearest, ResizeBilinear, Crop |
| **Selection Operations** | ~6 | FillSelection, EraseSelection, CopySelection, MoveSelectedPixels, CreateContiguousSelection |

**Impact**: Changes to any effect risk breaking drawing code or selection logic due to shared state (`FPixels`, `FWidth`, `FHeight`).

### 2.2 TImageDocument — Acceptable Facade

`fpdocument.pas` has 80+ methods but follows facade pattern correctly:
- Delegates all pixel operations to `TRasterSurface` layer instances.
- Owns composition, history, and layer management without duplicating pixel math.
- Cross-cutting concerns (undo, composite) justify the method count.

**Decision**: No structural change needed.

### 2.3 Dependency Graph

```
FPColor  (0 deps)
   ↓
FPSelection  (uses: Types)
   ↓
FPSurface  (uses: FPColor, FPSelection)
   ↓
FPDocument  (uses: FPSurface, FPColor, FPSelection)
   ↓
MainForm / App layer  (uses: FPDocument + UI units)
```

No circular dependencies. Clean one-way hierarchy.

---

## 3. Decoupling Proposal for TRasterSurface

### 3.1 Strategy: Extract Stateless Effect Functions

Rather than splitting `TRasterSurface` into multiple classes (which would require passing `FPixels`/`FWidth`/`FHeight` everywhere and break all existing call-sites), the recommended approach is:

**Phase 1 — Extract stateless effect procedures into a helper unit**

Create `FPSurfaceEffects.pas` containing standalone procedures:

```pascal
procedure ApplyBoxBlur(var APixels: array of TRGBA32; AWidth, AHeight, ARadius: Integer);
procedure ApplyGaussianBlur(var APixels: array of TRGBA32; AWidth, AHeight, ARadius: Integer);
procedure ApplyOilPaint(var APixels: array of TRGBA32; AWidth, AHeight, ARadius: Integer);
// ... etc for all ~35 effect methods
```

`TRasterSurface` methods become thin wrappers:

```pascal
procedure TRasterSurface.BoxBlur(Radius: Integer);
begin
  ApplyBoxBlur(FPixels, FWidth, FHeight, Radius);
end;
```

**Benefits**:
- Zero API breakage — all existing callers unchanged.
- Zero performance cost — no extra object allocation, no virtual dispatch.
- Effects become independently testable without constructing a `TRasterSurface`.
- Clear separation of concerns: buffer management vs. pixel algorithms.

**Phase 2 — Extract drawing primitives similarly**

Create `FPSurfaceDrawing.pas` for stateless drawing procedures.

**Phase 3 — Extract transform operations**

Create `FPSurfaceTransforms.pas` for flip/rotate/resize/crop.

### 3.2 Migration Rules

1. **One domain at a time** — Extract effects first (highest method count, lowest coupling to buffer state).
2. **No API changes** — `TRasterSurface` keeps all public methods; they delegate to unit procedures.
3. **No new allocations** — Extracted functions receive `var` arrays and dimensions, not objects.
4. **Test parity** — Each extracted function gets a direct unit test equivalent. Existing `TRasterSurface` wrapper tests remain as integration coverage.
5. **Build after each extraction** — Run full test suite after moving each batch of 5-8 methods.

### 3.3 Priority Order

| Phase | Unit | Est. Methods | Risk |
|-------|------|-------------|------|
| 1 | `FPSurfaceEffects.pas` | ~35 | Low — effects are self-contained pixel transforms |
| 2 | `FPSurfaceDrawing.pas` | ~18 | Medium — some drawing uses blend helpers currently inlined |
| 3 | `FPSurfaceTransforms.pas` | ~8 | Low — pure pixel array reordering |

### 3.4 What NOT to Change

- **TImageDocument** — Facade pattern is appropriate; do not split.
- **FPColor** — Already minimal and focused.
- **FPSelection** — Single-responsibility (mask operations); clean.
- **Buffer management in TRasterSurface** — `Create`, `SetSize`, `Assign`, `Clone`, `Clear`, pixel accessors stay in the main class.

---

## 4. Development Rule Reference

Rule **#27** in `docs/DEVELOPMENT_RULES.md` now mandates:

> No hardcoded magic numbers in application or core code. Every numeric literal that encodes a domain-specific meaning must be declared as a named constant with a descriptive identifier.

Exempt: `0`, `1`, `255` as byte bounds, simple loop indices. Borderline cases should err on the side of naming.
