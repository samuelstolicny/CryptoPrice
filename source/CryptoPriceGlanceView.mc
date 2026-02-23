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
        var startX = 5;
        var padding = 10;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, centerY, font, crypto.symbol, justify);

        var priceX = startX + dc.getTextWidthInPixels(crypto.symbol, font) + padding;
        dc.setColor(crypto.getPriceChangeColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(priceX, centerY, font, crypto.priceFormatted, justify);

        if (crypto.percentChange24h != null) {
            var percentX = priceX + dc.getTextWidthInPixels(crypto.priceFormatted, font) + padding;
            var percentText = (crypto.percentChange24h >= 0 ? "+" : "") + crypto.percentChange24h.format("%.2f") + "%";
            dc.drawText(percentX, centerY, Graphics.FONT_XTINY, percentText, justify);
        }
    }
}
