package chrome.xep;

interface IApp {
	
	var xepStatusFilters : Array<Int>;
	
	function updateXEPsDescription( ?cb : String->Void ) : Void;
	
	//function getXEPStatusfilters
	
	#if DEBUG
	function log( v : Dynamic, ?inf : haxe.PosInfos ) : Void;
	#end
	
}
