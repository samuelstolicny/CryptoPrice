import Toybox.Lang;
import Toybox.WatchUi;

function buildReorderMenu(view as CryptoPriceView) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => "Reorder"});
    var cryptos = view.getPortfolio().getAllCryptocurrencies();
    for (var i = 0; i < cryptos.size(); i++) {
        menu.addItem(new WatchUi.MenuItem(
            (i + 1) + ". " + cryptos[i].symbol,
            null,
            i.toString(),
            null
        ));
    }
    return menu;
}

class ReorderMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as CryptoPriceView;

    function initialize(view as CryptoPriceView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (!(id instanceof String)) { return; }
        var index = (id as String).toNumber();
        if (index == null) { return; }

        var count = _view.getPortfolio().getCount();
        var actionMenu = new WatchUi.Menu2({:title => item.getLabel()});

        if (index > 0) {
            actionMenu.addItem(new WatchUi.MenuItem("Move Up", null, "up", null));
        }
        if (index < count - 1) {
            actionMenu.addItem(new WatchUi.MenuItem("Move Down", null, "down", null));
        }

        WatchUi.pushView(actionMenu, new ReorderActionDelegate(_view, index), WatchUi.SLIDE_UP);
    }
}

class ReorderActionDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as CryptoPriceView;
    private var _index as Number;

    function initialize(view as CryptoPriceView, index as Number) {
        Menu2InputDelegate.initialize();
        _view = view;
        _index = index;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof String && id.equals("up")) {
            _view.reorderCrypto(_index, :up);
        } else if (id instanceof String && id.equals("down")) {
            _view.reorderCrypto(_index, :down);
        }

        // Pop action menu and reorder menu, then re-push fresh reorder menu
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(buildReorderMenu(_view), new ReorderMenuDelegate(_view), WatchUi.SLIDE_IMMEDIATE);
    }
}
