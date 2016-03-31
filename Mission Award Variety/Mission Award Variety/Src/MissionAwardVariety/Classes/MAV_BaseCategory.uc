//  FILE:    MAV_BaseCategory
//  AUTHOR:  atamize
//  PURPOSE: Base class for all award categories
//
//--------------------------------------------------------------------------------------- 
class MAV_BaseCategory extends Object dependson(XComGameState_MissionStats_Unit);

struct EnemyDamageCount
{
	var int UnitID;
	var name Type;
	var array<MAV_DamageResult> Results;
};

struct MAV_MissionStats
{
	var array<EnemyDamageCount> EnemyDamageCounts;
	var array<XComGameState_Unit> Squad;
	var array<XComGameState_MissionStats_Unit> UnitStats;
};

var string WinnerName;
var string Label;
var array<int> Winners;

var protected array<int> Scores;


function bool HasWinner()
{
	return Winners.Length > 0;
}

function MAV_BaseCategory Initialize(string LocalizedLabel, int Size)
{
	local int i;

	for (i = 0; i < Size; ++i)
	{
		Scores.AddItem(0);
	}

	Label = LocalizedLabel;
	return self;
}

protected function int CalculateMax(array<int> List)
{
	local int CurrentMax;
	local int CurrentLeader;
	local int i, Value;

	CurrentMax = -1;
	CurrentLeader = -1;

	for (i = 0; i < List.Length; ++i)
	{
		Value = List[i];
		if (Value > CurrentMax)
		{
			CurrentMax = Value;
			CurrentLeader = i;
		}
	}

	if (CurrentMax == 0)
		return -1;

	return CurrentLeader;
}

protected function int CalculateMin(array<int> List)
{
	local int CurrentMin;
	local int CurrentLeader;
	local int i, Value;

	CurrentMin = MaxInt;
	CurrentLeader = -1;

	for (i = 0; i < List.Length; ++i)
	{
		Value = List[i];
		if (Value < CurrentMin)
		{
			CurrentMin = Value;
			CurrentLeader = i;
		}
	}

	return CurrentLeader;
}

protected function SetWinnerBasic(array<XComGameState_Unit> Units)
{
	local int Winner;

	Winner = CalculateMax(Scores);
	if (Winner >= 0)
	{
		WinnerName = Units[Winner].GetName(eNameType_FullNick);
		Winners.AddItem(Winner);
	}
}

function CalculateWinner(MAV_MissionStats MissionStats);

DefaultProperties
{
	WinnerName = "--";
}
