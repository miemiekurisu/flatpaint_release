/*
 * fp_magnify.m — Native magnification (pinch-to-zoom) handler for FlatPaint.
 *
 * Compiled with clang separately, then linked into the FPC executable.
 * Uses Objective-C method swizzling to override -magnifyWithEvent: on a
 * target NSView so that LCL (which has no gesture support) can receive
 * pinch-to-zoom events.
 *
 * The Pascal side calls FPInstallMagnifyHandler() once after the canvas
 * TScrollBox has been created, passing the NSView handle and a callback
 * pointer.
 *
 * Callback signature (Pascal cdecl):
 *   procedure(AMagnification: Double; ALocationX, ALocationY: Double); cdecl;
 */

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

/* ---------- callback storage ---------- */

typedef void (*FPMagnifyCallback)(double magnification,
                                   double locationX,
                                   double locationY);

static FPMagnifyCallback gMagnifyCallback = NULL;

/* ---------- category on NSView ---------- */

@interface NSView (FPMagnify)
- (void)fp_magnifyWithEvent:(NSEvent *)event;
@end

@implementation NSView (FPMagnify)

- (void)fp_magnifyWithEvent:(NSEvent *)event {
    if (gMagnifyCallback) {
        NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
        gMagnifyCallback([event magnification], loc.x, loc.y);
    }
    /* Do NOT call the original — LCL's default impl is a no-op; calling it
       would just recurse via the swizzle. */
}

@end

/* ---------- public C entry point ---------- */

void FPInstallMagnifyHandler(void *nsViewHandle, void *callback) {
    if (!nsViewHandle || !callback) return;

    gMagnifyCallback = (FPMagnifyCallback)callback;

    /* Swizzle -magnifyWithEvent: on the *concrete* class of the passed view
       so we don't affect every NSView in the process. */
    Class viewClass = object_getClass((__bridge id)nsViewHandle);

    Method original = class_getInstanceMethod(viewClass, @selector(magnifyWithEvent:));
    Method replacement = class_getInstanceMethod([NSView class], @selector(fp_magnifyWithEvent:));

    if (original && replacement) {
        method_exchangeImplementations(original, replacement);
    } else if (replacement) {
        /* The class (or its parents) didn't override magnifyWithEvent: yet.
           Just add our implementation directly. */
        class_addMethod(viewClass,
                        @selector(magnifyWithEvent:),
                        method_getImplementation(replacement),
                        method_getTypeEncoding(replacement));
    }
}
