class NMD_BaseAward extends Object dependson(NMD_MissionInfo);

var name StatType;
var array<int> Winners;
var array<int> Losers;
var array<int> Scores;

var int MaxValue;
var int MinValue;

var string Label;
var string Tooltip;
var bool IsVisible;

function NMD_BaseAward Initialize(name Type, string DisplayName, string Tip, int Size, optional bool Visible)
{
	local int i;

	MaxValue = 0;
	MinValue = MaxInt;
	StatType = Type;
	Label = DisplayName;
	Tooltip = Tip;
	IsVisible = Visible;

	for (i = 0; i < Size; ++i)
		Scores.AddItem(0);

	return self;
}

protected function CalculateMinMax(array<int> List, NMD_MissionInfo Info)
{
	local int i, Value;
	foreach List(Value)
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

	for (i = 0; i < List.Length; ++i)
	{
		Value = List[i];
		if (Value == MaxValue && Value > 0)
		{
			Winners.AddItem(i);
			Info.AddAwardForUnit(self, i);
		}
		else if (Value == MinValue)
		{
			Losers.AddItem(i);
		}
	}
}

function DetermineWinners(NMD_MissionInfo Info)
{
	local int i, Value;
	local NMD_BaseStat Stat;

	for (i = 0; i < Info.GetSquadSize(); ++i)
	{
		Stat = Info.GetNMDUnit(i).GetStat(StatType);

		if (Stat == none)
			Value = 0;
		else
			Value = Stat.GetValue(Info.GetUnitID(i));

		Scores[i] = Value;
	}

	CalculateMinMax(Scores, Info);
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
