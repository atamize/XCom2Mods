//---------------------------------------------------------------------------------------
//  FILE:    MAV_UITacticalHUD_ScreenListener
//  AUTHOR:  atamize
//  PURPOSE: Calculates award winners and displays them on the mission end screen
//
//--------------------------------------------------------------------------------------- 
class MAV_UIMissionEndScreenListener extends UIScreenListener
	dependson(XComGameState_MissionStats_Unit, MAV_BaseCategory)
	config(MissionAwardVariety);

var localized string m_strHatesTheMost;
var localized string m_strLuckiest;
var localized string m_strSoloSlayer;
var localized string m_strPowerCouple;
var localized string m_strMostAssists;
var localized string m_strKillStealer;
var localized string m_strMostCritDamage;
var localized string m_strUnluckiest;
var localized string m_strTimeToBleed;
var localized string m_strTurtle;
var localized string m_strAlrightKid;
var localized string m_strTooOld;
var localized string m_strMostHigh;

var config bool ShowVanillaStats;
var config bool IncludeVanillaAwards;
var config int NDScreenIndex;
var config array<int> DisplayTime;
var config array<int> DisplayOrder;
var config int NumScreens;

var UIDropShipBriefing_MissionEnd MissionEndScreen;
var array<MAV_BaseCategory> Categories, Winners;
var int StatCycle, InfoCounter;

function name GetEnemyType(XComGameState_Unit Unit)
{
	local name GroupName, TemplateName;

	GroupName = Unit.GetMyTemplate().CharacterGroupName;
	TemplateName = Unit.GetMyTemplateName();

	switch (TemplateName)
	{
		case 'TutorialAdvTrooperM1':
		case 'AdvTrooperM1':
		case 'AdvTrooperM2':
		case 'AdvTrooperM3':
			return 'TROOPERS';

		case 'AdvCaptainM1':
		case 'AdvCaptainM2':
		case 'AdvCaptainM3':
			return 'OFFICERS';

		case 'AdvStunLancerM1':
		case 'AdvStunLancerM2':
		case 'AdvStunLancerM3':
			return 'STUN LANCERS';

		case 'AdvShieldBearerM2':
		case 'AdvShieldBearerM3':
			return 'SHIELD BEARERS';

		case 'AdvPsiWitchM2':
		case 'AdvPsiWitchM3':
			return 'AVATARS';

		case 'AdvMEC_M1':
		case 'AdvMEC_M2':
			return 'MECS';

		case 'Civilian':
		case 'HostileCivilian':
		case 'HostileVIPCivilian':
			return 'CIVILIANS';
	}

	switch (GroupName)
	{
		case 'AdventTurret':
			return 'TURRETS';

		case 'Sectopod':
			return 'SECTOPODS';

		case 'Sectoid':
			return 'SECTOIDS';

		case 'Archon':
			return 'ARCHONS';

		case 'Viper':
			return 'VIPERS';

		case 'Muton':
			return 'MUTONS';

		case 'Berserker':
			return 'BERSERKERS';

		case 'Cyberus':
			return 'CODICES';

		case 'Gatekeeper':
			return 'GATEKEEPERS';

		case 'Chryssalid':
			return 'CHRYSSALIDS';

		case 'Andromedon':
			return 'ANDROMEDONS';

		case 'Faceless':
			return 'FACELESS';

		case 'PsiZombie':
			return 'ZOMBIES';
	}

	return 'AYYS';
}

private function AddCategory(MAV_BaseCategory Category, string Label, int Size)
{
	Category.Initialize(Label, Size);
	Categories.AddItem(Category);
}

event OnInit(UIScreen Screen)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom HQ;
	local array<XComGameState_Unit> Squad;
	local array<XComGameState_MissionStats_Unit> UnitStats;
	local array<EnemyDamageCount> EnemyStats;
	local XComGameState_MissionStats_Unit MissionStats;
	local int i, j, Size;
	local EnemyDamageCount NewEnemyInfo;
	local MAV_DamageResult Result, NewResult;
	local bool Found;
	local MAV_MissionStats Stats;
	local MAV_BaseCategory Category;
	local array<MAV_BaseCategory> Backlog;
	local array<int> WinnerCounts;
	local XComGameState_Analytics Analytics;

	MissionEndScreen = UIDropShipBriefing_MissionEnd(Screen);
	History = `XCOMHISTORY;

	// Retrieve mission stats for the squad
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	for (i = 0; i < HQ.Squad.Length; ++i)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectId(HQ.Squad[i].ObjectID));
		Squad.AddItem(Unit);
		WinnerCounts.AddItem(0);
		MissionStats = class'MAV_Utilities'.static.EnsureHasUnitStats(Unit);
		`log("Stats for " $ Unit.GetName(eNameType_FullNick));
		`log("Rank: " $ Unit.GetSoldierRank());
		`log("Damage: " $ MissionStats.DamageDealt);
		`log("Luck: " $ MissionStats.Luck);
		`log("Elevation: " $ MissionStats.Elevation);
		`log("WoundedDamage: " $ MissionStats.WoundedDamage);
		`log("Turtle: " $ MissionStats.Turtle);
		`log("Shots Against: " $ MissionStats.ShotsAgainst);

		foreach MissionStats.EnemyStats(Result)
		{
			NewResult.UnitID = i;
			NewResult.Damage = Result.Damage;
			Found = false;

			for (j = 0; j < EnemyStats.Length; ++j)
			{	
				if (EnemyStats[j].UnitID == Result.UnitID)
				{
					EnemyStats[j].Results.AddItem(NewResult);
					NewEnemyInfo = EnemyStats[j];
					Found = true;
					break;
				}
			}

			if (!Found)
			{
				NewEnemyInfo.UnitID = Result.UnitID;
				Unit = XComGameState_Unit(History.GetGameStateForObjectId(Result.UnitID));
				NewEnemyInfo.Type = GetEnemyType(Unit);
				NewEnemyInfo.Results.Length = 0;
				NewEnemyInfo.Results.AddItem(NewResult);
				EnemyStats.AddItem(NewEnemyInfo);
			}
		}

		UnitStats.AddItem(MissionStats);
	}

	Stats.EnemyDamageCounts = EnemyStats;
	Stats.Squad = Squad;
	Stats.UnitStats = UnitStats;
	Size = Squad.Length;

	// Create categories
	Categories.Length = 0;
	Winners.Length = 0;

	AddCategory(new class'MAV_Category_HatesMost', m_strHatesTheMost, Size);
	AddCategory(new class'MAV_Category_Luckiest', m_strLuckiest, Size);
	AddCategory(new class'MAV_Category_SoloSlayer', m_strSoloSlayer, Size);
	AddCategory(new class'MAV_Category_PowerCouple', m_strPowerCouple, Size);
	AddCategory(new class'MAV_Category_MostAssists', m_strMostAssists, Size);
	AddCategory(new class'MAV_Category_KillStealer', m_strKillStealer, Size);
	AddCategory(new class'MAV_Category_MostHigh', m_strMostHigh, Size);
	AddCategory(new class'MAV_Category_MostCritDamage', m_strMostCritDamage, Size);
	AddCategory(new class'MAV_Category_Unluckiest', m_strUnluckiest, Size);
	AddCategory(new class'MAV_Category_TimeToBleed', m_strTimeToBleed, Size);
	AddCategory(new class'MAV_Category_Turtle', m_strTurtle, Size);
	AddCategory(new class'MAV_Category_AlrightKid', m_strAlrightKid, Size);
	AddCategory(new class'MAV_Category_TooOld', m_strTooOld, Size);

	if (IncludeVanillaAwards)
	{
		Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE, MissionEndScreen.m_strDealtMostDamage, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS, MissionEndScreen.m_strTookMostShots, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED, MissionEndScreen.m_strMostUnderFire, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_MOVEMENT, MissionEndScreen.m_strMovedFurthest, Squad);
	}

	// Shuffle list
	for (i = 0; i < Categories.Length; ++i)
	{
		Category = Categories[i];
		j = `SYNC_RAND(Categories.Length);
		Categories[i] = Categories[j];
		Categories[j] = Category;
	}

	// Determine unique winners
	for (i = 0; i < Categories.Length; ++i)
	{
		Category = Categories[i];
		Category.CalculateWinner(Stats);

		if (Category.HasWinner())
		{
			`log("Winner of" @ Category.Label $ ":" @ Category.WinnerName);
			Found = false;
			foreach Category.Winners(j)
			{
				if (WinnerCounts[j] == 0)
				{
					Found = true;
				}
				WinnerCounts[j]++;
			}

			if (Found)
			{
				Winners.AddItem(Category);
			}
			else
			{
				Backlog.AddItem(Category);
			}
		}
	}

	// Fill out winners with backlog once unique winners have been determined
	Size = ShowVanillaStats ? 4 : 8;
	j = 0;
	for (i = Winners.Length; i < Size && j < Backlog.Length; ++i)
	{
		Winners.AddItem(Backlog[j]);
		j++;
	}

	if (NDScreenIndex < 0)
	{
		DisplayWinners();
	}
	else
	{
		StatCycle = 0;
		InfoCounter = 0;
		MissionEndScreen.SetTimer(1.0f, true, nameof(UpdateStatistics), self);

		if (DisplayOrder[0] == NDScreenIndex)
		{
			DisplayWinners();
		}
	}
}

simulated function UpdateStatistics()
{
	StatCycle = (StatCycle + 1) % default.DisplayTime[InfoCounter];
	if (StatCycle == 0)
	{
		InfoCounter = (InfoCounter + 1) % default.DisplayOrder.Length;
		if (default.DisplayOrder[InfoCounter] == NDScreenIndex)
		{
			DisplayWinners();
		}
	}	
}

function AddVanillaAward(XComGameState_Analytics Analytics, name Metric, string Label, array<XComGameState_Unit> Squad)
{
	local XComGameState_Unit UnitState;
	local UnitAnalyticEntry AnalyticEntry;
	local MAV_BaseCategory Category;
	local int i;

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric(Metric);

	if (AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Category = new class'MAV_BaseCategory';
		Category.Label = Label;
		Category.WinnerName = UnitState.GetName(eNameType_FullNick);

		for (i = 0; i < Squad.Length; ++i)
		{
			if (Squad[i].ObjectID == UnitState.ObjectID)
			{
				Category.Winners.AddItem(i);
				break;
			} 
		}

		Categories.AddItem(Category);
	}
}

function DisplayWinners()
{
	local name ItemID;
	local int Size, i, j, MaxColumn;
	local UIPanel ItemContainer;
	local MAV_BaseCategory Category;

	if (ShowVanillaStats)
	{
		MaxColumn = 4;
	}
	else
	{
		ItemID = 'PostStatLeftRowItem';
		ItemContainer = MissionEndScreen.LeftList.ItemContainer;
		ItemContainer.RemoveChildren();

		Size = Min(4, Winners.Length);
		MaxColumn = 8;
		j = Size;

		for (i = 0; i < Size; ++i)
		{
			Category = Winners[i];
			MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Category.Label, Category.WinnerName, false);
		}
	}

	ItemID = 'PostStatRightRowItem';
	ItemContainer = MissionEndScreen.RightList.ItemContainer;
	ItemContainer.RemoveChildren();
	Size = Min(MaxColumn, Winners.Length);
	for (i = j; i < Size; ++i)
	{
		Category = Winners[i];
		MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Category.Label, Category.WinnerName, true);
	}
}

defaultproperties
{
    ScreenClass = UIDropShipBriefing_MissionEnd;
}
