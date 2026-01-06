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
            var cryptoData = cryptoList[i];
            if (cryptoData instanceof Dictionary) {
                var symbol = cryptoData.get("symbol");
                var name = cryptoData.get("name");
                if (symbol instanceof String && name instanceof String) {
                    var crypto = new CryptoCurrency(symbol, name);
                    
                    var price = cryptoData.get("price");
                    var percentChange = cryptoData.get("percentChange24h");
                    
                    if (price != null) {
                        if (price instanceof Float) {
                            crypto.price = price;
                        } else if (price instanceof Number) {
                            crypto.price = price.toFloat();
                        }
                        
                        if (crypto.price != null) {
                            crypto.priceFormatted = crypto.price >= 1.0 ? "$" + crypto.price.format("%.0f") : "$" + crypto.price.format("%.3f");
                            crypto.isLoading = false;
                        }
                    }
                    
                    if (percentChange != null) {
                        if (percentChange instanceof Float) {
                            crypto.percentChange24h = percentChange;
                        } else if (percentChange instanceof Number) {
                            crypto.percentChange24h = percentChange.toFloat();
                        }
                    }
                    
                    _cryptocurrencies.add(crypto);
                }
            }
        }
        if (savedCryptos.size() == 0) { saveCryptosToSettings(); }
    }
    
    function addCryptoCurrency(symbol as String, name as String) as Void {
        _cryptocurrencies.add(new CryptoCurrency(symbol, name));
        saveCryptosToSettings();
    }

    function addCrypto(symbol as String) as Void {
        addCryptoCurrency(symbol, symbol);
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
                "percentChange24h" => _cryptocurrencies[i].percentChange24h
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
    
    function getCount() as Number { return _cryptocurrencies.size(); }
}
