/*

	AUTHOR: aeroson
	NAME: vehicle_respawn.sqf
	VERSION: 2.0
	
	DOWNLOAD & PARTICIPATE: 
	https://github.com/aeroson/a3-misc
	
	DESCRIPTION:
	This scripts manages respawning of all vehicles in single thread as opposed to standart one thread one vehicle.
	I hope it will save some some cpu cycles, also it might be quite easier to set up.
	At startup it goes thru config from start to end, if it finds class matching vehicle it uses it and repeats process for next vehicle.
	So all you have to do is just put vehicle into your mission and it will automatically respawn.
	It is uav compatible, it creates uav crew if it respawns a vehicle with cfg value isUav=1		
	You can use: (vehicle player) call aero_vehicle_respawn_add;
	To add your current vehicle into respawn pool	
	
	USAGE:
	in (server's) init:  	
	[
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
	] execVM 'vehicle_respawn.sqf';

	
	
	CREDITS: 
	it is variation of vehicle respawn by Tophe
	http://forums.bistudio.com/showthread.php?147890-Simple-Vehicle-Respawn-Script-Arma3
	
*/

if (!isServer) exitWith {}; // isn't server     

#define PREFIX aero
#define COMPONENT vehicle_respawn

#define DOUBLES(A,B) ##A##_##B
#define TRIPLES(A,B,C) ##A##_##B##_##C
#define QUOTE(A) #A
#define CONCAT(A,B) A####B

#define GVAR(A) TRIPLES(PREFIX,COMPONENT,A)
#define QGVAR(A) QUOTE(GVAR(A))

#define SHOWSPAWNPOINT false
		
if (!isNil{GVAR(data)}) exitWith {}; // already running    		
			
GVAR(config) = _this;
GVAR(vehicles) = [];
GVAR(data) = [];

GVAR(add) = {
	private ["_vehicle","_cfgIndex","_thisOne"];
	_vehicle = _this;
	if(!(_vehicle in GVAR(vehicles))) then {
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
		} foreach GVAR(config);
		if(_cfgIndex>-1) then {
			GVAR(vehicles) set [count GVAR(vehicles), _vehicle];
			GVAR(data) set [count GVAR(data), [
				_cfgIndex, // 0 // config index
				typeOf _vehicle, // 1 // spawn class
				getPosASL _vehicle, // 2 // spawn pos
				getDir _vehicle, // 3 // spawn dir
				0, // 4 // when to respawn
				[0,0,0] // 5 // last pos				 
			]];
			_vehicle call ((GVAR(config) select _cfgIndex) select 3); // call back
			//if((GVAR(config) select _cfgIndex) select 4) then {
			if(SHOWSPAWNPOINT) then {
				_vehicle setVariable ["s", getPosASL _vehicle, true]; // public spawn/repair point, so we can show it to driver locally
			};
		};
	};
}; 

{
	_x call GVAR(add);
} forEach vehicles;


private ["_vehicle","_currentData","_currentConfig","_respawnTime","_deserted","_isUav","_positionChangeCheck","_distanceFromSpawn"];
while {true} do {
	sleep 5;
	for "_i" from 0 to count(GVAR(vehicles))-1 do {

		_vehicle = GVAR(vehicles) select _i;
		_currentData = GVAR(data) select _i;
		_currentConfig = GVAR(config) select (_currentData select 0); 
		_isUav = getNumber(configFile >> "CfgVehicles" >> (_currentData select 1) >> "isUav")==1;
        _positionChangeCheck = _isUav;

        _respawnTime = 0;
		if (
			(!_isUav && {isPlayer _x && alive _x} count crew _vehicle <= 0 ) ||
			(_isUav && isNull (uavControl _vehicle select 0) )  
		) then {			 
			if ( !alive _vehicle || damage _vehicle > 0.9) then {
				_respawnTime = time + (_currentConfig select 1); // destroyed
			} else {
				_distanceFromSpawn = (_currentData select 2) distance (getPosASL _vehicle);
				if( _distanceFromSpawn > 0.1) then {
					if(alive _vehicle && _distanceFromSpawn < 500) then { 
						_positionChangeCheck = true;
					};					
					_deserted = true;
					if(_positionChangeCheck) then { 					
						if(!([getPosASL _vehicle, _currentData select 5] call BIS_fnc_areEqual)) then {
							_currentData set[5, getPosASL _vehicle];
							_deserted = false;
						};  						
					} else {
						{								
							if (isPlayer _x && _deserted) then { 
								if (_x distance _vehicle < 200) then {
									_respawnTime = 0;
									_deserted = false;					
								}; 
							};
						} forEach (playableUnits+switchableUnits);
					};
					if(_deserted) then {
						_respawnTime = time + (_currentConfig select 2); // deserted
					};
				};
			};
		};
				
		// only load original timer if new is bigger
		if(_currentData select 4 != 0 && _currentData select 4 < _respawnTime) then {
			_respawnTime = _currentData select 4; 
		};
					
						
		if (_respawnTime > 0 ) then {
			if (_respawnTime < time) then {
				_vehicle setVehicleLock "LOCKED";
				_distanceFromSpawn = (_currentData select 2) distance (getPosASL _vehicle);
				if(_distanceFromSpawn > 100) then {
					_vehicle setDamage 1;
				} else {
					deleteVehicle _vehicle;					
				};				          
				_vehicle = createVehicle [(_currentData select 1), (_currentData select 2), [], 100,""];                         
				//_vehicle setPosASL (_currentData select 2);
				_vehicle setDir (_currentData select 3); 
				_respawnTime = 0;
				_vehicle call (_currentConfig select 3); // call back
				if(_isUav) then {
					createVehicleCrew _vehicle; 	
				};
				GVAR(vehicles) set [_i, _vehicle];
				//if(_currentConfig select 4) then {
				if(SHOWSPAWNPOINT) then {
					_vehicle setVariable ["s", _currentData select 2, true]; // public spawn point, so we can show it to driver locally
				};
			};
		};		
		
		_currentData set [4, _respawnTime];	
		GVAR(data) set [_i, _currentData];	
		 
	};

};



