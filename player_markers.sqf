/*
	
	AUTHOR: aeroson
	NAME: player_markers.sqf
	VERSION: 1.7
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc/blob/master/player_markers.sqf
	http://forums.bistudio.com/showthread.php?148577-GET-SET-Loadout-(saves-and-loads-pretty-much-everything)
	
	DESCRIPTION:
	a script to mark players on map
	all markers are created locally
	designed to be small and fast
	lets BTC mark unconscious players
	shows Norrin's revive unconscious units
	
	USAGE:
	in (client's) init do:
	execvm "player_markers.sqf"; 

*/

if (isDedicated) exitWith {};  
                   
private ["_marker","_markerText","_temp","_unitNumber","_show","_injured","_text","_index"];

_getNextMarker = {
	private ["_marker"]; 
	_unitNumber = _unitNumber + 1;
	_marker = format["um%1",_unitNumber];    
	if(getMarkerType _marker == "") then {
		createMarkerLocal [_marker, _this];
	} else {
		_marker setMarkerPosLocal _this;
	};
	_marker;
};

while {true} do {
	  
	waitUntil {
		sleep 0.025;
		true;
	};
	
	_unitNumber = 0; 
	{
		_show = false;
		_injured = false;
	
		//if(true) then {
		if(side _x == playerSide) then {		
			if((crew vehicle _x) select 0 == _x) then {
				_show = true;
			};	    
			if(!alive _x || damage _x > 0.9) then {
				_injured = true;
			};      
			if(!isNil {_x getVariable "BTC_need_revive"}) then {
				if(typeName(_x getVariable "BTC_need_revive")=="SCALAR") then {
					if((_x getVariable "BTC_need_revive") == 1) then {
						_show = false;
					};    
				};
			};      
			if(!isNil {_x getVariable "NORRN_unconscious"}) then {
				if(typeName(_x getVariable "NORRN_unconscious")=="BOOL") then {
					if(_x getVariable "NORRN_unconscious" == true) then {
						_injured = true;
					};
				};
			};      
		};
              	 
		if(_show) then {
						      	
			_temp = getPosATL vehicle _x;			      		
        	_marker = _temp call _getNextMarker;
			_markerText = _temp call _getNextMarker;
			
			_temp = ["ColorUnknown","ColorOPFOR","ColorBLUFOR","ColorIndependent","ColorCivilian"] select 1+([east,west,independent,civilian] find side _x);
			_marker setMarkerColorLocal _temp;  
			_markerText setMarkerColorLocal _temp;     
        	
			_marker setMarkerDirLocal getDir vehicle _x;			 				
 			_markerText setMarkerTypeLocal "c_unknown";
			_markerText setMarkerSizeLocal [0.8,0];
			  
 			_text = name _x; 
 			if(vehicle _x != _x) then { 						    
				if(vehicle _x isKindOf "car") then { 
					_marker setMarkerTypeLocal "c_car";
				} else {
					if(vehicle _x isKindOf "ship") then {
						_marker setMarkerTypeLocal "c_ship";
					} else {
						if(vehicle _x isKindOf "air") then {
							if(vehicle _x isKindOf "plane") then {						
								_marker setMarkerTypeLocal "c_plane";
							} else {
								_marker setMarkerTypeLocal "c_air";
							};
						} else {
							_marker setMarkerTypeLocal "c_unknown";
						};
					};
				};							
				_text = format["[%1]", getText(configFile>>"CfgVehicles">>typeOf vehicle _x>>"DisplayName")]; 
				if(!isNull driver vehicle _x) then {
					_text = format["%1 %2", name driver vehicle _x, _text];	
				};			 	
				_index = 0;
				{
					if(alive _x && isPlayer _x && _x != driver vehicle _x) then {						
						_text = format["%1%2 %3", _text, if(_index>0)then{","}else{""}, name _x];
						_index = _index + 1;
					};						
				} forEach crew vehicle _x;
				_marker setMarkerSizeLocal [0.9,0.9];
			} else {
				if(_injured) then {
					_marker setMarkerTypeLocal "waypoint";
				} else {
					if(leader group _x == _x) then {
						_marker setMarkerTypeLocal "mil_arrow2";
					} else {				
						_marker setMarkerTypeLocal "mil_arrow";
					};
				};

				_marker setMarkerSizeLocal [0.5,0.5];				
			};
			_markerText setMarkerTextLocal _text;
		};
		
	} forEach playableUnits;

	_unitNumber = _unitNumber + 1;
	_marker = format["um%1",_unitNumber];
    
	while {(getMarkerType _marker) != ""} do {
		deleteMarkerLocal _marker;
		_unitNumber = _unitNumber + 1;
		_marker = format["um%1",_unitNumber];
	};
     
};
