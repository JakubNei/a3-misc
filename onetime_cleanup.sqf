/*
	
	AUTHOR: aeroson
	NAME: onetime_cleanup.sqf
	VERSION: 2.1.3
	CONTRIBUTE: https://github.com/aeroson/a3-misc

	DESCRIPTION:
	one call deletes stuff within radius from player that is not really needed:
	dead bodies, dropped items, smokes, chemlights, explosives
	beware: if weapons on ground are intentional e.g. fancy weapons stack, it will delete them too
	beware: if dead bodies are intentional it will delete them to
	
	USAGE:
	put this into init of anything:
	this addAction ["Cleanup around you", { [300,["dropped","corpses","wrecks","misc"]] execVM "onetime_cleanup.sqf"; } ];
	where 300 is radius of cleanup, default is 1000
	[1000,["dropped","corpses","wrecks","misc"]] execVM "onetime_cleanup.sqf";
		
*/       

private	_player = player;
if(!isNil{ACE_player}) then {
	_player = ACE_player;
};

if(isNUll(_player)) exitWith {};

params [
	["_radius", 1000, [0]],
	["_whatToRemove", ["dropped","misc","corpses","wrecks"], [[""]]]
];

private _deletedWrecks = 0;
private _deletedDroppedItems = 0;
private _deletedCorpses = 0;
private _deletedMisc = 0;

private _start = diag_tickTime;

private _pos = getPos _player;

private _radiusSquared = _radius * _radius;


if("dropped" in _whatToRemove) then {
	{
		{ 
			if(isNull attachedTo _x) then { // for example backpack on chest is attached to player, we dont want to delete that
				deleteVehicle _x; 
				_deletedDroppedItems = _deletedDroppedItems+1;
			};
		} forEach (_pos nearObjects [_x, _radius]);
	} forEach ["ACE_Explosives_Place","ACE_DefuseObject","WeaponHolder","GroundWeaponHolder","WeaponHolderSimulated","TimeBombCore","SmokeShell"];
};

if("misc" in _whatToRemove) then {
	{
		{ 
			if(isNull attachedTo _x) then { 
				deleteVehicle _x; 
				_deletedMisc = _deletedMisc+1;
			};
		} forEach (_pos nearObjects [_x, _radius]);
	} forEach ["BagFence_base_F","CraterLong_small","CraterLong","AGM_FastRoping_Helper","#dynamicsound","#destructioneffects","#track","#particlesource"];
};

if("corpses" in _whatToRemove) then {
	{ 																																			
		if(!alive _x) then {
			deleteVehicle _x; 
			_deletedCorpses = _deletedCorpses + 1;
		};
	} forEach (_pos nearObjects ["Man", _radius]);
};

if("wrecks" in _whatToRemove) then {
	{ 	
		if(isNull attachedTo _x) then { 	
			if(_x distanceSqr _pos < _radiusSquared && !canMove _x && {alive _x} count crew _x==0) then {
				deleteVehicle _x; 
				_deletedWrecks = _deletedWrecks + 1;
			};
		};
	} forEach vehicles;
};

hint format ["
Cleanup took %1 seconds\n
wrecks deleted: %2\n
dropped items deleted: %3\n
corpses deleted: %4\n
misc deleted: %5\n
in radius: %6 m
",diag_tickTime - _start, _deletedWrecks, _deletedDroppedItems, _deletedCorpses, _deletedMisc, _radius];
