import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

class RemoveCryptoDelegate extends WatchUi.TextPickerDelegate {
    private var _view as CryptoPriceView;
    private static var _pendingNotification as Boolean = false;

    function initialize(view as CryptoPriceView) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (changed) {
            var success = _view.removeCrypto(text.toUpper());
            
            if (success) {
                try { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
            } else {
                _pendingNotification = true;
                var timer = new Timer.Timer();
                timer.start(method(:showNotification), 150, false);
            }
        }
        return true;
    }

    function showNotification() as Void {
        if (_pendingNotification) {
            _pendingNotification = false;
            try { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
            WatchUi.pushView(new NotificationView("Symbol not found", 3000), null, WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
