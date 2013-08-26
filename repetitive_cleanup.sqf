/*
	
	AUTHOR: aeroson
	NAME: repetitive_cleanup.sqf
	VERSION: 1.5
	
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

#define PREFIX aero
#define COMPONENT repetitive_cleanup

#define TRIPLES(A,B,C) ##A##_##B##_##C
#define GVAR(A) TRIPLES(PREFIX,COMPONENT,A)
#define QGVAR(A) QUOTE(GVAR(A))
#define PUSH(A,B) A set [count (A),B];
#define REM(A,B) A=A-[B];
#define PARAM_START private ["_PARAM_INDEX"]; _PARAM_INDEX=0;
#define PARAM_REQ(A) if (count _this <= _PARAM_INDEX) exitWith { systemChat format["required param '%1' not supplied in file:'%2' at line:%3", #A ,__FILE__,__LINE__]; }; A = _this select _PARAM_INDEX; _PARAM_INDEX=_PARAM_INDEX+1;
#define PARAM(A,B) A = B; if (count _this > _PARAM_INDEX) then { A = _this select _PARAM_INDEX; }; _PARAM_INDEX=_PARAM_INDEX+1;

private ["_ttwBodies","_ttwVehicles","_ttwWeapons","_ttwPlanted","_ttwSmokes","_delete","_unit"];

PARAM_START
PARAM(_ttwBodies,0)
PARAM(_ttwVehicles,0)
PARAM(_ttwWeapons,0)
PARAM(_ttwPlanted,0)
PARAM(_ttwSmokes,0)

if (_ttwWeapons<=0 && _ttwPlanted<=0 && _ttwSmokes<=0 && _ttwBodies<=0 && _ttwVehicles<=0) exitWith {};


GVAR(objects)=[];
GVAR(times)=[];

_delete = {
	_object = _this select 0;
	_time = _this select 1;
	if(GVAR(objects) find _object == -1) then {
		PUSH(GVAR(objects),_object)
		PUSH(GVAR(times),_time+time)
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


	{	
	    _unit = _x;
	    
		if (_ttwWeapons>0) then {
			{
				{ 	 
					[_x, _ttwWeapons] call _delete;			
				} forEach (getpos _unit nearObjects [_x, 100]);
			} forEach ["WeaponHolder","GroundWeaponHolder","WeaponHolderSimulated"];
		};
		
		if (_ttwPlanted>0) then {
			{
				{ 
					[_x, _ttwPlanted] call _delete;  
				} forEach (getpos _unit nearObjects [_x, 100]);
			} forEach ["TimeBombCore"];
		};
		
		if (_ttwSmokes>0) then {
			{
				{ 	 
					[_x, _ttwSmokes] call _delete; 
				} forEach (getpos _unit nearObjects [_x, 100]);
			} forEach ["SmokeShell"];
		};
	
	} forEach allUnits;
	
	{
		if ((count units _x)==0) then {
			deleteGroup _x;
		};
	} forEach allGroups;
		

	{        
		if(isNull(_x)) then {
			GVAR(objects) set[_forEachIndex, 0];
			GVAR(times) set[_forEachIndex, 0];
		} else {
			if(_x < GVAR(times) select _forEachIndex ) then {
				deleteVehicle _object;
				GVAR(objects) set[_forEachIndex, 0];
				GVAR(times) set[_forEachIndex, 0];			 	
			};
		};	
	} forEach GVAR(objects);
	
	REM(GVAR(objects),0)
	REM(GVAR(times),0)
				
};
