import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Application.Storage;
using CryptoConfig;

class CurrencyMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as CryptoPriceView;

    function initialize(view as CryptoPriceView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var code = item.getId() as String;
        Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, code);

        if (code.equals("USD")) {
            Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 1.0);
            Storage.setValue(CryptoConfig.STORAGE_RATES_LAST_UPDATE, Time.now().value());
            _view.getDataManager().refreshAllPriceDisplays();
        } else {
            _view.getDataManager().fetchExchangeRate(code);
        }

        // Pop currency menu, settings menu, and main menu
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
