import Toybox.Application.Storage;
import Toybox.Lang;

(:glance :background)
module CryptoConfig {
    const BINANCE_24H_TICKER_URL = "https://api.binance.com/api/v3/ticker/24hr";
    const KUCOIN_24H_STATS_URL = "https://api.kucoin.com/api/v1/market/stats";
    const FRANKFURTER_API_URL = "https://api.frankfurter.app/latest";

    const DEFAULT_CRYPTOS = [
        { "symbol" => "BTC", "name" => "Bitcoin" },
        { "symbol" => "ETH", "name" => "Ethereum" },
        { "symbol" => "BNB", "name" => "Binance Coin" },
        { "symbol" => "TRX", "name" => "Tron" },
        { "symbol" => "SOL", "name" => "Solana" },
        { "symbol" => "POL", "name" => "Polygon" }
    ];

    const STORAGE_LAST_UPDATE = "last_update";
    const STORAGE_DISPLAY_CURRENCY = "display_currency";
    const STORAGE_EXCHANGE_RATE = "exchange_rate";
    const STORAGE_RATES_LAST_UPDATE = "rates_last_update";
    const DEFAULT_DISPLAY_CURRENCY = "USD";

    const CURRENCY_SYMBOLS = {
        "USD" => "$",
        "EUR" => "€",
        "GBP" => "£",
        "CAD" => "$",
        "AUD" => "$",
        "NZD" => "$"
    };

    function getDisplayCurrencyCode() as String {
        var code = Storage.getValue(STORAGE_DISPLAY_CURRENCY);
        return (code instanceof String) ? code : DEFAULT_DISPLAY_CURRENCY;
    }

    function getDisplayCurrencySymbol() as String {
        var code = getDisplayCurrencyCode();
        var symbol = CURRENCY_SYMBOLS.get(code);
        return (symbol instanceof String) ? symbol : "$";
    }

    function getCurrencyLabel() as String? {
        var code = getDisplayCurrencyCode();
        if (code.equals("USD") || code.equals("EUR") || code.equals("GBP")) {
            return null;
        }
        return code;
    }

    function getDisplayCurrencyRate() as Float {
        var code = getDisplayCurrencyCode();
        if (code.equals("USD")) { return 1.0; }
        var rate = Storage.getValue(STORAGE_EXCHANGE_RATE);
        if (rate instanceof Float) { return rate; }
        if (rate instanceof Number) { return rate.toFloat(); }
        return 1.0;
    }

    function getErrorMessageForResponseCode(responseCode as Number) as String {
        if (responseCode == 401) { return "Invalid API Key"; }
        if (responseCode == 403) { return "Access Denied"; }
        if (responseCode == 429) { return "Rate Limited"; }
        if (responseCode >= 500) { return "Server Error"; }
        if (responseCode >= 400) { return "Client Error"; }
        return "Network Error";
    }
}
