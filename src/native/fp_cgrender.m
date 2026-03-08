/*
 * fp_cgrender.m — Core Graphics anti-aliased rendering for FlatPaint.
 *
 * Compiled with clang separately, then linked into the FPC executable.
 * Provides C entry points for rendering anti-aliased shapes directly into
 * a premultiplied BGRA pixel buffer using Core Graphics.
 *
 * The pixel format is kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
 * which corresponds to the TRGBA32 packed record layout (B, G, R, A byte order)
 * used throughout FlatPaint's premultiplied-alpha pipeline.
 *
 * Core Graphics renders with sub-pixel anti-aliasing quality that complements
 * the pure-Pascal SDF approach for complex paths and stroked curves.
 *
 * Pascal side: FPCGRenderbridge.pas
 */

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

/*
 * Create a CGBitmapContext wrapping the given BGRA pixel buffer.
 * CG y-axis is bottom-up; we flip to match FlatPaint's top-down convention.
 * Returns NULL if allocation fails.
 */
static CGContextRef CreateFlippedContext(void *pixelBuffer, int width, int height) {
    if (!pixelBuffer || width <= 0 || height <= 0) return NULL;

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    /* kCGImageAlphaPremultipliedFirst = premul alpha in first byte (BGRA on little-endian) */
    CGContextRef ctx = CGBitmapContextCreate(
        pixelBuffer,
        (size_t)width,
        (size_t)height,
        8,
        (size_t)(width * 4),
        cs,
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
    );
    CGColorSpaceRelease(cs);
    if (!ctx) return NULL;

    /* Flip y-axis: translate origin to top-left, then mirror vertically */
    CGContextTranslateCTM(ctx, 0.0, (CGFloat)height);
    CGContextScaleCTM(ctx, 1.0, -1.0);

    /* Enable anti-aliasing */
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);

    return ctx;
}

/*
 * Render a filled ellipse with anti-aliasing.
 * Color components are straight alpha (0-255); CG premultiplies internally.
 */
void FPCGRenderFilledEllipse(void *pixelBuffer, int width, int height,
                              double cx, double cy, double rx, double ry,
                              int r, int g, int b, int a) {
    CGContextRef ctx = CreateFlippedContext(pixelBuffer, width, height);
    if (!ctx) return;

    CGContextSetRGBFillColor(ctx,
        (CGFloat)r / 255.0, (CGFloat)g / 255.0,
        (CGFloat)b / 255.0, (CGFloat)a / 255.0);

    CGRect ellipseRect = CGRectMake(cx - rx, cy - ry, rx * 2.0, ry * 2.0);
    CGContextFillEllipseInRect(ctx, ellipseRect);

    CGContextRelease(ctx);
}

/*
 * Render a stroked ellipse with anti-aliasing.
 */
void FPCGRenderStrokedEllipse(void *pixelBuffer, int width, int height,
                               double cx, double cy, double rx, double ry,
                               double strokeWidth,
                               int r, int g, int b, int a) {
    CGContextRef ctx = CreateFlippedContext(pixelBuffer, width, height);
    if (!ctx) return;

    CGContextSetRGBStrokeColor(ctx,
        (CGFloat)r / 255.0, (CGFloat)g / 255.0,
        (CGFloat)b / 255.0, (CGFloat)a / 255.0);
    CGContextSetLineWidth(ctx, (CGFloat)strokeWidth);

    /* Inset the rect by half the stroke width so the stroke doesn't extend
       beyond the specified radii */
    double halfStroke = strokeWidth / 2.0;
    CGRect ellipseRect = CGRectMake(cx - rx + halfStroke, cy - ry + halfStroke,
                                     (rx - halfStroke) * 2.0, (ry - halfStroke) * 2.0);
    CGContextStrokeEllipseInRect(ctx, ellipseRect);

    CGContextRelease(ctx);
}

/*
 * Render a filled polygon path with anti-aliasing.
 * pointsXY: interleaved array of doubles [x0, y0, x1, y1, ...].
 * count: number of POINTS (not doubles), i.e. array has count*2 elements.
 */
void FPCGRenderFilledPath(void *pixelBuffer, int width, int height,
                           const double *pointsXY, int count,
                           int r, int g, int b, int a) {
    if (!pointsXY || count < 3) return;
    CGContextRef ctx = CreateFlippedContext(pixelBuffer, width, height);
    if (!ctx) return;

    CGContextSetRGBFillColor(ctx,
        (CGFloat)r / 255.0, (CGFloat)g / 255.0,
        (CGFloat)b / 255.0, (CGFloat)a / 255.0);

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, (CGFloat)pointsXY[0], (CGFloat)pointsXY[1]);
    for (int i = 1; i < count; i++) {
        CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[i * 2], (CGFloat)pointsXY[i * 2 + 1]);
    }
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);

    CGContextRelease(ctx);
}

/*
 * Render a stroked cubic Bezier curve with anti-aliasing.
 * (x1,y1) = start point, (cx1,cy1)/(cx2,cy2) = control points, (x2,y2) = end point.
 */
void FPCGRenderStrokedBezier(void *pixelBuffer, int width, int height,
                              double x1, double y1,
                              double cx1, double cy1,
                              double cx2, double cy2,
                              double x2, double y2,
                              double strokeWidth,
                              int r, int g, int b, int a) {
    CGContextRef ctx = CreateFlippedContext(pixelBuffer, width, height);
    if (!ctx) return;

    CGContextSetRGBStrokeColor(ctx,
        (CGFloat)r / 255.0, (CGFloat)g / 255.0,
        (CGFloat)b / 255.0, (CGFloat)a / 255.0);
    CGContextSetLineWidth(ctx, (CGFloat)strokeWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, (CGFloat)x1, (CGFloat)y1);
    CGContextAddCurveToPoint(ctx,
        (CGFloat)cx1, (CGFloat)cy1,
        (CGFloat)cx2, (CGFloat)cy2,
        (CGFloat)x2, (CGFloat)y2);
    CGContextStrokePath(ctx);

    CGContextRelease(ctx);
}

/*
 * Render a stroked polyline with anti-aliasing.
 * pointsXY: interleaved array of doubles [x0, y0, x1, y1, ...].
 * count: number of POINTS (not doubles).
 * closed: if non-zero, closes the path.
 */
void FPCGRenderStrokedPath(void *pixelBuffer, int width, int height,
                            const double *pointsXY, int count, int closed,
                            double strokeWidth,
                            int r, int g, int b, int a) {
    if (!pointsXY || count < 2) return;
    CGContextRef ctx = CreateFlippedContext(pixelBuffer, width, height);
    if (!ctx) return;

    CGContextSetRGBStrokeColor(ctx,
        (CGFloat)r / 255.0, (CGFloat)g / 255.0,
        (CGFloat)b / 255.0, (CGFloat)a / 255.0);
    CGContextSetLineWidth(ctx, (CGFloat)strokeWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, (CGFloat)pointsXY[0], (CGFloat)pointsXY[1]);
    for (int i = 1; i < count; i++) {
        CGContextAddLineToPoint(ctx, (CGFloat)pointsXY[i * 2], (CGFloat)pointsXY[i * 2 + 1]);
    }
    if (closed) {
        CGContextClosePath(ctx);
    }
    CGContextStrokePath(ctx);

    CGContextRelease(ctx);
}
