/*

  AUTHOR: aeroson
	NAME: vehicle_respawn.sqf
	VERSION: 1
	
	DESCRIPTION:
	this scripts manages respawning of all vehicles in single thread as opposed to standart one thread one vehicle
	it does manage all vehicles that are on map at server startup
	i hope it will save some some cpu cycles, also it might be quite easier to set up
	all config is done inside this script
	
	USAGE:
	in server's init: execVM 'vehicle_respawn.sqf';	
	
	CREDITS: 
	it is variation of vehicle respawn by Tophe
	http://forums.bistudio.com/showthread.php?147890-Simple-Vehicle-Respawn-Script-Arma3	
	
*/

if !isServer exitWith {};

private ["_config","_done","_data","_i","_x","_vehicle","_respawn"];
						
_config = [
	[
		["B_Quadbike_F"], // vehicle class(es)
		0, // once destroyed, how long it takes to respawn 
		0 // once seen deserted. how long it takes to respawn
	],
	[
		["Land","Ship"], // vehicle class(es)
		0, // once destroyed, how long it takes to respawn 
		10 // once seen deserted. how long it takes to respawn
	],
	[
		["Air"], // vehicle class(es)
		20, // once destroyed, how long it takes to respawn 
		60 // once seen deserted. how long it takes to respawn
	]
];

_done = [];
_data = [];
{
	_i = _x;
	{
		if(!(_x in _done)) then {
			_data = _data + [[
				_x, // 0 // unit 
				typeOf _x, // 1 // class
				getPosATL _x, // 2 // pos
				getDir _x, // 3 // dir
				0, // 4 // when to respawn
				_i select 1, // 5 // once destroyed, how long it takes to respawn 
				_i select 2 // 6 // once seen deserted. how long it takes to respawn				
			]];
			_x setVariable ["sp", getPosATL _x, true]; // public spawn point, so we can show it to driver locally 
			_done set [count _done, _x];
		};
	} forEach nearestObjects [getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition") , _i select 0, 25000];
} forEach _config;
_done = [];


while {true} do {

	sleep 5;

	for "_i" from 0 to count(_data)-1 do {
	
		_x = _data select _i;
		_vehicle = _x select 0;
		_respawn = _x select 4;
		
		if (_respawn > 0 ) then {
			if (_respawn < time) then {
				deleteVehicle _vehicle;
				_vehicle = createVehicle [_x select 1, _x select 2, [], 0, "CAN_COLLIDE"];	
				_vehicle setDir (_x select 3);
				_vehicle setVariable ["sp", _x select 2, true]; 
				_respawn = 0;
			};
		};
		

		if ({alive _x} count crew _vehicle > 0) then {
			_respawn = 0;
		} else {		
			if((_x select 2) distance getPosATL _vehicle < 10) then {
				if (damage _vehicle > 0.7) then {
					_respawn = time;
				} else {
					_vehicle setDamage 0;
					_vehicle setFuel 1;
					_vehicle setVehicleAmmo 1;
					_vehicle engineOn false;
					if((_x select 2) distance getPosATL _vehicle > 1) then {
						_vehicle setPosATL (_x select 2);
						_vehicle setDir (_x select 3);
					};
					_respawn = 0;
				};
			} else {		 
				if (damage _vehicle > 0.7) then {
					if(_respawn == 0) then {
						_respawn = time + (_x select 5);
					};
				} else {									 
					if ({alive _x} count (nearestObjects [getPos _vehicle, ["CAManBase"], 200]) == 0) then {
						if(_respawn == 0) then {
							_respawn = time + (_x select 6);
						};
					} else {
						_respawn = 0;
					};
				};
			};	
		};
		_x set [0, _vehicle];
		_x set [4, _respawn];	
		_data set [_i, _x];	
		 
	};

};



