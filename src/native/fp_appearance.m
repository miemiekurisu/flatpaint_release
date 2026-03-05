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
