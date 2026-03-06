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
                var exchange = firstCrypto.get("exchange");
                if (symbol instanceof String) {
                    if (exchange instanceof String && exchange.equals("kucoin")) {
                        makeKucoinRequest(symbol);
                    } else {
                        makeRequest(symbol);
                    }
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

    function makeKucoinRequest(symbol as String) as Void {
        var url = CryptoConfig.KUCOIN_24H_STATS_URL;
        var parameters = { "symbol" => symbol + "-USDT" };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        Communications.makeWebRequest(url, parameters, options, method(:onKucoinResponse));
    }

    function onKucoinResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            var code = data.get("code");
            var inner = data.get("data");
            if (code instanceof String && code.equals("200000") && inner instanceof Dictionary) {
                // Normalize to Binance-like format so onBackgroundData doesn't need changes
                var lastPrice = inner.get("last");
                var changeRate = inner.get("changeRate");
                var symbol = inner.get("symbol");
                var percentStr = "0";
                if (changeRate instanceof String) {
                    var rate = 0.0;
                    var neg = false;
                    var rateStr = changeRate;
                    if (changeRate.length() > 0 && changeRate.substring(0, 1).equals("-")) {
                        neg = true;
                        rateStr = changeRate.substring(1, changeRate.length());
                    }
                    try {
                        var dotPos = rateStr.find(".");
                        if (dotPos != null && dotPos >= 0) {
                            var intPart = rateStr.substring(0, dotPos);
                            var fracPart = rateStr.substring(dotPos + 1, rateStr.length());
                            var intVal = 0.0;
                            try { intVal = intPart.length() > 0 ? intPart.toNumber().toFloat() : 0.0; } catch(e) { intVal = 0.0; }
                            var fracVal = 0.0;
                            var scl = 1.0;
                            for (var i = 0; i < fracPart.length() && i < 8; i++) {
                                var idx = "0123456789".find(fracPart.substring(i, i+1));
                                if (idx == null || idx < 0) { break; }
                                scl *= 10.0;
                                fracVal += idx / scl;
                            }
                            rate = intVal + fracVal;
                        } else {
                            try { rate = rateStr.toNumber().toFloat(); } catch(e) { rate = 0.0; }
                        }
                    } catch(e) { rate = 0.0; }
                    if (neg) { rate = -rate; }
                    percentStr = (rate * 100.0).format("%.2f");
                }
                Background.exit({
                    "symbol" => symbol,
                    "lastPrice" => lastPrice,
                    "priceChangePercent" => percentStr
                });
                return;
            }
        }
        Background.exit(null);
    }
}
