package chrome.xep;

class Options {
	
	static var app : chrome.xep.IApp;
	
	static function init() {
	
		app = chrome.Extension.getBackgroundPage().instance;
		
		#if DEBUG
		haxe.Log.trace = mytrace;
		trace( "chrome.xep.options" );
		#end
		
		j( '#info' ).hide();
		
		var j_reload = j( '#btn_loadapi' );
		j_reload.click(function(e) {
			j_reload.fadeOut(100);
			haxe.Timer.delay( function(){
				app.updateXEPsDescription( function(err){
					if( err != null ) {
						showInfo( 'Failed to reload the XEP description ('+XEPDescription.FILE+')', true );
					} else {
						showInfo( 'XEP description reload complete' );
					}
					j_reload.fadeIn(200);
				});
			}, 1 );
		});
		
		for( f in app.xepStatusFilters )
			j( '#statusfilter_'+XEPDescription.getXEPStatusString(f) ).attr( 'checked', 'true' );
		for( f in Type.getClassFields( XEPStatus ) ) {
			var i = XEPDescription.getXEPStatus(f.toLowerCase());
			var e = j( '#statusfilter_'+f.toLowerCase() );
			e.change( function(_){
				if( e.is(':checked') ) {
					app.xepStatusFilters.push( i );
				} else {
					app.xepStatusFilters.remove( i );
					if( app.xepStatusFilters.length == 0 ) {
						showInfo( "Sure?! You just deactived every XEP! No suggestions will get listed!", true, 4000 );
					}
				}
				Storage.setObject( "xep_status_filters", app.xepStatusFilters );
			});
		}
		
		/*
		for( f in app.xepStatusFilters ) {
			j( '#statusfilter_'+Type.enumConstructor(f) ).attr( 'checked', "true" );
		}
		for( f in Type.getEnumConstructs( XEPStatus ) ) {
			var e = j( '#statusfilter_'+f );
			e.change( function(_){
				var status = Type.createEnum( XEPStatus, f );
				if( e.is(':checked') ) {
					if( !xepStatusFilterActive( status ) ) {
						app.xepStatusFilters.push( status );
						Storage.setObject( "xep_status_filters", app.xepStatusFilters );
					}
				} else {
					if( xepStatusFilterActive( status ) ) {
						app.xepStatusFilters.remove( status );
						Storage.setObject( "xep_status_filters", app.xepStatusFilters );
					}
				}
				for( f in app.xepStatusFilters ) trace(f);
			});
		}
		*/
	}
	
	/*
	static function xepStatusFilterActive( s : XEPStatus ) : Bool {
		for( f in app.xepStatusFilters ) {
			if( Type.enumIndex(f ) == Type.enumIndex(s) )
				return true;
		}
		return false;
	} 
	*/
	
	/* 
	static function updateXEPStatusFilterSetting( s : String ) {
		var f = 'use'+field+'Search'; 
		var e = j( '#'+field.toLowerCase()+'search' );
		e.attr( 'checked', ( Reflect.field( app, f ) ) ? "true" : null );
		e.change(function(ev){
			Reflect.setField( app, f, e.is( ':checked' ) );
			Settings.save( app );
		});
	}
	*/
	
	static function showInfo( text : String, error : Bool = false, time : Int = 2000 ) {
		var color = error ? "#ff0000" : "#ccc";
		j( '#info' ).hide().html( text ).css( "backgroundColor", color ).slideDown(200).delay( time ).slideUp(200);
	}
	
	static inline function j( id : Dynamic ) : js.JQuery { return new js.JQuery( id ); }
	
	#if DEBUG
	static inline function mytrace( v : Dynamic, ?inf : haxe.PosInfos ) { app.log( v, inf ); }
    #end
	
}
