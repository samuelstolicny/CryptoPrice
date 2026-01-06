import Toybox.Communications;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time;
using CryptoConfig;

class CryptoDataManager {
    private var _callback as Method?;
    private var _portfolio as CryptoPortfolio;
    private var _isRequestInProgress as Boolean;
    private var _lastRequestTime as Number;
    private var _minRequestInterval as Number;
    
    function initialize(portfolio as CryptoPortfolio) {
        _callback = null;
        _portfolio = portfolio;
        _isRequestInProgress = false;
        _lastRequestTime = 0;
        _minRequestInterval = 1;
    }
    
    function setCallback(callback as Method) as Void { _callback = callback; }
    
    function refreshAllPrices() as Void {
        if (!canMakeRequest()) { return; }
        var cryptosToUpdate = _portfolio.getCryptosNeedingRefresh();
        if (cryptosToUpdate.size() == 0) { return; }
        setLoadingState(cryptosToUpdate);
        makeApiRequestForSymbols(cryptosToUpdate);
    }
    
    function fetchCryptoPrice(symbol as String) as Void {
        if (!canMakeRequest()) { return; }
        var crypto = _portfolio.findCryptoCurrency(symbol);
        if (crypto != null) { crypto.setLoading(); }
        makeApiRequestForSymbols([symbol]);
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
        var cb = _pendingValidationCallback;
        var symbol = _pendingValidationSymbol;
        _pendingValidationCallback = null;
        _pendingValidationSymbol = null;
        var ok = (symbol != null && responseCode == 200 && data instanceof Dictionary && data.get("symbol") instanceof String);
        if (cb != null) { cb.invoke({ "success" => ok, "symbol" => symbol }); }
    }
    
    private function canMakeRequest() as Boolean {
        if (_isRequestInProgress) { return false; }
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
        _isRequestInProgress = true;
        _lastRequestTime = Time.now().value();

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
        _isRequestInProgress = false;
        
        if (responseCode != 200) {
            handleError(CryptoConfig.getErrorMessageForResponseCode(responseCode));
            return;
        }
        
        if (data == null) {
            handleError("No data received");
            return;
        }
        
        try {
            processSuccessfulResponse(data);
        } catch (ex) {
            handleError("Data processing error");
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

        Storage.setValue(CryptoConfig.STORAGE_LAST_UPDATE, Time.now().value());
        if (_callback != null) {
            _callback.invoke({ "success" => true, "updateCount" => updateCount });
        }
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

    private function simpleParseFloat(s as String) as Float {
        if (s == null || s.length() == 0) { return 0.0; }
        var dotPos = s.find(".");
        if (dotPos < 0) {
            try { return s.toNumber().toFloat(); } catch(e) { return 0.0; }
        }
        var intPart = s.substring(0, dotPos);
        var fracPart = s.substring(dotPos + 1, s.length());
        var intVal = 0.0;
        try { intVal = intPart.length() > 0 ? intPart.toNumber().toFloat() : 0.0; } catch(e) { intVal = 0.0; }
        var fracVal = 0.0;
        var scale = 1.0;
        for (var i = 0; i < fracPart.length() && i < 8; i++) {
            var idx = "0123456789".find(fracPart.substring(i, i+1));
            if (idx < 0) { break; }
            scale *= 10.0;
            fracVal += idx / scale;
        }
        return (intVal + fracVal).toFloat();
    }
    
    private function handleError(message as String) as Void {
        var allCryptos = _portfolio.getAllCryptocurrencies();
        for (var i = 0; i < allCryptos.size(); i++) {
            if (allCryptos[i].isLoading) { allCryptos[i].setError(message); }
        }
        if (_callback != null) { _callback.invoke({ "success" => false, "error" => message }); }
    }
    
    function isRequestInProgress() as Boolean { return _isRequestInProgress; }
    
    function getLastUpdateTime() as Number {
        var lastUpdate = Storage.getValue(CryptoConfig.STORAGE_LAST_UPDATE);
        return lastUpdate instanceof Number ? lastUpdate : 0;
    }
}
