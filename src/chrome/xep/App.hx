package chrome.xep;

import chrome.Omnibox;
import chrome.xep.XEPStatus;
using StringTools;

class App implements IApp {
	
//	static var DEF_URL = "https://raw.github.com/tong/chrome.xep.search/master/";
	static var XEP_BASE_URL = "http://xmpp.org/extensions/xep-";
	static inline var MAX_SUGGESTIONS = 5;
	
//	static var xeps_description_version : Int;
//	static var xeps_description_version_available : Int;
	static var xeps : Array<XEP>;
	//static var searchedTerm : String;
	
	public var xepStatusFilters(default,null) : Array<Int>;
	
	//var livePreview : Bool;
	
	function new() {
		
		//livePreview = true;
		
		xepStatusFilters = Storage.getObject( "xep_status_filters" );
		if( xepStatusFilters == null ) { // add all filters
			xepStatusFilters = new Array();
			for( i in 0...Type.getClassFields( XEPStatus ).length )
				xepStatusFilters.push(i);
			Storage.setObject( "xep_status_filters", xepStatusFilters );
		}
		
		xeps = new Array();
		var r = haxe.Resource.getString( "xep" );
		for( d in r.split("\n") )
			xeps.push( JSON.parse( d ) );
		for( xep in xeps ) {
			xep.abstract = jabber.util.Base64.decode( xep.abstract );
		}
		//LocalStorage.setItem( "xeps_description",JSON.stringify( xeps )  );
		trace( xeps.length+" XEP descriptions loaded" );
		//UI.desktopNotification( "", "XEP descriptions updated", 3000 );
		run();
		
		/*
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
		*/
	}
	
	/*
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
		UI.desktopNotification( "", "XEP descriptions updated", 3000 );
		if( cb != null ) cb( null );
	}
	*/
	
	#if DEBUG
	public inline function log( v : Dynamic, ?inf : haxe.PosInfos ) haxe.Log.trace( v, inf )
	#end
	
	function run() {
		setDefaultSuggestion();
		Omnibox.onInputStarted.addListener( onInputStarted );
		Omnibox.onInputChanged.addListener( onInputChanged );
		Omnibox.onInputCancelled.addListener( onInputCancelled );
		Omnibox.onInputEntered.addListener( onInputEntered );
		trace( "XEP search extension activated" );
	}
	
	function onInputStarted() {
		setDefaultSuggestion();
	}
	
	function onInputChanged( text : String, suggest : Array<chrome.SuggestResult>->Void ) {
		if( text == null ) {
			setDefaultSuggestion();
			return;
		}
		var stext = text.trim();
		if( stext == null ) {
			setDefaultSuggestion();
			return;
		}
		if( stext == "" ) {
			setDefaultSuggestion();
			return;
		}
		var term = stext.toLowerCase();
		var numberMatch = false;
		var found = new Array<XEP>();
		var numFound = 0;
		var r_number = ~/([0-9]+)/;
		if( r_number.match( term ) ) {
			numFound = 1;
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
				if( xep.title != null && xep.title.toLowerCase().indexOf( term ) != -1 ) {
					found.push( xep );
					_xeps.splice( i, 1 );
				}
				i++;
			}
			i = 0;
			for( xep in _xeps ) {
				if( xep.name != null && xep.name.toLowerCase().indexOf( term ) != -1 ) {
					found.push( xep );
					_xeps.splice( i, 1 );
				}
			}
			numFound = found.length;
		}
		
		if( found.length >= MAX_SUGGESTIONS )
			found = found.splice( 0, MAX_SUGGESTIONS );
		
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
		} else {
			//else
		}
		suggest( suggestions );
		//var nfo = found.join(",");
		//var nfo = "";
		//for( xep in found ) nfo += xep.number+",";
		setDefaultSuggestion( numFound+" found" );
		
		//TODO live site preview...
		/*
		if( livePreview ) {
			chrome.Tabs.getSelected( null, function(tab) {
				//if( tab.url == "chrome://newtab/" ) {
					//trace( suggestions );
					var s = suggestions[0];
					nav( suggestions[0].content );
				//}
			});
		}
		*/
	}
	
	function onInputCancelled() {
		setDefaultSuggestion();
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
    	setDefaultSuggestion();
	}
	
	static function createXEPSuggestResult( xep : XEP ) : SuggestResult {
		var slen = Std.string( xep.number ).length;
		var zeros = "";
		for( i in 0...(4-slen) ) zeros += "0";
		var url = XEP_BASE_URL + zeros + xep.number + ".html";
		var desc = "<match>XEP-"+zeros+xep.number+" : "+xep.title+"</match>";
		//var desc = "<url>XEP-"+zeros+xep.number+" : "+xep.title+"</url>";
		if( xep.abstract != null || xep.abstract != "null" ) {
			desc += "<dim> - "+xep.abstract+"</dim>";
		}
		desc += " - <url><dim>"+url+"</dim></url>";
		//desc += " - <url>"+url+"</url>";
		return { content : url, description : desc };
	}
	
	static inline function formatSearchSuggestionQuery( t : String, suffix : String ) : String {
		return t.substr( 0, t.length - suffix.length ).trim().urlEncode();
	}
	
	static function nav( url : String ) {
		chrome.Tabs.getCurrent( function(tab) { chrome.Tabs.update( tab.id, { url: url } ); });
	}
	
	static function setDefaultSuggestion( text : String = " " ) {
		if( text == "" ) text = " ";
		Omnibox.setDefaultSuggestion( { description : text } );
	}
	
	static function init() : IApp {
		#if DEBUG
		if( haxe.Firebug.detect() ) haxe.Firebug.redirectTraces();	
		trace( "chrome.xep.search", "debug" );
		#end
		return new App();
	}
	
}
