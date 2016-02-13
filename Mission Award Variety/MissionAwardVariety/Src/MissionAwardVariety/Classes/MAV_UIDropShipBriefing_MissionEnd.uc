class MAV_UIDropShipBriefing_MissionEnd extends UIDropShipBriefing_MissionEnd;

simulated function PopulateBattleStatistics()
{
	local name ItemID;
	local string Label, Value;
	local UIPanel ItemContainer;
	local XComGameStateHistory History;
	local XComGameState_Analytics Analytics;
	local XComGameState_Unit UnitState;
	local UnitAnalyticEntry AnalyticEntry;
	local float TurnCount, UnitKills, TotalShots, TotalHits, TotalDamage, TotalAttacks, CoverCount, CoverTotal;
	local float ShotPercent, AvgDamage, AvgKills, AvgCover;
	local float RecordShotPercent, RecordAvgDamage, RecordAvgKills, RecordAvgCover;
	local XComGameState_BattleData BattleData;
	local bool bMissionSuccess, bIsFirstMission, bShowStats;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	bMissionSuccess = BattleData.bLocalPlayerWon && !BattleData.bMissionAborted; 
	bShowStats = true; // bMissionSuccess; // for how Jake wants to play with them on all the time and see how much it makes sense to disable them on failure
	bIsFirstMission = BattleData.m_bIsFirstMission;

	Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	RecordShotPercent = Analytics.GetFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_RECORD_SHOT_PERCENTAGE );
	RecordAvgDamage = Analytics.GetFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_RECORD_AVERAGE_DAMAGE );
	RecordAvgKills = Analytics.GetFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_RECORD_AVERAGE_KILLS );
	RecordAvgCover = Analytics.GetFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_RECORD_AVERAGE_COVER );

	// Left List:
	LeftList.ClearItems();
	ItemID = 'PostStatLeftRowItem';
	ItemContainer = LeftList.ItemContainer;

	Value = "--";
	Label = "Fucking Shit $#!%";
	if (bShowStats)
	{
		TotalShots = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SHOTS_TAKEN );
		TotalHits = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SUCCESSFUL_SHOTS );
		if (TotalShots > 0)
		{
			ShotPercent = TotalHits / TotalShots;
			Value = class'UIUtilities'.static.FormatPercentage( ShotPercent * 100.0f, 2 );
			if ((ShotPercent > RecordShotPercent) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Value = "--";
	Label = m_strAverageDamagePerAttack;
	if (bShowStats)
	{
		TotalDamage = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE );
		TotalAttacks = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SUCCESSFUL_ATTACKS );
		if (TotalAttacks > 0)
		{
			AvgDamage = TotalDamage / TotalAttacks;
			Value = class'UIUtilities'.static.FormatFloat( AvgDamage, 2 );
			if ((AvgDamage > RecordAvgDamage) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Label = m_strAverageEnemiesKilledPerTurn;
	if (bShowStats)
	{
		TurnCount = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_TURN_COUNT );
		UnitKills = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_KILLS );
		if (TurnCount > 0)
		{
			AvgKills = UnitKills / TurnCount;
			Value = class'UIUtilities'.static.FormatFloat( AvgKills, 2 );
			if ((AvgKills > RecordAvgKills) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Label = m_strAverageCoverBonus;
	if (bShowStats)
	{
		CoverCount = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_COVER_COUNT );
		CoverTotal = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_COVER_TOTAL );
		if (CoverCount > 0)
		{
			AvgCover = CoverTotal / CoverCount;
			Value = class'UIUtilities'.static.FormatPercentage( AvgCover * 20.0f, 2 );
			if ((AvgCover > RecordAvgCover) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	// Right List:
	RightList.ClearItems();
	ItemID = 'PostStatRightRowItem';
	ItemContainer = RightList.ItemContainer;

	Label = m_strDealtMostDamage;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strTookMostShots;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strMostUnderFire;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strMovedFurthest;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_MOVEMENT );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}

	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);
}
