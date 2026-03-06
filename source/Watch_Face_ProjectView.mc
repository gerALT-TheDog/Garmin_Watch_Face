import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Weather;

// ═══════════════════════════════════════════════════════════════
//  WeatherManager – handles weather data via Toybox.Weather
// ═══════════════════════════════════════════════════════════════

class WeatherManager {

    private static var CONDITION_LABELS as Dictionary = {
        Weather.CONDITION_CLEAR                   => "Clear",
        Weather.CONDITION_PARTLY_CLOUDY           => "Partly Cloudy",
        Weather.CONDITION_MOSTLY_CLOUDY           => "Mostly Cloudy",
        Weather.CONDITION_RAIN                    => "Rain",
        Weather.CONDITION_SNOW                    => "Snow",
        Weather.CONDITION_WINDY                   => "Windy",
        Weather.CONDITION_THUNDERSTORMS           => "Thunderstorms",
        Weather.CONDITION_WINTRY_MIX              => "Wintry Mix",
        Weather.CONDITION_FOG                     => "Fog",
        Weather.CONDITION_HAZY                    => "Hazy",
        Weather.CONDITION_HAIL                    => "Hail",
        Weather.CONDITION_SCATTERED_SHOWERS       => "Showers",
        Weather.CONDITION_SCATTERED_THUNDERSTORMS => "T-Storms",
        Weather.CONDITION_CLOUDY                  => "Cloudy",
        Weather.CONDITION_DRIZZLE                 => "Drizzle",
        Weather.CONDITION_TORNADO                 => "Tornado",
        Weather.CONDITION_DUST                    => "Dusty",
        Weather.CONDITION_SANDSTORM               => "Sandstorm",
        Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN    => "Chance Rain",
        Weather.CONDITION_RAIN_SNOW               => "Rain/Snow",
        Weather.CONDITION_CHANCE_OF_RAIN_SNOW      => "Chance Rain/Snow",
        Weather.CONDITION_CHANCE_OF_SNOW           => "Chance Snow",
        Weather.CONDITION_CHANCE_OF_THUNDERSTORMS  => "Chance T-Storm",
        Weather.CONDITION_LIGHT_RAIN              => "Light Rain",
        Weather.CONDITION_HEAVY_RAIN              => "Heavy Rain",
        Weather.CONDITION_LIGHT_SNOW              => "Light Snow",
        Weather.CONDITION_HEAVY_SNOW              => "Heavy Snow",
        Weather.CONDITION_SMOKE                   => "Smoke"
    };

    private var _tempCelsius      as Number  = 0;
    private var _feelsLike        as Number  = 0;
    private var _conditionCode    as Number  = 13;
    private var _conditionLabel   as String  = "Unknown";
    private var _humidity         as Number  = 0;
    private var _windSpeed        as Float   = 0.0;
    private var _windDirection    as Number  = 0;
    private var _uvIndex          as Number  = 0;
    private var _isMetric         as Boolean = true;
    private var _dataAvailable    as Boolean = false;
    private var _lastUpdateEpoch  as Number  = 0;

    private static const STALE_THRESHOLD_SEC as Number = 1800;

    function update() as Void {
        var devSettings = System.getDeviceSettings();
        _isMetric = (devSettings.temperatureUnits == System.UNIT_METRIC);

        var conditions = Weather.getCurrentConditions();
        if (conditions == null) {
            _dataAvailable = false;
            return;
        }

        _dataAvailable = true;
        _tempCelsius   = (conditions.temperature != null) ? conditions.temperature : 0;
        _feelsLike     = (conditions.feelsLikeTemperature != null) ? conditions.feelsLikeTemperature : _tempCelsius;
        _conditionCode = (conditions.condition != null) ? conditions.condition : Weather.CONDITION_UNKNOWN_PRECIPITATION;
        _conditionLabel = getLabel(_conditionCode);
        _humidity      = (conditions.relativeHumidity       != null) ? conditions.relativeHumidity       : 0;
        _windSpeed     = (conditions.windSpeed               != null) ? conditions.windSpeed.toFloat()    : 0.0;
        _windDirection = (conditions.windBearing             != null) ? conditions.windBearing             : 0;
        _uvIndex       = (conditions.uvIndex                 != null) ? conditions.uvIndex                 : 0;
        _lastUpdateEpoch = System.getClockTime().sec;
    }

    function getTemperature() as Number {
        return _isMetric ? _tempCelsius : celsiusToFahrenheit(_tempCelsius);
    }

    function getTemperatureFahrenheit() as Number {
        return celsiusToFahrenheit(_tempCelsius);
    }

    function getFeelsLike() as Number {
        return _isMetric ? _feelsLike : celsiusToFahrenheit(_feelsLike);
    }

    function getTemperatureUnit() as String {
        return _isMetric ? "C" : "F";
    }

    function getConditionCode() as Number {
        return _conditionCode;
    }

    function getConditionLabel() as String {
        return _conditionLabel;
    }

    function getHumidity() as Number {
        return _humidity;
    }

    function getWindSpeed() as Float {
        return _isMetric ? _windSpeed * 3.6 : _windSpeed * 2.237;
    }

    function getWindSpeedUnit() as String {
        return _isMetric ? "km/h" : "mph";
    }

    function getWindDirection() as Number {
        return _windDirection;
    }

    function getWindCardinal() as String {
        var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"];
        var idx  = ((_windDirection + 22) / 45).toNumber();
        return dirs[idx];
    }

    function getUVIndex() as Number {
        return _uvIndex;
    }

    function getUVLabel() as String {
        if (_uvIndex <= 2)  { return "Low"; }
        if (_uvIndex <= 5)  { return "Moderate"; }
        if (_uvIndex <= 7)  { return "High"; }
        if (_uvIndex <= 10) { return "Very High"; }
        return "Extreme";
    }

    function isDataAvailable() as Boolean {
        return _dataAvailable;
    }

    function isDataStale() as Boolean {
        if (!_dataAvailable) { return true; }
        var now = System.getClockTime().sec;
        return (now - _lastUpdateEpoch) > STALE_THRESHOLD_SEC;
    }

    function isMetric() as Boolean {
        return _isMetric;
    }

    private function celsiusToFahrenheit(c as Number) as Number {
        return (c * 9 / 5) + 32;
    }

    private function getLabel(code as Number) as String {
        if (CONDITION_LABELS.hasKey(code)) {
            return CONDITION_LABELS[code] as String;
        }
        return "Unknown";
    }
}

// ═══════════════════════════════════════════════════════════════
//  Watchface1View
//
//  Ring layout:
//    Top-left     (180°→90°)   = Steps
//    Bottom-left  (270°→180°)  = Calories
//    Bottom-right (360°→270°)  = Battery %
//    Top-right                 = Weather (icon + temp)
//
//  Background shifts by time of day:
//    Morning   (6:00–10:59)   – dark warm navy   0x1A1A2E
//    Midday    (11:00–13:59)  – deep steel blue   0x16213E
//    Afternoon (14:00–17:59)  – warm dark slate   0x1B1B2F
//    Night     (18:00–5:59)   – pure black        0x000000
// ═══════════════════════════════════════════════════════════════

class Watchface1View extends WatchUi.WatchFace {

    private var _weatherMgr as WeatherManager;

    function initialize() {
        WatchFace.initialize();
        _weatherMgr = new WeatherManager();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
    }

    // ── Time-of-day color helpers ────────────────────────────

    private function getBackgroundColor(h as Number) as Number {
        if (h >= 6 && h < 11)  { return 0x1A1A2E; }
        if (h >= 11 && h < 14) { return 0x16213E; }
        if (h >= 14 && h < 18) { return 0x1B1B2F; }
        return 0x000000;
    }

    private function getTimeColor(h as Number) as Number {
        if (h >= 6 && h < 11)  { return 0xFFBE76; }
        if (h >= 11 && h < 14) { return 0xFFFFFF; }
        if (h >= 14 && h < 18) { return 0xF6B93B; }
        return 0xA4B0BE;
    }

    private function getDateColor(h as Number) as Number {
        if (h >= 6 && h < 11)  { return 0xD4A76A; }
        if (h >= 11 && h < 14) { return 0xC8D6E5; }
        if (h >= 14 && h < 18) { return 0xD4A76A; }
        return 0x636E72;
    }

    private function getDividerColor(h as Number) as Number {
        if (h >= 6 && h < 11)  { return 0x8B7355; }
        if (h >= 11 && h < 14) { return 0x576574; }
        if (h >= 14 && h < 18) { return 0x8B7355; }
        return 0x2F3640;
    }

    // ── Main draw ────────────────────────────────────────────

    function onUpdate(dc as Dc) as Void {
        // Load fonts
        var fontLarge = WatchUi.loadResource(Rez.Fonts.AudiowideLarge);
        var fontSmall = WatchUi.loadResource(Rez.Fonts.AudiowideSmall);
        var fontXSmall = WatchUi.loadResource(Rez.Fonts.fontXSmall);

        var clockTime = System.getClockTime();
        var hour      = clockTime.hour;

        // Clear with time-of-day background
        var bgColor = getBackgroundColor(hour);
        dc.setColor(bgColor, bgColor);
        dc.clear();

        var width   = dc.getWidth();
        var height  = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        // ── TIME & DATE ──────────────────────────────────────
        var hours = hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            } else if (hours == 0) {
                hours = 12;
            }
        }

        var minutes    = clockTime.min.format("%02d");
        var timeString = Lang.format("$1$:$2$", [hours.format("%02d"), minutes]);

        var today      = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.month, today.day]);

        dc.setColor(getTimeColor(hour), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 60, fontLarge, timeString, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setPenWidth(1);
        dc.setColor(getDividerColor(hour), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - 50, centerY + 5, centerX + 50, centerY + 5);

        dc.setColor(getDateColor(hour), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 10, fontSmall, dateString, Graphics.TEXT_JUSTIFY_CENTER);

        // ── ACTIVITY DATA ─────────────────────────────────────
        var stepInfo    = ActivityMonitor.getInfo();
        var steps       = stepInfo.steps    != null ? stepInfo.steps.toFloat()    : 0.0;
        var stepGoal    = stepInfo.stepGoal != null ? stepInfo.stepGoal.toFloat() : 10000.0;
        var stepPercent = steps / stepGoal;
        if (stepPercent > 1.0) { stepPercent = 1.0; }

        var calories    = stepInfo.calories != null ? stepInfo.calories.toFloat() : 0.0;
        var calGoal     = 500.0;
        var calPercent  = calories / calGoal;
        if (calPercent > 1.0) { calPercent = 1.0; }

        var stats      = System.getSystemStats();
        var battery    = stats.battery != null ? stats.battery.toFloat() : 100.0;
        var batPercent = battery / 100.0;

        var batColor;
        if (battery > 50) {
            batColor = 0x49FF00;
        } else if (battery > 20) {
            batColor = 0xFBFF00;
        } else {
            batColor = 0xFF0000;
        }

        // ── STATS TRIANGLE ────────────────────────────────────
        var statsTopY = centerY + 55;
        var statsBotY = centerY + 110;

       // Calculate digit widths for dynamic icon positioning
        var stepsDigits = steps.toNumber().toString().length();
        var calDigits = calories.toNumber().toString().length();
        var batDigits = (battery.toNumber().toString() + "%").length();

        // Offset per extra digit (adjust 8 if needed)
        var digitWidth = 8;

        var stepsIconX = centerX - 70 - ((stepsDigits - 4) * digitWidth);
        var calIconX = centerX - 108 - ((calDigits - 2) * digitWidth);
        var batIconX = centerX + 5 - ((batDigits - 3) * digitWidth);

        var stepsIcon = new WatchUi.Bitmap({:rezId => Rez.Drawables.ImgSteps,    :locX => stepsIconX, :locY => statsBotY + 32});
        var calIcon   = new WatchUi.Bitmap({:rezId => Rez.Drawables.ImgCalories, :locX => calIconX,   :locY => statsTopY + 34});
        var batIcon   = new WatchUi.Bitmap({:rezId => Rez.Drawables.ImgBattery,  :locX => batIconX,   :locY => statsTopY + 36});

        stepsIcon.draw(dc);
        calIcon.draw(dc);
        batIcon.draw(dc);

        // Steps count (teal)
        dc.setColor(0x184D47, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, statsBotY + 32, fontXSmall, steps.toNumber().toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Calories count (orange)
        dc.setColor(0xE85D04, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 60, statsTopY + 32, fontXSmall, calories.toNumber().toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Battery count (dynamic color)
        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 60, statsTopY + 32, fontXSmall, battery.toNumber().toString() + "%", Graphics.TEXT_JUSTIFY_CENTER);

        // ── OUTER RING SETUP ──────────────────────────────────
        var ringRadius = centerX - 10;
        dc.setPenWidth(10);

        // ── STEPS (top-left quarter: 180° → 90°) ─────────────
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 180, 90);

        if (stepPercent > 0) {
            dc.setColor(0x184D47, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 180, 180 - (stepPercent * 90).toNumber());
        }

        // ── CALORIES (bottom-left quarter: 270° → 180°) ──────
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 270, 180);

        if (calPercent > 0) {
            dc.setColor(0xE85D04, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 270, 270 - (calPercent * 90).toNumber());
        }

        // ── BATTERY (bottom-right quarter: 360° → 270°) ──────
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_CLOCKWISE, 360, 270);

        dc.setColor(batColor, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Graphics.ARC_COUNTER_CLOCKWISE, 270, 270 + (batPercent * 90).toNumber());

        // ── WEATHER (top-right icon + temperature) ────────────
        _weatherMgr.update();

        var weatherX = width - 85;
        var weatherY = 55;

        if (_weatherMgr.isDataAvailable()) {
            var cond = _weatherMgr.getConditionCode();

            var weatherIcon;
            if (cond == Weather.CONDITION_CLEAR) {
                weatherIcon = Rez.Drawables.ImgSunny;
            } else if (cond == Weather.CONDITION_PARTLY_CLOUDY) {
                weatherIcon = Rez.Drawables.ImgPartlyCloudy;
            } else if (cond == Weather.CONDITION_MOSTLY_CLOUDY ||
                       cond == Weather.CONDITION_CLOUDY ||
                       cond == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN) {
                weatherIcon = Rez.Drawables.ImgCloudy;
            } else if (cond == Weather.CONDITION_RAIN ||
                       cond == Weather.CONDITION_LIGHT_RAIN ||
                       cond == Weather.CONDITION_HEAVY_RAIN ||
                       cond == Weather.CONDITION_SCATTERED_SHOWERS ||
                       cond == Weather.CONDITION_DRIZZLE) {
                weatherIcon = Rez.Drawables.ImgRainy;
            } else if (cond == Weather.CONDITION_SNOW ||
                       cond == Weather.CONDITION_LIGHT_SNOW ||
                       cond == Weather.CONDITION_HEAVY_SNOW ||
                       cond == Weather.CONDITION_WINTRY_MIX ||
                       cond == Weather.CONDITION_RAIN_SNOW ||
                       cond == Weather.CONDITION_CHANCE_OF_RAIN_SNOW ||
                       cond == Weather.CONDITION_CHANCE_OF_SNOW) {
                weatherIcon = Rez.Drawables.ImgSnowy;
            } else if (cond == Weather.CONDITION_THUNDERSTORMS ||
                       cond == Weather.CONDITION_SCATTERED_THUNDERSTORMS ||
                       cond == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS) {
                weatherIcon = Rez.Drawables.ImgStormy;
            } else if (cond == Weather.CONDITION_WINDY) {
                weatherIcon = Rez.Drawables.ImgWindy;
            } else {
                weatherIcon = Rez.Drawables.ImgCloudy;
            }

            var icon = new WatchUi.Bitmap({
                :rezId => weatherIcon,
                :locX  => weatherX - 68,
                :locY  => weatherY - 10
            });
            icon.draw(dc);

            var tempStr = _weatherMgr.getTemperatureFahrenheit().format("%d") + "°";

            dc.setColor(getTimeColor(hour), Graphics.COLOR_TRANSPARENT);
            dc.drawText(weatherX - 40, weatherY + 34, fontXSmall, tempStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(getDateColor(hour), Graphics.COLOR_TRANSPARENT);
            dc.drawText(weatherX - 40, weatherY + 10, fontXSmall, "--", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}