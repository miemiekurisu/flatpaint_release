/*
 * fp_scrollview.m - NSScrollView behavior helpers for FlatPaint.
 *
 * Disables elastic scrolling (rubber-band bounce) for the canvas scroll view
 * so viewport edges remain static under repeated boundary-direction input.
 */

#import <Cocoa/Cocoa.h>

void FPDisableScrollElasticity(void *nsViewHandle) {
    if (!nsViewHandle) return;

    NSView *view = (__bridge NSView *)nsViewHandle;
    NSScrollView *scrollView = nil;

    if ([view isKindOfClass:[NSScrollView class]]) {
        scrollView = (NSScrollView *)view;
    } else if (view.enclosingScrollView) {
        scrollView = view.enclosingScrollView;
    }

    if (!scrollView) return;

    if ([scrollView respondsToSelector:@selector(setHorizontalScrollElasticity:)]) {
        [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    }
    if ([scrollView respondsToSelector:@selector(setVerticalScrollElasticity:)]) {
        [scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    }
}
