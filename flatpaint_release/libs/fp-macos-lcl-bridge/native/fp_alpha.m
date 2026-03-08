/*
 * fp_alpha.m — NSView alpha-value helper for FlatPaint.
 *
 * Compiled with clang separately, then linked into the FPC executable.
 * Provides a simple C entry point that sets the alpha (opacity) of any
 * NSView to the given value (0.0 = fully transparent, 1.0 = fully opaque).
 *
 * Used to make floating palette panels semi-transparent while the user
 * drags them so the canvas remains visible beneath.
 *
 * Pascal side: FPSetViewAlpha(AHandle: Pointer; AAlpha: Double); cdecl;
 */

#import <Cocoa/Cocoa.h>

void FPSetViewAlpha(void *nsViewHandle, double alpha) {
    if (!nsViewHandle) return;
    NSView *view = (__bridge NSView *)nsViewHandle;
    [view setAlphaValue:(CGFloat)alpha];
}
