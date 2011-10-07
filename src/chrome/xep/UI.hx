package chrome.xep;

class UI {
	
	public static function desktopNotification( title : String, m : String, time : Int = 3000 ) {
		dui.Notification.show( "XEP-search "+title, m, time, "img/icon_48.png");
	}
	
}
