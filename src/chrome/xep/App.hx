package chrome.xep;

import chrome.Omnibox;
import chrome.xep.XEPStatus;
using StringTools;

class App implements IApp {
	
	static var DEF_URL = "https://raw.github.com/tong/chrome.xep.search/master/";
	static var XEP_BASE_URL = "http://xmpp.org/extensions/xep-";
	static inline var MAX_SUGGESTIONS = 5;
	
	static var xeps_description_version : Int;
	static var xeps_description_version_available : Int;
	static var xeps : Array<XEP>;
	
	public var xepStatusFilters(default,null) : Array<Int>;
	
	function new() {
	
		xepStatusFilters = Storage.getObject( "xep_status_filters" );
		if( xepStatusFilters == null ) {
			xepStatusFilters = new Array();
			for( i in 0...Type.getClassFields(XEPStatus).length )
				xepStatusFilters.push(i);
			Storage.setObject( "xep_status_filters", xepStatusFilters );
		}
		
		var xeps_description = LocalStorage.getItem( "xeps_description" );
		xeps_description_version = LocalStorage.getItem( "xeps_description_version" );
		xeps_description_version_available = Std.parseInt( haxe.Http.requestUrl( DEF_URL+"xeps_description_version" ) );
		trace( "XEP description version: HAVE:"+xeps_description_version+" / AVAILABLE:"+xeps_description_version_available);
		if( xeps_description == null || xeps_description_version == null ) {
			updateXEPsDescription( function(err){
				//if( err != null ) //TODO
				run();
			});
		} else {
			if( xeps_description_version < xeps_description_version_available ) {
				updateXEPsDescription( function(err){
					//if( err != null ) //TODO
					run();
				});
			} else {
				xeps = JSON.parse( xeps_description );
				run();
			}
		}
	}
	
	public function updateXEPsDescription( ?cb : String->Void ) {
		trace( "Loading XEP descriptions from remote host..." );
		xeps = new Array();
		var f = haxe.Http.requestUrl( DEF_URL + XEPDescription.FILE );
		for( d in f.split("\n") )
			xeps.push( JSON.parse( d ) );
		for( xep in xeps ) {
			xep.abstract = jabber.util.Base64.decode( xep.abstract );
		}
		LocalStorage.setItem( "xeps_description",JSON.stringify( xeps )  );
		LocalStorage.setItem( "xeps_description_version", xeps_description_version_available );
		trace( xeps.length+" XEP descriptions loaded" );
		UI.desktopNotification( "", xeps.length+" XEP descriptions loaded", 3000 );
		if( cb != null ) cb( null );
	}
	
	#if DEBUG
	public function log( v : Dynamic, ?inf : haxe.PosInfos ) haxe.Log.trace( v, inf )
	#end
	
	function run() {
		setDefaultSuggestion();
		Omnibox.onInputStarted.addListener( onInputStarted );
		Omnibox.onInputChanged.addListener( onInputChanged );
		Omnibox.onInputEntered.addListener( onInputEntered );
		trace( "XEP search extension activated" );
	}
	
	function onInputStarted() {
		//setDefaultSuggestion();
	}
	
	function onInputChanged( text : String, suggest : Array<chrome.SuggestResult>->Void ) {
		if( text == null )
            return;
		var stext = text.trim();
		if( stext == null )
			return;
		if( stext == "" ) {
			setDefaultSuggestion();
			return;
		}
		var term = stext.toLowerCase();
		var numberMatch = false;
		var found = new Array<XEP>();
		var r_number = ~/([0-9]+)/;
		if( r_number.match( term ) ) {
			var number = Std.parseInt( r_number.matched(1) );
			for( xep in xeps ) {
				if( xep.number == number ) {
					found.push( xep );
					numberMatch = true;
					break;
				}
			}
		} else {
			var i = 0;
			var _xeps = xeps.copy();
			for( xep in _xeps ) {
				if( found.length >= MAX_SUGGESTIONS )
					break;
				if( xep.title != null && xep.title.toLowerCase().indexOf( term ) != -1 ) {
					found.push( xep );
					_xeps.splice( i, 1 );
				}
				i++;
			}
			i = 0;
			for( xep in _xeps ) {
				if( found.length >= MAX_SUGGESTIONS )
					break;
				if( xep.name != null && xep.name.toLowerCase().indexOf( term ) != -1 ) {
					found.push( xep );
					_xeps.splice( i, 1 );
				}
			}
		}
		
		//TODO use a faster algo, this sux!
		// filter by XEP status
		var temp = new Array<XEP>();
		for( xep in found ) {
			for( f in xepStatusFilters ) {
				if( f == xep.status ) {
					temp.push( xep );
					break;
				}
			}
		}
		found = temp;
		
		/*
		if( found.length == 0 ) {
			// search somewhere else
		}
		*/
		
		// list is already sorted
		//found.sort( function(a,b){ return ( a.number > b.number ) ? 1 : -1; } );
		//for( xep in found ) trace(xep.number);
		
		var suggestions = new Array<SuggestResult>();
		for( xep in found )
			suggestions.push( createXEPSuggestResult( xep ) );

		if( !numberMatch && suggestions.length < MAX_SUGGESTIONS && stext.length >= 2 ) {
			suggestions.push({
				content : stext+" [xmpp.org search]",
				description : 'Search for <url>"'+stext+'"</url> at xmpp.org'
			});
		}
		suggest( suggestions );
	}
	
	function onInputEntered( text : String ) {
		var stext = text.trim();
		if( stext == null ) {
			nav( "http://xmpp.org/xmpp-protocols/xmpp-extensions/" );
			return;
		}
		if( stext.startsWith( "http://" ) || stext.startsWith( "https://" ) ) {
			nav( stext );
			return;
		}
		if( stext.startsWith( "www." ) || stext.endsWith( ".com" ) || stext.endsWith( ".net" ) || stext.endsWith( ".org" ) || stext.endsWith( ".edu" ) ) {
			nav( "http://"+stext );
			return;
    	}
    	var suffix = " [xmpp.org search]";
    	if( stext.endsWith( suffix ) ) {
    		nav( "http://xmpp.org/search/"+formatSearchSuggestionQuery( stext, suffix ) );
			return;
    	}
	}
	
	static function createXEPSuggestResult( xep : XEP ) : SuggestResult {
		var slen = Std.string( xep.number ).length;
		var zeros = "";
		for( i in 0...(4-slen) ) zeros += "0";
		var url = XEP_BASE_URL + zeros + xep.number + ".html";
		var desc = "<match>XEP-"+zeros+xep.number+" : "+xep.title+"</match>";
		if( xep.abstract != null || xep.abstract != "null" ) {
			desc += "<dim> - "+xep.abstract+"</dim>";
		}
		desc += " - <url><dim>"+url+"</dim></url>";
		return { content : url, description : desc };
	}
	
	static function formatSearchSuggestionQuery( t : String, suffix : String ) : String {
		return t.substr( 0, t.length - suffix.length ).trim().urlEncode();
	}
	
	static function nav( url : String ) {
		chrome.Tabs.getSelected( null, function(tab) { chrome.Tabs.update( tab.id, { url: url } ); });
	}
	
	static function setDefaultSuggestion( text : String = "" ) {
		var d = '<url><match>XEP Search</match></url>';
		if( text != null ) d +=  " "+text;
		Omnibox.setDefaultSuggestion( { description : d } );
	}
	
	static function init() : IApp {
		#if DEBUG
		if( haxe.Firebug.detect() ) haxe.Firebug.redirectTraces();	
		trace( "XEP-search" );
		#end
		return new App();
	}
	
}
