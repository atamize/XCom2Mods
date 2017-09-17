class NMD_BaseAward extends Object;

var name StatType;
var array<int> Winners;
var array<int> Losers;

var int MaxValue;
var int MinValue;

var string Label;
var string Tooltip;
var bool IsVisible;

function NMD_BaseAward Initialize(name Type, string DisplayName, string Tip, optional bool Visible)
{
	MaxValue = 0;
	MinValue = MaxInt;
	StatType = Type;
	Label = DisplayName;
	Tooltip = Tip;
	IsVisible = Visible;
	return self;
}

function DetermineWinners(array<XComGameState_Unit> Squad)
{
	local array<int> Scores;
	local int i, Value;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUNit;
	local NMD_BaseStat Stat;

	foreach Squad(Unit)
	{
		NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));
		Stat = NMDUnit.GetStat(StatType);

		if (Stat == none)
			Value = 0;
		else
			Value = Stat.GetValue();

		Scores.AddItem(Value);
	}

	foreach Scores(Value)
	{
		if (Value > MaxValue)
		{
			MaxValue = Value;
		}
		if (Value < MinValue)
		{
			MinValue = Value;
		}
	}	

	for (i = 0; i < Scores.Length; ++i)
	{
		Value = Scores[i];
		if (Value == MaxValue)
		{
			Winners.AddItem(i);
		}
		else if (Value == MinValue)
		{
			Losers.AddItem(i);
		}
	}
}

function bool HasWinner()
{
	return MaxValue > 0;
}

function bool IsWinner(int Index)
{
	local int i;

	for (i = 0; i < Winners.Length; ++i)
	{
		if (Winners[i] == Index)
		{
			return true;
		}
	}

	return false;
}
