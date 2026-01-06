import Toybox.Lang;
import Toybox.WatchUi;

class AddCryptoDelegate extends WatchUi.TextPickerDelegate {
    private var _view as CryptoPriceView;

    function initialize(view as CryptoPriceView) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (!changed || text == null || text.length() == 0) { return true; }
        var dm = _view.getDataManager();
        if (dm != null) {
            dm.validateSymbol(text.toUpper(), method(:onSymbolValidated));
        }
        return true;
    }

    function onSymbolValidated(result as Dictionary) as Void {
        var success = result.get("success");
        var symbol = result.get("symbol");
        
        if (success instanceof Boolean && success && symbol instanceof String && symbol.length() > 0) {
            _view.addCrypto(symbol);
            try { _view.showLastPageNow(); } catch(e) {}
        } else {
            try { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
            try { WatchUi.pushView(new NotificationView("Symbol not found", 3000), null, WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
            return;
        }
        try { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); } catch(e) {}
    }
}
