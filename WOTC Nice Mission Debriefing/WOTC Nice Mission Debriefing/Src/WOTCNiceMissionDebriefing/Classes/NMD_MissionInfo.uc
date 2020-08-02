class NMD_MissionInfo extends Object dependson(XComGameState_NMD_Unit);

var localized string m_strHeavyHitter;
var localized string m_strHeavyHitterDesc;
var localized string m_strSneakiest;
var localized string m_strSneakiestDesc;
var localized string m_strTimeToBleed;
var localized string m_strTimeToBleedDesc;
var localized string m_strTimeToBleedRobot;
var localized string m_strRunningOverwatch;
var localized string m_strRunningOverwatchDesc;
var localized string m_strMostExposed;
var localized string m_strMostExposedDesc;
var localized string m_strCloseRange;
var localized string m_strCloseRangeDesc;
var localized string m_strMostHigh;
var localized string m_strMostHighDesc;
var localized string m_strMostAssists;
var localized string m_strMostAssistsDesc;
var localized string m_strSoloSlayer;
var localized string m_strSoloSlayerDesc;
var localized string m_strKillStealer;
var localized string m_strKillStealerDesc;
var localized string m_strNotBadKid;
var localized string m_strNotBadKidDesc;
var localized string m_strWantonDestruction;
var localized string m_strWantonDestructionDesc;
var localized string m_strPartingGift;
var localized string m_strPartingGiftDesc;
var localized string m_strTooOld;
var localized string m_strTooOldDesc;
var localized string m_strOverqualified;
var localized string m_strOverqualifiedDesc;

var localized string m_strKills;
var localized string m_strDamageDealt;
var localized string m_strShots;
var localized string m_strOverwatchAccuracy;
var localized string m_strTilesMoved;
var localized string m_strHeadshots;
var localized string m_strLootPickedUp;
var localized string m_strMostHatedUnit;

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

struct HateCount
{
	var name Type;
	var int Damage;
};

var array<EnemyDamageCount> EnemyDamageCounts;
var array<NMD_UnitInfo> UnitInfo;
var array<NMD_BaseAward> Awards;

var int MVPIndex;
var array<int> MVPWinners;

var array<HateCount> HateCounts;

delegate int UnitInfoIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit);

function Initialize(array<XComGameState_Unit> Squad)
{
	local NMD_UnitInfo UInfo;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;

	foreach Squad(Unit)
	{
		NMDUnit = class'NMD_Utilities'.static.FindUnitStats(Unit);
		if (NMDUnit != none)
		{
			UInfo.Unit = Unit;
			UInfo.NMDUnit = NMDUnit;

			AddLootStat(Unit, NMDUnit);
			AddMostHatedStat(Unit, NMDUnit);

			UnitInfo.AddItem(UInfo);
		}
	}

	DetermineEnemyDamageCounts();
	DetermineAwards();
}

function AddLootStat(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local NMD_DynamicStat Stat;
	local array<XComGameState_Item> BackpackItems; 

	Stat = new class'NMD_DynamicStat';
	Stat.Initialize('LootPickedUp', m_strLootPickedUp);

	if (Unit.HasBackpack())
	{
		BackpackItems = Unit.GetAllItemsInSlot(eInvSlot_Backpack);
		if (class'NMD_Utilities'.default.bLog) `LOG("NMD - " $ Unit.GetFullName() $ " has loot: " $ BackpackItems.Length);
		Stat.SetValue(BackpackItems.Length);
	}

	NMDUnit.AddDynamicStat(Stat);
}

function int GetHateValue(int i)
{
	return HateCounts[i].Damage;
}

function AddMostHatedStat(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local int i, j, UnitID;
	local HateCount Hate;
	local XComGameState_Unit DamagedUnit;
	local XComGameStateHistory History;
	local name Type;
	local bool Found;
	local array<int> MostHatedIndices;
	local NMD_DynamicStat Stat;

	History = `XCOMHISTORY;
	HateCounts.Length = 0;
	Stat = new class'NMD_DynamicStat';
	Stat.Initialize('MostHatedUnit', m_strMostHatedUnit);

	for (i = 0; i < NMDUnit.EnemyDamageResults.Length; ++i)
	{
		UnitID = NMDUnit.EnemyDamageResults[i].UnitID;
		DamagedUnit = XComGameState_Unit(History.GetGameStateForObjectId(UnitID));
		Type = GetUnitType(DamagedUnit);
		Found = false;

		for (j = 0; j < HateCounts.Length; ++j)
		{
			if (HateCounts[j].Type == Type)
			{
				HateCounts[j].Damage += NMDUnit.EnemyDamageResults[i].Damage;
				Found = true;
				break;
			}
		}

		if (!Found)
		{
			Hate.Type = Type;
			Hate.Damage = NMDUnit.EnemyDamageResults[i].Damage;
			HateCounts.AddItem(Hate);
		}
	}

	class'NMD_Utilities'.static.FindMax(GetHateValue, HateCounts.Length, MostHatedIndices);

	if (MostHatedIndices.Length > 0)
	{
		Stat.SetDisplayValue(string(HateCounts[MostHatedIndices[0]].Type));
	}
	else
	{
		Stat.SetDisplayValue("--");
	}

	NMDUnit.AddDynamicStat(Stat);
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

private function NMD_BaseAward AddAward(NMD_BaseAward Award, name Type, string Label, string Tooltip, optional bool IsVisible = true, optional bool HideIfNoWinner = false)
{
	Award.Initialize(Type, Label, Tooltip, UnitInfo.Length, IsVisible, HideIfNoWinner);
	Awards.AddItem(Award);
	return Award;
}

function DetermineAwards()
{
	local NMD_BaseAward Award;

	// Stat-based awards
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_Kills'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_ShotAccuracy'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_OverwatchAccuracy'.const._ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_DamageDealt'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_TilesMoved'.const.ID, "", "", false);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_Headshots'.const.ID, "", "", false, true);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_CloseRange'.const.ID, m_strCloseRange, m_strCloseRangeDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_ShotsFromElevation'.const.ID, m_strMostHigh, m_strMostHighDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_CriticalDamage'.const.ID, m_strHeavyHitter, m_strHeavyHitterDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_ConcealedTiles'.const.ID, m_strSneakiest, m_strSneakiestDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_OverwatchRuns'.const.ID, m_strRunningOverwatch, m_strRunningOverwatchDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_Exposure'.const.ID, m_strMostExposed, m_strMostExposedDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_EnvironmentDamage'.const.ID, m_strWantonDestruction, m_strWantonDestructionDesc);
	AddAward(new class'NMD_BaseAward', class'NMD_Stat_EvacDamage'.const.ID, m_strPartingGift, m_strPartingGiftDesc);
	AddAward(new class'NMD_Award_TimeToBleed', class'NMD_Stat_WoundedDamage'.const.ID, m_strTimeToBleed, m_strTimeToBleedDesc);

	// Non stat-based awards
	AddAward(new class'NMD_Award_MostAssists', '', m_strMostAssists, m_strMostAssistsDesc);
	AddAward(new class'NMD_Award_SoloSlayer', '', m_strSoloSlayer, m_strSoloSlayerDesc);
	AddAward(new class'NMD_Award_KillStealer', '', m_strKillStealer, m_strKillStealerDesc);
	AddAward(new class'NMD_Award_NotBadKid', '', m_strNotBadKid, m_strNotBadKidDesc);
	AddAward(new class'NMD_Award_TooOld', '', m_strTooOld, m_strTooOldDesc);
	AddAward(new class'NMD_Award_Overqualified', '', m_strOverqualified, m_strOverqualifiedDesc);

	// Dynamic awards
	AddAward(new class'NMD_BaseAward', 'LootPickedUp', "", "", false);

	foreach Awards(Award)
	{
		Award.DetermineWinners(self);
	}

	MVPIndex = DetermineMVP();
}

function int AwardLengthSorter(int i)
{
	if (class'NMD_Utilities'.default.bLog) `LOG("NMD - " $ UnitInfo[i].Unit.GetFullName() $ " has awards: " $ UnitInfo[i].Awards.Length);
	return UnitInfo[i].Awards.Length;
}

function int KillSorter(int i)
{
	local int Index;
	local int Kills;
	Index = MVPWinners[i];
	Kills = UnitInfo[Index].NMDUnit.GetStat(class'NMD_Stat_Kills'.const.ID).GetValue(UnitInfo[Index].Unit.ObjectID);
	if (class'NMD_Utilities'.default.bLog) `LOG("NMD - Kills for Unit " $ UnitInfo[Index].Unit.GetFullName() $ ": " $ Kills);
	return Kills;
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
		return MVPWinners[TieBreaker[0]];
	}

	TieBreaker.Length = 0;
	class'NMD_Utilities'.static.FindMax(DamageSorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return MVPWinners[TieBreaker[0]];
	}

	TieBreaker.Length = 0;
	class'NMD_Utilities'.static.FindMax(AccuracySorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return MVPWinners[TieBreaker[0]];
	}

	TieBreaker.Length = 0;
	class'NMD_Utilities'.static.FindMax(RankSorter, MVPWinners.Length, TieBreaker);
	if (TieBreaker.Length == 1)
	{
		return MVPWinners[TieBreaker[0]];
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