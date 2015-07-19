/*
	
	AUTHOR: aeroson
	NAME: protection_zones.sqf
	VERSION: 1
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc
	
	DESCRIPTION:
	creates protection zones on markers named pz_X
	where X is number from 0 incremented by 1
	protecion zone is an invisible object thru which you can not shoot or throw grenades
	in rare cases saw it to also disallow vehicles to pass thru
	
	CREDITS:
	stole the protection zones from Xeno's domination

*/


private ["_num","_maxNum","_marker","_pos","_pz"];
				 
_num = 0;
_maxNum = 10;		
while {_num < _maxNum } do {
	_marker = format["pz_%1",_num];
	if ((getMarkerType _marker) != "" ) then {
		_pos = getMarkerPos _marker;
		_pz = "ProtectionZone_Invisible_F" createVehicleLocal _pos;
		_pz setPos [_pos select 0, _pos select 1, -24];
		_pz = "ProtectionZone_F" createVehicleLocal _pos;
		_pz setPos [_pos select 0, _pos select 1, -28.45];
		_pz setObjectTexture [0,"#(argb,8,8,3)color(0,0,0,0.3,ca)"];
		_maxNum = _num + 10;			 
	};
	_num = _num + 1;
};

