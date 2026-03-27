import Toybox.Lang;
import Toybox.Math;
import Toybox.Application.Storage;
using CryptoConfig;

(:glance)
class CryptoPortfolio {
    private var _cryptocurrencies as Array<CryptoCurrency>;
    private var _currentIndex as Number;
    private var _maxDisplayCount as Number;
    
    function initialize() {
        _cryptocurrencies = [];
        _currentIndex = 0;
        _maxDisplayCount = 3;
        initializeDefaultCryptos();
    }
    
    private function initializeDefaultCryptos() as Void {
        var savedCryptos = loadCryptosFromSettings();
        var cryptoList = savedCryptos.size() > 0 ? savedCryptos : CryptoConfig.DEFAULT_CRYPTOS;

        for (var i = 0; i < cryptoList.size(); i++) {
            var cryptoData = cryptoList[i] as Dictionary;

            var symbol = cryptoData.get("symbol");
            var name = cryptoData.get("name");
            if (!(symbol instanceof String) || !(name instanceof String)) { continue; }

            var crypto = new CryptoCurrency(symbol, name);
            var ex = cryptoData.get("exchange");
            if (ex instanceof String) { crypto.exchange = ex; }
            var price = cryptoData.get("price");
            var percentChange = cryptoData.get("percentChange24h");

            if (price instanceof Float || price instanceof Number) {
                crypto.updatePriceData({
                    "price" => price.toFloat(),
                    "percent_change_24h" => (percentChange instanceof Float || percentChange instanceof Number) ? percentChange.toFloat() : null
                });
            }

            _cryptocurrencies.add(crypto);
        }
        if (savedCryptos.size() == 0) { saveCryptosToSettings(); }
    }
    
    function addCryptoCurrency(symbol as String, name as String, exchange as String) as Void {
        var crypto = new CryptoCurrency(symbol, name);
        crypto.exchange = exchange;
        _cryptocurrencies.add(crypto);
        saveCryptosToSettings();
    }

    function addCrypto(symbol as String, exchange as String) as Void {
        addCryptoCurrency(symbol, symbol, exchange);
    }
    
    function findCryptoCurrency(symbol as String) as CryptoCurrency? {
        for (var i = 0; i < _cryptocurrencies.size(); i++) {
            if (_cryptocurrencies[i].symbol.equals(symbol)) { return _cryptocurrencies[i]; }
        }
        return null;
    }

    function removeCryptoCurrency(symbol as String) as Boolean {
        for (var i = 0; i < _cryptocurrencies.size(); i++) {
            if (_cryptocurrencies[i].symbol.equals(symbol)) {
                _cryptocurrencies.remove(_cryptocurrencies[i]);
                if (_currentIndex >= _cryptocurrencies.size()) {
                    _currentIndex = _cryptocurrencies.size() > 0 ? _cryptocurrencies.size() - 1 : 0;
                }
                saveCryptosToSettings();
                return true;
            }
        }
        return false;
    }
    
    function getAllCryptocurrencies() as Array<CryptoCurrency> { return _cryptocurrencies; }
    
    function getCurrentPageCryptos() as Array<CryptoCurrency> {
        var result = [];
        var endIndex = _currentIndex + _maxDisplayCount;
        if (endIndex > _cryptocurrencies.size()) { endIndex = _cryptocurrencies.size(); }
        for (var i = _currentIndex; i < endIndex; i++) { result.add(_cryptocurrencies[i]); }
        return result;
    }
    
    function nextPage() as Boolean {
        var nextIndex = _currentIndex + _maxDisplayCount;
        if (nextIndex < _cryptocurrencies.size()) { _currentIndex = nextIndex; return true; }
        return false;
    }
    
    function previousPage() as Boolean {
        if (_currentIndex > 0) {
            var newIndex = _currentIndex - _maxDisplayCount;
            _currentIndex = newIndex > 0 ? newIndex : 0;
            return true;
        }
        return false;
    }
    
    function getPageInfo() as Dictionary {
        var totalPages = Math.ceil(_cryptocurrencies.size().toFloat() / _maxDisplayCount.toFloat()).toNumber();
        var currentPage = Math.floor(_currentIndex.toFloat() / _maxDisplayCount.toFloat()).toNumber() + 1;
        return { "currentPage" => currentPage, "totalPages" => totalPages };
    }

    function goToLastPage() as Void {
        var total = _cryptocurrencies.size();
        if (total <= 0) { _currentIndex = 0; return; }
        var totalPages = Math.ceil(total.toFloat() / _maxDisplayCount.toFloat()).toNumber();
        _currentIndex = (totalPages - 1) * _maxDisplayCount;
    }
    
    function getCryptosNeedingRefresh() as Array<String> {
        var symbols = [];
        for (var i = 0; i < _cryptocurrencies.size(); i++) {
            if (_cryptocurrencies[i].isDataStale()) { symbols.add(_cryptocurrencies[i].symbol); }
        }
        return symbols;
    }
    
    function saveCryptosToSettings() as Void {
        var cryptosToSave = [];
        for (var i = 0; i < _cryptocurrencies.size(); i++) {
            cryptosToSave.add({
                "symbol" => _cryptocurrencies[i].symbol,
                "name" => _cryptocurrencies[i].name,
                "price" => _cryptocurrencies[i].price,
                "percentChange24h" => _cryptocurrencies[i].percentChange24h,
                "exchange" => _cryptocurrencies[i].exchange
            });
        }
        Storage.setValue("cryptos", cryptosToSave);
    }
    
    private function loadCryptosFromSettings() as Array<Dictionary> {
        var savedCryptos = Storage.getValue("cryptos");
        return savedCryptos instanceof Array ? savedCryptos : [];
    }
    
    function resetToDefaults() as Void {
        _cryptocurrencies = [];
        _currentIndex = 0;
        Storage.deleteValue("cryptos");
        initializeDefaultCryptos();
    }
    
    function moveCryptoUp(index as Number) as Boolean {
        if (index <= 0 || index >= _cryptocurrencies.size()) { return false; }
        var temp = _cryptocurrencies[index - 1];
        _cryptocurrencies[index - 1] = _cryptocurrencies[index];
        _cryptocurrencies[index] = temp;
        saveCryptosToSettings();
        return true;
    }

    function moveCryptoDown(index as Number) as Boolean {
        if (index < 0 || index >= _cryptocurrencies.size() - 1) { return false; }
        var temp = _cryptocurrencies[index + 1];
        _cryptocurrencies[index + 1] = _cryptocurrencies[index];
        _cryptocurrencies[index] = temp;
        saveCryptosToSettings();
        return true;
    }

    function getCount() as Number { return _cryptocurrencies.size(); }
}
