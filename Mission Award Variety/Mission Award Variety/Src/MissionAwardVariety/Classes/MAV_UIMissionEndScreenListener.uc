//---------------------------------------------------------------------------------------
//  FILE:    MAV_UITacticalHUD_ScreenListener
//  AUTHOR:  atamize
//  PURPOSE: Calculates award winners and displays them on the mission end screen
//
//--------------------------------------------------------------------------------------- 
class MAV_UIMissionEndScreenListener extends UIScreenListener
	dependson(XComGameState_MissionStats_Unit)
	config (MissionAwardVariety);

struct EnemyDamageCount
{
	var int UnitID;
	var name Type;
	var array<MAV_DamageResult> Results;
};

struct HateCount
{
	var name Type;
	var int Damage;
};

struct PowerCouple
{
	var int Unit1;
	var int Unit2;
	var int Damage;
};

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
	local array<HateCount> HateCounts;
	local array<MAV_DamageResult> Results;
	local XComGameState_MissionStats_Unit MissionStats;
	local int i, j, k, m, Winner, CurrentMax, Value, MaxHate, UnitID, Unit1, Unit2;
	local MAV_DamageResult Result, NewResult;
	local bool Found;
	local EnemyDamageCount NewEnemyInfo;
	local string WinnerName, HatedName;
	local HateCount NewHateCount;
	local name MostHated;
	local array<int> SquadScores;
	local array<PowerCouple> PowerCouples;
	local PowerCouple Couple;
	
	MissionEndScreen = UIDropShipBriefing_MissionEnd(Screen);
	History = `XCOMHISTORY;

	// Retrieve mission stats for the squad
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	for (i = 0; i < HQ.Squad.Length; ++i)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectId(HQ.Squad[i].ObjectID));
		Squad.AddItem(Unit);
		SquadScores.AddItem(0);
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

			Found = false;
			for (j = 0; j < HateCounts.Length; ++j)
			{
				if (HateCounts[j].Type == NewEnemyInfo.Type)
				{
					HateCounts[j].Damage += NewResult.Damage;
					Found = true;
					break;
				}
			}

			if (!Found)
			{
				NewHateCount.Type = NewEnemyInfo.Type;
				NewHateCount.Damage = NewResult.Damage;
				HateCounts.AddItem(NewHateCount);
			}
		}

		UnitStats.AddItem(MissionStats);
	}

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

	// Hates this particular enemy
	CurrentMax = 0;
	Winner = -1;
	WinnerName = "--";
	MostHated = '';

	// Which enemy type was the damaged the most?
	for (i = 0; i < HateCounts.Length; ++i)
	{
		Value = HateCounts[i].Damage;
		if (Value > MaxHate)
		{
			MostHated = HateCounts[i].Type;
			MaxHate = Value;
		}
	}

	if (MostHated == '')
	{
		Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, repl(m_strHatesTheMost, "#Unit", "AYYS"), WinnerName, bOverrideRightList);
	}
	else
	{
		// Get damage counts for each Squad member for the most damaged enemy
		for (i = 0; i < EnemyStats.Length; ++i)
		{
			if (EnemyStats[i].Type == MostHated)
			{
				foreach EnemyStats[i].Results(Result)
				{
					SquadScores[Result.UnitID] += Result.Damage;
				}
			}
		}

		// Finally find the winner
		for (i = 0; i < SquadScores.Length; ++i)
		{
			Value = SquadScores[i];
			if (Value > CurrentMax)
			{
				CurrentMax = Value;
				Winner = i;
			}
		}

		// 'FACELESS' doesn't retain capitalization, probably because a non-capitalized version
		// already exists and Unrealscript names aren't case-sensitive. Just hack in the name here
		HatedName = string(MostHated);
		if (MostHated == 'FACELESS')
			HatedName = "FACELESS";

		WinnerName = Squad[Winner].GetName(eNameType_FullNick);
		Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, repl(m_strHatesTheMost, "#Unit", HatedName), WinnerName, bOverrideRightList);
	}

	// Determine luckiest
	CurrentMax = 0;
	Winner = -1;
	WinnerName = "--";

	for (i = 0; i < UnitStats.Length; ++i)
	{
		Value = UnitStats[i].Luck;
		if (Value > CurrentMax)
		{
			Winner = i;
			CurrentMax = Value;
		}
	}

	if (Winner >= 0)
	{
		WinnerName = Squad[Winner].GetName(eNameType_FullNick);
	}
	Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, m_strLuckiest, WinnerName, bOverrideRightList);


	// Solo Slayer
	CurrentMax = 0;
	Winner = -1;
	WinnerName = "--";

	for (i = 0; i < SquadScores.Length; ++i)
		SquadScores[i] = 0;

	// Find enemies that were killed by only one soldier
	for (i = 0; i < EnemyStats.Length; ++i)
	{
		if (EnemyStats[i].Results.Length == 1)
		{
			UnitID = EnemyStats[i].Results[0].UnitID;
			SquadScores[UnitID] += EnemyStats[i].Results[0].Damage;
		}
	}

	for (i = 0; i < SquadScores.Length; ++i)
	{
		Value = SquadScores[i];
		if (Value > CurrentMax)
		{
			CurrentMax = Value;
			Winner = i;
		}
	}

	if (Winner >= 0)
	{
		WinnerName = Squad[Winner].GetName(eNameType_FullNick);
	}
	Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, m_strSoloSlayer, WinnerName, bOverrideRightList);

	
	// Power couple
	CurrentMax = 0;
	Winner = -1;
	WinnerName = "--";

	for (i = 0; i < EnemyStats.Length; ++i)
	{
		Results = EnemyStats[i].Results;
		if (Results.Length > 1)
		{
			for (j = 0; j < Results.Length; ++j)
			{
				Unit1 = Results[j].UnitID;
				Found = false;
				for (k = j + 1; k < Results.Length; ++k)
				{
					Unit2 = Results[k].UnitID;

					for (m = 0; m < PowerCouples.Length; ++m)
					{
						Couple = PowerCouples[m];
						if ((Couple.Unit1 == Unit1 && Couple.Unit2 == Unit2) ||
							(Couple.Unit2 == Unit1 && Couple.Unit1 == Unit2))
						{
							PowerCouples[m].Damage += Results[j].Damage + Results[k].Damage;
							Found = true;
							break;
						}
					}

					// Add new power couple
					if (!Found)
					{
						Couple.Unit1 = Unit1;
						Couple.Unit2 = Unit2;
						Couple.Damage = Results[j].Damage + Results[k].Damage;
						PowerCouples.AddItem(Couple);
					}
				}
			}
		}
	}

	// Find the most powerful couple
	for (i = 0; i < PowerCouples.Length; ++i)
	{
		Value = PowerCouples[i].Damage;
		if (Value > CurrentMax)
		{
			CurrentMax = Value;
			Winner = i;
		}
	}
	
	if (Winner >= 0)
	{
		WinnerName = Squad[PowerCouples[Winner].Unit1].GetFullName() $ " & " $ Squad[PowerCouples[Winner].Unit2].GetFullName();
	}
	Screen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, m_strPowerCouple, WinnerName, bOverrideRightList);
}

defaultproperties
{
    ScreenClass = UIDropShipBriefing_MissionEnd;
}
