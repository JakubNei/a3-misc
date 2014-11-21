/*
	
	AUTHOR: aeroson
	NAME: onetime_cleanup.sqf
	VERSION: 1.1
	
	DESCRIPTION:
	one call immediately deletes everything that is not really needed 
	dead bodies, dropped items, smokes, chemlights, explosives, empty groups
	
	USAGE:
	in unit's init:
	this addAction ["<t color='#ff8822'>Cleanup server</t>", "onetime_cleanup.sqf"];
		
*/
         

private ["_start"];

_start = diag_tickTime;

{ 
	deleteVehicle _x; 
} forEach allDead;

{
	{ 
		deleteVehicle _x; 
	} forEach (getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition") nearObjects [_x, 25000]);
} forEach ["WeaponHolder","GroundWeaponHolder","WeaponHolderSimulated","TimeBombCore","SmokeShell"];

{
	if ((count units _x)==0) then {
		deleteGroup _x;
	};
} foreach allGroups;

hint format ["Cleanup took %1 seconds",diag_tickTime - _start];
