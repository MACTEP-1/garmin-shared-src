using Toybox.Time;
using Toybox.Lang;

//
// MoonPhase.mc - pure date-math moon phase calculation. Unlike the
// sunrise/sunset fields elsewhere in this codebase, this needs no
// Weather/Positioning permission and no location at all - the physical
// lunar phase is the same everywhere on Earth at a given instant, only
// the *local clock time* it rises/sets differs (which this doesn't
// attempt to show - just which of the 8 standard phases it's in).
//
// Formula: days elapsed since a known new moon, mod the synodic month,
// gives the moon's current "age" (0 = new, ~14.77 = full, ~29.53 = back
// to new). Reference epoch and synodic-month constant cross-checked
// against two independent sources before use (a commonly-cited "known
// new moon" reference of 2000-01-06 18:14 UTC, and a second source's
// SYNODIC_SECONDS=2551443 constant, which is independently derivable as
// 29.530588853 days * 86400 rounded - the two agree to within a second,
// so used with confidence rather than picked arbitrarily). Accurate to
// roughly half a day, more than enough precision for picking 1 of 8 icon
// buckets that each span about 3.7 days.
//
// Confirmed real API: Toybox.Time.Moment.value() - Garmin's own docs:
// "the UTC date of the Moment in seconds since the UNIX epoch." Time.now()
// itself is already used elsewhere in this codebase (worldClockText()/
// sunriseText() in each View.mc), just not .value() specifically before
// this file.
//
// SHARED FILE: lives in garmin/garmin-shared-src/, pulled into all three
// projects via monkey.jungle - see SettingsMenu.mc's header for the full
// explanation of why this folder exists. This file has no per-project
// state at all (pure function of "now"), so a single copy carries zero
// risk of drifting between projects the way hand-ported files used to.
//

// Unix epoch seconds for a known new moon: 2000-01-06 18:14:00 UTC.
// (946684800 = 2000-01-01T00:00:00Z, a commonly-cited constant, plus
// 5 days 18h14m = 497640 seconds.)
const MOON_REF_EPOCH = 947182440;

// Average synodic month (new moon to new moon), in seconds.
// 29.530588853 days * 86400 = 2551442.88..., rounded the same way the
// cross-checked source did.
const MOON_SYNODIC_SECONDS = 2551443;

// Returns 0-7: 0=New, 1=Waxing Crescent, 2=First Quarter, 3=Waxing
// Gibbous, 4=Full, 5=Waning Gibbous, 6=Last Quarter, 7=Waning Crescent.
// Standard 8-bucket division of the cycle, each bucket 1/8 wide with
// boundaries at odd multiples of 1/16 (so New is centered on fraction 0,
// not starting there).
function moonPhaseIndex() as Lang.Number {
    var nowEpoch = Time.now().value();
    var diff = nowEpoch - MOON_REF_EPOCH;
    var sinceNewMoon = diff % MOON_SYNODIC_SECONDS;
    if (sinceNewMoon < 0) {
        // Defensive only - diff is always positive for any real device
        // clock (this reference date is in 2000), but cheap to guard.
        sinceNewMoon += MOON_SYNODIC_SECONDS;
    }
    var fraction = sinceNewMoon / MOON_SYNODIC_SECONDS.toFloat(); // 0.0-1.0
    var bucket = ((fraction * 8.0) + 0.5).toNumber() % 8;
    return bucket;
}

// Single-glyph emoji for a moonPhaseIndex() result, shown as the badge's
// text row under the icon - shared here so all three View.mc's field-
// badge text stays identical without triplicating this array.
//
// HISTORY: originally used short text labels ("New", "Wax Cr", "Last
// Qtr", etc.) after an even-earlier full-name version ("Waxing Crescent")
// overflowed the badge on real hardware. Replaced with these emoji after
// the user explicitly asked to test whether Garmin's built-in system font
// even has these glyphs - real UTF-8 characters typed directly into this
// string literal (not an escape sequence - Monkey C's exact \u syntax
// couldn't be confirmed from Garmin's own docs, JS-rendered/unfetchable
// from this sandbox, so raw characters in the source sidesteps that
// uncertainty). Two rounds of on-device testing on the user's Venu 2
// (milan-personal only, before this was merged into the shared file):
// first, all 8 concatenated confirmed the glyphs render as distinct
// shapes rather than blank/tofu boxes (the font does have them); second,
// a single glyph for the real current phase confirmed it fits the badge
// cleanly, unlike the earlier text labels.
//
// KNOWN, CONSCIOUSLY ACCEPTED RISK: only confirmed on the Venu 2. Both
// rossonero and santorini-sunset target 8 other device models (epix2,
// fenix7/7s/7x, fr265/265s, fr965, venu2s, vivoactive5) this can't be
// tested on from this sandbox, and Garmin's own bug tracker has a
// confirmed real-world case of a font present on one physical device
// (Epix 2) being entirely missing on another (Fenix 8, specific
// firmware), silently falling back to a different font instead -
// https://forums.garmin.com/developer/connect-iq/i/bug-reports/fenix-8-47-51---font-mismatch---bionicbold-displayed-as-bionic-semi-bold
// - so glyph availability genuinely can vary by device/firmware in this
// ecosystem. Presented to the user as an explicit tradeoff (vector icons
// below have zero device-variance risk since they're drawn from raw
// shapes, not a font) before proceeding - user chose emoji everywhere
// over the safer per-project split. Worst-case failure mode on an
// untested device is expected to be a blank/fallback-font glyph for this
// one field, not a crash, but that's inference from the Fenix 8 case
// above, not a tested guarantee.
function moonPhaseEmoji(index as Lang.Number) as Lang.String {
    var emoji = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"];
    if (index < 0 || index >= emoji.size()) {
        return "--";
    }
    return emoji[index];
}
