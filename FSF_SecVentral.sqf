/*

	NAME: FSF_SecVentral.sqf
	VERSION: 1.0

	DESCRIPTION:
	Found addon that allows you to put backpack intro ventral position.
	Took and merged its scripts into this one.
	Addon soure: https://forums.bistudio.com/topic/162766-fsf-sacventral-put-every-backpack-in-ventral-position/
	Can now be used as script inside mission.

	USAGE:
	paste into init
	[] execVM 'FSF_SecVentral.sqf';

*/







/*
FSF_SacVentral
2013-2014

Auteur : ElDoktor, ToF, BeTeP

site : www.clan-fsf.fr
Debug : http://server.clan-fsf.fr:8008/redmine/projects/fsf-server-arma-26
Source : http://server.clan-fsf.fr:8008/redmine/projects/fsf-server-arma-26/repository
*/






//Fonction pour passer le sac du dos vers le ventral
if (isDedicated) exitwith {};

player setVariable ["FSFSV_BACKPACK",objNull];






FSFSV_EmplacementVideAutourjoueur =
{
	private ["_pos","_unit"];
    _unit = _this select 0;
	_pos = position player findEmptyPosition [0,100,"GroundWeaponHolder"];
	_pos
};
FSFSV_CreationGroundWeaponsHolder =
{
	private ["_i","_FSFSV_SacADosGwh","_backpack","_pos"];
    _i=0;
    _unit = _this select 0;
    _FSFSV_SacADosGwh = objNull;
    _backpack = backpack _unit;
    _pos = [_unit] call FSFSV_EmplacementVideAutourjoueur;
    while {!(backpack _unit == "") && (isNull _FSFSV_SacADosGwh) && _i<5} do
	    {
	    _i=_i+1;
	    _FSFSV_SacADosGwh = "GroundWeaponHolder" createVehicle _pos;
		_FSFSV_SacADosGwh setPos _pos;
		_unit reveal _FSFSV_SacADosGwh;
		_unit action ["DropBag",_FSFSV_SacADosGwh,_backpack];
		sleep 1.5;
	    };
		_unit forceWalk true;
		_FSFSV_SacADosGwh
};
FSFSV_PositionneBackpackSurJoueur =
{
	    private ["_FSFSV_SacADosGwh","_unit"];
	    _FSFSV_SacADosGwh =_this select 0;
	    _unit = _this select 1;
		if ((backpack _unit == "") && !(isNull _FSFSV_SacADosGwh)) then
	     {//anti Action::Process - No target [action: DropBag]
			private ["_positionMemorisee","_positionActualisee","_vehicle"];
			_FSFSV_SacADosGwh attachTo [_unit,[-0.1,0.8,-0.05],"pelvis"];
			_FSFSV_SacADosGwh setVectorDirAndUp [[0,0,-1],[0,1,0]];
			_positionMemorisee = "vertical";
			_unit setVariable ["FSFSV_BACKPACK",_FSFSV_SacADosGwh,true];
			while {!(isNull _FSFSV_SacADosGwh)} do
			{
				_positionActualisee = (animationState _unit) call FSFSV_QuellePosition;

				if ((_positionMemorisee != _positionActualisee) && (_positionActualisee != "")) then {
					switch (_positionActualisee) do {
						case "vertical" : {
							_FSFSV_SacADosGwh attachTo [_unit,[-0.1,0.8,-0.05],"pelvis"];
							_FSFSV_SacADosGwh setVectorDirAndUp [[0,0,-1],[0,1,0]];
						};
						case "horizontallower" : {
							_FSFSV_SacADosGwh attachTo [_unit,[-0.1,0,-0.72],"pelvis"];
							_FSFSV_SacADosGwh setVectorDirAndUp [[0,-1,-0.15],[0,0,-1]];
						};
						case "horizontalupper" : {
							_FSFSV_SacADosGwh attachTo [_unit,[-0.1,0.4,0.75],"pelvis"];
							_FSFSV_SacADosGwh setVectorDirAndUp [[0,0.75,-0.25],[0,0.25,0.75]];
						};
					};
					_positionMemorisee = _positionActualisee;
				};

				if (_unit != vehicle _unit) then {
					private "_para";
					_vehicle = vehicle _unit;
					_para = if (_vehicle isKindOf "ParachuteBase") then {true;} else {false;};

					if (_para) then {
						_FSFSV_SacADosGwh attachTo [_vehicle,[-0.12,0.65,-0.15]];
						_FSFSV_SacADosGwh setVectorDirAndUp [[0,-0.2,-1],[0,1,0]];
						//anti-bug Lino, addAction temporarily removed
						_unit setVariable ["FSFSV_BACKPACK",objNull,true];
					} else {
						detach _FSFSV_SacADosGwh;
						_FSFSV_SacADosGwh setPos [random 50,random 50,(10000 + (random 50))];
						[[_FSFSV_SacADosGwh,true],"FSFSV_cacheObjet"] call BIS_fnc_MP;
					};

					waitUntil {sleep 0.1;((_unit == vehicle _unit) || !(alive _unit))};

					if (_para) then {
						[[_FSFSV_SacADosGwh,true],"FSFSV_cacheObjet"] call BIS_fnc_MP;
						sleep 5;
						if (alive _unit) then {_unit setVariable ["FSFSV_BACKPACK",_FSFSV_SacADosGwh,true];};
					};
					[[_FSFSV_SacADosGwh,false],"FSFSV_cacheObjet"] call BIS_fnc_MP;
					_positionMemorisee = "out";
				};

				if !(alive _unit) exitWith {
					private ["_delay","_falling","_speed"];
					//anti-bug collision, shock or other... tempo 100s, if he died in freefall (~3000m)
					_delay = time + 100;
					waitUntil {
						sleep 0.2;
						_vehicle = vehicle _unit;
						_speed = speed _vehicle;
						_falling = (velocity _vehicle) select 2;
						(((_speed > -1) && (_speed < 1) && (_falling < 0.5) && (_falling > -0.5)) || (time > _delay))
					};
					if !(isNull (attachedTo _FSFSV_SacADosGwh)) then {detach _FSFSV_SacADosGwh;};
					_FSFSV_SacADosGwh setPos (getPos _unit);
					_unit setVariable ["FSFSV_BACKPACK",objNull,true];
				};
				sleep 0.1;
             };
		}
		 else
		{
			_unit forceWalk false;
		};

};
FSFSV_CallBackpackToFront =
{
	private ["_unit","_FSFSV_SacADosGwh"];
	_unit = _this select 0;
	_FSFSV_SacADosGwh = [_unit] call FSFSV_CreationGroundWeaponsHolder;
    [_FSFSV_SacADosGwh,_unit] call FSFSV_PositionneBackpackSurJoueur;
};

//Fonction pour passer le sac du ventral vers le dos
FSFSV_CallBackpackToBack = {
	private ["_FSFSV_SacADosGwh","_unit"];
	_unit = _this select 0;
	_FSFSV_SacADosGwh = _unit getVariable "FSFSV_BACKPACK";
	detach _FSFSV_SacADosGwh;
	_unit action ["AddBag",_FSFSV_SacADosGwh,(backpackCargo _FSFSV_SacADosGwh) select 0];
	_unit setVariable ["FSFSV_BACKPACK",objNull,true];
	_unit forceWalk false;
};

//Check si joueur a pied et si l'on peut placer le sac a dos en position ventral
FSFSV_TestPlayerBackpackBack = {
	private ["_return","_unit"];
	_unit = _this select 0;
	_return = false;
	if ((isNull (_unit getVariable "FSFSV_BACKPACK")) && (backpack _unit != "") && (vehicle _unit == _unit)) then {
		private ["_pos","_iswater"];
		_pos = getPosASL _unit;
		_iswater = surfaceIsWater _pos;
		if (!(_iswater) || (_iswater && ((_pos select 2) > 0.5))) then {_return = true;};
	};
	_return
};

//Check si joueur a pied et si il y a un sac en position ventral et aucun en position dos
FSFSV_TestPlayerBackpackFront = {
	private ["_return","_unit"];
	_unit = _this select 0;
	_return = if (!(isNull (_unit getVariable "FSFSV_BACKPACK")) && (backpack _unit == "") && (vehicle _unit == _unit)) then {
		true;
	} else {
		false;
	};
	_return
};

FSFSV_QuellePosition = {
	private "_animationAMemoriser";
	_animationAMemoriser = switch (_this) do {
	     // a genou
	     case "amovpknlmstpsraswrfldnon";
	     case "amovpknlmstpslowwrfldnon";
	     // vertical dans l'eau
	     case "asdvpercmstpsnonwrfldnon";
	     case "asdvpercmstpsnonwnondnon";
		// vertical au sol
		case "amovpercmstpsnonwnondnon";
	     case "amovpercmrunslowwrfldf";
	     case "amovpercmstpslowwrfldnon";
	     case "amovpercmstpsraswrfldnon";
	     case "advepercmstpsnonwnondnon";
	     case "advepercmstpsnonwrfldnon";
	     case "aswmpercmstpsnonwnondnon" : {"vertical";};

		// couche
		case "amovppnemstpsraswrfldnon";
		case "amovppnemsprslowwrfldf";
	     // Free Fall
	     case "halofreefall_non";
	     // Plongeur (nage) horizontal sac dessous
	     case "abdvpercmwlksnonwrfldf";
	     case "asdvpercmwlksnonwrfldf";
	     case "abdvpercmstpsnonwrfldnon";
	     case "advepercmwlksnonwnondf";
	     case "advepercmwlksnonwrfldf";
	     case "aswmpercmwlksnonwnondf" : {"horizontallower";};

		// Plongeur (nage sur le dos) horizontal sac dessus
		case "abdvpercmwlksnonwnondb";
	     case "abdvpercmwlksnonwrfldb";
	     case "advepercmwlksnonwrfldb";
	     case "asdvpercmwlksnonwrfldb" : {"horizontalupper";};

	     // vide par d?faut
	     default {"";};
    };
	_animationAMemoriser
};

FSFSV_cacheObjet = compileFinal "(_this select 0) hideObject (_this select 1);";

FSFSV_Player_Init = {
	player forceWalk false;
	player addAction ["Put backpack on CHEST","[player] spawn FSFSV_CallBackpackToFront;","",1.5,false,false,"","[player] call FSFSV_TestPlayerBackpackBack"];
	player addAction ["Put backpack on BACK","[player] spawn FSFSV_CallBackpackToBack;","",1.5,false,false,"","[player] call FSFSV_TestPlayerBackpackFront"];
};





player addEventHandler ["Respawn",{player spawn FSFSV_Player_Init;}];
[player] spawn FSFSV_Player_Init;

