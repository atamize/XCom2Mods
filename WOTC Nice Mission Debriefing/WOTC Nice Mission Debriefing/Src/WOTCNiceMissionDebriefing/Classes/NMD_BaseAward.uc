class NMD_BaseAward extends Object;

var name StatType;
var array<int> Winners;
var string Label;
var string Tooltip;

function NMD_BaseAward Initialize(name Type, string DisplayName, string Tip)
{
	StatType = Type;
	Label = DisplayName;
	Tooltip = Tip;
	return self;
}

protected function int CalculateMax(array<int> List)
{
	local int CurrentMax;
	local int i, Value;

	CurrentMax = -1;

	for (i = 0; i < List.Length; ++i)
	{
		Value = List[i];
		if (Value > CurrentMax)
		{
			CurrentMax = Value;
		}
	}

	if (CurrentMax == 0)
		return -1;

	return CurrentMax;
}

protected function int CalculateMin(array<int> List)
{
	local int CurrentMin;
	local int i, Value;

	CurrentMin = MaxInt;

	for (i = 0; i < List.Length; ++i)
	{
		Value = List[i];
		if (Value < CurrentMin)
		{
			CurrentMin = Value;
		}
	}

	if (CurrentMin == MaxInt)
		return -1;

	return CurrentMin;
}

function DetermineWinnerMax(array<XComGameState_Unit> Squad, array<int> Scores)
{
	local int Maxi, i;
	
	Maxi = CalculateMax(Scores);
	if (Maxi >= 0)
	{
		for (i = 0; i < Squad.Length; ++i)
		{
			if (Scores[i] == Maxi)
			{
				Winners.AddItem(i);
			}
		}
	}
}

function DetermineWinnerMin(array<XComGameState_Unit> Squad, array<int> Scores)
{
	local int Mini, i;
	
	Mini = CalculateMin(Scores);

	for (i = 0; i < Squad.Length; ++i)
	{
		if (Scores[i] == Mini)
		{
			Winners.AddItem(i);
		}
	}
}

function array<int> DetermineScores(array<XComGameState_Unit> Squad)
{
	local array<int> Scores;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUNit;
	local NMD_BaseStat Stat;

	foreach Squad(Unit)
	{
		NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));
		Stat = NMDUnit.GetStat(StatType);
		Scores.AddItem(Stat.GetValue());
	}

	return Scores;
}

function DetermineWinners(array<XComGameState_Unit> Squad)
{
	local array<int> Scores;

	Scores = DetermineScores(Squad);
	DetermineWinnerMax(Squad, Scores);
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
