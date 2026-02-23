import Toybox.Test;
import Toybox.Lang;
import Toybox.Graphics;

// ============================================================
// Price formatting tiers
// ============================================================

(:test)
function testPriceFormattingHighValue(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 45000.0, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$45000");
    return true;
}

(:test)
function testPriceFormattingMidValue(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("SOL", "Solana");
    crypto.updatePriceData({"price" => 45.5, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$45.5");
    return true;
}

(:test)
function testPriceFormattingLowValue(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("ADA", "Cardano");
    crypto.updatePriceData({"price" => 1.23, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$1.23");
    return true;
}

(:test)
function testPriceFormattingSubDollar(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("DOGE", "Dogecoin");
    crypto.updatePriceData({"price" => 0.123, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.123");
    return true;
}

// ============================================================
// getPriceChangeColor
// ============================================================

(:test)
function testPriceChangeColorPositive(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0, "percent_change_24h" => 5.2});
    Test.assertEqual(crypto.getPriceChangeColor(), Graphics.COLOR_GREEN);
    return true;
}

(:test)
function testPriceChangeColorNegative(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0, "percent_change_24h" => -3.1});
    Test.assertEqual(crypto.getPriceChangeColor(), Graphics.COLOR_RED);
    return true;
}

(:test)
function testPriceChangeColorNull(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    // percentChange24h is null by default after initialize
    Test.assertEqual(crypto.getPriceChangeColor(), Graphics.COLOR_WHITE);
    return true;
}

(:test)
function testPriceChangeColorZero(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.getPriceChangeColor(), Graphics.COLOR_WHITE);
    return true;
}

// ============================================================
// getDisplayText
// ============================================================

(:test)
function testDisplayTextLoading(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    // isLoading is true by default after initialize
    Test.assertEqual(crypto.getDisplayText(), "Loading...");
    return true;
}

(:test)
function testDisplayTextError(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.setError("Network error");
    Test.assertEqual(crypto.getDisplayText(), "Network error");
    return true;
}

(:test)
function testDisplayTextNormal(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 50000.0, "percent_change_24h" => 1.0});
    Test.assertEqual(crypto.getDisplayText(), "$50000");
    return true;
}

// ============================================================
// isDataStale
// ============================================================

(:test)
function testIsDataStaleFreshData(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0, "percent_change_24h" => 0.0});
    // lastUpdated was just set, so data should not be stale
    Test.assertEqual(crypto.isDataStale(), false);
    return true;
}

(:test)
function testIsDataStaleNullLastUpdated(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    // lastUpdated is null by default, so data should be stale
    Test.assertEqual(crypto.isDataStale(), true);
    return true;
}

// ============================================================
// setLoading
// ============================================================

(:test)
function testSetLoadingResetsErrorState(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.setError("Some error");
    crypto.setLoading();
    Test.assertEqual(crypto.isLoading, true);
    Test.assertEqual(crypto.hasError, false);
    Test.assert(crypto.errorMessage == null);
    return true;
}

// ============================================================
// setError
// ============================================================

(:test)
function testSetErrorSetsState(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.setError("API timeout");
    Test.assertEqual(crypto.errorMessage, "API timeout");
    Test.assertEqual(crypto.hasError, true);
    Test.assertEqual(crypto.isLoading, false);
    Test.assertEqual(crypto.priceFormatted, "Error");
    return true;
}

// ============================================================
// updatePriceData edge cases
// ============================================================

(:test)
function testUpdatePriceDataWithFloatPrice(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("ETH", "Ethereum");
    crypto.updatePriceData({"price" => 3456.78, "percent_change_24h" => 2.5});
    Test.assertNotEqual(crypto.price, null);
    Test.assertEqual(crypto.isLoading, false);
    Test.assertEqual(crypto.hasError, false);
    Test.assertEqual(crypto.priceFormatted, "$3457");
    return true;
}

(:test)
function testUpdatePriceDataNullPercentChange(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0});
    // percent_change_24h key is missing, so percentChange24h stays null
    Test.assert(crypto.percentChange24h == null);
    Test.assertEqual(crypto.priceFormatted, "$100");
    return true;
}
