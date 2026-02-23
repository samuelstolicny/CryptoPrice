import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.Application.Storage;

(:background)
class CryptoPriceApp extends Application.AppBase {
    private var _view as CryptoPriceView?;
    private var _delegate as CryptoPriceDelegate?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        if (_view != null && _delegate != null) { _delegate.setView(_view); }
        
        // Register for background events (every 1 hour)
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(60 * 60));
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new CryptoPriceView();
        _delegate = new CryptoPriceDelegate();
        _delegate.setView(_view);
        return [_view, _delegate];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new CryptoPriceGlanceView()];
    }
    
    (:background)
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new CryptoBackgroundServiceDelegate()];
    }
    
    function onBackgroundData(data) as Void {
        if (!(data instanceof Dictionary)) { return; }

        var savedCryptos = Storage.getValue("cryptos");
        if (!(savedCryptos instanceof Array) || savedCryptos.size() == 0) { return; }

        var firstCrypto = savedCryptos[0];
        if (!(firstCrypto instanceof Dictionary)) { return; }

        var price = data.get("lastPrice");
        if (price instanceof String || price instanceof Number || price instanceof Float) {
            firstCrypto.put("price", price.toFloat());
        }

        var percentChange = data.get("priceChangePercent");
        if (percentChange instanceof String || percentChange instanceof Number || percentChange instanceof Float) {
            firstCrypto.put("percentChange24h", percentChange.toFloat());
        }

        savedCryptos[0] = firstCrypto;
        Storage.setValue("cryptos", savedCryptos);
        WatchUi.requestUpdate();
    }
    
    function onSettingsChanged() as Void {
        if (_view != null && !_view.getDataManager().isRequestInProgress()) {
            _view.getDataManager().refreshAllPrices();
        }
    }
}

function getApp() as CryptoPriceApp {
    return Application.getApp() as CryptoPriceApp;
}