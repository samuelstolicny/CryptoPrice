import Toybox.Test;
import Toybox.Lang;
import Toybox.Application.Storage;

(:test)
function testPortfolioInitializesWithDefaults(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var count = portfolio.getCount();
    logger.debug("Default count: " + count);
    Test.assertEqual(count, 6);
    return true;
}

(:test)
function testPortfolioDefaultSymbols(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var expectedSymbols = ["BTC", "ETH", "BNB", "TRX", "SOL", "POL"];
    for (var i = 0; i < expectedSymbols.size(); i++) {
        var crypto = portfolio.findCryptoCurrency(expectedSymbols[i]);
        Test.assertMessage(crypto != null, "Expected to find " + expectedSymbols[i]);
    }
    return true;
}

(:test)
function testAddCrypto(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var initialCount = portfolio.getCount();
    portfolio.addCrypto("ADA", "binance");
    Test.assertEqual(portfolio.getCount(), initialCount + 1);
    var found = portfolio.findCryptoCurrency("ADA");
    Test.assertMessage(found != null, "Should find added crypto ADA");
    return true;
}

(:test)
function testAddCryptoCurrencyWithName(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var initialCount = portfolio.getCount();
    portfolio.addCryptoCurrency("DOGE", "Dogecoin", "binance");
    Test.assertEqual(portfolio.getCount(), initialCount + 1);
    var found = portfolio.findCryptoCurrency("DOGE");
    Test.assertMessage(found != null, "Should find added crypto DOGE");
    return true;
}

(:test)
function testFindCryptoCurrencyExisting(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var btc = portfolio.findCryptoCurrency("BTC");
    Test.assertMessage(btc != null, "BTC should exist in default portfolio");
    return true;
}

(:test)
function testFindCryptoCurrencyNonExistent(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var xyz = portfolio.findCryptoCurrency("XYZ");
    Test.assert(xyz == null);
    return true;
}

(:test)
function testRemoveCryptoCurrencyExisting(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var initialCount = portfolio.getCount();
    var result = portfolio.removeCryptoCurrency("BTC");
    Test.assertEqual(result, true);
    Test.assertEqual(portfolio.getCount(), initialCount - 1);
    var found = portfolio.findCryptoCurrency("BTC");
    Test.assert(found == null);
    return true;
}

(:test)
function testRemoveCryptoCurrencyNonExistent(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var initialCount = portfolio.getCount();
    var result = portfolio.removeCryptoCurrency("FAKECOIN");
    Test.assertEqual(result, false);
    Test.assertEqual(portfolio.getCount(), initialCount);
    return true;
}

(:test)
function testGetCurrentPageCryptos(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // Default page size is 3, with 6 cryptos first page should have 3
    var page = portfolio.getCurrentPageCryptos();
    Test.assertEqual(page.size(), 3);
    return true;
}

(:test)
function testNextPage(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // 6 items, page size 3: page 1 has 3, page 2 has 3
    var moved = portfolio.nextPage();
    Test.assertEqual(moved, true);
    var page = portfolio.getCurrentPageCryptos();
    Test.assertEqual(page.size(), 3);
    return true;
}

(:test)
function testNextPageAtEnd(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // Move to page 2
    portfolio.nextPage();
    // Try to move to page 3 (should fail, only 2 pages)
    var moved = portfolio.nextPage();
    Test.assertEqual(moved, false);
    return true;
}

(:test)
function testPreviousPage(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // Move to page 2 then back to page 1
    portfolio.nextPage();
    var moved = portfolio.previousPage();
    Test.assertEqual(moved, true);
    var page = portfolio.getCurrentPageCryptos();
    Test.assertEqual(page.size(), 3);
    return true;
}

(:test)
function testPreviousPageAtStart(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // Already on first page, previousPage should return false
    var moved = portfolio.previousPage();
    Test.assertEqual(moved, false);
    return true;
}

(:test)
function testGetPageInfo(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    var info = portfolio.getPageInfo();
    Test.assertEqual(info.get("currentPage"), 1);
    Test.assertEqual(info.get("totalPages"), 2);
    return true;
}

(:test)
function testGetPageInfoAfterNextPage(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    portfolio.nextPage();
    var info = portfolio.getPageInfo();
    Test.assertEqual(info.get("currentPage"), 2);
    Test.assertEqual(info.get("totalPages"), 2);
    return true;
}

(:test)
function testGoToLastPage(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    portfolio.goToLastPage();
    var info = portfolio.getPageInfo();
    Test.assertEqual(info.get("currentPage"), 2);
    Test.assertEqual(info.get("totalPages"), 2);
    return true;
}

(:test)
function testGetCryptosNeedingRefresh(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    // All default cryptos have lastUpdated = null, so all should need refresh
    var stale = portfolio.getCryptosNeedingRefresh();
    Test.assertEqual(stale.size(), 6);
    return true;
}

(:test)
function testGetCount(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    Test.assertEqual(portfolio.getCount(), 6);
    portfolio.addCrypto("AVAX", "binance");
    Test.assertEqual(portfolio.getCount(), 7);
    portfolio.removeCryptoCurrency("AVAX");
    Test.assertEqual(portfolio.getCount(), 6);
    return true;
}

(:test)
function testResetToDefaults(logger as Test.Logger) as Boolean {
    Storage.deleteValue("cryptos");
    var portfolio = new CryptoPortfolio();
    portfolio.addCrypto("AVAX", "binance");
    portfolio.addCrypto("LINK", "binance");
    Test.assertEqual(portfolio.getCount(), 8);
    portfolio.resetToDefaults();
    Test.assertEqual(portfolio.getCount(), 6);
    var avax = portfolio.findCryptoCurrency("AVAX");
    Test.assert(avax == null);
    return true;
}
