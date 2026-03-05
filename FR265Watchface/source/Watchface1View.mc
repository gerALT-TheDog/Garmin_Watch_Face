import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
// Date and time imports
import Toybox.Time;
import Toybox.Time.Gregorian;
// Step tracking import
import Toybox.ActivityMonitor;
//Weather import
import Toybox.Weather;

class Watchface1View extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
    // Clear the screen
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var width = dc.getWidth();
    var height = dc.getHeight();
    var centerX = width / 2;
    var centerY = height / 2;

    // ── TIME & DATE ──────────────────────────────────────────
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var minutes = clockTime.min.format("%02d");
    var timeString = Lang.format("$1$:$2$", [hours.format("%02d"), minutes]);

    var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    var dateString = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.month, today.day]);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(centerX, centerY - 60, Graphics.FONT_LARGE, timeString, Graphics.TEXT_JUSTIFY_CENTER);

    dc.setPenWidth(1);
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(centerX - 50, centerY + 5, centerX + 50, centerY + 5);

    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(centerX, centerY + 10, Graphics.FONT_SMALL, dateString, Graphics.TEXT_JUSTIFY_CENTER);

// ── OUTER RING SETUP ─────────────────────────────────────
    var ringRadius = centerX - 10;
    dc.setPenWidth(10);

   // ── STEPS (top-left quarter) ──────────────────────────────
    var stepInfo = ActivityMonitor.getInfo();
    var steps = stepInfo.steps != null ? stepInfo.steps.toFloat() : 0.0;
    var stepGoal = stepInfo.stepGoal != null ? stepInfo.stepGoal.toFloat() : 10000.0;
    var stepPercent = steps / stepGoal;
    if (stepPercent > 1.0) { stepPercent = 1.0; }

    // Background (full quarter)
    dc.setColor(0x0C2624, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 180, 90);

    // Progress (grows clockwise from 180°)
    if (stepPercent > 0) {
        dc.setColor(0x184D47, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 180, 180 - (stepPercent * 90).toNumber());
    }

    // ── CALORIES (bottom-left quarter) ───────────────────────
    var calories = stepInfo.calories != null ? stepInfo.calories.toFloat() : 0.0;
    var calGoal = 500.0;
    var calPercent = calories / calGoal;
    if (calPercent > 1.0) { calPercent = 1.0; }

    // Background (full quarter)
    dc.setColor(0x4A5C3C, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 270, 180);

    // Progress (grows clockwise from 270°)
    if (calPercent > 0) {
        dc.setColor(0x96BB7C, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 270, 270 - (calPercent * 90).toNumber());
    }

    // ── BATTERY (bottom-right quarter) ───────────────────────
    var stats = System.getSystemStats();
    var battery = stats.battery != null ? stats.battery.toFloat() : 100.0;
    var batPercent = battery / 100.0;

    // Background (full quarter)
    dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 360, 270);

    // Progress color
    var batColor;
    if (battery > 50) {
        batColor = 0x49FF00;
    } else if (battery > 20) {
        batColor = 0xFBFF00;
    } else {
        batColor = 0xFF0000;
    }

    // Battery shrinks as it depletes (starts full, shrinks toward 270°) (shrinks counter-clockwise)
    dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_COUNTER_CLOCKWISE, 270, 270 + (batPercent * 90).toNumber());


// ── WEATHER (top-right) ───────────────────────────────────
    var weatherX = width - 85;
    var weatherY = 55;

    var conditions = Weather.getCurrentConditions();
    var cond = 0;
    var tempF = "---";

    if (conditions != null) {
        if (conditions.condition != null) {
            cond = conditions.condition.toNumber();
        }
        if (conditions.temperature != null) {
            var tempC = conditions.temperature;
            tempF = (((tempC * 9) / 5) + 32).format("%d") + "F";
        }
    }

    // Pick icon based on condition
    var weatherIcon;
    if (cond == 0 || cond == 40) {
        weatherIcon = Rez.Drawables.ImgSunny;
    } else if (cond == 2 || cond == 1 || cond == 52) {
        weatherIcon = Rez.Drawables.ImgCloudy;
    } else if (cond == 3 || cond == 11 || cond == 13 || cond == 14) {
        weatherIcon = Rez.Drawables.ImgRainy;
    } else if (cond == 5 || cond == 8 || cond == 9) {
        weatherIcon = Rez.Drawables.ImgSnowy;
    } else if (cond == 32 || cond == 38) {
        weatherIcon = Rez.Drawables.ImgWindy;
    } else if (cond == 6 || cond == 7) {
        weatherIcon = Rez.Drawables.ImgStormy;
    } else {
        weatherIcon = Rez.Drawables.ImgPartlyCloudy;
    }

    // Draw the icon
    var icon = new WatchUi.Bitmap({
        :rezId => weatherIcon,
        :locX => weatherX - 20,
        :locY => weatherY
    });
    icon.draw(dc);

    // Draw temperature below icon
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(weatherX, weatherY + 44, Graphics.FONT_XTINY, tempF, Graphics.TEXT_JUSTIFY_CENTER);
}
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
