class NMD_BaseStat extends XComGameState_BaseObject;

function InitComponent() {}
function int GetValue(int UnitID) { return 0; }
//function int GetMVPValue() { return GetValue(); }
function string GetName();
function string GetDisplayValue();
function name GetType();
function bool IsVisible() { return true; }
function bool IsPersistent() { return false; }
