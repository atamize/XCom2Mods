class NMD_BaseStat extends XComGameState_BaseObject;

var bool IsPersistent;

function InitComponent() {}
function int GetValue() { return 0; }
function int GetMVPValue() { return GetValue(); }
function string GetName();
function string GetDisplayValue();
function name GetType();
function bool IsVisible() { return true; }

defaultProperties
{
	IsPersistent=false
}
