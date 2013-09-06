/*

	AUTHOR: aeroson	
	NAME: chemlights.sqf	
	VERSION: 1.1
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/a3-misc
	http://forums.bistudio.com/showthread.php?163206-Group-Manager
	
	REQUIRES: group_manager.sqf
	
	DESCRIPTION:
	Port of chemlights from pokertour's =ATM= Air Drop http://forums.bistudio.com/showthread.php?157793-ATM-Airdrop-A3-Beta	
	
	USAGE:
	in (client's) init:
	0 = [] execVM 'chemlights.sqf';
	or if you want to use chemlights from your inventory do:
	0 = [true] execVM 'chemlights.sqf';
			
*/

#define PREFIX aero
#define COMPONENT chemlights
//#define DEBUG_MODE

#define DOUBLES(A,B) ##A##_##B
#define TRIPLES(A,B,C) ##A##_##B##_##C
#define QUOTE(A) #A
#define CONCAT(A,B) A####B

#define GVAR(A) TRIPLES(PREFIX,COMPONENT,A)
#define QGVAR(A) QUOTE(GVAR(A))

#define INC(A) A=(A)+1
#define DEC(A) A=(A)-1
#define ADD(A,B) A=(A)+(B)
#define SUB(A,B) A=(A)-(B)
#define REM(A,B) A=A-[B]
#define PUSH(A,B) A set [count (A),B]
#define EL(A,B) ((A) select (B))

#define PUSH_START(A) A set[count (A),
#define PUSH_END ];
#define THIS(A) EL(this,A)
#define _THIS(A) EL(_this,A)

if(isDedicated) exitWith {}; // is server
waitUntil{!isNil{aero_gm_actions_add}};


GVAR(useInventory)=[_this,0,false] call BIS_fnc_param;


GVAR(attached)=[];

player addEventHandler ["Respawn", {
	GVAR(attached)=[];
}];

GVAR(menu_main)={
	call aero_gm_actions_remove;
	{
		if(
			(GVAR(useInventory) && ((_x select 2) select 1) in magazines player) ||
			!GVAR(useInventory)
		) then {
			(player addAction _x) call aero_gm_actions_addId;
		};
	} forEach [
		["<t color='#B40404'>Attach Red Chemlight ...</t>", { _THIS(3) call GVAR(menu_shoulder); }, ["B40404","Chemlight_red"],5090],
		["<t color='#30fd07'>Attach Green Chemlight ...</t>", { _THIS(3) call GVAR(menu_shoulder); }, ["30fd07","Chemlight_green"],5080],
		["<t color='#68ccf6'>Attach Blue Chemlight ...</t>", { _THIS(3) call GVAR(menu_shoulder); }, ["68ccf6","Chemlight_blue"],5070],
		["<t color='#fcf018'>Attach Yellow Chemlight ...</t>", { _THIS(3) call GVAR(menu_shoulder); }, ["fcf018","Chemlight_yellow"],5060]
	];	
	if(count GVAR(attached)>0) then {
		(player addAction ["<t color='#cccccc'>Detach chemlights</t>", { _THIS(3) call GVAR(chemlights_detach); },[],3000]) call aero_gm_actions_addId;		
	};
	[] call aero_gm_actions_addBack;
};


GVAR(menu_shoulder)={
	call aero_gm_actions_remove;	
	{
		(player addAction _x) call aero_gm_actions_addId;
	} forEach [
		[format["<t color='#%1'>Attach To Left Shoulder</t>",_THIS(0)], { _THIS(3) call GVAR(chemlight_attach); }, [_THIS(1),"LeftShoulder",[-0.02,-0.05,0.04]],5090],
		[format["<t color='#%1'>Attach To Right Shoulder</t>",_THIS(0)], { _THIS(3) call GVAR(chemlight_attach); }, [_THIS(1),"RightShoulder",[0.02,-0.05,0.04]],5080],
		[format["<t color='#%1'>Attach To Left Hand</t>",_THIS(0)], { _THIS(3) call GVAR(chemlight_attach); }, [_THIS(1),"LeftHand",[0,0,0]],5070],
		[format["<t color='#%1'>Attach To Right Hand</t>",_THIS(0)], { _THIS(3) call GVAR(chemlight_attach); }, [_THIS(1),"RightHand",[0,0,0]],5060]
	];
	[{call GVAR(menu_main);}] call aero_gm_actions_addBack;
};

// default vectorDirUp [[0,0,1],[0,0,1]]
// for chest [[0,0,1],[1,0,0]]

GVAR(chemlight_attach) = {
	if(GVAR(useInventory)) then {
		player removeMagazine (_this select 0);
	};
	[] call aero_gm_menu_main;
	private["_chemlight"];
	_chemlight = (_this select 0) createVehicle [0,0,0]; 
	_chemlight attachTo [player, (_this select 2), (_this select 1)];
	PUSH(GVAR(attached),_chemlight)
};
GVAR(chemlights_detach) = {
	{
		deletevehicle _x;
	} forEach GVAR(attached);
};



[
	"<t color='#0033ee'><img image='\A3\ui_f\data\IGUI\RscIngameUI\RscOptics\laser_designator_iconlaseron.paa' size='0.7' /> Chemlights ...</t>",
	{ [] call GVAR(menu_main); },
	[],
	100
] call aero_gm_actions_add;

