/*
	
	AUTHOR: aeroson
	NAME: vehicle_spawn_marker.sqf
	VERSION: 1
	
	DESCRIPTION:
	works with one thread respawn script that sets public variable sp with position of vehicle's spawn point
	shows the point where your vehicle belongs and where it gets serviced

*/


private["_marker","_spawnPos","_vehicle","_serviced"];

_serviced = true;
while {true} do { 		
	sleep 3;

	_vehicle = vehicle player;	
	if(_vehicle != player) then {
	
		_marker = "vs";
		if(driver _vehicle == player) then {
			_spawnPos = _vehicle getVariable "s";			
			if(!isNil("_spawnPos")) then {					
			    if((getMarkerType _marker) == "") then {
			    	createMarkerLocal[_marker, _spawnPos];
			    	_marker setMarkerTypeLocal "o_maint";
			    	_marker setMarkerSizeLocal [1,1];
			    	_marker setMarkerColorLocal "ColorWhite";
					_marker setMarkerTextLocal format["Service point"];
			    } else {
			      _marker setMarkerPosLocal _spawnPos;
			    };		
								
				if(_spawnPos distance getPosASL _vehicle < 10) then {
					if(!_serviced) then {
						_serviced = true;
						player action ["engineOff",_vehicle];
						_vehicle setDamage 0;
						_vehicle setFuel 1;
						_vehicle setVehicleAmmo 1;
					};
				} else {
					_serviced = false;
				};
			};				
		};
		
	} else {
		
		_serviced = true;	
		_marker = "vs";
		if (getMarkerType _marker != "") then {
		  deleteMarkerLocal _marker;
		};
		
	};

};
