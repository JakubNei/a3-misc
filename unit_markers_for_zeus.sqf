/*

	AUTHOR: aeroson
	NAME: unit_markers_for_zeus.sqf
	VERSION: 2.0
	CONTRIBUTE: https://github.com/aeroson/a3-misc

	DESCRIPTION:
	Zeuses by default can not see any units on map.
	If player is zeus, this script shows all units markers on map.
	So zeuses can now easily spawn units out of players's view.
	Has standard colors for each side.
	AI units have no name, player units have name.

	USAGE:
	paste into init
	[] execVM 'unit_markers_for_zeus.sqf';
	
	REQUIRES:
	player_markers.sqf
	in the same folder

*/
	
if (!hasInterface) exitWith {}; // exit if we have no interface to show markers on

[] spawn {

	private _isPlayerZeus = {
		if (isNil{player}) exitWith { false; };
		if (player == player && {({getAssignedCuratorUnit _x == player} count allCurators) > 0}) exitWith { true; };
		false;
	};
	
	private _seesAllUnits = false;
	while {true} do {
		if(call _isPlayerZeus) then {
			if(!_seesAllUnits) then {
				_seesAllUnits = true;
				["all"] execVM 'player_markers.sqf';
			};
		} else {
			if(_seesAllUnits) then {
				_seesAllUnits = false;
				["stop"] execVM 'player_markers.sqf';
			};
		};
		sleep 5;
	};
	
};	
