import Toybox.WatchUi;
import Toybox.Graphics;

(:glance)
class CryptoPriceGlanceView extends WatchUi.GlanceView {
    private var _portfolio as CryptoPortfolio;

    function initialize() {
        GlanceView.initialize();
        _portfolio = new CryptoPortfolio();
    }

    function onUpdate(dc as Dc) as Void {
        var cryptos = _portfolio.getAllCryptocurrencies();
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        if (cryptos.size() > 0) {
            var crypto = cryptos[0];
            var symbol = crypto.symbol;
            var price = crypto.priceFormatted;
            
            var startX = 5;
            var font = Graphics.FONT_TINY;
            
            // Draw Symbol
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startX, dc.getHeight() / 2, font, symbol, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            
            // Calculate position for price
            var symbolWidth = dc.getTextWidthInPixels(symbol, font);
            var padding = 10; 
            var priceX = startX + symbolWidth + padding;
            
            // Determine Color
            var priceColor = Graphics.COLOR_WHITE;
            if (crypto.percentChange24h != null) {
                if (crypto.percentChange24h >= 0) {
                    priceColor = Graphics.COLOR_GREEN;
                } else {
                    priceColor = Graphics.COLOR_RED;
                }
            }
            
            // Draw Price
            dc.setColor(priceColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(priceX, dc.getHeight() / 2, font, price, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Draw Percentage
            if (crypto.percentChange24h != null) {
                var priceWidth = dc.getTextWidthInPixels(price, font);
                var percentX = priceX + priceWidth + padding;
                var percentText = (crypto.percentChange24h >= 0 ? "+" : "") + crypto.percentChange24h.format("%.2f") + "%";
                
                dc.drawText(percentX, dc.getHeight() / 2, Graphics.FONT_XTINY, percentText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            dc.drawText(40, dc.getHeight() / 2, Graphics.FONT_TINY, "No Crypto", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
