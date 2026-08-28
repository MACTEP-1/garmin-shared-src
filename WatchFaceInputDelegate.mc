using Toybox.WatchUi;
using Toybox.Lang;

//
// WatchFaceInputDelegate.mc - long-press-to-swap-fields, added after you
// described a watch face where a long press swaps the data-field circles
// to an alternate, separately-configurable set instead of doing nothing
// (or leaving the watch-face carousel/Controls menu to the physical
// button, which those already do independently of this).
//
// SHARED FILE, same convention as SettingsMenu.mc in this folder: one
// copy, pulled into rossonero/milan-personal/santorini-sunset via each
// project's monkey.jungle sourcePath. Duck-typed against `view` rather
// than importing a per-project View class, so this one file works for
// all three - each project's View just needs a toggleAltFields() method
// (see <Project>View.mc's toggleAltFields()).
//
// RESEARCHED, not guessed, before writing this - a genuinely non-obvious
// API for a watch face specifically (most watch-face code in this project
// has been drawing-only; this is the first time a watch face here
// receives live input):
//   - Toybox.WatchUi.WatchFaceDelegate exists specifically for this and
//     has been in the SDK since API 2.3.0, but its onPress(clickEvent)
//     method (touch-and-hold) needs API 4.2.0+ - confirmed against
//     Garmin's own WatchFaceDelegate docs. This project's manifest.xml
//     was bumped from 4.0.0 to 4.2.0 for exactly this (see manifest.xml's
//     comment - this dropped vivoactive4 from rossonero's and
//     milan-personal's device lists, a deliberate tradeoff you approved;
//     santorini-sunset had already dropped vivoactive4 earlier so wasn't
//     affected either way).
//   - A real forum thread (forums.garmin.com/developer/connect-iq/f/
//     discussion/5386) confirms watch faces couldn't receive ANY input at
//     all before API 4.2.0, and specifically that "a small tap does not
//     work" for a watch face - you have to tap-and-hold (onPress) to get
//     a callback, which matches exactly what you described seeing on
//     another face and what this implements.
//   - onPress only fires on touchscreen devices - every device in this
//     project's manifest.xml is touchscreen-capable (Venu 2/2S, vivoactive
//     5, fenix 7 series, epix 2, FR265/265s/965), so this isn't expected
//     to silently no-op anywhere in the current device list, but there's
//     no way to confirm the exact on-device feel (does it conflict with
//     anything, how long is "hold") without your own build - flagged in
//     the README same as every other never-compiled-here feature.
//
class WatchFaceInputDelegate extends WatchUi.WatchFaceDelegate {
    private var _view;

    // `view` is deliberately untyped (no `as` clause) - it's one of three
    // different concrete View classes (RossoneroView/MilanPersonalView/
    // SantoriniSunsetView) depending which project this compiles into,
    // with no shared base class declaring toggleAltFields(), so there's
    // no single static type to give it that wouldn't be a lie for two of
    // the three projects. This project has no typeCheckLevel set in any
    // monkey.jungle (SDK default applies), which permits calling a method
    // on an untyped/Object-ish reference - if a stricter typecheck level
    // is ever turned on project-wide, this is the one spot that would
    // need revisiting (e.g. a shared marker interface).
    function initialize(view) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    // touch-and-hold anywhere on the face - no need to check clickEvent's
    // coordinates, this is a whole-face toggle, not a per-region tap.
    function onPress(clickEvent) as Lang.Boolean {
        _view.toggleAltFields();
        return true;
    }
}
