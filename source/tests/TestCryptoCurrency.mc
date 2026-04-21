import Toybox.Test;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application.Storage;
using CryptoConfig;

function resetCurrencyToUSD() as Void {
    Storage.deleteValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY);
    Storage.deleteValue(CryptoConfig.STORAGE_EXCHANGE_RATE);
}

// ============================================================
// Price formatting tiers
// ============================================================

(:test)
function testPriceFormattingHighValue(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 45000.0, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$45000");
    return true;
}

(:test)
function testPriceFormattingMidValue(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("SOL", "Solana");
    crypto.updatePriceData({"price" => 45.5, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$45.5");
    return true;
}

(:test)
function testPriceFormattingLowValue(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("ADA", "Cardano");
    crypto.updatePriceData({"price" => 1.23, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$1.23");
    return true;
}

(:test)
function testPriceFormattingSubDollar(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("DOGE", "Dogecoin");
    crypto.updatePriceData({"price" => 0.123, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.123");
    return true;
}

(:test)
function testPriceFormattingSubCent(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("XLM", "Stellar");
    crypto.updatePriceData({"price" => 0.0456, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.0456");
    return true;
}

(:test)
function testPriceFormattingMilliDollar(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("SHIB", "Shiba Inu");
    crypto.updatePriceData({"price" => 0.00234, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.00234");
    return true;
}

(:test)
function testPriceFormattingTenthMilliDollar(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BONK", "Bonk");
    crypto.updatePriceData({"price" => 0.000234, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.0(3)234");
    return true;
}

(:test)
function testPriceFormattingMicroDollar(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("PEPE", "Pepe");
    crypto.updatePriceData({"price" => 0.0000087, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.priceFormatted, "$0.0(5)870");
    return true;
}

(:test)
function testBracketNotationSplitsPriceParts(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("PEPE", "Pepe");
    crypto.updatePriceData({"price" => 0.0000087, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.pricePrefix, "$0.0(5)");
    Test.assertEqual(crypto.priceMain, "870");
    return true;
}

(:test)
function testStandardFormatHasNoPriceParts(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 45000.0, "percent_change_24h" => 0.0});
    Test.assert(crypto.pricePrefix == null);
    Test.assert(crypto.priceMain == null);
    return true;
}

(:test)
function testSetErrorClearsPriceParts(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("PEPE", "Pepe");
    crypto.updatePriceData({"price" => 0.0000087, "percent_change_24h" => 0.0});
    Test.assertEqual(crypto.pricePrefix, "$0.0(5)");
    crypto.setError("Network error");
    Test.assert(crypto.pricePrefix == null);
    Test.assert(crypto.priceMain == null);
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
    resetCurrencyToUSD();
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
    resetCurrencyToUSD();
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
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 100.0});
    // percent_change_24h key is missing, so percentChange24h stays null
    Test.assert(crypto.percentChange24h == null);
    Test.assertEqual(crypto.priceFormatted, "$100");
    return true;
}

// ============================================================
// formatPriceDisplay with currency conversion
// ============================================================

(:test)
function testFormatPriceDisplayUSD(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 50000.0, "percent_change_24h" => 1.0});
    crypto.formatPriceDisplay(1.0, "$");
    Test.assertEqual(crypto.priceFormatted, "$50000");
    return true;
}

(:test)
function testFormatPriceDisplayEUR(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 50000.0, "percent_change_24h" => 1.0});
    crypto.formatPriceDisplay(0.92, "€");
    Test.assertEqual(crypto.priceFormatted, "€46000");
    return true;
}

(:test)
function testFormatPriceDisplayCAD(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("ETH", "Ethereum");
    crypto.updatePriceData({"price" => 3000.0, "percent_change_24h" => 0.0});
    crypto.formatPriceDisplay(1.36, "$");
    Test.assertEqual(crypto.priceFormatted, "$4080");
    return true;
}

(:test)
function testFormatPriceDisplayAUDMidValue(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("SOL", "Solana");
    crypto.updatePriceData({"price" => 20.0, "percent_change_24h" => 0.0});
    crypto.formatPriceDisplay(1.53, "$");
    Test.assertEqual(crypto.priceFormatted, "$30.6");
    return true;
}

(:test)
function testFormatPriceDisplaySubDollarConverted(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("DOGE", "Dogecoin");
    crypto.updatePriceData({"price" => 0.5, "percent_change_24h" => 0.0});
    crypto.formatPriceDisplay(0.92, "€");
    Test.assertEqual(crypto.priceFormatted, "€0.460");
    return true;
}

(:test)
function testFormatPriceDisplayNullPrice(logger as Test.Logger) as Boolean {
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    // price is null by default, formatPriceDisplay should not crash
    crypto.formatPriceDisplay(0.92, "€");
    Test.assertEqual(crypto.priceFormatted, "Loading...");
    return true;
}

// ============================================================
// refreshPriceDisplay reads from Storage
// ============================================================

(:test)
function testRefreshPriceDisplayUSD(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 1000.0, "percent_change_24h" => 0.0});
    crypto.refreshPriceDisplay();
    Test.assertEqual(crypto.priceFormatted, "$1000");
    return true;
}

(:test)
function testRefreshPriceDisplayEUR(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 0.9);
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 1000.0, "percent_change_24h" => 0.0});
    crypto.refreshPriceDisplay();
    Test.assertEqual(crypto.priceFormatted, "€900");
    resetCurrencyToUSD();
    return true;
}

(:test)
function testUpdatePriceDataUsesCurrencySettings(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "CAD");
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 1.5);
    var crypto = new CryptoCurrency("ETH", "Ethereum");
    crypto.updatePriceData({"price" => 2000.0, "percent_change_24h" => 0.0});
    // 2000 * 1.5 = 3000, CAD now uses "$" symbol with label shown separately
    Test.assertEqual(crypto.priceFormatted, "$3000");
    resetCurrencyToUSD();
    return true;
}

(:test)
function testCurrencySwitchReformatsPrice(logger as Test.Logger) as Boolean {
    resetCurrencyToUSD();
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 50000.0, "percent_change_24h" => 1.0});
    Test.assertEqual(crypto.priceFormatted, "$50000");

    // Switch to EUR
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 0.9);
    crypto.refreshPriceDisplay();
    Test.assertEqual(crypto.priceFormatted, "€45000");

    // Switch back to USD
    resetCurrencyToUSD();
    crypto.refreshPriceDisplay();
    Test.assertEqual(crypto.priceFormatted, "$50000");
    return true;
}

(:test)
function testRawPriceUnchangedAfterConversion(logger as Test.Logger) as Boolean {
    Storage.setValue(CryptoConfig.STORAGE_DISPLAY_CURRENCY, "EUR");
    Storage.setValue(CryptoConfig.STORAGE_EXCHANGE_RATE, 0.9);
    var crypto = new CryptoCurrency("BTC", "Bitcoin");
    crypto.updatePriceData({"price" => 50000.0, "percent_change_24h" => 1.0});
    // raw price stays in USDT
    Test.assert(crypto.price > 49999.0 && crypto.price < 50001.0);
    // but display is converted
    Test.assertEqual(crypto.priceFormatted, "€45000");
    resetCurrencyToUSD();
    return true;
}
