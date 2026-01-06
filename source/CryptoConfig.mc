import Toybox.Application.Storage;
import Toybox.Lang;

(:glance :background)
module CryptoConfig {
    const BINANCE_24H_TICKER_URL = "https://api.binance.com/api/v3/ticker/24hr";
    
    const DEFAULT_CRYPTOS = [
        { "symbol" => "BTC", "name" => "Bitcoin" },
        { "symbol" => "ETH", "name" => "Ethereum" },
        { "symbol" => "BNB", "name" => "Binance Coin" },
        { "symbol" => "TRX", "name" => "Tron" },
        { "symbol" => "SOL", "name" => "Solana" },
        { "symbol" => "POL", "name" => "Polygon" }
    ];
    
    const STORAGE_LAST_UPDATE = "last_update";
    
    function getErrorMessageForResponseCode(responseCode as Number) as String {
        if (responseCode == 401) { return "Invalid API Key"; }
        if (responseCode == 403) { return "Access Denied"; }
        if (responseCode == 429) { return "Rate Limited"; }
        if (responseCode >= 500) { return "Server Error"; }
        if (responseCode >= 400) { return "Client Error"; }
        return "Network Error";
    }
}
