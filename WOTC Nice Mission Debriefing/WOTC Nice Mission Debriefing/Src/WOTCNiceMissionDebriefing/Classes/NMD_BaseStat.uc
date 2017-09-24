class NMD_BaseStat extends XComGameState_BaseObject;

var int Value;

function InitComponent()
{
	Value = 0;
}

function int GetValue(int UnitID)
{
	return Value; 
}

function SetValue(int Val)
{
	Value = Val;
}

function AddValue(int Amount)
{
	Value += Amount;
}

function string GetName()
{
	return "";
}

function string GetDisplayValue()
{
	return string(Value);
}

function name GetType();

function bool IsVisible()
{
	return true;
}

function bool IsPersistent()
{
	return false;
}
