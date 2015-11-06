/*

	AUTHOR: aeroson
	NAME: mouse_wheel_view_distance_settings.sqf
	VERSION: 1.0

	DESCRIPTION:
	Based on Mouse Wheel View Distance for Arma 2 (DVD) by TPW http://www.armaholic.com/page.php?id=13437
	Ctrl+Alt+Mousewheel changes view distance
	Ctrl+Alt+Shift+Mousewheel changes grass density
	Settings are saved into profileNamespace and loaded everytime you enter a game
	Has different contexts: on foot, in land vehicle, in air vehicle (idea from Tonic's view distance settings)
	Anyone can set mouse_wheel_view_distance_settings_disable = true; to disable and stop this script

	USAGE:
	paste into init.sqf
	[] execVM 'mouse_wheel_view_distance_settings.sqf';

*/

#define COMPONENT mouse_wheel_view_distance_settings

#define GVAR(A) COMPONENT##_##A
#define QUOTE(A) #A
#define QGVAR(A) QUOTE(GVAR(A))
#define DEBUG(A) systemChat format[QUOTE(%1|%2(%3:%4)=%5),time,QUOTE(COMPONENT),__FILE__,__LINE__,A];
#define DEBUGQ(A) DEBUG(QUOTE(A))
#define CONCAT(A,B) A####B


if (isDedicated) exitWith { };

if(!isNil{GVAR(alradyRuns)}) exitWith { };
GVAR(alradyRuns) = true;

waitUntil {!isNull(findDisplay 46)};
waitUntil {!isNull player};

// systemChat QUOTE(COMPONENT\init.sqf);

GVAR(viewDistance_min) = 200;
GVAR(viewDistance_max) = 15000;

GVAR(terrainGrid_names) = ["No Grass", "Little Grass", "Medium Grass", "Full Grass"];
GVAR(terrainGrid_values) = [50, 30, 12.5, 3.125];

GVAR(terrainGrid_index) = round(count(GVAR(terrainGrid_values))/2); 
GVAR(state) = 0;
GVAR(hintIsShown) = false;

GVAR(config) = profileNamespace getVariable QUOTE(COMPONENT);
GVAR(version) = 1; // increment this in case config format changes



if(isNil{GVAR(config)} || {!((typeName GVAR(config)) == "ARRAY")} || {!((count GVAR(config))>0)} || {!((GVAR(config) select 0) isEqualTo GVAR(version))} ) then {
	systemChat "Ctrl+Alt+Mousewheel changes view distance";
	systemChat "Ctrl+Alt+Shift+Mousewheel changes grass density";
	GVAR(config) = [
		GVAR(version),
		[viewDistance, 0],
		[viewDistance, 0],
		[viewDistance, 0]
	];
} else {
	[] spawn {
		sleep 10;
		call GVAR(setViewDistanceAndTerrainGridFromConfig);
	};
}; 


GVAR(setViewDistanceAndTerrainGridFromConfig) = {
	setViewDistance (call GVAR(getViewDistance));
	setTerrainGrid (GVAR(terrainGrid_values) select (call GVAR(getTerrainGrid)));
};

GVAR(getContextIndex) = {
	if((vehicle player) isKindOf "Man") exitWith { 1; };
	if((vehicle player) isKindOf "LandVehicle") exitWith { 2; };
	if((vehicle player) isKindOf "Air") exitWith { 3; };
};


GVAR(getContextName) = {
	["", "Infantry", "Land vehicle", "Air vehicle"] select (call GVAR(getContextIndex));
};



GVAR(getViewDistance) = {
	(GVAR(config) select (call GVAR(getContextIndex))) select 0;
};
GVAR(getViewDistance_increase) = {
	200;	
};
GVAR(getViewDistance_decrease) = {
	200;
};

GVAR(setViewDistance) = {
	params [
		"_newViewDistance"
	];
	if (_newViewDistance > GVAR(viewDistance_max)) then {
		_newViewDistance = GVAR(viewDistance_max);
	};
	if (_newViewDistance < GVAR(viewDistance_min)) then {
		_newViewDistance = GVAR(viewDistance_min);
	};
	setViewDistance _newViewDistance; 
	hintsilent format ["%1",_newViewDistance]; 
	(GVAR(config) select (call GVAR(getContextIndex))) set [0, _newViewDistance];
	GVAR(hintIsShown) = true;
};


GVAR(getTerrainGrid) = {
	(GVAR(config) select (call GVAR(getContextIndex))) select 1;
};
GVAR(setTerrainGrid) = {
	params [
		"_newTerrainGridIndex"
	];
	if (_newTerrainGridIndex < 0) then {
		_newTerrainGridIndex = 0;
	};
	if (_newTerrainGridIndex > count(GVAR(terrainGrid_values))-1) then {
		_newTerrainGridIndex = count(GVAR(terrainGrid_values))-1;
	};																			
	(GVAR(config) select (call GVAR(getContextIndex))) set [1, _newTerrainGridIndex];						 
	setTerrainGrid (GVAR(terrainGrid_values) select _newTerrainGridIndex);
	hintsilent format ["%1", GVAR(terrainGrid_names) select _newTerrainGridIndex];
	GVAR(hintIsShown) = true;
};


[] spawn {
	private ["_lastContextIndex"];
	while {true} do {
		_lastContextIndex = call GVAR(getContextIndex);
		waituntil {GVAR(hintIsShown) || _lastContextIndex != (call GVAR(getContextIndex))};
		if(! ( !isNil{GVAR(disable)} && {GVAR(disable)} )  ) then { // skip context change response if disabled
			if(_lastContextIndex != (call GVAR(getContextIndex))) then {					
				// hintsilent format["%1\n%2\n%3", call GVAR(getContextName), call GVAR(getViewDistance), GVAR(terrainGrid_names) select (call GVAR(getTerrainGrid))];
				// GVAR(hintIsShown) = true;
				call GVAR(setViewDistanceAndTerrainGridFromConfig);
			};
		};

		if(GVAR(hintIsShown)) then { 
			GVAR(hintIsShown) = false;
			sleep 1; 
			if(!GVAR(hintIsShown)) then { 
				hintsilent "";
				profileNamespace setVariable [QUOTE(COMPONENT), GVAR(config)];
			};
		};
	};
};


(findDisplay 46) displayAddEventHandler ["KeyDown", QUOTE(_this call GVAR(KeyDown))];
GVAR(KeyDown) = {
	private["_shift","_ctrl","_alt"];
	
	_shift = _this select 2;
	_ctrl = _this select 3;
	_alt = _this select 4;
	
	if (_ctrl && _alt) then { 
		GVAR(state) = 1;
	} else { 
		GVAR(state) = 0;
	}; 
	
	if (GVAR(state) == 1 && _shift) then {
		 GVAR(state) = 2;
	};
	
	false;
};


(findDisplay 46) displayAddEventHandler ["KeyUp", QUOTE(_this call GVAR(KeyUp))];
GVAR(KeyUp) = {
	GVAR(state) = 0;
	false;
};


(findDisplay 46) displayAddEventHandler ["MouseZChanged", QUOTE(_this call GVAR(MouseZChanged))];
GVAR(MouseZChanged) = {

	if(!isNil{GVAR(disable)} && {GVAR(disable)}) exitWith {
		false;
	};

	private["_state"];
	_state = _this select 1;

	// view distance
	if (GVAR(state) == 1) then {
		if (_state > 0) then {
			[ (call GVAR(getViewDistance)) + (call GVAR(getViewDistance_increase)) ] call GVAR(setViewDistance);
		};
		if (_state < 0) then {
			[ (call GVAR(getViewDistance)) - (call GVAR(getViewDistance_decrease)) ] call GVAR(setViewDistance);			
		}; 
		call GVAR(disable_tawvd);
	};
	
	// terrain grid
	if (GVAR(state) == 2) then {	
		if (_state > 0) then {
			[ (call GVAR(getTerrainGrid)) + 1 ] call GVAR(setTerrainGrid);
		};
		if (_state < 0) then {
			[ (call GVAR(getTerrainGrid)) - 1 ] call GVAR(setTerrainGrid);
		}; 
		call GVAR(disable_tawvd);
	}; 
	
	false;		
};

GVAR(disable_tawvd) = {
	tawvd_disable = true;
};
