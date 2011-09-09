package chrome.xep;

class Storage {
	
	public static inline function setObject( key : String, value : Dynamic ) {
		LocalStorage.setItem( key, JSON.stringify( value ) );
	}
	
	public static inline function getObject( key : String ) {
		return JSON.parse( LocalStorage.getItem( key ) );
	}
	
}
