/*

	AUTHOR: aeroson	
	NAME: unflip_vehicle.sqf	
	VERSION: 1	
	
	DESCRIPTION:
	If vehicle's angle to ground is over 45 and vehicle has no alive crew,
	shows Unflip vehicle action in player's action menu
	
	USAGE:
	paste this into init.sqf
	0 = [] execVM 'unflip_vehicle.sqf';
			
*/

if(!hasInterface) exitWith { }; // exit if we are not a player


aero_unflip_unflipVehicle = {

	_veh = _this;

	if(owner _veh != owner player) exitWith { // if we dont own it, remote execute this on the owner machine
		[_veh, "aero_unflip_unflipVehicle", _veh] call BIS_fnc_mp;
	};

	_veh allowDamage false; // prevent damage from collision

	_newPos = getPos _veh;
	_veh setVectorUp (surfaceNormal _newPos);
	_newPos set[2, 0];
	_veh setPos _newPos;

	sleep 2; // wait a bit for physics to kick in

	_veh setVelocity [0,0,0]; // stop vehicle, so it doesnt fly away due to collision
	_veh allowDamage true;

};


// unit addAction [title, script, arguments, priority, showWindow, hideOnUse, shortcut, condition, positionInModel, radius, radiusView, showIn3D, available, textDefault, textToolTip]
aero_unflip_canShow = {

	_t = player;
	_radius = 2;
	_pos = (getPos _t) vectorAdd ((eyeDirection _t) vectorMultiply _radius); // look for pos that is infront of us and towards the direction we look
	_objs = nearestObjects[_pos, ["Car","Tank"], _radius*2]; // so find vehicles in sphere of _radius in front of you

	aero_unflip_targetVehicle = {
		if(
			// true || // uncomment for debug
			({alive _x} count crew _x  == 0) && // if vehicle has no alive crew
			((vectorUp _x) vectorDotProduct (surfaceNormal (getpos _x)) < 0.5) // if vehicle angle to surface is over 45 degrees
		) exitWith { _x };
	} forEach _objs;
	
	!isNil{aero_unflip_targetVehicle}

};


aero_unflip_addAction = {

	if(!isNil{aero_unflip_handle_addAction}) then {
		(aero_unflip_handle_addAction select 0) removeAction (aero_unflip_handle_addAction select 1);
	};

	aero_unflip_handle_addAction = [
		player, 
		player addAction [
			"<t color='#FF0000'>Unflip vehicle</t>", 
			{
				aero_unflip_targetVehicle call aero_unflip_unflipVehicle;
			},
			[],
			1000,
			false,
			true,
			"",
			"[] call aero_unflip_canShow"
		]
	];

};


[] call aero_unflip_addAction;
player addEventHandler ["respawn", { [] call aero_unflip_addAction; }];
