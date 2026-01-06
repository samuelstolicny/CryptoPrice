import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
using CryptoConfig;

class CryptoPriceView extends WatchUi.View {
    private var _portfolio as CryptoPortfolio;
    private var _dataManager as CryptoDataManager;
    private var _currentCryptos as Array<CryptoCurrency>;
    private var _resetRequested as Boolean;
    
    function initialize() {
        View.initialize();
        _portfolio = new CryptoPortfolio();
        _dataManager = new CryptoDataManager(_portfolio);
        _dataManager.setCallback(method(:onDataReceived));
        _currentCryptos = [];
        _resetRequested = false;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        if (_resetRequested) {
            _portfolio.resetToDefaults();
            _resetRequested = false;
            refreshData();
            return;
        }
        
        updateCurrentCryptos();
        WatchUi.requestUpdate();
        refreshData();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        if (_currentCryptos.size() > 0) {
            drawCryptoList(dc);
        } else {
            drawLoadingMessage(dc);
        }
    }
    
    function drawLoadingMessage(dc as Dc) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, screenHeight / 2 - 30, Graphics.FONT_LARGE, "CRYPTO", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, screenHeight / 2, Graphics.FONT_MEDIUM, "LOADING...", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawCryptoList(dc as Dc) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var displayCount = _currentCryptos.size() > 3 ? 3 : _currentCryptos.size();
        var itemHeight = screenHeight > 300 ? 90 : 60;
        var totalListHeight = displayCount * itemHeight;
        var startY = (screenHeight - totalListHeight) / 2;
        
        for (var i = 0; i < displayCount; i++) {
            drawCryptoCurrency(dc, _currentCryptos[i], screenWidth, startY + (i * itemHeight), itemHeight);
        }
        
        var pageInfo = _portfolio.getPageInfo();
        var totalPages = pageInfo.get("totalPages");
        if (totalPages instanceof Number && totalPages > 1) {
            drawPageIndicator(dc, pageInfo);
        }
    }
    
    function drawCryptoCurrency(dc as Dc, crypto as CryptoCurrency, screenWidth as Number, yPosition as Number, itemHeight as Number) as Void {
        var centerX = screenWidth / 2;
        var symbolX = centerX - (screenWidth > 300 ? 150 : 80);
        var priceX = centerX + (screenWidth > 300 ? 150 : 80);
        var mainFont = screenWidth > 300 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        var mainFontHeight = dc.getFontHeight(mainFont);
        
        // Draw symbol
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(symbolX, yPosition, mainFont, crypto.symbol, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw price
        var priceColor = crypto.getPriceChangeColor();
        var displayText = crypto.getDisplayText();
        if (displayText == null || displayText.length() == 0) {
            displayText = "No Data";
            priceColor = Graphics.COLOR_YELLOW;
        }
        
        dc.setColor(priceColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(priceX, yPosition, mainFont, displayText, Graphics.TEXT_JUSTIFY_RIGHT);
        
        // Draw percentage
        if (crypto.percentChange24h != null) {
            var changeText = (crypto.percentChange24h >= 0 ? "+" : "") + crypto.percentChange24h.format("%.2f") + "%";
            dc.drawText(priceX, yPosition + mainFontHeight - 5, Graphics.FONT_XTINY, changeText, Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }
    
    function drawPageIndicator(dc as Dc, pageInfo as Dictionary) as Void {
        var currentPage = pageInfo.get("currentPage");
        var totalPages = pageInfo.get("totalPages");
        
        if (currentPage instanceof Number && totalPages instanceof Number) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, 8, Graphics.FONT_TINY, currentPage + "/" + totalPages, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function refreshData() as Void {
        if (!_dataManager.isRequestInProgress()) {
            _dataManager.refreshAllPrices();
            WatchUi.requestUpdate();
        }
    }

    function onDataReceived(result as Dictionary) as Void {
        updateDisplay();
        WatchUi.requestUpdate();
    }
    
    function updateCurrentCryptos() as Void {
        _currentCryptos = _portfolio.getCurrentPageCryptos();
    }
    
    function updateDisplay() as Void {
        updateCurrentCryptos();
        try { WatchUi.requestUpdate(); } catch (e) {}
    }
    
    function nextPage() as Boolean {
        if (_portfolio.nextPage()) { updateDisplay(); return true; }
        return false;
    }
    
    function previousPage() as Boolean {
        if (_portfolio.previousPage()) { updateDisplay(); return true; }
        return false;
    }
    
    function getPortfolio() as CryptoPortfolio { return _portfolio; }
    function getDataManager() as CryptoDataManager { return _dataManager; }
    function requestResetOnNextShow() as Void { _resetRequested = true; }

    function addCrypto(symbol as String) as Void {
        _portfolio.addCrypto(symbol);
        _portfolio.goToLastPage();
        updateCurrentCryptos();
        refreshData();
    }

    function showLastPageNow() as Void {
        _portfolio.goToLastPage();
        updateCurrentCryptos();
        try { WatchUi.requestUpdate(); } catch (e) {}
    }
    
    function removeCrypto(symbol as String) as Boolean {
        var success = _portfolio.removeCryptoCurrency(symbol != null ? symbol.toUpper() : "");
        if (success) {
            if (_portfolio.getCount() > 0 && _portfolio.getCurrentPageCryptos().size() == 0) {
                _portfolio.goToLastPage();
            }
            updateCurrentCryptos();
            try { WatchUi.requestUpdate(); } catch (e) {}
        }
        return success;
    }
    
    function onHide() as Void {}
}
