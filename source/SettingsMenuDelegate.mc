import Toybox.Lang;
import Toybox.WatchUi;

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as CryptoPriceView;

    function initialize(view as CryptoPriceView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("reset_defaults")) {
            _view.requestResetOnNextShow();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
