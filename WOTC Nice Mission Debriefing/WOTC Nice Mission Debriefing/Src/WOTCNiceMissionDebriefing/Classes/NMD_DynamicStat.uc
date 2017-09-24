class NMD_DynamicStat extends NMD_BaseStat;

var name Type;
var string DisplayName;
var string DisplayValue;

function NMD_DynamicStat Initialize(name _Type, string _Name)
{
	Value = 0;
	Type = _Type;
	DisplayName = _Name;
	return self;
}

function string GetName()
{
	return DisplayName;
}

function SetDisplayValue(string Text)
{
	DisplayValue = Text;
}

function string GetDisplayValue()
{
	if (Len(DisplayValue) > 0)
		return DisplayValue;
	else
		return string(Value);
}

function name GetType()
{
	return Type;
}