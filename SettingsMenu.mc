using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Lang;

//
// SettingsMenu.mc - on-device settings ("Customize" from the watch-face
// carousel), separate from the phone-based settings.xml/properties.xml
// mechanism already in this project.
//
// SHARED FILE: this lives in garmin/shared-src/, not inside any single
// project's own source/ folder, and is pulled into rossonero,
// milan-personal, and santorini-sunset via each project's monkey.jungle
// (`base.sourcePath = source;../shared-src`). It was byte-identical
// across all three projects already (only a per-project class-name
// prefix differed, e.g. RossoneroSettingsMenu vs
// SantoriniSunsetSettingsMenu - dropped here since one copy now compiles
// into all three), and this exact file had already been hand-ported with
// `sed` three separate times in one session before this - moving it here
// once, instead of copy-pasting again next time a field/setting changes.
// Edit THIS copy, not a per-project one - there shouldn't be a per-
// project copy anymore. Relies on all three projects' strings.xml
// defining the same string resource IDs this file references
// (SettingClockStyle, ClockStyleDigital/Analog, FieldSteps through
// FieldWorldClock, etc.) - if a future setting adds a new string here,
// it needs adding to all three projects' strings.xml, or that project's
// build will fail with an undefined Rez.Strings reference (which is a
// good thing: a build error beats the three projects silently drifting
// out of sync the way manually porting risked).
//
// You asked whether the gear-icon/"Customize" flow you'd seen on other
// installed faces was something we could add here too. Researched it
// properly rather than guessing (see AppBase.getSettingsView() in
// Garmin's Properties and App Settings doc + the WatchUi.Menu2 API docs):
// it's a real, third-party-usable API since Connect IQ 3.2.0 (this
// project targets 4.0.0, so no issue), separate from the phone/Connect
// Mobile settings system - it works even sideloaded, no store
// publication needed, which is exactly the "test it right now" path you
// want.
//
// IMPORTANT design note: getSettingsView() is deliberately implemented
// to return the real top-level menu/delegate pair directly (see
// App.mc), NOT a wrapper View that itself pushes a menu.
// Garmin's own bundled "Analog" sample app uses that wrapper pattern,
// and multiple real forum bug reports trace a double-back-press glitch
// on real hardware directly to it - not something I can catch myself
// without a device, so the flatter, confirmed-working pattern was used
// instead of copying Analog's structure.
//
// This is a SECOND, independent way to set Field1/Field2/Field3/
// WorldClockOffset - it reads/writes the exact same Properties as the
// phone-based settings.xml, so whichever one you use most recently wins;
// they can't get out of sync with each other.

class SettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Customize"});
        addItem(new WatchUi.MenuItem("Left circle", currentFieldLabel("Field1", 0), :field1, {}));
        addItem(new WatchUi.MenuItem("Middle circle", currentFieldLabel("Field2", 1), :field2, {}));
        addItem(new WatchUi.MenuItem("Right circle", currentFieldLabel("Field3", 2), :field3, {}));
        addItem(new WatchUi.MenuItem("World clock offset", currentWorldClockLabel(), :worldClock, {}));
        addItem(new WatchUi.MenuItem(Rez.Strings.SettingClockStyle, currentClockStyleLabel(), :clockStyle, {}));
    }
}

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id.equals(:field1)) {
            pushFieldPicker(item, "Field1");
        } else if (id.equals(:field2)) {
            pushFieldPicker(item, "Field2");
        } else if (id.equals(:field3)) {
            pushFieldPicker(item, "Field3");
        } else if (id.equals(:worldClock)) {
            pushWorldClockPicker(item);
        } else if (id.equals(:clockStyle)) {
            pushClockStylePicker(item);
        }
    }

    // Submenu listing all 10 selectable fields - same FIELD_* ids as
    // View.mc's constants and settings.xml's Field1/2/3 list
    // values. propKey is which of Field1/Field2/Field3 this circle is.
    function pushFieldPicker(parentItem as WatchUi.MenuItem, propKey as Lang.String) as Void {
        var menu = new WatchUi.Menu2({:title => parentItem.getLabel()});
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldSteps, null, 0, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldHeartRate, null, 1, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldCalories, null, 2, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldDistance, null, 3, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldFloors, null, 4, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldActiveMinutes, null, 5, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldBattery, null, 6, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldStress, null, 7, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldTemperature, null, 8, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.FieldWorldClock, null, 9, {}));
        WatchUi.pushView(menu, new FieldPickerDelegate(parentItem, propKey), WatchUi.SLIDE_IMMEDIATE);
    }

    // Whole-hour UTC offsets only, same range as settings.xml's
    // WorldClockOffset list (-12..+14) - see View.mc's
    // worldClockText() for why this is a fixed offset, not a real
    // timezone/DST lookup. Kept as plain "UTC+N" text here rather than
    // the city-name hints ("UTC-5 (New York)") the phone-based Settings
    // show, to keep this on-device submenu's code (and the watch's tiny
    // screen) simple - the offset number is what actually matters.
    function pushWorldClockPicker(parentItem as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({:title => "World clock offset"});
        var offset = -12;
        while (offset <= 14) {
            menu.addItem(new WatchUi.MenuItem(utcLabel(offset), null, offset, {}));
            offset += 1;
        }
        WatchUi.pushView(menu, new WorldClockPickerDelegate(parentItem), WatchUi.SLIDE_IMMEDIATE);
    }

    // Digital (the original hour:minute readout) vs Analog (hour/minute
    // hands from screen center) - see View.mc's drawAnalogTime()
    // for the design tradeoffs of the analog option.
    function pushClockStylePicker(parentItem as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({:title => parentItem.getLabel()});
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.ClockStyleDigital, null, 0, {}));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.ClockStyleAnalog, null, 1, {}));
        WatchUi.pushView(menu, new ClockStylePickerDelegate(parentItem), WatchUi.SLIDE_IMMEDIATE);
    }
}

class FieldPickerDelegate extends WatchUi.Menu2InputDelegate {
    private var _parentItem as WatchUi.MenuItem;
    private var _propKey as Lang.String;

    function initialize(parentItem as WatchUi.MenuItem, propKey as Lang.String) {
        Menu2InputDelegate.initialize();
        _parentItem = parentItem;
        _propKey = propKey;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var fieldId = item.getId() as Lang.Number;
        Properties.setValue(_propKey, fieldId);
        _parentItem.setSubLabel(fieldLabelText(fieldId));
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class WorldClockPickerDelegate extends WatchUi.Menu2InputDelegate {
    private var _parentItem as WatchUi.MenuItem;

    function initialize(parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var offset = item.getId() as Lang.Number;
        Properties.setValue("WorldClockOffset", offset);
        _parentItem.setSubLabel(utcLabel(offset));
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class ClockStylePickerDelegate extends WatchUi.Menu2InputDelegate {
    private var _parentItem as WatchUi.MenuItem;

    function initialize(parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var style = item.getId() as Lang.Number;
        Properties.setValue("ClockStyle", style);
        _parentItem.setSubLabel(clockStyleLabelText(style));
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

// ---- Shared label helpers --------------------------------------------

function currentFieldLabel(propKey as Lang.String, defaultId as Lang.Number) as Lang.String {
    var id = Properties.getValue(propKey) as Lang.Number?;
    if (id == null) { id = defaultId; }
    return fieldLabelText(id);
}

function fieldLabelText(fieldId as Lang.Number) as Lang.String {
    if (fieldId == 1) {
        return WatchUi.loadResource(Rez.Strings.FieldHeartRate) as Lang.String;
    } else if (fieldId == 2) {
        return WatchUi.loadResource(Rez.Strings.FieldCalories) as Lang.String;
    } else if (fieldId == 3) {
        return WatchUi.loadResource(Rez.Strings.FieldDistance) as Lang.String;
    } else if (fieldId == 4) {
        return WatchUi.loadResource(Rez.Strings.FieldFloors) as Lang.String;
    } else if (fieldId == 5) {
        return WatchUi.loadResource(Rez.Strings.FieldActiveMinutes) as Lang.String;
    } else if (fieldId == 6) {
        return WatchUi.loadResource(Rez.Strings.FieldBattery) as Lang.String;
    } else if (fieldId == 7) {
        return WatchUi.loadResource(Rez.Strings.FieldStress) as Lang.String;
    } else if (fieldId == 8) {
        return WatchUi.loadResource(Rez.Strings.FieldTemperature) as Lang.String;
    } else if (fieldId == 9) {
        return WatchUi.loadResource(Rez.Strings.FieldWorldClock) as Lang.String;
    }
    // 0, and the fallback for any unrecognized value.
    return WatchUi.loadResource(Rez.Strings.FieldSteps) as Lang.String;
}

function currentWorldClockLabel() as Lang.String {
    var offset = Properties.getValue("WorldClockOffset") as Lang.Number?;
    if (offset == null) { offset = 0; }
    return utcLabel(offset);
}

function utcLabel(offset as Lang.Number) as Lang.String {
    if (offset > 0) {
        return "UTC+" + offset.format("%d");
    } else if (offset < 0) {
        return "UTC" + offset.format("%d");
    }
    return "UTC+0";
}

function currentClockStyleLabel() as Lang.String {
    var style = Properties.getValue("ClockStyle") as Lang.Number?;
    if (style == null) { style = 0; }
    return clockStyleLabelText(style);
}

function clockStyleLabelText(style as Lang.Number) as Lang.String {
    if (style == 1) {
        return WatchUi.loadResource(Rez.Strings.ClockStyleAnalog) as Lang.String;
    }
    return WatchUi.loadResource(Rez.Strings.ClockStyleDigital) as Lang.String;
}
