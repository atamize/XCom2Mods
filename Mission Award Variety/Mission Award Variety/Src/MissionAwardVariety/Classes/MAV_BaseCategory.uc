//  FILE:    MAV_BaseCategory
//  AUTHOR:  atamize
//  PURPOSE: Base class for all award categories
//
//--------------------------------------------------------------------------------------- 
class MAV_BaseCategory extends Object dependson(XComGameState_MissionStats_Unit, XComGameState_MissionStats_Root);

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
	var array<MAV_UnitStats> UnitStats;
};

var string WinnerName;
var string Label;
var array<int> Winners;

var array<int> Scores;


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

function string GetName(XComGameState_Unit Unit, optional bool Nick = true)
{
	local string charName;

	if (Unit.IsSoldier())
		return Unit.GetName(Nick ? eNameType_FullNick : eNameType_Full);
	
	if (Unit.IsCivilian())
		return Unit.GetFullName();

	// Name Your Pet mod lets you name mind-controlled enemies, but you
	// have to manually get their last name, otherwise their template name is used
	charName = Unit.GetLastName();
	
	if (len(charName) > 0)
		return charName;

	return Unit.GetMyTemplate().strCharacterName;
}

function SetWinnerBasic(array<XComGameState_Unit> Units)
{
	local int Winner;

	Winner = CalculateMax(Scores);
	if (Winner >= 0)
	{
		WinnerName = GetName(Units[Winner]);
		Winners.AddItem(Winner);
	}
}

function SetWinnerMin(array<XComGameState_Unit> Units)
{
	local int Winner;

	Winner = CalculateMin(Scores);
	if (Winner >= 0)
	{
		WinnerName = GetName(Units[Winner]);
		Winners.AddItem(Winner);
	}
}

function CalculateWinner(MAV_MissionStats MissionStats);

DefaultProperties
{
	WinnerName = "--";
}
