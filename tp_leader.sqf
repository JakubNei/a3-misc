/*

	NAME: tp_leader.sqf
	AUTHOR: TAW_SAFORAX, aeroson
	VERSION: 1.2

	DESCRIPTION:
	upon executon: 
	teleports player behind his squad leader, or moves him into squad leader's vehicle
	if player is his own squad leader, it teleports him to member of his group in the field

	USAGE:
	place this into flag's init:
	this addAction ["TP to SL", "tpLeader.sqf"];

*/

private ["_leader", "_leaderVehicle"];

_leader = leader player;

if(player == _leader) then {
	private ["_units", "_sumOfDistanceSqr", "_avgOfDistanceSqr"];
	// player is hiw own leader, find member of player's group that is above the average of distances of all group members
	_units = units group player;
	_sumOfDistanceSqr = 0;
	{
		_sumOfDistanceSqr = _sumOfDistanceSqr + (player distanceSqr _x); 
	} forEach _units;
	_avgOfDistanceSqr = _sumOfDistanceSqr / count _units;
	{
		if(player distanceSqr _x >= _avgOfDistanceSqr) exitWith {
			_leader = _x;
		};
	} forEach _units;
};

_leaderVehicle = vehicle _leader;

if(_leaderVehicle == _leader) then {
	// leader is on foot
	private ["_howFarBehindSquadLeader"];
	_howFarBehindSquadLeader = 2 + random 3; // move to 2-5 meters behind the back of squad leader
	_pos = ( (getPosATL _leader) vectorDiff ( (vectorDir _leader) vectorMultiply _howFarBehindSquadLeader ) );
	if((_pos select 2)>1) then {
		_pos = _pos findEmptyPosition [0, 10]; // teleports to safe position if your leader is too high up, but doesnt look nice, since you dont end up behind your sl
	};
	player setPosATL _pos;
	player setDir ( getDir _leader );
} else {
	// leader is in vehicle
	if(!(player moveInAny  _leaderVehicle)) then {
		hint "Your squad leader is in vehicle, which is full."; // failed moveInAny _leaderVehicle
	};
};
