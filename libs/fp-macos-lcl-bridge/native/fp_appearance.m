/*
 * fp_appearance.m — Force light appearance for FlatPaint on macOS.
 *
 * On macOS Cocoa, NSPopUpButton and NSComboBox dropdown popups inherit
 * the window's effective appearance.  When the system is in dark mode,
 * or when a vibrancy/material effect is in play, the dropdown can render
 * with a dark background while the app draws custom light-themed controls,
 * resulting in dark text on a dark popup — nearly unreadable.
 *
 * This helper forces the main window to use NSAppearanceNameAqua (light),
 * ensuring all native controls (popups, dropdowns, context menus) render
 * with a white/light background as Apple HIG expects for a light-themed app.
 *
 * Pascal side:
 *   FPForceAquaAppearance(AWindowHandle: Pointer); cdecl;
 */

#import <Cocoa/Cocoa.h>

void FPForceAquaAppearance(void *nsViewHandle) {
    if (!nsViewHandle) return;
    NSView *view = (__bridge NSView *)nsViewHandle;
    NSWindow *window = view.window;
    if (window) {
        NSAppearance *aqua = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        if (aqua) {
            [window setAppearance:aqua];
        }
    }
}

/*
 * Return the main screen's backing scale factor (e.g. 2.0 on Retina).
 *
 * Pascal side:
 *   FPGetScreenBackingScale: Double; cdecl;
 */
double FPGetScreenBackingScale(void) {
    NSScreen *screen = [NSScreen mainScreen];
    if (!screen) return 1.0;
    return (double)[screen backingScaleFactor];
}

/*
 * Set the interpolation quality on the current graphics context.
 * quality: 0 = none (nearest-neighbor), 1 = low, 2 = medium, 3 = high
 *
 * Pascal side:
 *   FPSetInterpolationQuality(AQuality: LongInt); cdecl;
 */
void FPSetInterpolationQuality(int quality) {
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    if (!gc) return;
    CGContextRef ctx = (CGContextRef)[gc CGContext];
    if (!ctx) return;
    CGInterpolationQuality q;
    switch (quality) {
        case 0:  q = kCGInterpolationNone; break;
        case 1:  q = kCGInterpolationLow; break;
        case 2:  q = kCGInterpolationMedium; break;
        default: q = kCGInterpolationHigh; break;
    }
    CGContextSetInterpolationQuality(ctx, q);
}

/*
 * Draw a marching-ants polyline on the current NSGraphicsContext.
 *
 * Renders two passes in a single call:
 *   1) White solid base stroke  – ensures the outline is visible on any background
 *   2) Black dashed overlay     – MarqueeSegmentLength-pixel dash with animated phase
 *
 * The CGContext already carries the LCL SetWindowOrgEx translation (Cocoa LCL
 * applies it via CGContextTranslateCTM), so coordinates are in LCL logical space.
 *
 * pointsXY  : interleaved doubles [x0,y0, x1,y1, …] in LCL logical coordinates
 * count     : number of POINTS (array has count*2 doubles)
 * dashLen   : dash/gap length in user-space points (typically 4)
 * dashPhase : phase offset for animation (advances each timer tick)
 * closed    : non-zero to close the subpath
 *
 * Pascal side:
 *   FPDrawMarchingAntsPolyline(APointsXY: PDouble; ACount: LongInt;
 *     ADashLength, ADashPhase: Double; AClosed: LongInt); cdecl;
 */
void FPDrawMarchingAntsPolyline(const double *pointsXY, int count,
                                double dashLen, double dashPhase,
                                int closed) {
    if (!pointsXY || count < 2) return;
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    if (!gc) return;
    CGContextRef ctx = (CGContextRef)[gc CGContext];
    if (!ctx) return;

    CGContextSaveGState(ctx);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);

    /* --- Pass 1: white solid base --- */
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineDash(ctx, 0, NULL, 0);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, (CGFloat)pointsXY[0], (CGFloat)pointsXY[1]);
    for (int i = 1; i < count; i++)
        CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[i * 2], (CGFloat)pointsXY[i * 2 + 1]);
    if (closed)
        CGContextClosePath(ctx);
    CGContextStrokePath(ctx);

    /* --- Pass 2: black dashed overlay --- */
    CGFloat dashLengths[2] = { (CGFloat)dashLen, (CGFloat)dashLen };
    CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 1.0);
    CGContextSetLineDash(ctx, (CGFloat)dashPhase, dashLengths, 2);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, (CGFloat)pointsXY[0], (CGFloat)pointsXY[1]);
    for (int i = 1; i < count; i++)
        CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[i * 2], (CGFloat)pointsXY[i * 2 + 1]);
    if (closed)
        CGContextClosePath(ctx);
    CGContextStrokePath(ctx);

    CGContextRestoreGState(ctx);
}

/*
 * Draw multiple marching-ants contours in a SINGLE CGPath stroke.
 *
 * Batches all contours into one CGPath with multiple subpaths, then
 * strokes the entire path in exactly 2 passes (white base + black dash).
 * This avoids the O(N) GPU draw-call overhead that occurs when calling
 * FPDrawMarchingAntsPolyline once per contour.
 *
 * pointsXY        : interleaved doubles [x0,y0, x1,y1, …] for ALL contours
 * contourOffsets   : per-contour start index into pointsXY (in POINTS, not doubles)
 * contourLengths   : per-contour point count
 * contourCount     : number of contours
 * closedFlags      : per-contour flag: non-zero to close that subpath
 * dashLen          : dash/gap length in user-space points
 * dashPhase        : phase offset for animation
 *
 * Pascal side:
 *   FPDrawMarchingAntsMultiContour(APointsXY: PDouble;
 *     AContourOffsets, AContourLengths, AClosedFlags: PLongInt;
 *     AContourCount: LongInt;
 *     ADashLength, ADashPhase: Double); cdecl;
 */
void FPDrawMarchingAntsMultiContour(const double *pointsXY,
                                     const int *contourOffsets,
                                     const int *contourLengths,
                                     const int *closedFlags,
                                     int contourCount,
                                     double dashLen, double dashPhase) {
    if (!pointsXY || contourCount <= 0) return;
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    if (!gc) return;
    CGContextRef ctx = (CGContextRef)[gc CGContext];
    if (!ctx) return;

    CGContextSaveGState(ctx);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);

    /* --- Pass 1: white solid base --- */
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineDash(ctx, 0, NULL, 0);
    CGContextBeginPath(ctx);
    for (int c = 0; c < contourCount; c++) {
        int off = contourOffsets[c];
        int len = contourLengths[c];
        if (len < 1) continue;
        CGContextMoveToPoint(ctx, (CGFloat)pointsXY[off * 2],
                                  (CGFloat)pointsXY[off * 2 + 1]);
        for (int i = 1; i < len; i++)
            CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[(off + i) * 2],
                                         (CGFloat)pointsXY[(off + i) * 2 + 1]);
        if (closedFlags[c])
            CGContextClosePath(ctx);
    }
    CGContextStrokePath(ctx);

    /* --- Pass 2: black dashed overlay --- */
    CGFloat dashLengths[2] = { (CGFloat)dashLen, (CGFloat)dashLen };
    CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 1.0);
    CGContextSetLineDash(ctx, (CGFloat)dashPhase, dashLengths, 2);
    CGContextBeginPath(ctx);
    for (int c = 0; c < contourCount; c++) {
        int off = contourOffsets[c];
        int len = contourLengths[c];
        if (len < 1) continue;
        CGContextMoveToPoint(ctx, (CGFloat)pointsXY[off * 2],
                                  (CGFloat)pointsXY[off * 2 + 1]);
        for (int i = 1; i < len; i++)
            CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[(off + i) * 2],
                                         (CGFloat)pointsXY[(off + i) * 2 + 1]);
        if (closedFlags[c])
            CGContextClosePath(ctx);
    }
    CGContextStrokePath(ctx);

    CGContextRestoreGState(ctx);
}
