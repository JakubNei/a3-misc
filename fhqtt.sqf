/* FHQ TaskTracker with disabledAi=1; support
 *
 * Will work with any type of respawn.
 *
 * Filters are now saved instead of filtered units.
 * One drawback is, filters are now not complementing each other,
 * so in the example mission you would have to change west filter to 
 * { playerside == west && ! (player in units PlayerGroup) }
 *
 */
 
/* FHQ TaskTracker, forums thread
 * http://forums.bistudio.com/showthread.php?151680-FHQ-TaskTracker
 */

/* FHQ TaskTracker for the FHQ Multiplayer framework
 * 
 * This scriptset is used to create briefings and tasks, and keep track of
 * task states.
 * 
 * In general, briefings and tasks can be created for individual players, for
 * groups of players, and specific to the side or faction of the player.
 * 
 * Unit filters:
 * Whenever a unit filter is asked for, there are several possibilities to 
 * define what you need to assign to:
 * single object: A single player
 * group: All players of a group
 * side: All players of a side
 * faction (string): All players of a certain faction
 * code: The piece of code is called for every playable character. Return true if you want
 *       the character to be selected, or false otherwise. The only parameter is the playable 
 *   	 object to be tested
 * 
 * When calling a function that assigns briefings or tasks, a pool of all playable units is created.
 * The filter is tested against those units, and all units matching the filter will have the tasks/briefing
 * assigned to them. Subsequently, these units (that mached the filter) are removed from the pool. Further
 * filtering is done on the remaining units.
 * 
 * This essentially means that you should define tasks/briefing entries from specific to general. For example,
 * assuming one player group is west (whith special tasks), and the rest of the players share another set of tasks,
 * you would first use the specific group as filter value, followed by west to assign the following tasks to all
 * remaining west players.
 * 
 * Examples:
 *  {(side _this) != west): All playable characters that are not BLUFOR
 *  player: the player on the current client
 *  group westMan1_1: All units in westMan1_1's group
 * 	east: All playable characters on the OPFOR side
 *  "BIS_BAF": All playable british soliders
 * 
 * 
 * Briefing entries:
 * Briefing entries are defined as an array of two strings. The first string is the title as it
 * will appear in the middle colum when the "Notes" section is highlighted in the left colum.
 * The second string is a text that can contains links to markers, code, and some html formatting
 * and will be displayed on the right column when the title in the center column is highlited.
 * 
 * 
 * Task entries:
 * A single task entry is an array. The elements in the array are as follows:
 * String: task name 
 * String: Task text (the text that will appear in the right colum)
 * String: Task title (it will appear in the center column when "Tasks" is highlited in the left column).
 * String: optional Waypoint title (Will appear on the waypoint marker in the player's main view).
 * Object or position: The destination for this task, either an object, or a position.
 * String: Optional initial state ("created" if nothing given)
 * 
 * 
 * Commonly used examples:
 * 
 * 1. Assign a task as current task:
 * ["taskDestroy", "assigned"] call FHQ_TT_setTaskState;
 * 
 * 
 * 2. Check if a task is completed (Note, might be successful, failed or cancelled)
 * if (["taskInsert"] call FHQ_TT_isTaskCompleted) then {hint "yes";};
 * 
 * 
 * 3. Check if a task is successful
 * if (["taskDestroy"] call FHQ_TT_isTaskSuccessful) then {hint "yay";};
 * 
 * 
 * 4. Mark a task and select another task that is not completed yet.
 * ["taskDestroySecondary", "succeeded", "taskDestroyPrimary", "taskDestroySecondary", "taskExfiltrate"] 
 * 			call FHQ_TT_markTaskAndNext;
 * 
 * This example marks taskDestroySecondary as succesful, and then checks if taskDestroyPrimary is completed.
 * If not, it is set to assigned. If it is completed, it continues with the taskDestroySecondary and eventually
 * taskExfiltrate. 
 * 
 * 
 * 
 * 
 * TODO: Add possibility to change waypoint position
 */
 
FHQ_TT_init =
{
    FHQ_TT_supressTaskHints = true;
    
    /* Check for Arma 3 or 2 */
	FHQ_TT_is_arma3 = false;

	if (isClass (configfile >> "CfgAddons" >> "PreloadAddons" >> "A3")) then {
	    FHQ_TT_is_arma3 = true;
	};

	if (isServer) then
    {
        // Global list of tasks kept on the server. Always contains full info:
        // [unit filter, description, state] 
    	FHQ_TT_TaskList = [];
	};
     
	if (!isDedicated) then
	{
        // Local version of the client
        // I wonder, though, why this is necessary, since according to the documentation,
        // the effects of createSimpleTask are global
        // Anyway, [name, state, list of objects]
        FHQ_TT_ClientTaskList = [];
     
        if (isNil {player} || isNull player) then
        {
            FHQ_TT_isJIPPlayer = true;
        };
         
        [] spawn 
        {
            // Wait for join in progress
	       	waitUntil {!isNil {player}};
        	waitUntil {!isNull player};
            
           	// Wait until the task list is ready. 
           	waitUntil {!isNil "FHQ_TT_initialized"};
			FHQ_TT_TaskList call FHQ_TT_UpdateTaskList;
			FHQ_TT_supressTaskHints = false;
			"FHQ_TT_TaskList" addPublicVariableEventHandler {(_this select 1) call FHQ_TT_UpdateTaskList}; 
		};
    };
};
 
 
FHQ_TT_filterUnits =
{
    private ["_unitsArray", "_inputArray", "_outputArray"];
    
	_unitsArray = _this select 1;
    _inputArray = _this select 0; 
	_outputArray = [];
    
    switch (typename _inputArray) do
    {
        case "CODE":
        {
            // Filter all playable units by comparing them with the code
            {if (_x call _inputArray) then {_outputArray = _outputArray + [_x];};} forEach _unitsArray;
        };
        case "GROUP":
        {
            // Filter out all objects not in group
            {if (_x in units _inputArray) then {_outputArray = _outputArray + [_x];};} forEach _unitsArray;
        };
        case "OBJECT":
        {
            // Result is only the array containing the object
          	_outputArray = [_inputArray];
        };
        case "SIDE":
        {
            // Filter out all objects not belonging to side
            {if (side _x == _inputArray) then {_outputArray = _outputArray + [_x];};} forEach _unitsArray;
        };
        case "STRING":
        {
            // Filer out all objects not belonging to the faction
            {if (faction _x == _inputArray) then {_outputArray = _outputArray + [_x];};} forEach _unitsArray;
        };
	};
    
	_outputArray;
}; 
  
/* FHQ_TT_addBriefingEntry: Add a briefing entry for the given entities
 * 
 * This function adds a briefing entry for the given units. The units can be
 * supplied as either a player, a group, a side, a faction, or a piece of code.
 * All playable units will receive the given entries if they match the condition.
 * 
 * [_units, _topic, _text] call FHQ_TT_addBriefingEntry;
 * [_units, _subject, _topic, _text] call FHQ_TT_addBriefingEntry; (NOT YET IMPLEMENTED)
 * 
 * Parameters:
 * 	_units: A single unit, a group, side faction, or piece of code that will
 *          be run on all playable units.
 * 	_topic: topic to add to
 *  _text: text for this subject
 *  _subject: Subject to file this under. A new subject is created if it does not exist yet.
 * 			(optional, not yet implemented)
 * 	
 */

FHQ_TT_addBriefingEntry =
{
    private ["_units", "_subject", "_topic", "_text", "_unitsArray", "_unitPool"];
    
    _units = _this select 0;
    _subject = "Diary";
    _topic = _this select 1;
    _text = _this select 2;
    _unitPool = (if (isMultiplayer) then {playableUnits} else {switchableUnits});
    
    _unitsArray = [_units, _unitPool] call FHQ_TT_filterUnits;

    {_x createDiaryRecord [_subject, [_topic, _text]]} forEach _unitsArray;
};
 

/* Internally used to add topics to units in reversed order */
FHQ_TT_addBriefingEntries =
{
    private ["_units", "_subject", "_topics", "_count", "_i", "_topic", "_text"];
    
    _units = _this select 0;
    _subject = "Diary";
    _topics = _this select 1;
 
    _count = count _topics;
    if (_count > 0) then
    {
   		for [ {_i = _count - 1}, {_i >= 0}, {_i = _i - 1}] do
        {    
        	_topic = (_topics select _i) select 0;
            _text = (_topics select _i) select 1;
    		{_x createDiaryRecord [_subject, [_topic, _text]]} forEach _units;
        };
    };
};

/* FHQ_TT_addBriefing: Add a full briefing to the selected units.
 * 
 * This functions receives an array as input. The elements of the input array
 * are interpreted as follows:
 * If the element is a two-element array consisting of two strings, the entry is 
 * interpreted as a new briefing topic.
 * If the element is anything else, the following topics will only be presented to 
 * the units matching the element. For example, if the element is a group, the following
 * entries are added to this group only.
 * If a new unit match is encountered, the units that have been assigned targets before
 * will be removed from the pool of units being considered for future topics.
 * 
 * In other words, you can define briefings from bottom up. If you first define briefing topics
 * for a group of players, and then for a side, the side specific topics will not be added to the 
 * group. This is meant to enable you to go from specific units up to general.
 * 
 * In normal circumstances, you will most likely only define one briefing for a single group of
 * players, and thus passing only an array of string pairs.   
 */
 
FHQ_TT_addBriefing =
{
    private ["_unitPool", "_numEntries", "_currentUnits", "_currentTopicList", "_current"];
    _unitPool = (if (isMultiplayer) then {playableUnits} else {switchableUnits});
    _numEntries = count _this;
    _currentUnits = _unitPool;
    _currentTopicList = [];

    for "_i" from 0 to (_numEntries - 1) do
    {
        _current = _this select _i;

                
        if (typename _current == "ARRAY") then
        {
            // Parameter is an entry for the briefing, apply it to the _currentUnits pool
         	//   {_x createDiaryRecord ["Diary", [_current select 0, _current select 1]];} forEach _currentUnits;
            _currentTopicList = _currentTopicList + [[_current select 0, _current select 1]];
        }
        else
        {
            // Parameter is a filter for the units. Remove the _currentUnits from the pool and select
            // units according to the filter. Note: not removing anything on _i = 0
            if (_i != 0) then
            {
                _unitPool = _unitPool - _currentUnits;
            };
            
            if (count _currentTopicList > 0) then
            {
                [_currentUnits, _currentTopicList] call FHQ_TT_addBriefingEntries;
                _currentTopicList = [];
            };
            
            _currentUnits = [_current, _unitPool] call FHQ_TT_filterUnits;
        };
    };
    
    // Add any leftovers
    if (count _currentTopicList > 0) then
	{
    	[_currentUnits, _currentTopicList] call FHQ_TT_addBriefingEntries;
        _currentTopicList = [];
	};   
};


/* FHQ_TT_getTaskName
 * Internal
 */
 
FHQ_TT_getTaskName =
{
	private ["_task", "_name"];
        
    _task = (_this select 0) select 0;
	if (typename _task == "ARRAY") then 
    {
    	_name = _task select 0;
	}
	else
	{
		_name = _task;
	};
    
    _name;
};

/* FHQ_TT_createSimpleTask:
 * 
 * Internal
 */
FHQ_TT_createSimpleTask =
{
    private ["_currentUnits", "_currentTask", "_currentTaskState", "_taskObjects", "_taskName"];
    _currentUnits = _this select 0;
    _currentTask = _this select 1; // [name|[name,parent], text, title, waypoint, object/position]
    _currentTaskState = _this select 2;
	_taskObjects = [];
   
    {
    	private "_task";
        if (typename (_currentTask select 0) == "ARRAY") then 
        {
            private ["_parentTask"];
            
            _taskName = (_currentTask select 0) select 0;
            _parentTask = (_currentTask select 0) select 1;
            _task = _x createSimpleTask [_taskName, _x getVariable format["FHQ_TT_taskname_%1", _parentTask]];
        } 
        else
        { 
        	_taskName = _currentTask select 0;
           	_task = _x createSimpleTask [_currentTask select 0];
		};
                    
		_task setSimpleTaskDescription [_currentTask select 1, _currentTask select 2, _currentTask select 3];

        if (count _currentTask > 4) then
        {
			switch (typename (_currentTask select 4)) do
			{
				case "ARRAY": 
				{ 
					_task setSimpleTaskDestination (_currentTask select 4); 
				};
				case "OBJECT":
				{
					_task setSimpleTaskTarget [_currentTask select 4, true];
				};
			};
        };
                
		_task setTaskState _currentTaskState;
        if (tolower(_currentTaskState) == "assigned") then
        {
            _x setCurrentTask _task;
        };
        
        _x setVariable [format["FHQ_TT_taskname_%1", _taskName], _task, true];
        
		_taskObjects = _taskObjects + [_task];
	} forEach _currentUnits;   
    
    _taskObjects;
};

/* Internal */
FHQ_TT_addTaskEntries =
{
    private ["_currentUnits", "_tasks", "_count", "_i", "_current", "_state"];
    _currentUnits = _this select 0;
    _tasks = _this select 1;
    _count = count _tasks;
    
    if (_count > 0) then
    {
        if (FHQ_TT_is_arma3) then 
        {
            for [ {_i = 0}, {_i < _count}, {_i = _i + 1}] do                
        	{
	            _current = _tasks select _i;
            	_state = "created";
            
	            // Optional state
            	if (count _current >= 6) then
            	{
	                _state = _current select 5;
            	};
            
            	// fifth element is either an object/position, or a string. In the latter case,
            	// object/position was ommited but initial state given
            	if (count _current >= 5) then
            	{
 	               if (typename (_current select 4) == "STRING") then
 	               {
 	                   _state = _current select 4;
 	               };
	            };
             
           	 	FHQ_TT_TaskList = FHQ_TT_TaskList + [[_currentUnits, _current, _state]];
			};
        }
        else 
        {
	    	for [ {_i = _count - 1}, {_i >= 0}, {_i = _i - 1}] do                
        	{
	            _current = _tasks select _i;
            	_state = "created";
            
	            // Optional state
            	if (count _current >= 6) then
            	{
	                _state = _current select 5;
            	};
            
            	// fifth element is either an object/position, or a string. In the latter case,
            	// object/position was ommited but initial state given
            	if (count _current >= 5) then
            	{
 	               if (typename (_current select 4) == "STRING") then
 	               {
 	                   _state = _current select 4;
 	               };
	            };
             
           	 	FHQ_TT_TaskList = FHQ_TT_TaskList + [[_currentUnits, _current, _state]];
			};
		}
	};
};

/* FHQ_TT_addTasks: Add tasks to the mission
 * 
 * write me
 * 
 */
FHQ_TT_addTasks =
{
    private ["_numEntries", "_unitPool", "_currentUnits", "_currentTaskList", "_current"];
    
    if (!isServer) exitWith {};

    _numEntries = count _this;
    if (_numEntries <= 0) exitWith {};
    
	//_unitPool = (if (isMultiplayer) then {playableUnits} else {switchableUnits});
 	//_currentUnits = _unitPool;
    _currentTaskList = [];
       
    for "_i" from 0 to (_numEntries - 1) do
    {
        _current = _this select _i;
            
        if (typename _current == "ARRAY") then
        {
			_currentTaskList = _currentTaskList + [_current];
        }
        else
        {
            // Parameter is a filter for the units.
            if (_i != 0) then
            {
                //_unitPool = _unitPool - _currentUnits;
            };
            
            if (count _currentTaskList > 0) then
            {
                [_currentUnits, _currentTaskList] call FHQ_TT_addTaskEntries;
                _currentTaskList = [];
            };
            
            //_currentUnits = [_current, _unitPool] call FHQ_TT_filterUnits;
            _currentUnits = _current;
        };
    };    
    
	if (count _currentTaskList > 0) then
	{
		[_currentUnits, _currentTaskList] call FHQ_TT_addTaskEntries;
	};
    
    // Send task list to clients
    publicVariable "FHQ_TT_TaskList";
    if (!isDedicated) then
    {
    	FHQ_TT_TaskList call FHQ_TT_UpdateTaskList;
    };
    
    FHQ_TT_initialized = true;
    publicVariable "FHQ_TT_initialized";
    
};      

FHQ_TT_hasTask =
{
    private "_result";
    
    _result = false;
    
    {
        if ((_x call FHQ_TT_getTaskName) == _this) exitWith {_result = true;};
    } forEach FHQ_TT_ClientTaskList;
    
    _result;
};


FHQ_TT_taskHint =
{
    if (!FHQ_TT_is_arma3) then 
    {
        /* Arma 2 */
    	private ["_desc", "_state", "_color", "_icon", "_text"];
    
	    _desc = _this select 0;
	    _state = _this select 1;
    
		_color = [1, 1, 1, 1];
		_icon = "taskNew";
		_text = "New Task";

		switch (tolower(_state)) do
		{
			case "created":
			{
				_color = [1, 1, 1, 1];
				_icon = "taskNew";
				_text = localize "str_taskNew";
			};
			case "assigned":
			{
				_color = [1, 1, 1, 1];
				_icon = "taskCurrent";
			 	_text = localize "str_taskSetCurrent";
			};
			case "succeeded":
			{
				_color = [0.600000,0.839215,0.466666,1];
				_icon = "taskDone";
				_text = localize "str_taskAccomplished";
			};
			case "canceled":
			{
				_color = [0.75,0.75,0.75,1];
				_icon = "taskFailed";
				_text = localize "str_taskCancelled";
			};
			case "cancelled":
			{
				_color = [0.75,0.75,0.75,1];
				_icon = "taskFailed";
				_text = localize "str_taskCancelled";
			};
			case "failed":
			{
				_color = [0.972549,0.121568,0,1];
				_icon = "taskFailed";
				_text = localize "str_taskFailed";
			};
		};
    
	    taskHint [format ["%1\n%2", _text, _desc], _color, _icon];
	}
    else
    {
        /* Arma 3 */
        private ["_notifyTemplate", "_desc", "_state"];
        
        _desc = _this select 0;
	    _state = _this select 1;
        
        switch (tolower _state) do 
        {
			case "created":
            {
                _notifyTemplate = "TaskCreated";
            };
			case "assigned":
            {
                _notifyTemplate = "TaskAssigned";
            };
			case "succeeded":
            {
                _notifyTemplate = "TaskSucceeded";
            };
			case "canceled":
            {
                _notifyTemplate = "TaskCanceled";
            };
			case "cancelled":
            {
                _notifyTemplate = "TaskCanceled";
            };
			case "failed":
            {
                _notifyTemplate = "TaskFailed";
            };
		};
        
        [_notifyTemplate, ["", _desc]] call BIS_fnc_showNotification;
	};
};


FHQ_TT_UpdateTaskList =
{
    if (isDedicated) exitWith {};
    
    private ["_count", "_i", "_tasks"];
    _tasks = _this;
    _count = count _tasks;

    _unitPool = (if (isMultiplayer) then {playableUnits} else {switchableUnits});
    
    if (_count > 0) then
    {
    	for [ {_i = 0}, {_i < _count}, {_i = _i + 1}] do                
        {
            private ["_current", "_currentUnits", "_taskObjects", "_currentTask",
            		"_currentTaskState", "_currentTaskName", "_currentTaskParent"];
            _current = _tasks select _i; // [units, taskDesc, state]
            _currentTask = _current select 1; // [name|[name,parent], text, title, waypoint, object/position]
            _currentUnits = _current select 0;
            _currentTaskState = _current select 2;
            _currentTaskName = "";
            _currentTaskParent = "";
            
            _currentUnits = [_currentUnits, _unitPool] call FHQ_TT_filterUnits; 
            
            if (typename (_currentTask select 0) == "ARRAY") then 
            {
                _currentTaskName = (_currentTask select 0) select 0;
                _currentTaskParent = (_currentTask select 0) select 1; 
            }
            else
            {
                _currentTaskName = _currentTask select 0;
            };

            if (_currentTaskName call FHQ_TT_hasTask) then
            {
                private ["_localTask", "_x", "_task"];
                 
				_localTask = FHQ_TT_ClientTaskList select _i; // [name, state, objects]
                diag_log format["_localTask -> %1, _curent -> %2", _localTask select 1, _current select 2];
                if ((_current select 2) != (_localTask select 1)) then
                {
					// Update the task
                    _localTask set [1, _current select 2];
                    FHQ_TT_ClientTaskList set [_i, _localTask];
					
                    if (player in (_currentUnits)) then
                    {
						[_currentTask select 2, _current select 2] call FHQ_TT_taskHint;
                    };  
                    
					{
                        _task = _x;
                        if (_current select 2 == "assigned") then
                        {
                    		{
                         		if (_task in (simpletasks _x)) then
                        		{
	                            	_x setCurrentTask _task;
                        		};
                           	} forEach _currentUnits;
                        };
                    	_task setTaskState (_current select 2);
                    } forEach (_localTask select 2);   
				}; 
             } 
             else
             {
            	_taskObjects = [_currentUnits, _currentTask, _currentTaskState] call FHQ_TT_createSimpleTask;
               	FHQ_TT_ClientTaskList set  [_i, [(_current select 1), _currentTaskState, _taskObjects]];
                if (player in (_currentUnits) && !FHQ_TT_supressTaskHints) then
                {
					[_currentTask select 2, _currentTaskState] call FHQ_TT_taskHint;
				};  
                    
             };
		};
	}; 
};

/* FHQ_TT_setTaskState: Set state of a specific task
 * 
 * write me
 * 
 * [_taskName, _state] call FHQ_TT_setTaskState;
 */

FHQ_TT_setTaskState = 
{
    if (!isServer) exitWith {};
    
    private ["_count", "_taskName", "_newState", "_i", "_curTask"];
    
    _count = count FHQ_TT_TaskList;
    _taskName = _this select 0;
    _newState = _this select 1;
     
	for [ {_i = 0}, {_i < _count}, {_i = _i + 1}] do
    {
        _curTask = FHQ_TT_TaskList select _i;
        diag_log format["_curTask = %1", _curTask];
        
        //if (_taskName == ((_curTask select 1) select 0)) exitWith
        if (_taskName == ([_curTask select 1] call FHQ_TT_getTaskName)) exitWith
        { 
            _curTask set [2, _newState];
            FHQ_TT_TaskList set [_i, _curTask];
        };
   	};
    
    publicVariable "FHQ_TT_TaskList";
    if (!isDedicated) then
    {
    	FHQ_TT_TaskList call FHQ_TT_UpdateTaskList;
    };
};


/* FHQ_TT_getTaskState: Get state of a specific task
 * 
 * write me
 * 
 * _result = [_taskName] call FHQ_TT_getTaskState;
 */
FHQ_TT_getTaskState =
{
	private ["_result", "_taskName"];
    
    _result = "";
    _taskName = _this select 0;
    
    {
	//	if (((_x select 1) select 0) == _taskname) exitWith
        if (([_x select 1] call FHQ_TT_getTaskName) == _taskname) exitWith
        {
            _result = (_x select 2);
        };
    } forEach FHQ_TT_TaskList;
    
    _result;
};

/* FHQ_TT_isTaskCompleted: Check whether a task is canceled, successful or failed
 * 
 * _result = [_taskName] call FHQ_TT_isTaskCompleted;
 */
FHQ_TT_isTaskCompleted =
{
    private "_result";

    _result = (tolower(_this call FHQ_TT_getTaskState) in ["succeeded", "canceled", "failed"]);
    
    _result;    
};

/* FHQ_TT_areTasksCompleted: Check for all tasks given whether they are cancelled, successful, or failed
 * _result = [_taskName1, _taskName2, ...] call FHQ_TT_areTasksCompleted
 */
FHQ_TT_areTasksCompleted =
{
    private ["_result", "_x"];
    
    _result = true;
    
     {
         if (!(tolower ([_x] call FHQ_TT_getTaskState) in ["succeeded", "canceled", "failed"])) exitWith 
         {
             _result = false;
         };
     } forEach _this;
     
     _result;
};

/* FHQ_TT_isTaskSuccessful: Check whether a task is ended successfully
 * 
 * _result = [_taskName] call FHQ_TT_isTaskSuccessful;
 */
FHQ_TT_isTaskSuccessful = 
{
    private "_result";
    
    _result = (tolower(_this call FHQ_TT_getTaskState) == "succeeded");
    
    _result;
};

/* FHQ_TT_areTasksSuccessful: Check success for all tasks given
 * _result = [_taskName1, _taskName2, ...] call FHQ_TT_areTasksSuccessful
 */
FHQ_TT_areTasksSuccessful =
{
    private ["_result", "_x"];
    
    _result = true;
    
     {
         if (tolower ([_x] call FHQ_TT_getTaskState) != "succeeded") exitWith 
         {
             _result = false;
         };
     } forEach _this;
     
     _result;
};
    
 
/* FHQ_TT_getAllTasksWithState: Get all tasks with a given state
 * 
 * _taskList = [_state] call FHQ_TT_getAllTasksWithState;
 */
FHQ_TT_getAllTasksWithState =
{
    private ["_result", "_taskState"];
    
	_result = [];
    _taskState = _this select 0;
    
    {
        if ((_x select 2) == _taskState) then
        {
            _result = _result + [(_x select 1) select 0];
        };
    } forEach FHQ_TT_TaskList;
    
    _result;   	
};

/* FHQ_TT_markTaskAndNext: Mark a task as completed, and look for the next 
 *                         open task.
 * 
 * ["taskName", "state", ("newTask1", "newTask2" ... )] call FHQ_TT_markTaskAndNext;
 */
FHQ_TT_markTaskAndNext =
{
    private "_i";
    [_this select 0, _this select 1] call FHQ_TT_setTaskState;
    
    for [ {_i = 2}, {_i < count _this}, {_i = _i + 1} ] do
    {
        if (!([_this select _i] call FHQ_TT_isTaskCompleted)) exitWith
        {
            [_this select _i, "assigned"] call FHQ_TT_setTaskState;
        };
    };
    
};

/* ------------ End of file, calling init ------------ */
call FHQ_TT_init;
