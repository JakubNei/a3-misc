/*
	
	AUTHOR: aeroson
	NAME: onetime_cleanup.sqf
	VERSION: 2.1.0

	DESCRIPTION:
	one call deletes stuff within radius from player that is not really needed:
	dead bodies, dropped items, smokes, chemlights, explosives
	beware: if weapons on ground are intentional e.g. fancy weapons stack, it will delete them too
	beware: if dead bodies are intentional it will delete them to
	
	USAGE:
	put this into init of anything:
	this addAction ["Cleanup around you", { [300,["dropped","corpses","wrecks"]] execVM "onetime_cleanup.sqf"; } ];
	where 300 is radius of cleanup, default is 1000
	[1000,["dropped","corpses","wrecks"] ] execVM "onetime_cleanup.sqf";
		
*/
         

private ["_start", "_args", "_radius"];


_deletedWrecks = 0;
_deletedDroppedItems = 0;
_deletedCorpses = 0;

_start = diag_tickTime;

_args = _this;
//_args = [_args, 3, [], [[]] ] call BIS_fnc_param;
_radius = [_args, 0, 1000, [0] ] call BIS_fnc_param;
_whatToRemove = [_args, 1, ["dropped","corpses","wrecks"], [[""]] ] call BIS_fnc_param;


if("dropped" in _whatToRemove) then {
	{
		{ 
			deleteVehicle _x; 
			_deletedDroppedItems = _deletedDroppedItems+1;
		} forEach ((getPos player) nearObjects [_x, _radius]);
	} forEach ["WeaponHolder","GroundWeaponHolder","WeaponHolderSimulated","TimeBombCore","SmokeShell"];
};

if("corpses" in _whatToRemove) then {
	{ 																																			
		if(!alive _x) then {
			deleteVehicle _x; 
			_deletedCorpses = _deletedCorpses + 1;
		};
	} forEach ((getPos player) nearObjects ["Man", _radius]);
};

if("wrecks" in _whatToRemove) then {
	_pos = getpos player;
	{ 
		
		if(_x distanceSqr _pos < _radius*_radius && !canMove _x ) then {
			deleteVehicle _x; 
			_deletedWrecks = _deletedWrecks + 1;
		};
	} forEach vehicles;
};

hint format ["Cleanup took %1 seconds\nwrecks deleted: %2\ndropped items deleted: %3\ncorpses deleted: %4\nin radius: %5",diag_tickTime - _start, _deletedWrecks, _deletedDroppedItems, _deletedCorpses, _radius];
