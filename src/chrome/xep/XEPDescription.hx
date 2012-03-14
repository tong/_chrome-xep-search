package chrome.xep;

#if PREPARE
import neko.FileSystem;
import neko.io.File;
using StringTools;
#end

/**
 */
class XEPDescription {
	
	public static inline var FILE = "xep_description";
	public static inline var MAX_ABSTRACT_LEN = 256;
	
	public static function getXEPStatus( s : String )  : Int {
		return switch( s ) {
		case "active" : XEPStatus.ACTIVE;
		case "deferred" : XEPStatus.DEFERRED;
		case "deprecated" : XEPStatus.DEPRECATED;
		case "draft" : XEPStatus.DRAFT;
		case "experimental" : XEPStatus.EXPERIMENTAL;
		case "final" : XEPStatus.FINAL;
		case "obsolete" : XEPStatus.OBSOLETE;
		case "proposed" : XEPStatus.PROPOSED;
		case "rejected" : XEPStatus.REJECTED;
		case "retracted" : XEPStatus.RETRACTED;
		}
	}
	
	#if !PREPARE
	public static function getXEPStatusString( i : Int )  : String {
		return switch( i ) {
		case XEPStatus.ACTIVE : "active";
		case XEPStatus.DEFERRED : "deferred";
		case XEPStatus.DEPRECATED : "deprecated";
		case XEPStatus.DRAFT : "draft";
		case XEPStatus.EXPERIMENTAL : "experimental";
		case XEPStatus.FINAL : "final";
		case XEPStatus.OBSOLETE : "obsolete";
		case XEPStatus.PROPOSED : "proposed";
		case XEPStatus.REJECTED : "rejected";
		case XEPStatus.RETRACTED : "retracted";
		}
	}
	#end
	
	
	#if PREPARE
	
	static function build() {
		
		log( "Building XEP description list ..." );
		
		var srcdir = "data/xeps";
		
		if( !FileSystem.exists( srcdir ) ) {
			log( "Directory with XEP list does not exist!" );
			log( "Run the data/update_xep_list bash script first" );
			return;
		}
		
		var r_title = ~/<title>(.+)<\/title>/;
		var r_name = ~/<shortname>(.+)<\/shortname>/;
		var r_number = ~/<number>([0-9]+)<\/number>/;
		var r_abstract = ~/<abstract>(.+)<\/abstract>/;
		//TODO
		//shortname
		var r_status = ~/<status>([a-zA-Z]+)<\/status>/; //status
		//version
		//initials
		//type
		////date
		////depends
			
		var xeps = new Array<XEP>();
		
		for( f in FileSystem.readDirectory( srcdir ) ) {
		
			var t = File.getContent( srcdir+"/"+f );
			
			if( !r_number.match( t ) ) {
				log( "Failed to read XEP, number is missing => "+f );
				continue;
			}
			
			var title : String = null;
			var name : String = null;
			var abstract : String = null;
			
			if( !r_title.match( t ) ) {
//				trace( "Ignorig XEP, no title = "+f );
//				continue;
			}
			title = r_title.matched(1);
			
			if( !r_name.match( t ) ) {
//				trace( "Ignorig XEP, no name = "+f+" ("+title+")" );
//				continue;
			}
			
			r_status.match( t );
			var status = r_status.matched(1).toLowerCase();
			
			if( r_abstract.match( t ) ) {
				abstract = r_abstract.matched(1);
				if( abstract.length > MAX_ABSTRACT_LEN ) abstract = abstract.substr( 0, MAX_ABSTRACT_LEN );
				abstract = jabber.util.Base64.encode( abstract );
			}
			
			var name = r_name.matched(1);
			if( name == "TO BE ASSIGNED" || name == "NOT_YET_ASSIGNED" ) {
				name  = null;
			} else {
				var r = ~/(\\20)/;
				if( r.match(  name ) ) {
					name = r.replace( name, " " );
				}
			}
			
			xeps.push( {
				number : Std.parseInt( r_number.matched(1) ),
				title : title,
				name : name,
				status : getXEPStatus( status ), //Type.createEnum( XEPStatus, status ),
				abstract : abstract
			} );
		}
		
		xeps.sort( function(a,b){ return ( a.number > b.number ) ? 1 : -1; } );
		
		var fo = File.write( FILE );
		for( i in 0...xeps.length ) {
			var xep = xeps[i];
			//fo.writeString( '{ "number":"'+xep.number+'","title":"'+xep.title+'","name":"'+xep.name+'","status":"'+Type.enumConstructor(xep.status)+'","abstract":"'+xep.abstract+'"}' );
			fo.writeString( '{ "number":"'+xep.number+'","title":"'+xep.title+'","name":"'+xep.name+'","status":"'+xep.status+'","abstract":"'+xep.abstract+'"}' );
			if( i != xeps.length-1 ) fo.writeString( '\n' );
		}
		fo.flush();
		fo.close();
		
		log( "Done" );
		log( "File is available at chrome.xep.search/"+FILE );
		log( "Make sure to update the description version number in chrome.xep.search/xeps_description_version if required" );
	}
	
	static function clean() {
		//TODO
	}
	
	static function deleteFile( f : String ) {
		//TODO
	}
	
	static inline function log( t : String ) neko.Lib.println(t) 
	
	#end
	
}
