class NMD_MissionInfo extends Object dependson(XComGameState_NMD_Unit);

struct EnemyDamageCount
{
	var int UnitID;
	var name Type;
	var array<NMD_DamageResult> Results;
};

struct NMD_UnitInfo
{
	var XComGameState_Unit Unit;
	var XComGameState_NMD_Unit NMDUnit;
	var array<NMD_BaseAward> Awards;
};

var array<EnemyDamageCount> EnemyDamageCounts;
var array<NMD_UnitInfo> UnitInfo;
var array<NMD_BaseAward> Awards;

var int MVPIndex;
var array<int> MVPWinners;

delegate int UnitInfoIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit);

function Initialize(array<XComGameState_Unit> Squad)
{
	local NMD_UnitInfo UInfo;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;

	foreach Squad(Unit)
	{
		NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));
		if (NMDUnit != none)
		{
			UInfo.Unit = Unit;
			UInfo.NMDUnit = NMDUnit;
			UnitInfo.AddItem(UInfo);
		}
	}

	DetermineEnemyDamageCounts();
	DetermineAwards();
}

function name GetUnitType(XComGameState_Unit Unit)
{
	local name TemplateName;

	TemplateName = Unit.GetMyTemplateName();

	switch (TemplateName)
	{
		case 'Civilian':
		case 'HostileCivilian':
		case 'HostileVIPCivilian':
		case 'FriendlyVIPCivilian':
			return 'CIVILIANS';
	}

	if (Unit.GetTeam() == eTeam_Resistance)
	{
		return 'RESISTANCE';
	}

	return name(Unit.GetFullName());
}

function DetermineEnemyDamageCounts()
{
	local int i, j, k, UnitID;
	local EnemyDamageCount Entry;
	local NMD_DamageResult NewResult;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;
	local XComGameStateHistory History;
	local bool Found;

	History = `XCOMHISTORY;

	for (i = 0; i < UnitInfo.Length; ++i)
	{
		NMDUnit = UnitInfo[i].NMDUnit;
		for (j = 0; j < NMDUnit.EnemyDamageResults.Length; ++j)
		{
			UnitID = NMDUnit.EnemyDamageResults[j].UnitID;

			NewResult.UnitID = i;
			NewResult.Damage = NMDUnit.EnemyDamageResults[j].Damage;
			NewResult.Killed = NMDUnit.EnemyDamageResults[j].Killed;

			Found = false;
			for (k = 0; k < EnemyDamageCounts.Length; ++k)
			{
				if (EnemyDamageCounts[k].UnitID == UnitID)
				{
					EnemyDamageCounts[k].Results.AddItem(NewResult);
					Found = true;
					break;
				}
			}

			if (!Found)
			{
				Entry.UnitID = UnitID;

				Unit = XComGameState_Unit(History.GetGameStateForObjectId(UnitID));
				Entry.Type = GetUnitType(Unit);
				Entry.Results.AddItem(NewResult);
				EnemyDamageCounts.AddItem(Entry);
			}
		}
	}
}

function int GetSquadSize()
{
	return UnitInfo.Length;
}

function XComGameState_Unit GetUnit(int Index)
{
	return UnitInfo[Index].Unit;
}

function XComGameState_NMD_Unit GetNMDUnit(int Index)
{
	return UnitInfo[Index].NMDUnit;
}

function int GetUnitID(int Index)
{
	return UnitInfo[Index].Unit.ObjectID;
}

function IterateUnits(delegate<UnitInfoIterator> Iter, out array<int> Scores)
{
	local int i, Value;

	for (i = 0; i < UnitInfo.Length; ++i)
	{
		Value = Iter(UnitInfo[i].Unit, UnitInfo[i].NMDUnit);
		Scores[i] = Value;
	}
}

function AddAwardForUnit(NMD_BaseAward Award, int Index)
{
	UnitInfo[Index].Awards.AddItem(Award);
}

private function NMD_BaseAward AddAward(NMD_BaseAward Award, name Type, string Label, string Tooltip, optional bool IsVisible = true)
{
	Award.Initialize(Type, Label, Tooltip, UnitInfo.Length, IsVisible);
	Awards.AddItem(Award);
	return Award;
}

function DetermineAwards()
{
	local NMD_BaseAward Award;

	AddAward(new class'NMD_BaseAward', class'NMD_Stat_Kills'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_ShotAccuracy'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_DamageDealt'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_TilesMoved'.const.ID, "MOVED FURTHEST", "Traversed the most tiles");
	AddAward(new class'NMD_Award_MostAssists', '', "MOST ASSISTS", "Dealt the most damage that did not result in a kill");
	AddAward(new class'NMD_Award_SoloSlayer', '', "SOLO SLAYER", "Killed the most enemies without help from teammates");
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_CloseRange'.const.ID, "CLOSE RANGE?!", "Dealt the most damage at...close range");

	foreach Awards(Award)
	{
		Award.DetermineWinners(self);
	}

	MVPIndex = DetermineMVP();
}

function int AwardLengthSorter(int i)
{
	return UnitInfo[i].Awards.Length;
}

function int KillSorter(int i)
{
	local int Index;
	Index = MVPWinners[i];
	return UnitInfo[Index].NMDUnit.GetStat(class'NMD_Stat_Kills'.const.ID).GetValue(UnitInfo[Index].Unit.ObjectID);
}

function int DamageSorter(int i)
{
	local int Index;
	Index = MVPWinners[i];
	return UnitInfo[Index].NMDUnit.GetStat(class'NMD_Stat_DamageDealt'.const.ID).GetValue(UnitInfo[Index].Unit.ObjectID);
}

function int AccuracySorter(int i)
{
	local int Index;
	Index = MVPWinners[i];
	return UnitInfo[MVPWinners[i]].NMDUnit.GetStat(class'NMD_Stat_ShotAccuracy'.const.ID).GetValue(UnitInfo[Index].Unit.ObjectID);
}

function int RankSorter(int i)
{
	return UnitInfo[MVPWinners[i]].Unit.GetSoldierRank();
}

function int DetermineMVP()
{
	local array<int> TieBreaker;

	MVPWinners.Length = 0;

	class'NMD_Utilities'.static.FindMax(AwardLengthSorter, UnitInfo.Length, MVPWinners);

	if (MVPWinners.Length == 1)
	{
		return MVPWinners[0];
	}
	
	// Tie break
	class'NMD_Utilities'.static.FindMax(KillSorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return TieBreaker[0];
	}

	class'NMD_Utilities'.static.FindMax(DamageSorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return TieBreaker[0];
	}

	class'NMD_Utilities'.static.FindMax(AccuracySorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return TieBreaker[0];
	}

	class'NMD_Utilities'.static.FindMax(RankSorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return TieBreaker[0];
	}

	return 0;
}

function NMD_BaseAward GetAwardForStat(name Type)
{
	local NMD_BaseAward Award;

	foreach Awards(Award)
	{
		if (Award.StatType == Type)
		{
			return Award;
		}
	}
	return none;
}