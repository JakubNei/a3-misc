/*

	AUTHOR: aeroson
	NAME: unit_markers_for_zeus.sqf
	VERSION: 1.1
	CONTRIBUTE: https://github.com/aeroson/a3-misc

	DESCRIPTION:
	Zeuses by default can not see any units on map.
	If player is zeus, this script shows all units markers on map.
	So zeuses can now easily spawn units out of players's view.
	Has standard colors for each side.
	AI units have no name, player units have name.

	USAGE:
	paste into init
	[] execVM 'unit_markers_for_zeus.sqf';

*/
	
if (!hasInterface) exitWith {}; // exit if we have no interface to show markers on

waitUntil {!isNull (findDisplay 46)};

private ["_marker","_markerText","_temp","_unit","_vehicle","_markerNumber","_show","_injured","_text","_num","_getNextMarker","_getMarkerColor","_drawLine","_showAllSides","_showPlayers","_showAIs","_isPlayerZeus","_zeusSeesUnits","_l"];

_showAllSides = true;
_showPlayers = true;
_showAIs = true;

zeus_player_markers_pos = [0,0];
onMapSingleClick "zeus_player_markers_pos=_pos;";

_getNextMarker = {
	private ["_marker"]; 
	_markerNumber = _markerNumber + 1;
	_marker = format["dum%1",_markerNumber];	
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

_isPlayerZeus = {
	if (({getAssignedCuratorUnit _x == player} count allCurators)>0) exitWith { true; };
	false;
};


_shouldCleanUpMarkers = false;


while {true} do {

	sleep 5;

	if([] call _isPlayerZeus) then {
		  
		_shouldCleanUpMarkers = true;

		waitUntil {
			sleep 0.025;
			true;
		};
		
		_markerNumber = 0; 
		
		// show players or player's vehicles
		{
			_show = false;
			_injured = false;
			_unit = _x;
			
			if(
				(
					(_showAIs && {!isPlayer _unit} && {0=={ {_x==_unit} count crew _x>0} count allUnitsUav}) ||
					(_showPlayers && {isPlayer _unit})
				) && {
					_showAllSides || side _unit==side player
				}
			) then {	
				if((crew vehicle _unit) select 0 == _unit) then {
					_show = true;
				};		
				if(!alive _unit || damage _unit > 0.9) then {
					_injured = true;
				};	  
				if(!isNil {_unit getVariable "hide"}) then {
					_show = false;
				};  
				if(_unit getVariable ["BTC_need_revive",-1] == 1) then {
					_injured = true;
					_show = false;
				};		  
				if(_unit getVariable ["NORRN_unconscious",false]) then {
					_injured = true;
				};	  			
			};
				  	 
			if(_show) then {
				_vehicle = vehicle _unit;  				  	
				_pos = getPosATL _vehicle;		  					
				_color = _unit call _getMarkerColor;  

				_marker = _pos call _getNextMarker;
				_marker setMarkerShapeLocal "ICON";	
				_marker setMarkerColorLocal _color;
				_marker setMarkerDirLocal getDir _vehicle;
				_marker setMarkerTypeLocal "mil_triangle";
				_marker setMarkerTextLocal "";			
				if(_vehicle == vehicle player) then {
					_marker setMarkerSizeLocal [0.8,1];
				} else {
					_marker setMarkerSizeLocal [0.5,0.7];
				};
				
				_text = "";
	 			if(_vehicle != _unit && !(_vehicle isKindOf "ParachuteBase")) then {			 						
					_text = format["[%1]", getText(configFile>>"CfgVehicles">>typeOf _vehicle>>"DisplayName")];
					if(!isNull(driver _vehicle) && isPlayer(driver _vehicle)) then {
						_text = format["%1 %2", name driver _vehicle, _text];	
					};							 						
					
					if((zeus_player_markers_pos distance getPosATL _vehicle) < 50) then {
						zeus_player_markers_pos = getPosATL _vehicle;
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
							if (isNull(driver _vehicle) && isPlayer(driver _vehicle)) then {
								_text = format["%1 %2", _text, name (crew _vehicle select 0)];
								_num = _num - 1;
							};
							if (_num>0) then {
								_text = format["%1 +%2", _text, _num];
							};
						};
					};	 					
				} else {
					if(isPlayer _unit) then {
						_text = name _unit;
					};		
				};

				if(_text != "") then {
					_markerText = _pos call _getNextMarker;
					_markerText setMarkerShapeLocal "ICON";
					_markerText setMarkerColorLocal _color;	 						 				
		 			_markerText setMarkerTypeLocal "c_unknown";		  			   
					_markerText setMarkerSizeLocal [0.8,0];
					_markerText setMarkerTextLocal _text;
				};
			};
			
		} forEach allUnits;


		// show player controlled uavs
		{
			if(isUavConnected _x) then {	
				_unit=(uavControl _x) select 0;
				if(
					(				
						(_showAIs && {!isPlayer _unit}) || 
						(_showPlayers && {isPlayer _unit})
					) && {
						_showAllSides || side _unit==side player
					}
				) then {
					_color = _x call _getMarkerColor;								  										  				
					_pos = getPosATL _x;
					
					_marker = _pos call _getNextMarker;			
					_marker setMarkerColorLocal _color;
					_marker setMarkerDirLocal getDir _x;
					_marker setMarkerTypeLocal "mil_triangle";			
					_marker setMarkerTextLocal "";
					if(_unit == player) then {
						_marker setMarkerSizeLocal [0.8,1];
					} else {
						_marker setMarkerSizeLocal [0.5,0.7];
					};
										  		
					_markerText = _pos call _getNextMarker;	
					_markerText setMarkerColorLocal _color;	   
					_markerText setMarkerTypeLocal "c_unknown";
					_markerText setMarkerSizeLocal [0.8,0];
					_markerText setMarkerTextLocal format["%1 [%2]", name _unit, getText(configFile>>"CfgVehicles">>typeOf _x>>"DisplayName")];	
				};
			};
		} forEach allUnitsUav; 		
		

		_markerNumber = _markerNumber + 1;
		_marker = format["dum%1",_markerNumber];	
		while {(getMarkerType _marker) != ""} do {
			deleteMarkerLocal _marker;
			_markerNumber = _markerNumber + 1;
			_marker = format["dum%1",_markerNumber];
		};


	} else {

		if(_shouldCleanUpMarkers) then {
			_shouldCleanUpMarkers = false;

			_markerNumber = 1;
			_marker = format["dum%1",_markerNumber];	
			while {(getMarkerType _marker) != ""} do {
				deleteMarkerLocal _marker;
				_markerNumber = _markerNumber + 1;
				_marker = format["dum%1",_markerNumber];
			};

		};

	};
	 
};
