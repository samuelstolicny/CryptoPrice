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
        } else if (id.equals("display_currency")) {
            var currencyMenu = new WatchUi.Menu2({:title=>"Display Currency"});
            currencyMenu.addItem(new WatchUi.MenuItem("USD ($)", null, "USD", null));
            currencyMenu.addItem(new WatchUi.MenuItem("EUR (€)", null, "EUR", null));
            currencyMenu.addItem(new WatchUi.MenuItem("GBP (£)", null, "GBP", null));
            currencyMenu.addItem(new WatchUi.MenuItem("CAD (C$)", null, "CAD", null));
            currencyMenu.addItem(new WatchUi.MenuItem("AUD (A$)", null, "AUD", null));
            currencyMenu.addItem(new WatchUi.MenuItem("NZD (NZ$)", null, "NZD", null));
            WatchUi.pushView(currencyMenu, new CurrencyMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
