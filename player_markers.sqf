/*
	
	AUTHOR: aeroson
	NAME: player_markers.sqf
	VERSION: 1.5
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc/player_markers.sqf
	http://forums.bistudio.com/showthread.php?148577-GET-SET-Loadout-(saves-and-loads-pretty-much-everything)
	
	DESCRIPTION:
	a script to locally mark players on map without polluting global variable namespace
	all markers are created locally, instead of standart way where markers have to be send over net
	which allows for very fast and smooth refresh rate
	it doees also remove all unused markers, instead of leaving them at [0,0]
	lets BTC mark unconscious players, shows Norrin's revive unconscious units

*/

if (isDedicated) exitWith {};  
                   
private ["_marker","_unitNumber","_show","_injured","_text"];

 
while {true} do {
	  
	waitUntil {
		sleep 0.05;
		true;
	};
	
	_unitNumber = 0; 
	{
		_show = false;
		_injured = false;
	
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
			_unitNumber = _unitNumber + 1;
			_marker = format["um%1",_unitNumber];    
			if(getMarkerType _marker == "") then {
				createMarkerLocal [_marker, getPos vehicle _x];
			} else {
				_marker setMarkerPosLocal getPosATL vehicle _x;
			};      
			_marker setMarkerDirLocal getDir vehicle _x;
 
 			_text = name _x; 
 			if(vehicle _x != _x) then { 			
 			    _marker setMarkerColorLocal "ColorBlue"; 			    
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
				if(count crew vehicle _x > 1) then {
					{
						if(alive _x && _x != driver vehicle _x) then {
							_text = format["%1, %2", _text, name _x];
						};						
					} forEach crew vehicle _x;
					/*for "_i" from 1 to (count crew vehicle _x)-1 do {					
						if(alive (crew vehicle _x select _i)) then {
							_text = format["%1, %2", _text, name(crew vehicle _x select _i)];
						};
					};*/ 
				};
			} else {
				if(_injured) then {
					_marker setMarkerColorLocal "ColorRed";
					_marker setMarkerTypeLocal "dot";
				} else {
				 	_marker setMarkerColorLocal "ColorBlue";
					if(leader group _x == _x) then {
						_marker setMarkerTypeLocal "mil_arrow2";
					} else {				
						_marker setMarkerTypeLocal "mil_triangle";
					};
				};				
			};
			if(vehicle _x == vehicle player) then {
				_marker setMarkerSizeLocal [0.6,0.6];
			} else {
				_marker setMarkerSizeLocal [0.3,0.3];
			};
			_marker setMarkerTextLocal _text;
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
