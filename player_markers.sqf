/*
	
	AUTHOR: aeroson
	NAME: player_markers.sqf
	VERSION: 2.1
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc/blob/master/player_markers.sqf
	http://forums.bistudio.com/showthread.php?156103-Dynamic-Player-Markers
	
	DESCRIPTION:
	A script to mark players on map.
	All markers are created locally.
	Designed to be dynamic, small and fast.
	Shows driver/pilot, vehicle name and number of passengers
	Click vehicle marker to unfold its passengers list
	Lets BTC mark unconscious players.
	Shows Norrin's revive unconscious units.
	
	USAGE:
	in (client's) init do:
	execvm "player_markers.sqf"; 

*/

if (isDedicated) exitWith {};  
                   
private ["_marker","_markerText","_temp","_vehicle","_unitNumber","_show","_injured","_text","_num"];

aero_player_markers_pos = [0,0];
onMapSingleClick "aero_player_markers_pos=_pos;";

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
			if(!isNil {_x getVariable "hide"}) then {
				_show = false;
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
			_vehicle = vehicle _x;  			      	
			_temp = getPosATL _vehicle;			      		
        	_marker = _temp call _getNextMarker;
			_markerText = _temp call _getNextMarker;
			
			_temp = ["ColorUnknown","ColorOPFOR","ColorBLUFOR","ColorIndependent","ColorCivilian"] select 1+([east,west,independent,civilian] find side _x);
			_marker setMarkerColorLocal _temp;  
			_markerText setMarkerColorLocal _temp;     
        	
			_marker setMarkerDirLocal getDir _vehicle;			 				
 			_markerText setMarkerTypeLocal "c_unknown";
			_markerText setMarkerSizeLocal [0.8,0];
			  

 			if(_vehicle != _x && !(_vehicle isKindOf "ParachuteBase")) then {			 
				switch true do {												  						    
					case (_vehicle isKindOf "car"): { 
						_marker setMarkerTypeLocal "c_car";
					};
					case (_vehicle isKindOf "ship"): {
						_marker setMarkerTypeLocal "c_ship";
					};				 
					case (_vehicle isKindOf "plane"): {
						_marker setMarkerTypeLocal "c_plane";
					}; 
					case (_vehicle isKindOf "air"): {
						_marker setMarkerTypeLocal "c_air";
					};
					case (_vehicle isKindOf "tank"): {
						_marker setMarkerTypeLocal "n_armor";
					};
					case (_vehicle isKindOf "staticweapon"): {
						_marker setMarkerTypeLocal "n_mortar";
					};
					default {
						_marker setMarkerTypeLocal "n_unknown";
					};
				};						
				_text = format["[%1]", getText(configFile>>"CfgVehicles">>typeOf _vehicle>>"DisplayName")];
				if(!isNull driver _vehicle) then {
					_text = format["%1 %2", name driver _vehicle, _text];	
				};	
				
				if((aero_player_markers_pos distance getPosATL _vehicle) < 50) then {
					aero_player_markers_pos = getPosATL _vehicle;
					_num = 0;
					{
						if(alive _x && isPlayer _x && _x != driver _vehicle) then {						
							_text = format["%1%2 %3", _text, if(_num>0)then{","}else{""}, name _x];
							_num = _num + 1;
						};						
					} forEach crew _vehicle; 
				} else { 
					_num = {alive _x && isPlayer _x && _x != driver _vehicle} count crew _vehicle;
					if (_num>0) then {					
						if (isNull driver _vehicle) then {
							_text = format["%1 %2", _text, name (crew _vehicle select 0)];
							_num = _num - 1;
						};
						if (_num>0) then {
							_text = format["%1 +%2", _text, _num];
						};
					};
				};		 	
				
				_marker setMarkerSizeLocal [0.9,0.9];
			} else {
				_text = name _x;
				if(_injured) then {
					_marker setMarkerTypeLocal "mil_destroy";
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
