import Toybox.Lang;
import Toybox.WatchUi;

class CryptoPriceDelegate extends WatchUi.BehaviorDelegate {
    private var _view as CryptoPriceView?;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = null;
    } 

    function setView(view as CryptoPriceView) as Void { _view = view; }

    function onMenu() as Boolean {
        var menuDelegate = new ShowMenuDelegate();
        if (_view != null) { menuDelegate.setView(_view); }
        WatchUi.pushView(new Rez.Menus.MainMenu(), menuDelegate, WatchUi.SLIDE_UP);
        return true;
    }
    
    function onSelect() as Boolean {
        if (_view != null) { _view.refreshData(); }
        return true;
    }
    
    function onNextPage() as Boolean {
        return _view != null ? _view.nextPage() : false;
    }
    
    function onPreviousPage() as Boolean {
        return _view != null ? _view.previousPage() : false;
    }
    
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_LEFT && _view != null) { return _view.nextPage(); }
        if (direction == WatchUi.SWIPE_RIGHT && _view != null) { return _view.previousPage(); }
        return false;
    }
    
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_RIGHT) { return onNextPage(); }
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_LEFT) { return onPreviousPage(); }
        if (key == WatchUi.KEY_ENTER) { return onSelect(); }
        return false;
    }
}