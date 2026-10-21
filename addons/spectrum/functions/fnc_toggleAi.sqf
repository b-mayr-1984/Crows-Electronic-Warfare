#include "script_component.hpp"
/*/////////////////////////////////////////////////
Author: Crowdedlight
			   
File: fnc_toggleAi.sqf
Parameters: _unit
Return: none

Called to enable or disable AI

*///////////////////////////////////////////////
params [["_unit", objNull], ["_enable", false]];

// only run on where the unit is local
if (!local _unit) exitWith {};

if (_enable) then {
	{
		_x enableAI "all";
	} forEach (crew _unit);

	if (_unit isKindOf "Air") then {
		// cancel pulling force
		private _PFH_handle = _unit getVariable[QGVAR(aiPullForceHandle), -1];
		[_PFH_handle] call CBA_fnc_removePerFrameHandler;
	};
} else {
	{
		_x disableAI "all";
	} forEach (crew _unit);

	if ((_unit isKindOf "Air") && (isEngineOn _unit)) then {
		// add a pull down force to make drone land
		_unit setVariable[QGVAR(aiPullForce), -20, true];	// initialize pull force; this will be updated in the PFH
		private _PFH_handle = [{
			params ["_args", "_handle"];
			_args params ["_drone"];
			if ((!alive _drone) || ((getPos _drone select 2) < 0.1)) then { 
				[_handle] call CBA_fnc_removePerFrameHandler; 	// exit loop
				diag_log format ["CrowsEW:fnc_toggleAi: Drone %1 is dead or on ground, removing pull force PFH", _drone];
			};
			// calculate and apply pull down force
			private _sinkrateFactor = -2;	// factor to control sinkrate in m/s; negative value means drone will sink down
			if ((getPos _drone select 2) < 3) then {	// when drone is near ground
				(driver _drone) action ["LandGear", _drone];	// lower landing gear (needed for MQ-12 Falcon)
				_drone engineOn false;	// turn off engine
				_sinkrateFactor = -0.5;	// slow down sink rate near ground
			};
			private _pullForce = _drone getVariable[QGVAR(aiPullForce), 0];
			private _sinkrate = velocity _drone select 2;
			// TODO: special case when sinkrate is positive
			_pullForce = (_pullForce * _sinkrateFactor/(_sinkrate min -0.1) min -1.5);	// control sinkrate to be around _sinkrateFactor in m/s
			_drone addForce [[0,0,_pullForce], [0,0,0]];
			_drone setVariable[QGVAR(aiPullForce), _pullForce, true];	// store updated pull force
		}, 0, [_unit]] call CBA_fnc_addPerFrameHandler;
		_unit setVariable[QGVAR(aiPullForceHandle), _PFH_handle, true];
	};
};
