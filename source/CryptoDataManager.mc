import Toybox.Communications;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time;
using CryptoConfig;

class CryptoDataManager {
    private var _callback as Method?;
    private var _portfolio as CryptoPortfolio;
    private var _pendingRequestCount as Number;
    private var _lastRequestTime as Number;
    private var _minRequestInterval as Number;
    private var _exchangeRateNeeded as Boolean;
    private var _pendingBinanceSymbols as Array<String>;

    function initialize(portfolio as CryptoPortfolio) {
        _callback = null;
        _portfolio = portfolio;
        _pendingRequestCount = 0;
        _lastRequestTime = 0;
        _minRequestInterval = 1;
        _exchangeRateNeeded = false;
        _pendingBinanceSymbols = [];
    }
    
    function setCallback(callback as Method) as Void { _callback = callback; }
    
    function refreshAllPrices() as Void {
        if (!canMakeRequest()) { return; }
        var cryptosToUpdate = _portfolio.getCryptosNeedingRefresh();
        if (cryptosToUpdate.size() == 0) {
            fetchExchangeRateIfNeeded();
            return;
        }
        setLoadingState(cryptosToUpdate);
        _exchangeRateNeeded = true;

        var binanceSymbols = [];
        var kucoinSymbols = [];
        for (var i = 0; i < cryptosToUpdate.size(); i++) {
            var s = cryptosToUpdate[i];
            var crypto = _portfolio.findCryptoCurrency(s);
            if (crypto != null && crypto.exchange.equals("kucoin")) {
                kucoinSymbols.add(s);
            } else {
                binanceSymbols.add(s);
            }
        }

        if (binanceSymbols.size() > 0) {
            makeApiRequestForSymbols(binanceSymbols);
        }
        for (var i = 0; i < kucoinSymbols.size(); i++) {
            makeKucoinRequest(kucoinSymbols[i]);
        }
    }

    function fetchCryptoPrice(symbol as String) as Void {
        if (!canMakeRequest()) { return; }
        var crypto = _portfolio.findCryptoCurrency(symbol);
        if (crypto != null) { crypto.setLoading(); }
        if (crypto != null && crypto.exchange.equals("kucoin")) {
            makeKucoinRequest(symbol);
        } else {
            makeApiRequestForSymbols([symbol]);
        }
    }

    function validateSymbol(symbol as String, callback as Method) as Void {
        var url = CryptoConfig.BINANCE_24H_TICKER_URL;
        var parameters = { "symbol" => symbol + "USDT" };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        _pendingValidationCallback = callback;
        _pendingValidationSymbol = symbol;
        Communications.makeWebRequest(url, parameters, options, method(:onValidateSymbol));
    }

    private var _pendingValidationCallback as Method?;
    private var _pendingValidationSymbol as String?;

    function onValidateSymbol(responseCode as Number, data as Dictionary or String or Null) as Void {
        var ok = (_pendingValidationSymbol != null && responseCode == 200 && data instanceof Dictionary && data.get("symbol") instanceof String);
        if (ok) {
            var cb = _pendingValidationCallback;
            var symbol = _pendingValidationSymbol;
            _pendingValidationCallback = null;
            _pendingValidationSymbol = null;
            if (cb != null) { cb.invoke({ "success" => true, "symbol" => symbol, "exchange" => "binance" }); }
        } else {
            validateSymbolKucoin();
        }
    }

    private function validateSymbolKucoin() as Void {
        var symbol = _pendingValidationSymbol;
        if (symbol == null) { return; }
        var url = CryptoConfig.KUCOIN_24H_STATS_URL;
        var parameters = { "symbol" => symbol + "-USDT" };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        Communications.makeWebRequest(url, parameters, options, method(:onValidateSymbolKucoin));
    }

    function onValidateSymbolKucoin(responseCode as Number, data as Dictionary or String or Null) as Void {
        var cb = _pendingValidationCallback;
        var symbol = _pendingValidationSymbol;
        _pendingValidationCallback = null;
        _pendingValidationSymbol = null;
        var ok = false;
        if (symbol != null && responseCode == 200 && data instanceof Dictionary) {
            var code = data.get("code");
            var inner = data.get("data");
            if (code instanceof String && code.equals("200000") && inner instanceof Dictionary && inner.get("last") != null) {
                ok = true;
            }
        }
        if (cb != null) { cb.invoke({ "success" => ok, "symbol" => symbol, "exchange" => "kucoin" }); }
    }
    
    private function canMakeRequest() as Boolean {
        if (_pendingRequestCount > 0) { return false; }
        return (Time.now().value() - _lastRequestTime) >= _minRequestInterval;
    }
    
    private function setLoadingState(symbols as Array<String>) as Void {
        for (var i = 0; i < symbols.size(); i++) {
            var crypto = _portfolio.findCryptoCurrency(symbols[i]);
            if (crypto != null) { crypto.setLoading(); }
        }
    }

    private function formatSymbolsJson(pairs as Array<String>) as String {
        var result = "[";
        for (var i = 0; i < pairs.size(); i++) {
            if (i > 0) { result += ","; }
            result += "\"" + pairs[i] + "\"";
        }
        return result + "]";
    }

    private function makeApiRequestForSymbols(symbolArray as Array<String>) as Void {
        _pendingRequestCount++;
        _lastRequestTime = Time.now().value();
        _pendingBinanceSymbols = symbolArray;

        var pairs = [];
        for (var i = 0; i < symbolArray.size(); i++) {
            var s = symbolArray[i];
            if (s != null && s.length() > 0) { pairs.add(s + "USDT"); }
        }

        var url = CryptoConfig.BINANCE_24H_TICKER_URL;
        var parameters = { "symbols" => formatSymbolsJson(pairs) };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        Communications.makeWebRequest(url, parameters, options, method(:onDataReceived));
    }
    
    function onDataReceived(responseCode as Number, data as Dictionary or String or Null) as Void {
        _pendingRequestCount--;

        if (responseCode != 200 || data == null) {
            fallbackToKucoin();
            return;
        }

        try {
            processSuccessfulResponse(data);
        } catch (ex) {
            fallbackToKucoin();
        }
    }

    private function fallbackToKucoin() as Void {
        var symbols = _pendingBinanceSymbols;
        _pendingBinanceSymbols = [];
        for (var i = 0; i < symbols.size(); i++) {
            makeKucoinRequest(symbols[i]);
        }
    }
    
    private function processSuccessfulResponse(data as Dictionary or String or Array<Dictionary>) as Void {
        var updateCount = 0;

        if (data instanceof Array) {
            for (var i = 0; i < data.size(); i++) {
                var item = data[i];
                if (item instanceof Dictionary && processBinanceTicker(item)) { updateCount++; }
            }
        } else if (data instanceof Dictionary) {
            if (processBinanceTicker(data)) { updateCount++; }
        }

        if (updateCount > 0) {
            _portfolio.saveCryptosToSettings();
        }

        finalizeRequest({ "success" => true, "updateCount" => updateCount }, false);
    }

    private function processBinanceTicker(ticker as Dictionary) as Boolean {
        var symbolPair = ticker.get("symbol");
        if (!(symbolPair instanceof String)) { return false; }

        var baseSymbol = symbolPair;
        var usdtIndex = symbolPair.find("USDT");
        if (usdtIndex >= 0) { baseSymbol = symbolPair.substring(0, usdtIndex); }

        var crypto = _portfolio.findCryptoCurrency(baseSymbol);
        if (crypto == null) { return false; }

        var price = ticker.get("lastPrice");
        if (price == null) { price = ticker.get("weightedAvgPrice"); }
        if (price == null) { crypto.setError("Price N/A"); return false; }

        var percentChange = null;
        var percentChangeStr = ticker.get("priceChangePercent");
        if (percentChangeStr instanceof String) { percentChange = simpleParseFloat(percentChangeStr); }
        else if (percentChangeStr instanceof Number) { percentChange = percentChangeStr.toFloat(); }

        var priceNum = price instanceof String ? simpleParseFloat(price) : price;
        crypto.updatePriceData({ "price" => priceNum, "percent_change_24h" => percentChange });
        return true;
    }

    private function makeKucoinRequest(symbol as String) as Void {
        _pendingRequestCount++;
        _lastRequestTime = Time.now().value();
        var url = CryptoConfig.KUCOIN_24H_STATS_URL;
        var parameters = { "symbol" => symbol + "-USDT" };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        Communications.makeWebRequest(url, parameters, options, method(:onKucoinDataReceived));
    }

    function onKucoinDataReceived(responseCode as Number, data as Dictionary or String or Null) as Void {
        _pendingRequestCount--;
        if (responseCode != 200 || !(data instanceof Dictionary)) {
            if (_pendingRequestCount <= 0 && _callback != null) {
                _callback.invoke({ "success" => false, "error" => "KuCoin error" });
            }
            return;
        }

        var code = data.get("code");
        var inner = data.get("data");
        if (!(code instanceof String) || !code.equals("200000") || !(inner instanceof Dictionary)) {
            if (_pendingRequestCount <= 0 && _callback != null) {
                _callback.invoke({ "success" => false, "error" => "KuCoin error" });
            }
            return;
        }

        if (processKucoinTicker(inner)) {
            _portfolio.saveCryptosToSettings();
        }

        finalizeRequest({ "success" => true, "updateCount" => 1 }, true);
    }

    private function processKucoinTicker(inner as Dictionary) as Boolean {
        var symbolPair = inner.get("symbol");
        if (!(symbolPair instanceof String)) { return false; }

        var dashIndex = symbolPair.find("-");
        if (dashIndex == null || dashIndex < 0) { return false; }

        var baseSymbol = symbolPair.substring(0, dashIndex);
        var crypto = _portfolio.findCryptoCurrency(baseSymbol);
        if (crypto == null) { return false; }

        var priceStr = inner.get("last");
        if (!(priceStr instanceof String)) { return false; }

        var price = simpleParseFloat(priceStr);
        var percentChange = null;
        var changeRateStr = inner.get("changeRate");
        if (changeRateStr instanceof String) {
            percentChange = simpleParseFloat(changeRateStr) * 100.0;
        }
        crypto.updatePriceData({ "price" => price, "percent_change_24h" => percentChange });
        return true;
    }

    private function simpleParseFloat(s as String) as Float {
        if (s == null || s.length() == 0) { return 0.0; }
        var negative = false;
        var str = s;
        if (s.substring(0, 1).equals("-")) {
            negative = true;
            str = s.substring(1, s.length());
        }
        var dotPos = str.find(".");
        if (dotPos == null || dotPos < 0) {
            try { var v = str.toNumber().toFloat(); return negative ? -v : v; } catch(e) { return 0.0; }
        }
        var intPart = str.substring(0, dotPos);
        var fracPart = str.substring(dotPos + 1, str.length());
        var intVal = 0.0;
        try { intVal = intPart.length() > 0 ? intPart.toNumber().toFloat() : 0.0; } catch(e) { intVal = 0.0; }
        var fracVal = 0.0;
        var scale = 1.0;
        for (var i = 0; i < fracPart.length() && i < 8; i++) {
            var idx = "0123456789".find(fracPart.substring(i, i+1));
            if (idx == null || idx < 0) { break; }
            scale *= 10.0;
            fracVal += idx / scale;
        }
        var result = (intVal + fracVal).toFloat();
        return negative ? -result : result;
    }
    
    function fetchExchangeRateIfNeeded() as Void {
        var code = CryptoConfig.getDisplayCurrencyCode();
        if (code.equals("USD")) {
            Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 1.0);
            return;
        }
        if (!isExchangeRateStale()) { return; }
        fetchExchangeRate(code);
    }

    function fetchExchangeRate(currencyCode as String) as Void {
        var url = CryptoConfig.FRANKFURTER_API_URL;
        var parameters = { "from" => "USD", "to" => currencyCode };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Accept" => "application/json" }
        };
        _pendingRateCurrency = currencyCode;
        Communications.makeWebRequest(url, parameters, options, method(:onExchangeRateReceived));
    }

    private var _pendingRateCurrency as String?;

    function onExchangeRateReceived(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            var rates = data.get("rates");
            if (rates instanceof Dictionary && _pendingRateCurrency != null) {
                var rate = rates.get(_pendingRateCurrency);
                if (rate instanceof Float || rate instanceof Number) {
                    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, rate.toFloat());
                    Storage.setValue(CryptoConfig.STORAGE_RATES_LAST_UPDATE, Time.now().value());
                    refreshAllPriceDisplays();
                }
            }
        }
        _pendingRateCurrency = null;
    }

    private function isExchangeRateStale() as Boolean {
        var lastUpdate = Storage.getValue(CryptoConfig.STORAGE_RATES_LAST_UPDATE);
        if (!(lastUpdate instanceof Number)) { return true; }
        return (Time.now().value() - lastUpdate) > 3600;
    }

    function refreshAllPriceDisplays() as Void {
        var allCryptos = _portfolio.getAllCryptocurrencies();
        for (var i = 0; i < allCryptos.size(); i++) {
            allCryptos[i].refreshPriceDisplay();
        }
        if (_callback != null) {
            _callback.invoke({ "success" => true, "updateCount" => 0 });
        }
    }

    private function finalizeRequest(result as Dictionary, waitForPending as Boolean) as Void {
        Storage.setValue(CryptoConfig.STORAGE_LAST_UPDATE, Time.now().value());
        if (_pendingRequestCount <= 0 && _exchangeRateNeeded) {
            _exchangeRateNeeded = false;
            fetchExchangeRateIfNeeded();
        }
        if (_callback != null && (!waitForPending || _pendingRequestCount <= 0)) {
            _callback.invoke(result);
        }
    }

    function isRequestInProgress() as Boolean { return _pendingRequestCount > 0; }
    
    function getLastUpdateTime() as Number {
        var lastUpdate = Storage.getValue(CryptoConfig.STORAGE_LAST_UPDATE);
        return lastUpdate instanceof Number ? lastUpdate : 0;
    }
}
