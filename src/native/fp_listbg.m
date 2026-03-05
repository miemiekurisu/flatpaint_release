/*
 * fp_listbg.m — NSScrollView background-color helper for FlatPaint.
 *
 * Compiled with clang separately, then linked into the FPC executable.
 * Provides a C entry point that sets the background color of the
 * NSScrollView wrapping a TListBox to a specified RGB color.
 *
 * On macOS Cocoa, TListBox with lbOwnerDrawFixed may not propagate the
 * LCL Color property to the native NSScrollView/NSTableView background.
 * The empty area below the last drawn item defaults to black/dark.
 * This helper explicitly sets the background color on both the scroll
 * view and its document view.
 *
 * Pascal side:
 *   FPSetListBackground(AHandle: Pointer; R, G, B: Double); cdecl;
 */

#import <Cocoa/Cocoa.h>

void FPSetListBackground(void *nsViewHandle, double r, double g, double b) {
    if (!nsViewHandle) return;
    NSView *view = (__bridge NSView *)nsViewHandle;
    NSColor *color = [NSColor colorWithCalibratedRed:(CGFloat)r
                                               green:(CGFloat)g
                                                blue:(CGFloat)b
                                               alpha:1.0];

    /* The LCL handle may point to the scroll view itself or a child view.
       Walk up to find the enclosing NSScrollView. */
    NSScrollView *scrollView = nil;
    if ([view isKindOfClass:[NSScrollView class]])
        scrollView = (NSScrollView *)view;
    else if (view.enclosingScrollView)
        scrollView = view.enclosingScrollView;

    if (scrollView) {
        [scrollView setDrawsBackground:YES];
        [scrollView setBackgroundColor:color];
        /* Also set on the document view (NSTableView) if present */
        if ([scrollView.documentView respondsToSelector:@selector(setBackgroundColor:)]) {
            [(id)scrollView.documentView setBackgroundColor:color];
        }
    } else {
        /* Fallback: directly set the layer background */
        view.wantsLayer = YES;
        view.layer.backgroundColor = [color CGColor];
    }
}
