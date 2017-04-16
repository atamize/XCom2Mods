//---------------------------------------------------------------------------------------
//  FILE:    MAV_UITacticalHUD_ScreenListener
//  AUTHOR:  atamize
//  PURPOSE: Calculates award winners and displays them on the mission end screen
//
//--------------------------------------------------------------------------------------- 
class MAV_UIMissionEndScreenListener extends UIScreenListener
	dependson(XComGameState_MissionStats_Unit, MAV_BaseCategory, XComGameState_MissionStats_Root)
	config(MissionAwardVariety);

struct Awardee
{
	var array<MAV_BaseCategory> Awards;
};

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
var localized string m_strCloseRange;
var localized string m_strCongeniality;
var localized string m_strRanOverwatch;
var localized string m_strUnfinishedBusiness;
var localized string m_strMostUseless;
var localized string m_strOverqualified;
var localized string m_strSneakiest;
var localized string m_strPropertyDamage;
var localized string m_strMostKillsInTurn;
var localized string m_strTimeToBleedMec;
var localized string m_strCongenialityAlien;
var localized string m_strCongenialityMec;
var localized string m_strMostExposed;
var localized string m_strWhoNeedsAmmo;
var localized string m_strMostLootPickedUp;
var localized string m_strMostBurnDamageDealt;
var localized string m_strMostPoisonDamageDealt;
var localized string m_strMostAcidDamageDealt;
var localized string m_strMostEvacDamageDealt;

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
	local string FullName;

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
		case 'FriendlyVIPCivilian':
			return 'CIVILIANS';

		case 'Soldier':
			return 'XCOM';

		case 'MutonM2_LW':
			return 'CENTURIONS';

		case 'MutonM3_LW':
			return 'MUTON ELITES';

		case 'NajaM1':
		case 'NajaM2':
		case 'NajaM3':
			return 'NAJAS';

		case 'SidewinderM1':
		case 'SidewinderM2':
		case 'SidewinderM3':
			return 'SIDEWINDERS';

		case 'ViperM2_LW':
		case 'ViperM3_LW':
			return 'VIPERS';

		case 'ArchonM2_LW':
			return 'GREAT ARCHONS';

		case 'SectoidM2_LW':
			return 'SECTOID COMMANDERS';

		case 'AdvGunnerM1':
		case 'AdvGunnerM2':
		case 'AdvGunnerM3':
			return 'ADVENT GUNNERS';

		case 'AdvSentryM1':
		case 'AdvSentryM2':
		case 'AdvSentryM3':
			return 'ADVENT SENTRIES';

		case 'AdvGrenadierM1':
		case 'AdvGrenadierM2':
		case 'AdvGrenadierM3':
			return 'ADVENT GRENADIERS';

		case 'AdvRocketeerM1':
		case 'AdvRocketeerM2':
		case 'AdvRocketeerM3':
			return 'ADVENT ROCKETEERS';

		case 'AdvMec_M3_LW':
		case 'AdvMECArcherM1':
		case 'AdvMECArcherM2':
			return 'MECS';

		case 'LWDroneM1':
		case 'LWDroneM2':
			return 'DRONES';

		case 'ChryssalidSoldier':
			return 'CHRYSSALID SOLDIERS';

		case 'HiveQueen':
			return 'HIVE QUEENS';
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

	FullName = Unit.GetMyTemplate().strCharacterName;
	if (len(FullName) > 0)
	{
		return name(caps(FullName $ "S"));
	}

	return 'AYYS';
}

private function MAV_BaseCategory AddCategory(MAV_BaseCategory Category, string Label, int Size, int Priority)
{
	Category.Initialize(Label, Size, Priority);
	Categories.AddItem(Category);
	return Category;
}

event OnInit(UIScreen Screen)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_MissionStats_Root Root;
	local array<XComGameState_Unit> Squad;
	local array<MAV_UnitStats> UnitStats;
	local array<EnemyDamageCount> EnemyStats;
	local MAV_UnitStats MissionStats;
	local int i, j, Size, NumToShow;
	local EnemyDamageCount NewEnemyInfo;
	local MAV_DamageResult Result, NewResult;
	local bool Found, PowerCoupleAdded;
	local MAV_MissionStats Stats;
	local MAV_BaseCategory Category, PowerCouple;
	local MAV_Category_TimeToBleed BleedCategory;
	local array<int> Losers;
	local XComGameState_Analytics Analytics;
	local name TemplateName;
	local array<Awardee> Awardees;
	local array<MAV_BaseCategory> Unique, Guaranteed, Backlog;
	local Awardee Winner;

	MissionEndScreen = UIDropShipBriefing_MissionEnd(Screen);
	History = `XCOMHISTORY;
	Root = XComGameState_MissionStats_Root(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionStats_Root', true));

	if (Root != none)
	{
		// Retrieve mission stats for the squad
		for (i = 0; i < Root.MAV_Stats.Length; ++i)
		{
			MissionStats = Root.MAV_Stats[i];
			Unit = XComGameState_Unit(History.GetGameStateForObjectId(MissionStats.UnitID));
			TemplateName = Unit.GetMyTemplateName();

			if (TemplateName == 'None')
				continue;

			Squad.AddItem(Unit);
			Awardees.AddItem(Winner);
			//`log("Stats for " $ Unit.GetName(eNameType_FullNick) $ ": " $ TemplateName);
			//`log("Rank: " $ Unit.GetSoldierRank());
			//`log("Enemy stats length: " $ MissionStats.EnemyStats.Length);
			class'MAV_Utilities'.static.LogStats(MissionStats);

			foreach MissionStats.EnemyStats(Result)
			{
				NewResult.UnitID = i;
				NewResult.Damage = Result.Damage;
				NewResult.Killed = Result.Killed;
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
	}
	else
	{
		HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
		for (i = 0; i < HQ.Squad.Length; ++i)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectId(HQ.Squad[i].ObjectID));
			Squad.AddItem(Unit);
		}
	}

	Stats.EnemyDamageCounts = EnemyStats;
	Stats.Squad = Squad;
	Stats.UnitStats = UnitStats;
	Size = Squad.Length;

	// Create categories
	Categories.Length = 0;
	Winners.Length = 0;

	if (Root != none)
	{
		AddCategory(new class'MAV_Category_HatesMost', m_strHatesTheMost, Size, 1);
		AddCategory(new class'MAV_Category_Luckiest', m_strLuckiest, Size, 1);
		AddCategory(new class'MAV_Category_SoloSlayer', m_strSoloSlayer, Size, 2);
		PowerCouple = AddCategory(new class'MAV_Category_PowerCouple', m_strPowerCouple, Size, 2);
		AddCategory(new class'MAV_Category_MostAssists', m_strMostAssists, Size, 1);
		AddCategory(new class'MAV_Category_KillStealer', m_strKillStealer, Size, 2);
		AddCategory(new class'MAV_Category_MostHigh', m_strMostHigh, Size, 2);
		AddCategory(new class'MAV_Category_MostCritDamage', m_strMostCritDamage, Size, 1);
		AddCategory(new class'MAV_Category_Unluckiest', m_strUnluckiest, Size, 1);

		BleedCategory = new class'MAV_Category_TimeToBleed';
		BleedCategory.AlternateLabel = m_strTimeToBleedMec;
		AddCategory(BleedCategory, m_strTimeToBleed, Size, 3);

		AddCategory(new class'MAV_Category_Turtle', m_strTurtle, Size, 2);
		AddCategory(new class'MAV_Category_AlrightKid', m_strAlrightKid, Size, 4);
		AddCategory(new class'MAV_Category_TooOld', m_strTooOld, Size, 3);
		AddCategory(new class'MAV_Category_CloseRange', m_strCloseRange, Size, 2);
		AddCategory(new class'MAV_Category_RanOverwatches', m_strRanOverwatch, Size, 4);
		AddCategory(new class'MAV_Category_UnfinishedBusiness', m_strUnfinishedBusiness, Size, 2);
		AddCategory(new class'MAV_Category_PunchingAboveWeight', m_strOverqualified, Size, 4);
		AddCategory(new class'MAV_Category_Sneakiest', m_strSneakiest, Size, 1);
		AddCategory(new class'MAV_Category_PropertyDamage', m_strPropertyDamage, Size, 1);
		AddCategory(new class'MAV_Category_MostKillsInTurn', m_strMostKillsInTurn, Size, 4);
		AddCategory(new class'MAV_Category_MostExposed', m_strMostExposed, Size, 1);
		AddCategory(new class'MAV_Category_WhoNeedsAmmo', m_strWhoNeedsAmmo, Size, 2);
		AddCategory(new class'MAV_Category_MostLootPickedUp', m_strMostLootPickedUp, Size, 2);
		AddCategory(new class'MAV_Category_PoisonDamage', m_strMostPoisonDamageDealt, Size, 1);
		AddCategory(new class'MAV_Category_BurnDamage', m_strMostBurnDamageDealt, Size, 1);
		AddCategory(new class'MAV_Category_AcidDamage', m_strMostAcidDamageDealt, Size, 1);
		AddCategory(new class'MAV_Category_MostEvacDamage', m_strMostEvacDamageDealt, Size, 3);
	}

	if (IncludeVanillaAwards)
	{
		Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE, MissionEndScreen.m_strDealtMostDamage, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS, MissionEndScreen.m_strTookMostShots, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED, MissionEndScreen.m_strMostUnderFire, Squad);
		AddVanillaAward(Analytics, class'XComGameState_Analytics'.const.ANALYTICS_UNIT_MOVEMENT, MissionEndScreen.m_strMovedFurthest, Squad);
	}

	// Determine winners
	for (i = 0; i < Categories.Length; ++i)
	{
		Category = Categories[i];
		Category.CalculateWinner(Stats);

		if (Category.HasWinner())
		{
			`log("Winner of" @ Category.Label $ ":" @ Category.WinnerName);
			foreach Category.Winners(j)
			{
				Awardees[j].Awards.AddItem(Category);
			}
		}
	}

	// Determine losers
	for (i = 0; i < Awardees.Length; ++i)
	{
		if (Awardees[i].Awards.Length == 0)
			Losers.AddItem(i);
	}

	// Determine unique winners
	NumToShow = ShowVanillaStats ? 4 : 8;
	PowerCoupleAdded = false;
	for (i = 0; i < Awardees.Length; ++i)
	{
		if (Awardees[i].Awards.Length > 0)
		{
			j = RollAwardByPriority(Awardees[i].Awards);
			Category = Awardees[i].Awards[j];
			Awardees[i].Awards.RemoveItem(Category);

			// Don't want Power Couple to be added twice
			if (Category == PowerCouple)
			{
				if (PowerCoupleAdded)
					continue;
				else
					PowerCoupleAdded = true;
			}
					
			Unique.AddItem(Category);
		}
	}

	if (Unique.Length > NumToShow)
	{
		// Multiple award winners should be guaranteed to appear in the final display
		for (i = 0; i < Unique.Length; ++i)
		{
			j = Unique[i].Winners[0];
			if (Awardees[j].Awards.Length > 0)
				Guaranteed.AddItem(Unique[i]);
			else
				Backlog.AddItem(Unique[i]);
		}

		// Add rest of Unique winners
		Shuffle(Backlog);
		for (i = 0; i < Backlog.Length && Guaranteed.Length < NumToShow; ++i)
		{
			Guaranteed.AddItem(Backlog[i]);
		}
	}
	else if (Unique.Length < NumToShow && Losers.Length > 0)
	{
		for (i = 0; i < Unique.Length; ++i)
		{
			Guaranteed.AddItem(Unique[i]);
		}

		// Deal with losers	
		Category = new class'MAV_BaseCategory';
		Category.Initialize(m_strCongeniality, Size, 0);

		for (i = 0; i < Losers.Length; ++i)
		{
			j = Losers[i];
			Category.Scores[j] += UnitStats[j].DamageDealt;
			//`log("Loser value for " $ Squad[j].GetFullName() $ ": " $ Category.Scores[j]);
		}

		Category.SetWinnerBasic(Squad);
		if (Category.HasWinner())
		{
			Unit = Squad[Category.Winners[0]];
			if (Unit.IsAlien())
			{
				Category.Label = m_strCongenialityAlien;
			}
			else if (Unit.IsRobotic())
			{
				Category.Label = m_strCongenialityMec;
			}
			else
			{
				Category.Label = m_strCongeniality;
			}

			Category.Label = repl(Category.Label, "#Title", (Unit.kAppearance.iGender == eGender_Male) ? "MISTER" : "MISS");
			`log("Winner of" @ Category.Label $ ":" @ Category.WinnerName);
			Guaranteed.AddItem(Category);
			Losers.RemoveItem(Category.Winners[0]);
		}

		// There are still losers, so we must choose the worst one
		if (Guaranteed.Length < NumToShow && Losers.Length > 0)
		{
			Category = new class'MAV_BaseCategory';
			Category.Initialize(m_strMostUseless, Size, 0);

			for (i = 0; i < Squad.Length; ++i)
			{
				if (Squad[i].IsSoldier() || (!Squad[i].IsCivilian() && Squad[i].GetMyTemplateName() != 'MimicBeacon'))
				{
					if (Losers.Find(i) != INDEX_NONE)
					{
						Category.Scores[i] = UnitStats[i].DamageDealt;
						continue;
					}
				}
				Category.Scores[i] = MaxInt;
			}

			Category.SetWinnerMin(Squad);
			if (Category.HasWinner())
			{
				if (len(Category.WinnerName) > 0)
				{
					`log("Winner of" @ Category.Label $ ":" @ Category.WinnerName);
					Guaranteed.AddItem(Category);
				}
			}
		}
	}
	else
	{
		for (i = 0; i < Unique.Length; ++i)
		{
			Guaranteed.AddItem(Unique[i]);
		}
	}

	// Fill rest of slots
	Awardees.Sort(SortAwardeesByLength);
	while (Guaranteed.Length < NumToShow)
	{
		Found = false;
		for (i = 0; i < Awardees.Length; ++i)
		{
			if (Awardees[i].Awards.Length > 0)
			{
				Found = true;
				j = RollAwardByPriority(Awardees[i].Awards);
				Category = Awardees[i].Awards[j];
				//`log("Awardee " $ Category.WinnerName $ " with length " $ Awardees[i].Awards.Length);

				Awardees[i].Awards.RemoveItem(Category);

				// Don't want Power Couple to be added twice
				if (Category == PowerCouple)
				{
					if (PowerCoupleAdded)
						continue;
					else
						PowerCoupleAdded = true;
				}
				
				Guaranteed.AddItem(Category);
				if (Guaranteed.Length >= NumToShow)
				{
					Found = false;
					break;
				}
			}
		}

		if (!Found) // We've exhausted the available awards
			break;
	}

	for (i = 0; i < Guaranteed.Length; ++i)
		Winners.AddItem(Guaranteed[i]);

	// Shuffle list
	Shuffle(Winners);

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

private function Shuffle(array<MAV_BaseCategory> arr)
{
	local MAV_BaseCategory Category;
	local int i, j;

	for (i = 0; i < arr.Length; ++i)
	{
		Category = arr[i];
		j = `SYNC_RAND(arr.Length);
		arr[i] = arr[j];
		arr[j] = Category;
	}
}

private function int SortAwardeesByLength(Awardee A, Awardee B)
{
	if (A.Awards.Length > B.Awards.Length) return 1;
	else if (A.Awards.Length < B.Awards.Length) return -1;
	return 0;
}

function int SortCategoryByPriority(MAV_BaseCategory A, MAV_BaseCategory B)
{
	if (A.Priority > B.Priority) return 1;
	else if (A.Priority < B.Priority) return -1;
	return 0;
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
		Category.WinnerName = Category.GetName(UnitState);
		Category.Priority = 1;

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

private function int RollAwardByPriority(array<MAV_BaseCategory> Awards)
{
	local int i, Sum, Pivot, Total;

	for (i = 0; i < Awards.Length; ++i)
	{
		Sum += Awards[i].Priority;
	}

	Pivot = `SYNC_RAND(Sum);

	for (i = 0; i < Awards.Length; ++i)
	{
		Total += Awards[i].Priority;
		if (Pivot < Total)
			return i;
	}
	return -1;
}

defaultproperties
{
    ScreenClass = UIDropShipBriefing_MissionEnd;
}
