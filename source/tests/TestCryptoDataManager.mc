import Toybox.Test;
import Toybox.Lang;
import Toybox.Application.Storage;
using CryptoConfig;

// ============================================================
// CryptoConfig.getErrorMessageForResponseCode
// ============================================================

(:test)
function testErrorMessageCode401(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(401), "Invalid API Key");
    return true;
}

(:test)
function testErrorMessageCode403(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(403), "Access Denied");
    return true;
}

(:test)
function testErrorMessageCode429(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(429), "Rate Limited");
    return true;
}

(:test)
function testErrorMessageCode500(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(500), "Server Error");
    return true;
}

(:test)
function testErrorMessageCode503(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(503), "Server Error");
    return true;
}

(:test)
function testErrorMessageCode400(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(400), "Client Error");
    return true;
}

(:test)
function testErrorMessageCode404(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(404), "Client Error");
    return true;
}

(:test)
function testErrorMessageCode300(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(300), "Network Error");
    return true;
}

(:test)
function testErrorMessageCodeNegative(logger as Test.Logger) as Boolean {
    Test.assertEqual(CryptoConfig.getErrorMessageForResponseCode(-1), "Network Error");
    return true;
}

// ============================================================
// CryptoConfig currency helper functions
// ============================================================

(:test)
function testGetDisplayCurrencyCodeDefault(logger as Test.Logger) as Boolean {
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Test.assertEqual(CryptoConfig.getDisplayCurrencyCode(), "USD");
    return true;
}

(:test)
function testGetDisplayCurrencyCodeSet(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Test.assertEqual(CryptoConfig.getDisplayCurrencyCode(), "EUR");
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    return true;
}

(:test)
function testGetDisplayCurrencySymbolUSD(logger as Test.Logger) as Boolean {
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Test.assertEqual(CryptoConfig.getDisplayCurrencySymbol(), "$");
    return true;
}

(:test)
function testGetDisplayCurrencySymbolEUR(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Test.assertEqual(CryptoConfig.getDisplayCurrencySymbol(), "€");
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    return true;
}

(:test)
function testGetDisplayCurrencySymbolCAD(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "CAD");
    Test.assertEqual(CryptoConfig.getDisplayCurrencySymbol(), "$");
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    return true;
}

(:test)
function testGetDisplayCurrencySymbolAUD(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "AUD");
    Test.assertEqual(CryptoConfig.getDisplayCurrencySymbol(), "$");
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    return true;
}

(:test)
function testGetDisplayCurrencyRateDefaultUSD(logger as Test.Logger) as Boolean {
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Storage.deleteValue(CryptoConfig.STORAGE_EXCHANGE_RATE);
    Test.assertEqual(CryptoConfig.getDisplayCurrencyRate(), 1.0);
    return true;
}

(:test)
function testGetDisplayCurrencyRateWithStoredRate(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 0.92);
    var rate = CryptoConfig.getDisplayCurrencyRate();
    // Compare with tolerance for float precision
    Test.assert(rate > 0.91 && rate < 0.93);
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Storage.deleteValue(CryptoConfig.STORAGE_EXCHANGE_RATE);
    return true;
}

(:test)
function testGetDisplayCurrencyRateUSDIgnoresStoredRate(logger as Test.Logger) as Boolean {
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 0.92);
    // USD should always return 1.0 regardless of stored rate
    Test.assertEqual(CryptoConfig.getDisplayCurrencyRate(), 1.0);
    Storage.deleteValue(CryptoConfig.STORAGE_EXCHANGE_RATE);
    return true;
}

(:test)
function testGetDisplayCurrencyRateNoStoredRateFallback(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Storage.deleteValue(CryptoConfig.STORAGE_EXCHANGE_RATE);
    // No rate stored, should fallback to 1.0
    Test.assertEqual(CryptoConfig.getDisplayCurrencyRate(), 1.0);
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    return true;
}

// ============================================================
// CryptoCurrency.updatePriceData integration tests
// (exercises the data flow path that simpleParseFloat feeds into)
// ============================================================

(:test)
function testUpdatePriceDataWithDictionary(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 42000.50, "percent_change_24h" => 3.25});
    Test.assertEqual(crypto.isLoading, false);
    Test.assertEqual(crypto.hasError, false);
    Test.assertNotEqual(crypto.price, null);
    Test.assertNotEqual(crypto.priceFormatted, "Loading...");
    return true;
}

(:test)
function testUpdatePriceDataSetsFieldsCorrectly(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("ETH", "Ethereum");
    crypto.updatePriceData({"price" => 2500.0, "percent_change_24h" => -1.5});
    Test.assertEqual(crypto.priceFormatted, "$2500");
    Test.assertNotEqual(crypto.percentChange24h, null);
    Test.assertEqual(crypto.isLoading, false);
    Test.assertEqual(crypto.hasError, false);
    return true;
}
