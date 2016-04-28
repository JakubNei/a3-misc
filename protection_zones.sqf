/*

	AUTHOR: aeroson
	NAME: protection_zones.sqf
	VERSION: 1.1

	DOWNLOAD & CONTRIBUTE:
	https://github.com/aeroson/a3-misc

	DESCRIPTION:
	Creates protection zones on markers named "protectionZone X".
	Where X is number from 0 incremented by 1, can skip up to 10 X numbers.
	Protection zone is an invisible object thru which you can not shoot or throw grenades.
	Protection zone is short cylinder with radius of 25 m, you can place elipsoid marker with 25x25 to mark it on map.
	In rare cases saw it to also disallow vehicles to pass thru.

	CREDITS:
	Stole the protection zones from Xeno's domination.

*/


private ["_num","_maxNum","_marker","_pos","_pz"];

_num = 0;
_maxNum = 10;
while {_num < _maxNum } do {
	_marker = format["protectionZone %1",_num];
	if ((getMarkerType _marker) != "" ) then {
		_pos = getMarkerPos _marker;
		_pz = "ProtectionZone_Invisible_F" createVehicleLocal _pos;
		_pz setPosATL [_pos select 0, _pos select 1, -24];
		_pz setVectorUp (surfaceNormal _pos);
		_pz = "ProtectionZone_F" createVehicleLocal _pos;
		_pz setPosATL [_pos select 0, _pos select 1, -28.35]; //-28.45
		_pz setVectorUp (surfaceNormal _pos);
		_pz setObjectTexture [0,"#(argb,8,8,3)color(0,0,0,0.3,ca)"];
		_maxNum = _num + 10;
	};
	_num = _num + 1;
};

