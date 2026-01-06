import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class NotificationView extends WatchUi.View {
    private var _message as String;
    private var _expiresAt as Number;

    function initialize(message, durationMs) {
        View.initialize();
        _message = message != null ? message : "";
        var duration = (durationMs instanceof Number && durationMs > 0) ? durationMs : 3000;
        if (duration > 10000) { duration = 10000; }
        _expiresAt = System.getTimer() + duration;
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var font = _message.length() > 18 ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 8, font, _message, Graphics.TEXT_JUSTIFY_CENTER);

        if (System.getTimer() >= _expiresAt) {
            try { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
        } else {
            WatchUi.requestUpdate();
        }
    }
}
