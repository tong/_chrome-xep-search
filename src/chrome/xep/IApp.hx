package chrome.xep;

interface IApp {
	
	var xepStatusFilters(default,null) : Array<Int>;
	
	function updateXEPsDescription( ?cb : String->Void ) : Void;
	
	#if DEBUG
	function log( v : Dynamic, ?inf : haxe.PosInfos ) : Void;
	#end
	
}
