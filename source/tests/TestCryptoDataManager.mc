import Toybox.Test;
import Toybox.Lang;
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
