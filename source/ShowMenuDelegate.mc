import Toybox.Lang;
import Toybox.WatchUi;
using CryptoConfig;

class ShowMenuDelegate extends WatchUi.MenuInputDelegate {
    private var _view as CryptoPriceView?;

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function setView(view as CryptoPriceView) as Void {
        _view = view;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :refresh) {
            handleRefresh();
        } else if (item == :settings) {
            var settingsMenu = new WatchUi.Menu2({:title=>"Settings"});
            var currencyCode = CryptoConfig.getDisplayCurrencyCode();
            var currencySymbol = CryptoConfig.getDisplayCurrencySymbol();
            settingsMenu.addItem(new WatchUi.MenuItem("Display Currency", currencyCode + " (" + currencySymbol + ")", "display_currency", null));
            settingsMenu.addItem(new WatchUi.MenuItem("Reset to Defaults", null, "reset_defaults", null));
            WatchUi.pushView(settingsMenu, new SettingsMenuDelegate(_view), WatchUi.SLIDE_UP);
        } else if (item == :add_crypto) {
            handleAddCrypto();
        } else if (item == :remove_crypto) {
            handleRemoveCrypto();
        } else if (item == :reset_defaults && _view != null) {
            _view.requestResetOnNextShow();
        }
    }
    
    private function handleRefresh() as Void {
        if (_view != null) {
            _view.refreshData();
        }
    }
    
    private function handleAddCrypto() as Void {
        if (_view != null) {
            WatchUi.pushView(new WatchUi.TextPicker(""), new AddCryptoDelegate(_view), WatchUi.SLIDE_UP);
        }
    }

    private function handleRemoveCrypto() as Void {
        if (_view != null) {
            WatchUi.pushView(new WatchUi.TextPicker(""), new RemoveCryptoDelegate(_view), WatchUi.SLIDE_UP);
        }
    }
}