/*
	
	AUTHOR: aeroson
	NAME: player_markers.sqf
	VERSION: 2.5
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc
	http://forums.bistudio.com/showthread.php?156103-Dynamic-Player-Markers
	
	DESCRIPTION:
	A script to mark players on map
	All markers are created locally
	Designed to be dynamic, small and fast
	Shows driver/pilot, vehicle name and number of passengers
	Click vehicle marker to unfold its passengers list
	Lets BTC mark unconscious players
	Shows Norrin's revive unconscious units
	Shows who is in control of UAV unit
	
	USAGE:
	in (client's) init do:
	0 = [] execVM 'player_markers.sqf'; 

*/
				   
if (isDedicated) exitWith {}; // is server  
if (!isNil{aero_player_markers_pos}) exitWith {}; // already running
				   
private ["_marker","_markerText","_temp","_vehicle","_markerNumber","_show","_injured","_text","_num","_getNextMarker","_getMarkerColor"];

aero_player_markers_pos = [0,0];
onMapSingleClick "aero_player_markers_pos=_pos;";

_getNextMarker = {
	private ["_marker"]; 
	_markerNumber = _markerNumber + 1;
	_marker = format["um%1",_markerNumber];	
	if(getMarkerType _marker == "") then {
		createMarkerLocal [_marker, _this];
	} else {
		_marker setMarkerPosLocal _this;
	};
	_marker;
};

_getMarkerColor = {	
	[(((side _this) call bis_fnc_sideID) call bis_fnc_sideType),true] call bis_fnc_sidecolor;
};

while {true} do {
	  
	waitUntil {
		sleep 0.025;
		true;
	};
	
	_markerNumber = 0; 
	
	// show players or player's vehicles
	{
		_show = false;
		_injured = false;
	
		//if(true) then {
		if(side _x == side player) then {		
			if((crew vehicle _x) select 0 == _x) then {
				_show = true;
			};		
			if(!alive _x || damage _x > 0.9) then {
				_injured = true;
			};	  
			if(!isNil {_x getVariable "hide"}) then {
				_show = false;
			};  
			if(_x getVariable ["BTC_need_revive",-1] == 1) then {
				_injured = true;
				_show = false;
			};		  
			if(_x getVariable ["NORRN_unconscious",false]) then {
				_injured = true;
			};	  
		};
			  	 
		if(_show) then {
			_vehicle = vehicle _x;  				  	
			_pos = getPosATL _vehicle;		  					
			_color = _x call _getMarkerColor;  

			_markerText = _pos call _getNextMarker;						
			_markerText setMarkerColorLocal _color;	 						 				
 			_markerText setMarkerTypeLocal "c_unknown";		  			   
			_markerText setMarkerSizeLocal [0.8,0];

			_marker = _pos call _getNextMarker;			
			_marker setMarkerColorLocal _color;
			_marker setMarkerDirLocal getDir _vehicle;
			_marker setMarkerTypeLocal "mil_triangle";
			_marker setMarkerTextLocal "";			
			if(_vehicle == vehicle player) then {
				_marker setMarkerSizeLocal [0.8,1];
			} else {
				_marker setMarkerSizeLocal [0.5,0.7];
			};
			
 			if(_vehicle != _x && !(_vehicle isKindOf "ParachuteBase")) then {			 						
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
			} else {
				_text = name _x;			
			};
			_markerText setMarkerTextLocal _text;
		};
		
	} forEach playableUnits;


	// show player controlled uavs
	{
		if(isUavConnected _x) then {	
			_operator=(uavControl _x) select 0;
			if(isPlayer _operator && side _operator == playerSide) then {
				_color = _x call _getMarkerColor;								  										  				
				_pos = getPosATL _x;
				
				_marker = _pos call _getNextMarker;			
				_marker setMarkerColorLocal _color;
				_marker setMarkerDirLocal getDir _x;
				_marker setMarkerTypeLocal "mil_triangle";			
				_marker setMarkerTextLocal "";
				if(_operator == player) then {
					_marker setMarkerSizeLocal [0.8,1];
				} else {
					_marker setMarkerSizeLocal [0.5,0.7];
				};
									  		
				_markerText = _pos call _getNextMarker;	
				_markerText setMarkerColorLocal _color;	   
				_markerText setMarkerTypeLocal "c_unknown";
				_markerText setMarkerSizeLocal [0.8,0];
				_markerText setMarkerTextLocal format["%1", name _operator];				  
			};
		};
	} forEach allUnitsUav; 
	
	
	

	_markerNumber = _markerNumber + 1;
	_marker = format["um%1",_markerNumber];	
	while {(getMarkerType _marker) != ""} do {
		deleteMarkerLocal _marker;
		_markerNumber = _markerNumber + 1;
		_marker = format["um%1",_markerNumber];
	};
	 
};
