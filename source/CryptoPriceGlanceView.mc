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
        var centerY = dc.getHeight() / 2;
        var justify = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (cryptos.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(40, centerY, Graphics.FONT_TINY, "No Crypto", justify);
            return;
        }

        var crypto = cryptos[0];
        var font = Graphics.FONT_TINY;
        var smallFont = Graphics.FONT_XTINY;
        var startX = 5;
        var padding = 10;
        var screenWidth = dc.getWidth();

        var percentText = "";
        if (crypto.percentChange24h != null) {
            percentText = (crypto.percentChange24h >= 0 ? "+" : "") + crypto.percentChange24h.format("%.2f") + "%";
        }

        // Check if everything fits with normal font
        var symbolWidth = dc.getTextWidthInPixels(crypto.symbol, font);
        var priceWidth = dc.getTextWidthInPixels(crypto.priceFormatted, font);
        var percentWidth = percentText.length() > 0 ? dc.getTextWidthInPixels(percentText, smallFont) : 0;
        var totalWidth = symbolWidth + padding + priceWidth + padding + percentWidth;

        // Use smaller font for price if it doesn't fit
        var priceFont = font;
        if (totalWidth > screenWidth) {
            priceFont = smallFont;
            priceWidth = dc.getTextWidthInPixels(crypto.priceFormatted, smallFont);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, centerY, font, crypto.symbol, justify);

        var priceX = startX + symbolWidth + padding;
        dc.setColor(crypto.getPriceChangeColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(priceX, centerY, priceFont, crypto.priceFormatted, justify);

        if (percentText.length() > 0) {
            var percentX = priceX + priceWidth + padding;
            dc.drawText(percentX, centerY, smallFont, percentText, justify);
        }
    }
}
