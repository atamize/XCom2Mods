//---------------------------------------------------------------------------------------
//  FILE:    MAV_UITacticalHUD_ScreenListener
//  AUTHOR:  atamize
//  PURPOSE: Calculates award winners and displays them on the mission end screen
//
//--------------------------------------------------------------------------------------- 
class MAV_UIMissionEndScreenListener extends UIScreenListener
	dependson(XComGameState_MissionStats_Unit, MAV_BaseCategory)
	config (MissionAwardVariety);

var localized string m_strHatesTheMost;
var localized string m_strLuckiest;
var localized string m_strSoloSlayer;
var localized string m_strPowerCouple;

var config bool bOverrideRightList;

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

event OnInit(UIScreen Screen)
{
	local UIDropShipBriefing_MissionEnd MissionEndScreen;
	local UIPanel ItemContainer;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom HQ;
	local array<XComGameState_Unit> Squad;
	local name ItemID;
	local array<XComGameState_MissionStats_Unit> UnitStats;
	local array<EnemyDamageCount> EnemyStats;
	local XComGameState_MissionStats_Unit MissionStats;
	local int i, j, Size;
	local EnemyDamageCount NewEnemyInfo;
	local MAV_DamageResult Result, NewResult;
	local bool Found;
	local MAV_MissionStats Stats;
	local array<MAV_BaseCategory> Categories;
	local MAV_BaseCategory Category;

	MissionEndScreen = UIDropShipBriefing_MissionEnd(Screen);
	History = `XCOMHISTORY;

	// Retrieve mission stats for the squad
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	for (i = 0; i < HQ.Squad.Length; ++i)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectId(HQ.Squad[i].ObjectID));
		Squad.AddItem(Unit);
		MissionStats = class'MAV_Utilities'.static.EnsureHasUnitStats(Unit);
		`log("Stats for " $ Unit.GetName(eNameType_FullNick));
		`log("Damage: " $ MissionStats.DamageDealt);
		`log("Luck: " $ MissionStats.Luck);

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
	Category = new class'MAV_Category_HatesMost';
	Category.Initialize(m_strHatesTheMost, Size);
	Categories.AddItem(Category);

	Category = new class'MAV_Category_Luckiest';
	Category.Initialize(m_strLuckiest, Size);
	Categories.AddItem(Category);

	Category = new class'MAV_Category_SoloSlayer';
	Category.Initialize(m_strSoloSlayer, Size);
	Categories.AddItem(Category);

	Category = new class'MAV_Category_PowerCouple';
	Category.Initialize(m_strPowerCouple, Size);
	Categories.AddItem(Category);

	if (bOverrideRightList)	// Override default mission awards (Dealt Most Damage)
	{
		ItemID = 'PostStatRightRowItem';
		ItemContainer = MissionEndScreen.RightList.ItemContainer;
	}
	else // Override team stats
	{
		ItemID = 'PostStatLeftRowItem';
		ItemContainer = MissionEndScreen.LeftList.ItemContainer;
	}
	ItemContainer.RemoveChildren();

	// Calculate and display winners
	for (i = 0; i < 4; ++i)
	{
		Category = Categories[i];
		Category.CalculateWinner(Stats);
		Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Category.Label, Category.WinnerName, bOverrideRightList);
	}	
}

defaultproperties
{
    ScreenClass = UIDropShipBriefing_MissionEnd;
}
