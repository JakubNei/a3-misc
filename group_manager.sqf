/*

	AUTHOR: aeroson	
	NAME: group_manager.sqf	
	VERSION: 1.1
	
	DESCRIPTION:
	Hold T and use scrollwheel to see squad manager menu
	You can: invite others, request to join, or join squad based on squad options
	leave squad, kick members or take leadership if you have better score
	If taw view distance is present it will take over the mousewheel menu for it	
	
	USAGE:
	in client's init:
	execVM 'group_manager.sqf';
			
*/

if(isDedicated) exitWith {};
waitUntil { !isNull(findDisplay 46); };

#define KEY 0x14 // T // http://community.bistudio.com/wiki/DIK_KeyCodes
#define TIMEOUT 120 // seconds


#define COMPONENT aero_gm

#define GVAR(A) COMPONENT##_##A
#define QUOTE(A) #A
#define CONCAT(A,B) A####B
#define EL(A,B) ((A) select (B))

#define DEBUG(A) //systemChat format[QUOTE(%1|%2(%3:%4)=%5),time,QUOTE(COMPONENT),__FILE__,__LINE__,A];
#define DEBUGQ(A) DEBUG(QUOTE(A))
#define ADD_START(A) A set[count A,
#define ADD_END ];
#define PARAM_START private ["_PARAM_INDEX"]; _PARAM_INDEX=0;
#define PARAM_REQ(A) if (count _this <= _PARAM_INDEX) exitWith { systemChat format["required param '%1' not supplied in file:'%2' at line:%3", #A ,__FILE__,__LINE__]; }; A = _this select _PARAM_INDEX; _PARAM_INDEX=_PARAM_INDEX+1;
#define PARAM(A,B) A = B; if (count _this > _PARAM_INDEX) then { A = _this select _PARAM_INDEX; }; _PARAM_INDEX=_PARAM_INDEX+1;

#define _THIS0 EL(_this,0)
#define _THIS1 EL(_this,1)
#define _THIS2 EL(_this,2)
#define _THIS3 EL(_this,3)
#define _THIS4 EL(_this,4)
#define _THIS5 EL(_this,5)
#define _THIS6 EL(_this,6)

// SQUAD JOIN
#define JOIN_FREE 0 // squad is open, anyone can join
#define JOIN_INVITE_BY_SQUAD 1 // squad is invite only, everyone from squad can invite
#define JOIN_INVITE_BY_LEADER 2 // squad is invite only, only leader can invite
#define JOIN_DISABLED 3 // none can invite
#define JOIN_DEFAULT JOIN_FREE 


// SQUAD ACCEPT JOINT REQUEST PERMISSION (WHO CAN ACCEPT REQUEST) ONLY IF SQUAD JOIN IS 1, 2 OR 3
#define ACCEPT_BY_SQUAD 0 // everyone from squad can accept join requests
#define ACCEPT_BY_LEADER 1 // only leader can accept join requests
#define ACCEPT_DISABLED 2 // disable join requests
#define ACCEPT_DEFAULT ACCEPT_BY_LEADER 


GVAR(possibleTargets) = [];
GVAR(opened) = false;

GVAR(invites) = [];
GVAR(requests) = [];

GVAR(msg) = {
	hint _this;
	systemChat _this;
};


GVAR(playersOnly) = {
	private ["_out"];
	_out = [];
	{
		if(isPlayer _x) then {
			ADD_START(_out)
				_x
			ADD_END
		};
	} forEach _THIS0;
	_out;	
};

GVAR(actions) = [];

GVAR(actions_add) = {
	GVAR(actions) set [count GVAR(actions), _this];
};
GVAR(actions_remove) = {
	{
		player removeAction _x;
	} forEach GVAR(actions);
	GVAR(actions) = [];	
};
GVAR(actions_addBack) = {
	player addAction [
		"<t color='#cccccc'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_sidebar_show.paa' size='0.7' /> ... Back</t>",
		{ call GVAR(menu_main); },
		[],
		100
	] call GVAR(actions_add);
};


// [unit1] // you have joined unit1's group 
GVAR(join) = {
	if(([group _THIS0] call GVAR(options_getJoin))!=JOIN_FREE) exitWith {
		format["%1's group (led by %2) is no longer free to join", name _THIS0, name leader _THIS0] call GVAR(msg);
	};
	[
		format["%1 has joined your squad", name player],
		QUOTE(GVAR(msg)),
		[(units group _THIS0)-[player]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	format["You have joined %1's squad led by %2", name _THIS0, name leader _THIS0] call GVAR(msg);	
	[player] joinSilent group _THIS0;
	waitUntil{group player==group _THIS0};	
	call GVAR(menu_main); 	
};

// you left your group
GVAR(leaveGroup) = {
	DEBUGQ(GVAR(leaveGroup))
	[
		format["%1 has left your squad", name player],
		QUOTE(GVAR(msg)),
		[(units group player)-[player]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	"You have left squad" call GVAR(msg);
	[player] joinSilent createGroup (side player);
	call GVAR(menu_main);			
};


// [unit1] // you have invited unit1 to join your group 
GVAR(invite) = {
	private ["_myJoin"];
	_myJoin = [group player] call GVAR(options_getJoin);
	if(!(
		(_myJoin==JOIN_FREE) ||
		(_myJoin==JOIN_INVITE_BY_SQUAD && player in units group player) ||
		(_myJoin==JOIN_INVITE_BY_LEADER && leader player == player)
	)) exitWith {
		"You no longer haver permission to invite" call GVAR(msg);
	};
	format["You have invited %1 into your squad", name _THIS0] call GVAR(msg);
	[
		format["%1 has invited %2 into your squad", name player, name _THIS0],
		QUOTE(GVAR(msg)),
		[(units group player)-[player]] call GVAR(playersOnly)	
	] spawn BIS_fnc_MP;
	[
		[
			player,
			group player
		],
		QUOTE(GVAR(invited)),
		[[_THIS0]] call GVAR(playersOnly)	
	] spawn BIS_fnc_MP;
	call GVAR(menu_main);				 	
};

// [unit1, group1] // you got invited by unit1 to join a unit1's group1
GVAR(invited) = {
	if(_THIS0 in units _THIS1) then {
		format["%1 has invited you to join his/her squad (led by %2)", name _THIS0, name leader _THIS1] call GVAR(msg);
		{
			if((_x select 1)==_THIS0 && (_x select 2)==_THIS1) then {
				GVAR(invites) set[_forEachIndex, 0];				
			};                         
		} forEach GVAR(invites);
		
		ADD_START(GVAR(invites))
			[time, _THIS0, _THIS1]
		ADD_END 
	};
	call GVAR(menu_main);
};

// [unit1, forEachIndex] // you have accepted invite by unit1 to unit1's group, forEachIndex in GVAR(invites) 
GVAR(invite_accepted) = {	
	format["Invite by %1 (led by %2) accepted", name _THIS0, name leader _THIS0] call GVAR(msg),
	[
		format["%1 has accepted your invite", name player],
		QUOTE(GVAR(msg)),
		[[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	[
		format["%1 joined your group, invited by %2", name player, name _THIS0],
		QUOTE(GVAR(msg)),
		[(units group _THIS0)-[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	[player] joinSilent group _THIS0;	
	GVAR(invites) set[_THIS1, 0];
	call GVAR(menu_main);
};

// [unit1, forEachIndex] // you have declined invite by unit1 to unit1's group, forEachIndex in GVAR(invites)
GVAR(invite_declined) = {	
	format["Invite by %1 (led by %2) declined", name _THIS0, name leader _THIS0] call GVAR(msg),
	[
		format["%1 has declined your invite", name player],
		QUOTE(GVAR(msg)),
		[[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	GVAR(invites) set[_THIS1, 0];
	call GVAR(menu_main);	
};



 
// [unit1, unit2, accept:int] // unit1 is requesting to join unit2's group, accept is either ACCEPT_BY_SQUAD or ACCEPT_BY_LEADER 
GVAR(request) = {
	private ["_accept"];
	_accept = [group _THIS1] call GVAR(options_getAccept);	
    if(!(
		(_accept==ACCEPT_BY_SQUAD && ({isPlayer _x} count units group unit2>0)) ||
		(_accept==ACCEPT_BY_LEADER && isPlayer leader group unit2) 
	)) exitWith {
		format["You are no longer able to request join to %1's group (led by %2)", name _THIS1, name leader _THIS1] call GVAR(msg);
	};				
	format["You have requested to join %1's squad (led by %2)", name _THIS1, name leader _THIS1] call GVAR(msg);
	[
		[
			_THIS0,
			group _THIS1
		],
		QUOTE(GVAR(requested)),
		[
			if(_accept==ACCEPT_BY_SQUAD) then { units group _THIS1 } else { [leader _THIS1] }
		] call GVAR(playersOnly)
	] spawn BIS_fnc_MP;
	call GVAR(menu_main);		
};

// [unit1, group1] // unit1 requested to join yours group1
GVAR(requested) = {
	if(player in units _THIS1) then {
		format["%1 has requested to join your squad", name _THIS0, name leader _THIS1] call GVAR(msg);
		{
			if((_x select 1)==_THIS0 && (_x select 2)==_THIS1) then {
				GVAR(requests) set[_forEachIndex, 0];				
			};                         
		} forEach GVAR(requests);
		ADD_START(GVAR(requests))
			[time, _THIS0, _THIS1]
		ADD_END
	};
	call GVAR(menu_main);
};

// [unit1, forEachIndex] // you have accepted request from unit1 to join your group, forEachIndex in GVAR(requests) 
GVAR(request_accepted) = {
	format["Join request by %1 accepted", name _THIS0] call GVAR(msg),
	[
		format["%1 (led by %2) has accepted your join request", name player, name leader player],
		QUOTE(GVAR(msg)),
		[[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	[
		format["%1 has joined your squad (accepted by %2)", name _THIS0, name player],
		QUOTE(GVAR(msg)),
		[(units group player)-[player]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;		
	[_THIS0] joinSilent group player;
	GVAR(requests) set[_THIS1, 0];
	call GVAR(menu_main);
};

// [unit1, forEachIndex] // you have declined request from unit1 to join your group, forEachIndex in GVAR(requests)
GVAR(request_declined) = {
	format["Join request by %1 declined", name _THIS0] call GVAR(msg),
	[
		format["%1 (led by %2) has declined your join request", name player, name leader player],
		QUOTE(GVAR(msg)),
		[[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;	
	GVAR(requests) set[_THIS1, 0];
	call GVAR(menu_main);
};



// you are taking leadership of your squad
GVAR(takeLeaderShip) = {
	DEBUGQ(GVAR(takeLeaderShip))
	if(!([player] call GVAR(canTakeLeadership))) exitWith {
		"You can't take leadership anymore" call GVAR(msg); 
		call GVAR(menu_main);
	};
	"You took leadership" call GVAR(msg);	
	[
		format["%1 has taken leadership", name player],
		QUOTE(GVAR(msg)),
		[(units group player)-[player, _THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	_oldLeader = leader player;
	[
		[player],		
		QUOTE(GVAR(takeLeaderShip_remote)),
		leader player		
	] spawn BIS_fnc_MP;	
	waitUntil{_oldLeader!=leader player};
	call GVAR(menu_main);	 
}; 

// [unit1] // unit1 takes leadership of his+yours group
GVAR(takeLeaderShip_remote) = {
	if(group _THIS0 == group player) then {
		if(isPlayer leader player) then {
			format["%1 took leadership from you", name _THIS0] call GVAR(msg);
		};
		(group player) selectLeader _THIS0;
		call GVAR(menu_main);
	};
};


// [unit1] // returns true if unit1 can take leadership of his group, false if can't
GVAR(canTakeLeadership) = {	
	if(count units group _THIS0 == 1) exitWith { false; };
	if(leader _THIS0 == _THIS0) exitWith { false; };
	if(isNil{aero_playtime_get}) then {
		if(rating leader _THIS0 + 10 > rating _THIS0) exitWith { false; };
	} else {
		if((leader _THIS0) call aero_playtime_get > ARG0 call aero_playtime_get) exitWith { false; };
	};	 	
	true;
};



// show menu to give leadership
GVAR(menu_giveLeaderShip) = {
	DEBUGQ(GVAR(menu_giveLeaderShip))
	if(leader player!=player) exitWith {
		"You are not leader anymore" call GVAR(msg); 
		call GVAR(menu_main);
	};
	call GVAR(actions_remove);
	{
		ADD_START(GVAR(actions))
			player addAction [
				format["<t color='#0099ee'><img image='\A3\ui_f\data\gui\Rsc\RscDisplayConfigViewer\bookmark_gs.paa' size='0.7' /> Give leadership to %1</t>", name _x],
				{ _THIS3 call GVAR(giveLeaderShip); },
				[_x],
				1000-_forEachIndex
			]
		ADD_END
	} forEach ((units group player)-[player]);
	call GVAR(actions_addBack);
};


// [unit1] // you gave group leadership to unit1
GVAR(giveLeaderShip) = {
	format["You gave leadership to %1", name _THIS0] call GVAR(msg);
	[
		format["%1 was given leadership by %2", name _THIS0, name player],
		QUOTE(GVAR(msg)),
		[(units group _THIS0)-[_THIS0, player]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	[
		format["%1 gave you leadership", name player],
		QUOTE(GVAR(msg)),
		[[_THIS0]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;			
	(group _THIS0) selectLeader _THIS0;
	call GVAR(menu_main);
};


// show menu for squad options
GVAR(menu_squadOptions) = {
	DEBUGQ(GVAR(menu_squadOptions))
	if(leader player!=player) exitWith {
		"You are not leader anymore" call GVAR(msg); 
		call GVAR(menu_main);
	};
	call GVAR(actions_remove);	
	private ["_join","_accept"];
	_join = [group player] call GVAR(options_getJoin);
	{
		ADD_START(GVAR(actions))
			player addAction [
				format["<t color='#0099ee'>%1 %2</t>", _x, if(_join==_forEachIndex) then {"(Current)"} else {""}],
				{ _args=_THIS3; (_args select 0) setVariable ["j", (_args select 1), true]; call GVAR(menu_squadOptions); },
				[group player, _forEachIndex],
				2000-_forEachIndex
			]
		ADD_END		
	} forEach ["Anyone can join","Squad members can invite","Squad leader can invite","Disable invite"];
	
	_accept = [group player] call GVAR(options_getAccept);  		
	{
		ADD_START(GVAR(actions))
			player addAction [
				format["<t color='#0077ee'>%1 %2</t>", _x, if(_accept==_forEachIndex) then {"(Current)"} else {""}],
				{ _args=_THIS3; (_args select 0) setVariable ["a", (_args select 1), true]; call GVAR(menu_squadOptions); },
				[group player, _forEachIndex],
				1000-_forEachIndex
			]
		ADD_END		
	} forEach ["Squad members can accept join request","Squad leader can accept join request","Disable join request"];
	
	call GVAR(actions_addBack);	
};

// show menu to kick squad member
GVAR(menu_kickSquadMember) = {
	DEBUGQ(GVAR(menu_kickSquadMember))
	if(leader player!=player) exitWith {
		"You are not leader anymore" call GVAR(msg); 
		call GVAR(menu_main);
	};
	call GVAR(actions_remove);
	{
		ADD_START(GVAR(actions)) 
			player addAction [
				format["<t color='#ff8822'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\top_close_gs.paa' size='0.7' /> Kick %1</t>", name _x],
				{ _THIS3 call GVAR(kickSquadMember); },
				[_x],
				1000-_forEachIndex
			]	
		ADD_END
	} forEach ((units group player)-[player]);	
	call GVAR(actions_addBack);
}; 

// [unit1] // you are kicking unit1
GVAR(kickSquadMember) = {
	DEBUGQ(GVAR(kickSquadMember))
	format["You have kicked %1", name _THIS0] call GVAR(msg); 				
	[
		format["%1 was kicked by %2", name _THIS0, name player],
		QUOTE(GVAR(msg)),
		[(units group _THIS1)-[_THIS0, player]] call GVAR(playersOnly)		
	] spawn BIS_fnc_MP;
	[
		[player, _THIS0],
		QUOTE(GVAR(kickSquadMember_remote)),		
		_THIS0		
	] spawn BIS_fnc_MP;
	waitUntil{!(_THIS0 in units group player)};
	call GVAR(menu_main);
};

// [unit1, unit2] // unit2 (local) have been kicked by unit1
GVAR(kickSquadMember_remote) = {
	if(isPlayer _THIS1) then {	
		format["You have been kicked by %1", name _THIS0] call GVAR(msg);
	};		
	[_THIS1] joinSilent createGroup (side _THIS1);
	call GVAR(menu_main);
};


// [group1] // returns JOIN_ option for group1
GVAR(options_getJoin) = {
	private ["_join"];
	_join = _THIS0 getVariable "j";
    if(isNil{_join}) then {
    	_join = JOIN_DEFAULT;
    	_THIS0 setVariable ["j", _join, true];
    };
    _join;
};

// [group1] // returns ACCEPT_ option for group1
GVAR(options_getAccept) = {
	private ["_accept"];
	_accept = _THIS0 getVariable "a";
    if(isNil{_accept}) then {
    	_accept = ACCEPT_DEFAULT;
    	_THIS0 setVariable ["a", _accept, true];
    };
    _accept;
};

// main menu D:
GVAR(menu_main) = {
	call GVAR(actions_remove);
	if(!GVAR(opened)) exitWith {};
	
	if(!isNil{tawvd_action} && !isNil{tawvd_foot}) then {
		player removeAction tawvd_action;	  
		ADD_START(GVAR(actions))  
			player addAction[
				"<t color='#FF0000'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_textures_ca.paa' size='0.7' /> View Distance Settings</t>",
				"taw_vd\open.sqf",
				[],-900,false,false,"",""
			]	  
		ADD_END
	};	
	
	if(leader player == player) then {
		if(count units group player > 1)then {
			ADD_START(GVAR(actions))
				player addAction [
					"<t color='#0099ee'><img image='\A3\ui_f\data\gui\Rsc\RscDisplayConfigViewer\bookmark_gs.paa' size='0.7' /> Give Leadership to ...</t>",
					{ _THIS3 call GVAR(menu_giveLeaderShip); },
					[],
					5010				
				]
			ADD_END
			ADD_START(GVAR(actions))
				player addAction [
					"<t color='#ff8822'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\top_close_gs.paa' size='0.7' /> Kick Squad Member ...</t>",
					{ _THIS3 call GVAR(menu_kickSquadMember); },
					[],
					5030
				]
			ADD_END
		};
		ADD_START(GVAR(actions))
			player addAction [
				"<t color='#0088ee'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_config_ca.paa' size='0.7' /> Squad Options ...</t>",
				{ _THIS3 call GVAR(menu_squadOptions); },
				[],
				5020
			]
		ADD_END
	} else {
		if([player] call GVAR(canTakeLeadership)) then {
			ADD_START(GVAR(actions))
				player addAction [
					"<t color='#0099ee'><img image='\A3\ui_f\data\gui\Rsc\RscDisplayConfigViewer\bookmark_gs.paa' size='0.7' /> Take Leadership</t>",
					{ _THIS3 call GVAR(takeLeaderShip) },
					[],
					5000					
				]
			ADD_END
		};
	};

	if(count units group player > 1)then {	
		ADD_START(GVAR(actions))
			player addAction [
				"<t color='#ff1111'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_sidebar_hide_up.paa' size='0.7' /> Leave squad</t>",
				{ _THIS3 call GVAR(leaveGroup) },
				[],
				4000					
			]
		ADD_END
	};
	

	// GVAR(invites) = [[time, unit1, group1], ] // you got invited by unit1 to join a unit1's group1
	GVAR(invites) = GVAR(invites) - [0];
	{
		_unit1 = _x select 1;
		if(_unit1 in units (_x select 2) && (_x select 0) + TIMEOUT > time) then {						
			ADD_START(GVAR(actions))
				player addAction [
					format["<t color='#00cc00'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_continue_ca.paa' size='0.7' /> Accept invite by %1 (led by %2)</t>", name _unit1, name leader _unit1],
					{ _THIS3 call GVAR(invite_accepted) },
					[_unit1, _forEachIndex],
					2500-_forEachIndex					
				]
			ADD_END			
			ADD_START(GVAR(actions))
				player addAction [
					format["<t color='#ff1111'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\top_close_gs.paa' size='0.7' /> Decline invite by %1 (led by %2)</t>", name _unit1, name leader _unit1],
					{ _THIS3 call GVAR(invite_declined) },
					[_unit1, _forEachIndex],
					2000-_forEachIndex
				]
			ADD_END
		} else {
			GVAR(invites) set [_forEachIndex, 0];
		};
	} forEach GVAR(invites);
	GVAR(invites) = GVAR(invites) - [0];
	
	
	// GVAR(requests) = [[time, unit1, group1], ] // unit1 requested to join yours group1
	GVAR(requests) = GVAR(requests) - [0];
	{
      	_unit1 = _x select 1;
      	if(player in units (_x select 2) && (_x select 0) + TIMEOUT > time) then {						
			ADD_START(GVAR(actions))
				player addAction [
					format["<t color='#00cc00'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_continue_ca.paa' size='0.7' /> Accept join request by %1</t>", name _unit1],
					{ _THIS3 call GVAR(request_accepted) },
					[_unit1, _forEachIndex],
					1500-_forEachIndex
				]
			ADD_END			
			ADD_START(GVAR(actions))
				player addAction [
					format["<t color='#ff1111'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\top_close_gs.paa' size='0.7' /> Decline join request by %1</t>", name _unit1],
					{ _THIS3 call GVAR(request_declined) },
					[_unit1, _forEachIndex],
					1000-_forEachIndex
				]
			ADD_END
		} else {
			GVAR(requests) set [_forEachIndex, 0];
		};
	} forEach GVAR(requests);
	GVAR(requests) = GVAR(requests) - [0];
	
	_myJoin = [group player] call GVAR(options_getJoin);  	    	
  	{
  		//if(side _x == side player && group _x != group player) then {
  		if(group _x != group player) then {
		    
		    if(_myJoin!=JOIN_DISABLED && isPlayer _x) then {
				if(
					(_myJoin==JOIN_FREE) ||
					(_myJoin==JOIN_INVITE_BY_SQUAD && player in units group player) ||
					(_myJoin==JOIN_INVITE_BY_LEADER && leader player == player)
				) then {
			    	ADD_START(GVAR(actions))
						player addAction [
							format["<t color='#ffcc66'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_toolbox_units_ca.paa' size='0.7' /> Invite %1 into your squad</t>", name _x],
							{ _THIS3 call GVAR(invite); },
							[_x],
							3000-_forEachIndex
						]
					ADD_END
				};
		    }; 
		    			    			    
		    _join = [group _x] call GVAR(options_getJoin);
	    			    				
		    if(_join==JOIN_FREE) then {
		    	ADD_START(GVAR(actions))
					player addAction [
						format["<t color='#ffcc66'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_toolbox_units_ca.paa' size='0.7' /> Join %1's squad (led by %2)</t>", name _x, name leader _x],
						{ _THIS3 call GVAR(join); },
						[_x],
						3000-_forEachIndex 
					]
				ADD_END				
		    } else {	    
				_accept = [group _x] call GVAR(options_getAccept);
			    if(
					(_accept==ACCEPT_BY_SQUAD && ({isPlayer _x} count units group _x>0)) ||
					(_accept==ACCEPT_BY_LEADER && isPlayer leader group _x) 
				) then {
				    ADD_START(GVAR(actions)) 
						player addAction [
							format["<t color='#ffcc66'><img image='\A3\ui_f\data\gui\rsc\rscdisplayarcademap\icon_toolbox_units_ca.paa' size='0.7' /> Request to join %1's squad (led by %2)</t>", name _x, name leader _x],
							{ _THIS3 call GVAR(request); },
							[player, _x, _accept],
							3000-_forEachIndex
						]
					ADD_END
			    };			    
		    };			    
			    		    			 
  		};
  	} forEach GVAR(possibleTargets);
	     
  	DEBUGQ(main_menu done)
};


(findDisplay 46) displayAddEventHandler ["keyDown", QUOTE(_this call GVAR(keyDown))];
GVAR(keyDown) = {	
	if(_THIS1==KEY) then {
		if(!GVAR(opened)) then {
			GVAR(opened) = true;
			GVAR(possibleTargets) = [];
			if(!isNull(group cursorTarget)) then {
				ADD_START(GVAR(possibleTargets))
					cursorTarget
				ADD_END
			};
			{
				if(!(_x in GVAR(possibleTargets))) then {
					ADD_START(GVAR(possibleTargets))
						_x
					ADD_END
				}; 			 
			} forEach nearestObjects [player, ["man"], 5];
			call GVAR(menu_main);	
		};		
	};	
	false;
};


(findDisplay 46) displayAddEventHandler ["keyUp", QUOTE(_this call GVAR(keyUp))];
GVAR(keyUp) = {
	if(_THIS1==KEY) then {
		if(GVAR(opened)) then {
			GVAR(opened) = false;
			call GVAR(actions_remove);
		};
	};	
	false;
};


"group manager is active, hold T and use mousewheel to bring it up" call GVAR(msg);
