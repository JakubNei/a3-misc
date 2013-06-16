/*

	AUTHOR: aeroson
	NAME: vehicle_respawn.sqf
	VERSION: 1.2
	
	DESCRIPTION:
	this scripts manages respawning of all vehicles in single thread as opposed to standart one thread one vehicle
	i hope it will save some some cpu cycles, also it might be quite easier to set up	
	
	CREDITS: 
	it is variation of vehicle respawn by Tophe
	http://forums.bistudio.com/showthread.php?147890-Simple-Vehicle-Respawn-Script-Arma3
	
*/


private ["_config","_vehicles","_data","_vehicle","_cfg","_cfgIndex","_thisOne","_respawnTime"];
						
_config = [
	[
		["B_Quadbike_F"], // vehicle class(es)
		0, // once destroyed, how long it takes to respawn 
		0, // once seen deserted. how long it takes to respawn
		{} // call back where _this is the newly created vehicle
	],
	[
		["Land","Ship"], // vehicle class(es)
		0, // once destroyed, how long it takes to respawn 
		10, // once seen deserted. how long it takes to respawn
		{} // call back where _this is the newly created vehicle
	],
	[
		["Air"], // vehicle class(es)
		20, // once destroyed, how long it takes to respawn 
		60, // once seen deserted. how long it takes to respawn
		{} // call back where _this is the newly created vehicle
	]
];

_vehicles = [];
_data = [];
{
	_vehicle = _x;
	if(!(_vehicle in _vehicles)) then {
		_cfgIndex = -1;		
		{
			if(_cfgIndex<=-1) then {
				_thisOne = false;
				{
					if((_vehicle isKindOf _x) || ((typeof _vehicle)==_x)) then {
						_thisOne = true;	
					};
				} foreach (_x select 0);
				if(_thisOne) then {	
					_cfgIndex = _forEachIndex;
				};
			};
		} foreach _config;
		if(_cfgIndex>-1) then {
			_vehicles set [count _vehicles, _vehicle];
			_data set [count _data, [
				_cfgIndex, // 0 // config index
				typeOf _vehicle, // 1 // class
				getPosASL _vehicle, // 2 // pos
				getDir _vehicle, // 3 // dir
				0 // 4 // when to respawn				 
			]];
			_vehicle setVariable ["s", getPosASL _vehicle, true]; // public spawn point, so we can show it to driver locally
			systemchat str(_vehicle); 
		};
	};
} forEach vehicles; 

a=_vehicles;
b=_data;


while {true} do {

	sleep (2 + random 10);

	for "_i" from 0 to count(_vehicles)-1 do {
	
		_vehicle = _vehicles select _i;
		_currentData = _data select _i;
		_currentConfig = _config select (_currentData select 0); 
		_respawnTime = _currentData select 4;
		
		if (_respawnTime > 0 ) then {
			if (_respawnTime < time) then {
				_vehicle setVehicleLock "LOCKED";
				_vehicle setDamage 1;                                 
				_vehicle = (_currentData select 1) createVehicle (_currentData select 2);
				_vehicle setPosASL (_currentData select 2);
				_vehicle setDir (_currentData select 3); 
				_respawnTime = 0;
				_vehicle call (_currentConfig select 3); // call back
				_vehicles set [_i, _vehicle];
			};
		};
		
		if (({alive _x} count crew _vehicle) <= 0) then {
			if(((_currentData select 2) distance (getPosASL _vehicle)) < 10) then {
				_vehicle setDamage 0;
				_vehicle setFuel 1;
				_vehicle setVehicleAmmo 1;
				_respawnTime = 0;
			} else {		 
				if (getDammage _vehicle > 0.9) then {
					if(_respawnTime == 0) then {
						_respawnTime = time + (_currentConfig select 1); // destroyed
					};
				} else {									 
					if (({alive _x} count (nearestObjects [getPos _vehicle, ["CAManBase"], 200])) <= 0) then {
						if ((getDammage _vehicle) > 0.7) then {
							if(_respawnTime == 0) then {
								_respawnTime = time + (_currentConfig select 1);  // destroyed + deserted
							};
						} else {
							if(_respawnTime == 0) then {
								_respawnTime = time + (_currentConfig select 2); // deserted
							};
						};
					} else {
						_respawnTime = 0;
					};
				};
			};	
		} else {
			_respawnTime = 0;				
		};
		
		_currentData set [4, _respawnTime];	
		_data set [_i, _currentData];	
		 
	};

};



