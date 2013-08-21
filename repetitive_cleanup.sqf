/*
	
	AUTHOR: aeroson
	NAME: repetitive_cleanup.sqf
	VERSION: 1.3
	
	DESCRIPTION:
	can delete everything that is not really needed 
	dead bodies, dropped items, smokes, chemlights, explosives, empty groups
	
	USAGE:
	in server's init
	[
		60, // seconds to delete dead bodies (0 means don't delete) 
		5*60, // seconds to delete dead vehicles (0 means don't delete)
		2*60, // seconds to delete dropped weapons (0 means don't delete)
		10*60, // seconds to deleted planted explosives (0 means don't delete)
		0 // seconds to delete dropped smokes/chemlights (0 means don't delete)
	] execVM 'repetitive_cleanup.sqf';
	
	will delete dead bodies after 60 seconds (1 minute)
	will delete dead vehicles after 5*60 seconds (5 minutes)
	will delete weapons after 2*60 seconds (2 minutes)
	will delete planted explosives after 10*60 seconds (10 minutes)
	will not delete any smokes/chemlights since its disabled (set to 0)
		
*/

if (!isServer) exitWith {};         

#define PARAM_START private ["_PARAM_INDEX"]; _PARAM_INDEX=0;
#define PARAM_REQ(A) if (count _this <= _PARAM_INDEX) exitWith { systemChat format["required param '%1' not supplied in file:'%2' at line:%3", #A ,__FILE__,__LINE__]; }; A = _this select _PARAM_INDEX; _PARAM_INDEX=_PARAM_INDEX+1;
#define PARAM(A,B) A = B; if (count _this > _PARAM_INDEX) then { A = _this select _PARAM_INDEX; }; _PARAM_INDEX=_PARAM_INDEX+1;

private ["_centerPos","_ttwBodies","_ttwVehicles","_ttwWeapons","_ttwPlanted","_ttwSmokes"];

PARAM_START
PARAM(_ttwBodies,0)
PARAM(_ttwVehicles,0)
PARAM(_ttwWeapons,0)
PARAM(_ttwPlanted,0)
PARAM(_ttwSmokes,0)

if (_ttwWeapons<=0 && _ttwPlanted<=0 && _ttwSmokes<=0 && _ttwBodies<=0 && _ttwVehicles<=0) exitWith {};


_centerPos = getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition");


_delete = {
	_obj = _this select 0;
	_time = _this select 1;
	if(isNil {_obj getVariable "time"}) then {
		_x setVariable ["time", time + _time ];
	} else {
		if( _obj getVariable "time" < time ) then {
			deleteVehicle _obj; 	
		};				
	};     
};


while{true} do {

	sleep 10;
    	
	if (_ttwBodies>0) then {
		{
			if(!isPlayer _x) then { 	 
				[_x, _ttwBodies] call _delete;
			}; 
		} forEach allDeadMen;
	};	
	
	if (_ttwVehicles>0) then {		
		{
			if(!isPlayer _x) then { 	 
				[_x, _ttwVehicles] call _delete;
			}; 
		} forEach (allDead - allDeadMen);
	};

	if (_ttwWeapons>0) then {
		{
			{ 	 
				[_x, _ttwWeapons] call _delete;			
			} forEach (_centerPos nearObjects [_x, 25000]);
		} forEach ["WeaponHolder","GroundWeaponHolder","WeaponHolderSimulated"];
	};
	
	if (_ttwPlanted>0) then {
		{
			{ 
				[_x, _ttwPlanted] call _delete;  
			} forEach (_centerPos nearObjects [_x, 25000]);
		} forEach ["TimeBombCore"];
	};
	
	if (_ttwSmokes>0) then {
		{
			{ 	 
				[_x, _ttwSmokes] call _delete; 
			} forEach (_centerPos nearObjects [_x, 25000]);
		} forEach ["SmokeShell"];
	};
	
	{
		if ((count units _x)==0) then {
			deleteGroup _x;
		};
	} forEach allGroups;
			
};
