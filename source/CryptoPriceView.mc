import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

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

        var pageInfo = _portfolio.getPageInfo();
        var totalPages = pageInfo.get("totalPages");
        var hasPageIndicator = (totalPages instanceof Number && totalPages > 1);

        // Available vertical space: below page indicator to bottom
        var topOffset = hasPageIndicator ? (8 + dc.getFontHeight(Graphics.FONT_TINY)) : 0;
        var currencyLabel = CryptoConfig.getCurrencyLabel();
        var labelHeight = (currencyLabel != null) ? dc.getFontHeight(Graphics.FONT_XTINY) : 0;
        var availableHeight = screenHeight - topOffset - labelHeight;
        var itemCount = _currentCryptos.size();
        var maxItemHeight = screenHeight > 300 ? 105 : 70;
        var itemHeight = itemCount > 0 ? availableHeight / itemCount : availableHeight;
        if (itemHeight > maxItemHeight) { itemHeight = maxItemHeight; }
        var startY = topOffset + (availableHeight - (itemCount * itemHeight)) / 2;

        // Determine uniform price font for all items on this page
        var priceFont = determinePriceFont(dc, screenWidth);

        for (var i = 0; i < itemCount; i++) {
            drawCryptoCurrency(dc, _currentCryptos[i], screenWidth, startY + (i * itemHeight), itemHeight, priceFont);
        }

        // Draw currency label (e.g. "CAD", "AUD") below list for dollar-variant currencies
        if (currencyLabel != null) {
            var lastItemBottom = startY + (itemCount * itemHeight);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth / 2, lastItemBottom, Graphics.FONT_XTINY, currencyLabel, Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (hasPageIndicator) {
            drawPageIndicator(dc, pageInfo);
        }
    }

    private function getContentMargin(screenWidth as Number) as Number {
        return screenWidth * 35 / 100;
    }

    private function determinePriceFont(dc as Dc, screenWidth as Number) as FontDefinition {
        var mainFont = screenWidth > 300 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        var fallbacks = screenWidth > 300
            ? [Graphics.FONT_SMALL, Graphics.FONT_TINY]
            : [Graphics.FONT_TINY, Graphics.FONT_XTINY];
        var centerX = screenWidth / 2;
        var margin = getContentMargin(screenWidth);
        var symbolX = centerX - margin;
        var priceX = centerX + margin;
        var availableWidth = priceX - symbolX - 20;
        var font = mainFont;

        for (var i = 0; i < _currentCryptos.size(); i++) {
            var crypto = _currentCryptos[i];
            var symbolWidth = dc.getTextWidthInPixels(crypto.symbol, mainFont);
            var displayText = crypto.getDisplayText();
            for (var f = 0; f < fallbacks.size(); f++) {
                if (symbolWidth + dc.getTextWidthInPixels(displayText, font) > availableWidth) {
                    font = fallbacks[f];
                }
            }
        }
        return font;
    }

    function drawCryptoCurrency(dc as Dc, crypto as CryptoCurrency, screenWidth as Number, yPosition as Number, itemHeight as Number, priceFont as FontDefinition) as Void {
        var centerX = screenWidth / 2;
        var margin = getContentMargin(screenWidth);
        var symbolX = centerX - margin;
        var priceX = centerX + margin;
        var mainFont = screenWidth > 300 ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
        var mainFontHeight = dc.getFontHeight(mainFont);

        // Draw symbol
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(symbolX, yPosition, mainFont, crypto.symbol, Graphics.TEXT_JUSTIFY_LEFT);

        // Draw price
        var priceColor = crypto.getPriceChangeColor();
        var displayText = crypto.getDisplayText();
        if (displayText.length() == 0) {
            displayText = "No Data";
            priceColor = Graphics.COLOR_YELLOW;
        }

        dc.setColor(priceColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(priceX, yPosition, priceFont, displayText, Graphics.TEXT_JUSTIFY_RIGHT);

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
    }
    
    function updateCurrentCryptos() as Void {
        _currentCryptos = _portfolio.getCurrentPageCryptos();
    }
    
    function updateDisplay() as Void {
        updateCurrentCryptos();
        WatchUi.requestUpdate();
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

    function addCrypto(symbol as String, exchange as String) as Void {
        _portfolio.addCrypto(symbol, exchange);
        showLastPageNow();
        refreshData();
    }

    function showLastPageNow() as Void {
        _portfolio.goToLastPage();
        updateDisplay();
    }
    
    function reorderCrypto(index as Number, direction as Symbol) as Boolean {
        var success = false;
        if (direction == :up) {
            success = _portfolio.moveCryptoUp(index);
        } else if (direction == :down) {
            success = _portfolio.moveCryptoDown(index);
        }
        if (success) { updateDisplay(); }
        return success;
    }

    function removeCrypto(symbol as String) as Boolean {
        var success = _portfolio.removeCryptoCurrency(symbol.toUpper());
        if (success) {
            if (_portfolio.getCount() > 0 && _portfolio.getCurrentPageCryptos().size() == 0) {
                _portfolio.goToLastPage();
            }
            updateDisplay();
        }
        return success;
    }
}
