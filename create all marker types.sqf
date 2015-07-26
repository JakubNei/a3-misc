/*
just execute this file, it will create all marker types that exist with their names under them
*/

_start=[100,3000];
_config=configfile >> "cfgMarkers";
_count=count _config;
_widthcount=6;
_widthspace=500;
_heightcount=ceil(_count/_widthcount); 
_heightspace=80;


for "_i" from 0 to 10 do {
	_marker = format["bg%1",_i];
	deleteMarkerLocal _marker;
	createMarkerLocal[ _marker, [(_start select 0) + _widthspace*_widthcount/2 , (_start select 1) - _heightspace*_heightcount/2 ] ];
	_marker setMarkerShapeLocal "RECTANGLE";
	_marker setMarkerColorLocal "ColorWhite";
	_marker setMarkerAlphaLocal 1;
	_marker setMarkerBrushLocal "Solid";
	_marker setMarkerSizeLocal [_widthspace*_widthcount, _heightspace*_heightcount]; 
};

	
_start = [(_start select 0) + _widthspace/2, (_start select 1) - _heightspace/2];
for "_i" from 0 to _count-1 do {
	_current = _config select _i;
	_x =(_start select 0)+ _widthspace*(_i mod _widthcount);
	_y = (_start select 1) - _heightspace*floor(_i/_widthcount);
	
	_marker = format["tm%1",_i];
	deleteMarkerLocal _marker;
	createMarkerLocal[ _marker, [_x,_y]];
	_marker setMarkerSizeLocal [0.9, 0.9];
	_marker setMarkerTypeLocal (configName _current);

	_marker = format["tmt%1",_i];
	deleteMarkerLocal _marker;
	createMarkerLocal[ _marker, [_x+50,_y] ];
	_marker setMarkerTypeLocal "hd_dot";
	_marker setMarkerColorLocal "ColorBlack";
	_marker setMarkerSizeLocal [0, 0];
	_marker setMarkerTextLocal (configName _current); 
};
