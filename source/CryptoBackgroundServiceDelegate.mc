import Toybox.System;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Application.Storage;
import Toybox.Lang;
using CryptoConfig;

(:background)
class CryptoBackgroundServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();
    }
    
    function onTemporalEvent() as Void {
        var savedCryptos = Storage.getValue("cryptos");
        if (savedCryptos instanceof Array && savedCryptos.size() > 0) {
            var firstCrypto = savedCryptos[0];
            if (firstCrypto instanceof Dictionary) {
                var symbol = firstCrypto.get("symbol");
                if (symbol instanceof String) {
                    makeRequest(symbol);
                    return;
                }
            }
        }
        Background.exit(null);
    }
    
    function makeRequest(symbol as String) as Void {
        var url = CryptoConfig.BINANCE_24H_TICKER_URL;
        var parameters = { "symbol" => symbol + "USDT" };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        Communications.makeWebRequest(url, parameters, options, method(:onResponse));
    }
    
    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}
