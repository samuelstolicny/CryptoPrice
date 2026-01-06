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
        _view = null;
        _delegate = null;
    }

    function onStart(state as Dictionary?) as Void {
        if (_view != null && _delegate != null) { _delegate.setView(_view); }
        
        // Register for background events (every 1 hour)
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(60 * 60));
        }
    }

    function onStop(state as Dictionary?) as Void {
        if (_view != null) { _view.onHide(); }
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
        if (data instanceof Dictionary) {
            var savedCryptos = Storage.getValue("cryptos");
            if (savedCryptos instanceof Array && savedCryptos.size() > 0) {
                var firstCrypto = savedCryptos[0];
                if (firstCrypto instanceof Dictionary) {
                    var price = data.get("lastPrice");
                    var percentChange = data.get("priceChangePercent");
                    
                    if (price != null) { 
                        if (price instanceof String) { firstCrypto.put("price", price.toFloat()); }
                        else if (price instanceof Number) { firstCrypto.put("price", price.toFloat()); }
                        else if (price instanceof Float) { firstCrypto.put("price", price); }
                    }
                    
                    if (percentChange != null) { 
                        if (percentChange instanceof String) { firstCrypto.put("percentChange24h", percentChange.toFloat()); }
                        else if (percentChange instanceof Number) { firstCrypto.put("percentChange24h", percentChange.toFloat()); }
                        else if (percentChange instanceof Float) { firstCrypto.put("percentChange24h", percentChange); }
                    }
                    
                    savedCryptos[0] = firstCrypto;
                    Storage.setValue("cryptos", savedCryptos);
                    
                    WatchUi.requestUpdate();
                }
            }
        }
    }
    
    function onSettingsChanged() as Void {
        if (_view != null) {
            var dataManager = _view.getDataManager();
            if (dataManager != null && !dataManager.isRequestInProgress()) {
                dataManager.refreshAllPrices();
            }
        }
    }
}

function getApp() as CryptoPriceApp {
    return Application.getApp() as CryptoPriceApp;
}