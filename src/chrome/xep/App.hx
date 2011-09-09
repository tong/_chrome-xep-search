package chrome.xep;

import chrome.Omnibox;
import chrome.xep.XEPStatus;
using StringTools;

class App implements IApp {
	
	static var DEF_URL = "https://raw.github.com/tong/chrome.xep.search/master/";
	static var XEP_BASE_URL = "http://xmpp.org/extensions/xep-";
	static inline var MAX_SUGGESTION_LEN = 10;
	
	static var xeps_description_version : Int;
	static var xeps_description_version_available : Int;
	static var xeps : Array<XEP>;
	
	public var xepStatusFilters(default,null) : Array<Int>;
	
	function new() {
	
		xepStatusFilters = Storage.getObject( "xep_status_filters" );
		if( xepStatusFilters == null ) {
			xepStatusFilters = new Array();
			for( i in 0...Type.getClassFields(XEPStatus).length ) xepStatusFilters.push(i);
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
		trace( "Updating XEP description ..." );
		xeps = new Array();
		var f = haxe.Http.requestUrl( DEF_URL + XEPDescription.FILE );
		for( d in f.split("\n") )
			xeps.push( JSON.parse( d ) );
		for( xep in xeps ) {
			xep.abstract = jabber.util.Base64.decode( xep.abstract );
		}
		LocalStorage.setItem( "xeps_description",JSON.stringify( xeps )  );
		LocalStorage.setItem( "xeps_description_version", xeps_description_version_available );
		trace( ".. complete ("+xeps.length+")" );
		if( cb != null ) cb( null );
	}
	
	#if DEBUG
	public function log( v : Dynamic, ?inf : haxe.PosInfos ) haxe.Log.trace( v, inf )
	#end
	
	function run() {
	
		Omnibox.onInputStarted.addListener(
			function(){ setDefaultSuggestion( "" ); }
		);

		setDefaultSuggestion( "" );
		
		Omnibox.onInputChanged.addListener( function(text,suggest) {
			setDefaultSuggestion( text );
			if( text == null )
	            return;
			var stripped_text = text.trim();
			if( stripped_text == null )
				return;
			if( stripped_text == "" ) {
				setDefaultSuggestion( "" );
				return;
			}
			var term = stripped_text.toLowerCase();
			trace( "Searching for: "+term );
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
					if( found.length >= MAX_SUGGESTION_LEN )
						break;
					if( xep.title != null && xep.title.toLowerCase().indexOf( term ) != -1 ) {
						//trace( "Found XEP by title "+xep.title );
						found.push( xep );
						_xeps.splice( i, 1 );
					}
					i++;
				}
				i = 0;
				for( xep in _xeps ) {
					if( found.length >= MAX_SUGGESTION_LEN )
						break;
					if( xep.name != null && xep.name.toLowerCase().indexOf( term ) != -1 ) {
						//trace( "Found XEP by name "+xep.name );
						found.push( xep );
						_xeps.splice( i, 1 );
					}
				}
			}
			
			// filter by XEP status
			for( xep in found ) {
				var filter = true;
				for( f in xepStatusFilters ) {
					if( f == xep.status ) {
						filter = false;
						break;
					}
				}
				if( filter )
					return;
			}
			
			if( found.length == 0 ) {
				//TODO search something else
				return;
			}
			
			found.sort( function(a,b){ return ( a.number > b.number ) ? 1 : -1; } );
			var suggestions = new Array<SuggestResult>();
			for( xep in found ) suggestions.push( createXEPSuggestResult( xep ) );
			if( !numberMatch &&
				found.length < MAX_SUGGESTION_LEN &&
				stripped_text.length >= 2 ) {
				suggestions.push({
					 content : stripped_text+" [xmpp.org search]",
					 description : [ "Search for \"<match>", stripped_text, "</match>\" at <match><url>xmpp.org</url></match> - <url>http://xmpp.org/search/", StringTools.urlEncode( stripped_text ), "</url>" ].join( '' )
				});
			}
			suggest( suggestions );
		});
		
		Omnibox.onInputEntered.addListener( function(text) {
			/*
			if( text == null ) {
				nav( docpath );
				return;
			}
			*/
			var stripped_text = text.trim();
			if( stripped_text == null ) {
				nav( "http://xmpp.org/xmpp-protocols/xmpp-extensions/" );
				return;
			}
			if( stripped_text.startsWith( "http://" ) || stripped_text.startsWith( "https://" ) ) {
				nav( stripped_text );
				return;
			}
			if( stripped_text.startsWith( "www." ) || stripped_text.endsWith( ".com" ) || stripped_text.endsWith( ".net" ) || stripped_text.endsWith( ".org" ) || stripped_text.endsWith( ".edu" ) ) {
				nav( "http://"+stripped_text );
				return;
        	}
        	
        	var suffix = " [xmpp.org search]";
        	if( stripped_text.endsWith( suffix ) ) {
        		nav( "http://xmpp.org/search/"+formatSearchSuggestionQuery( stripped_text, suffix ) );
				return;
        	}
		});
		
		trace( "XEP search extension active, use it!" );
	}
	
	static function createXEPSuggestResult( xep : XEP ) : SuggestResult {
		var slen = Std.string( xep.number ).length;
		var zeros = "";
		for( i in 0...(4-slen) ) zeros += "0";
		var url = XEP_BASE_URL + zeros + xep.number + ".html";
		var description = "<match>XEP-"+zeros+xep.number+" : "+xep.title+"</match>";
		if( xep.abstract != null || xep.abstract != "null" ) {
			description += " - "+xep.abstract;
		}
		description += "<url>("+url+")</url>";
		return { content : url, description : description };
	}
	
	static function formatSearchSuggestionQuery( t : String, suffix : String ) : String {
		return t.substr( 0, t.length - suffix.length ).trim().urlEncode();
	}
	
	static function nav( url : String ) {
		chrome.Tabs.getSelected( null, function(tab) { chrome.Tabs.update( tab.id, { url: url } ); });
	}
	
	static function setDefaultSuggestion( ?text : String ) {
		var desc = '<url><match>XEP Search</match></url>';
		if( text != null ) desc +=  " "+text;
		Omnibox.setDefaultSuggestion( { description : desc } );
	}
	
	static function init() : IApp {
		#if DEBUG
		if( haxe.Firebug.detect() ) haxe.Firebug.redirectTraces();	
		trace( "XEP-search" );
		#end
		return new App();
	}
	
}
