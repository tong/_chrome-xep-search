package chrome.xep;

using StringTools;

class Options {
	
	static var app : chrome.xep.IApp;
	
	static function init() {
	
		app = chrome.Extension.getBackgroundPage().instance;
		
		#if DEBUG
		haxe.Log.trace = mytrace;
		trace( "chrome.xep.options" );
		#end
		
		var root = {
			name : "XEP-search", icon : "icon/icon_32.png", search : false,
			tabs : [
				{
					id : "settings",
					label : "Settings",
					groups : [
						{
							id : "xep_description",
							label : "XEP description",
							content : [
								{ id : "reload_xep_description", type : "button", btn_label : "Reload" }
							]
						},
						{
							id : "xep_filter",
							label : "XEP status filter",
							content : [
								{ id : "xep_filter_description", type : "description", content : "Uncheck XEP status to avoid listing in suggestions." },
								{ id : "xep_filter_active", type : "checkbox", label : "Active" },
								{ id : "xep_filter_deferred", type : "checkbox", label : "Deferred" },
								{ id : "xep_filter_deprecated", type : "checkbox", label : "Deprecated" },
								{ id : "xep_filter_draft", type : "checkbox", label : "Draft" },
								{ id : "xep_filter_experimental", type : "checkbox", label : "Experimental" },
								{ id : "xep_filter_final", type : "checkbox", label : "Final" },
								{ id : "xep_filter_obsolete", type : "checkbox", label : "Obsolete" },
								{ id : "xep_filter_proposed", type : "checkbox", label : "Proposed" },
								{ id : "xep_filter_rejected", type : "checkbox", label : "Rejected" },
								{ id : "xep_filter_retracted", type : "checkbox", label : "Retracted" }
							]
						},
						{
							id : "source",
							label : "Source code",
							content : [
								{ id : "source", type : "description", content : "<p>XEP-search for chrome is open source, written in <a href='http://haxe.org' title='http://haxe.org' target='_blank'>haXe</a> and licensed under <a href='http://www.gnu.org/licenses/gpl-3.0.txt' target='_blank'>GPL 3.0</a>.<br>
You can grab the source code from <a href='https://github.com/tong/chrome.xep.search' title='https://github.com/tong/chrome.xep.search' target='_blank'>github</a>.</p>" }
							]
						},
						{
							id : "author",
							content : [
								{ id : "author", type : "description", content : "<p>XEP-search is created by <a href='http://disktree.net' title='http://disktree.net' target='_blank'>disktree.net</a>.<br>
Drop us a <a href='mailto:sdk@disktree.net'>mail</a> for improvement suggestions or anything else on your mind.</p>" }
							]
						}
					]
				}
			]
		}
		chrome.ui.Options.onGroupsChange = function(ids:Array<String>) {
			for( id in ids ) {
				switch( id ) {
				case "xep_filter" :
					for( i in app.xepStatusFilters ) {
						j( "#checkbox_xep_filter_"+XEPDescription.getXEPStatusString(i) ).attr( 'checked', 'true' );
					}
				}
			}
		}
		chrome.ui.Options.onUserInteraction = function(id:String,?params:Dynamic){
			switch( id ) {
			case 'reload_xep_description' :
				trace("RELOAD XEP DESCRIPTION");
				j( '#reload_xep_description' ).fadeOut(100);
				haxe.Timer.delay( function(){
				app.updateXEPsDescription( function(err){
					/*
					if( err != null ) {
						//showInfo( 'Failed to reload the XEP description ('+XEPDescription.FILE+')', true );
					} else {
						//showInfo( 'XEP description reload complete' );
					}
					j_reload.fadeIn(200);
					*/
					j( '#reload_xep_description' ).fadeIn(100);
				});
			}, 1 );
			
			default :
				if( id.startsWith( 'checkbox_xep_filter' ) ) {
					trace(id+":"+params);
					var _id = id.substr( 20 );
					//trace( _id );
					var i = XEPDescription.getXEPStatus( _id );
					if( params ) {
						app.xepStatusFilters.push( i );
					} else {
						app.xepStatusFilters.remove( i );
					}
					Storage.setObject( 'xep_status_filters', app.xepStatusFilters );
				}
			}
		}
		chrome.ui.Options.init( root );
	}
	
	/*
	static function showInfo( text : String, error : Bool = false, time : Int = 2000 ) {
		var color = error ? "#ff0000" : "#ccc";
		j( '#info' ).hide().html( text ).css( "backgroundColor", color ).slideDown(200).delay( time ).slideUp(200);
	}
	*/
	
	static inline function j( id : Dynamic ) : js.JQuery { return new js.JQuery( id ); }
	
	#if DEBUG
	static inline function mytrace( v : Dynamic, ?inf : haxe.PosInfos ) { app.log( v, inf ); }
    #end
	
}
