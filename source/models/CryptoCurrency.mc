import Toybox.Lang;
import Toybox.Time;
import Toybox.Graphics;

(:glance)
class CryptoCurrency {
    public var symbol as String;
    public var name as String;
    public var price as Float?;
    public var priceFormatted as String;
    public var percentChange24h as Float?;
    public var lastUpdated as Number?;
    public var isLoading as Boolean;
    public var hasError as Boolean;
    public var errorMessage as String?;
    
    function initialize(symbol as String, name as String) {
        self.symbol = symbol;
        self.name = name;
        self.price = null;
        self.priceFormatted = "Loading...";
        self.percentChange24h = null;
        self.lastUpdated = null;
        self.isLoading = true;
        self.hasError = false;
        self.errorMessage = null;
    }
    
    function updatePriceData(priceData as Dictionary) as Void {
        self.isLoading = false;
        self.hasError = false;
        self.errorMessage = null;
        
        var p = priceData.get("price");
        if (p instanceof Float or p instanceof Double or p instanceof Number) {
            self.price = p.toFloat();
            // Format to always show at least 3 significant digits
            if (self.price >= 100.0) {
                self.priceFormatted = "$" + self.price.format("%.0f");
            } else if (self.price >= 10.0) {
                self.priceFormatted = "$" + self.price.format("%.1f");
            } else if (self.price >= 1.0) {
                self.priceFormatted = "$" + self.price.format("%.2f");
            } else {
                self.priceFormatted = "$" + self.price.format("%.3f");
            }
        }
        
        var pc = priceData.get("percent_change_24h");
        if (pc instanceof Float or pc instanceof Double or pc instanceof Number) {
            self.percentChange24h = pc.toFloat();
        }
        
        self.lastUpdated = Time.now().value();
    }
    
    function setLoading() as Void {
        self.isLoading = true;
        self.hasError = false;
        self.errorMessage = null;
    }
    
    function setError(errorMessage as String) as Void {
        self.isLoading = false;
        self.hasError = true;
        self.errorMessage = errorMessage;
        self.priceFormatted = "Error";
    }
    
    function isDataStale() as Boolean {
        if (self.lastUpdated == null) { return true; }
        return (Time.now().value() - self.lastUpdated) > 60;
    }
    
    function getDisplayText() as String {
        if (self.isLoading) { return "Loading..."; }
        if (self.hasError) { return self.errorMessage != null ? self.errorMessage : "Error"; }
        if (self.priceFormatted == null || self.priceFormatted.length() == 0) { return "No Data"; }
        return self.priceFormatted;
    }
    
    function getPriceChangeColor() as Number {
        if (self.percentChange24h == null) { return Graphics.COLOR_WHITE; }
        if (self.percentChange24h > 0) { return Graphics.COLOR_GREEN; }
        if (self.percentChange24h < 0) { return Graphics.COLOR_RED; }
        return Graphics.COLOR_WHITE;
    }
}
