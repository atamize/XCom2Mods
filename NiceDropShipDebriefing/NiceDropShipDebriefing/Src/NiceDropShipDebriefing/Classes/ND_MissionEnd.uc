//-----------------------------------------------------------
//
//-----------------------------------------------------------
//class ND_MissionEnd extends UIDropShipBriefing_MissionEnd config(ND_Config);
class ND_MissionEnd extends UIScreenListener config(ND_Config);

// Local vars
var int StatCycle;
var int InfoCounter;

// Config vars for dealing with the order of showing the screens
var config array<int> DisplayTime;
var config array<int> DisplayOrder;
var config int NumScreens;


struct storage {
	var string A,B,C,D,Label;
};


// Localisation Strings
var string OverwatchStr;
var localized string ND_Tiles;
var localized string ND_Points;
var localized string ND_Shots;
var localized string ND_Luck;
var localized string ND_Total;
var localized string ND_Offensive;
var localized string ND_Defensive;
var localized string ND_Def_Abbr;
var localized string ND_Off_Abbr;
var localized string ND_Lucker;
var localized string ND_BadDay;
var localized array<string> ND_OffensiveNames;
var localized array<string> ND_DefensiveAdjectives;
var localized string ND_SoldierRating;

// Config variables
var config array<int> OffensiveThresholds; 
var config array<int> DefensiveThresholds;

var UIDropShipBriefing_MissionEnd MissionEndScreen;

// Constructor
//simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
event OnInit(UIScreen Screen)
{
	/*local X2AbilityTemplate Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'overwatch');
	OverwatchStr=Template.LocFriendlyName;
	*/
	OverwatchStr="Overwatch";
	`log("ND: InitScreen");

	
	StatCycle=0;
	InfoCounter=0;

	//super.InitScreen(InitController, InitMovie, InitName);

	MissionEndScreen = UIDropShipBriefing_MissionEnd(Screen);
	Screen.SetTimer(1.0f, true, nameof(UpdateStatistics), self);
}

simulated function UpdateStatistics()
{
	StatCycle = (StatCycle + 1) % default.DisplayTime[InfoCounter];
	if (StatCycle == 0)
	{
		InfoCounter=(InfoCounter+1) % default.NumScreens;
		PopulateBattleStatistics();
	}	
}


simulated function PopulateBattleStatistics()
{
	switch(default.DisplayOrder[InfoCounter])
	{
		case 0: ShowMyStandardScreen(); break;
		case 1: ShowSecondScreen(); break;
		case 2: ShowThirdScreen(); break;
	}
}



////////////////////////////////////////////////////////
////////////////////// Show StandardScreen (Reworked)
////////////////////////////////////////////////////////
simulated function ShowMyStandardScreen()
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
	local string str; // ND
	local float compareValue; // ND




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

	////////////////////////////////////////////////////////
	////////////////////// Left List:
	////////////////////////////////////////////////////////
	MissionEndScreen.LeftList.ClearItems();
	ItemID = 'PostStatLeftRowItem';
	ItemContainer = MissionEndScreen.LeftList.ItemContainer;

	Value = "--";
	Label = MissionEndScreen.m_strSuccessfulShotPercentage;
	if (bShowStats)
	{
		TotalShots =	Analytics.GetTacticalFloatValue(  class'ND_AnalyticsManager'.const.ND_UNIT_SHOTS_TAKEN );
		TotalHits =		Analytics.GetTacticalFloatValue(  class'ND_AnalyticsManager'.const.ND_UNIT_SUCCESSFUL_SHOTS );
		
		compareValue = Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_UNIT_SHOTS_ACCURACY ); // ND
		
		if (TotalShots > 0)
		{
			ShotPercent = TotalHits / TotalShots;

			Value = class'UIUtilities'.static.FormatPercentage( ShotPercent * 100.0f, 2 );
			str = class'UIUtilities'.static.FormatPercentage( compareValue/TotalShots, 2 ); // ND
			Value=Value $ "/" $ str; // ND
			if ((ShotPercent > RecordShotPercent) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ MissionEndScreen.m_strNewRecord;
		}
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Value = "--";
	Label = MissionEndScreen.m_strAverageDamagePerAttack;
	if (bShowStats)
	{
		TotalDamage = Analytics.GetTacticalFloatValue(  class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE );
		TotalAttacks = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SUCCESSFUL_ATTACKS );
		if (TotalAttacks > 0)
		{
			AvgDamage = TotalDamage / TotalAttacks;
			Value = class'UIUtilities'.static.FormatFloat( AvgDamage, 2 );
			if ((AvgDamage > RecordAvgDamage) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ MissionEndScreen.m_strNewRecord;
		}
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Label = MissionEndScreen.m_strAverageEnemiesKilledPerTurn;
	if (bShowStats)
	{
		TurnCount = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_TURN_COUNT );
		UnitKills = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_KILLS );
		if (TurnCount > 0)
		{
			AvgKills = UnitKills / TurnCount;
			Value = class'UIUtilities'.static.FormatFloat( AvgKills, 2 );
			if ((AvgKills > RecordAvgKills) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ MissionEndScreen.m_strNewRecord;
		}
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Label = MissionEndScreen.m_strAverageCoverBonus;
	if (bShowStats)
	{
		CoverCount = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_COVER_COUNT );
		CoverTotal = Analytics.GetTacticalFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_COVER_TOTAL );
		if (CoverCount > 0)
		{
			AvgCover = CoverTotal / CoverCount;
			Value = class'UIUtilities'.static.FormatPercentage( AvgCover * 20.0f, 2 );
			if ((AvgCover > RecordAvgCover) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ MissionEndScreen.m_strNewRecord;
		}
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);
	
	////////////////////////////////////////////////////////
	////////////////////// Right List:
	////////////////////////////////////////////////////////
	MissionEndScreen.RightList.ClearItems();
	ItemID = 'PostStatRightRowItem';
	ItemContainer = MissionEndScreen.RightList.ItemContainer;

	Label = MissionEndScreen.m_strDealtMostDamage;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick ) $ " (" $ int(AnalyticEntry.Value) $ default.ND_Points $ ")"; // ND
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = MissionEndScreen.m_strTookMostShots;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick ) $ " (" $ int(AnalyticEntry.Value) $ "x)"; //ND
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = MissionEndScreen.m_strMostUnderFire;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick ) $ " (" $ int(AnalyticEntry.Value) $ "x)";
	}
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = MissionEndScreen.m_strMovedFurthest;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_MOVEMENT );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick ) $ " (" $ int(AnalyticEntry.Value) $ default.ND_Tiles $ ")";
	}

	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);
}










////////////////////////////////////////////////////////
////////////////////// Show Luck Statistics
////////////////////////////////////////////////////////
simulated function ShowSecondScreen()
{
	local name ItemID;
	local string Label, Value;
	local UIPanel ItemContainer;
	local XComGameStateHistory History;
	local XComGameState_Analytics Analytics;
	// Variables used for nicer Formatting
	local array<string> part1, part2;
	local array<string> Labels;
	local int index, i, LenLeft1, LenLeft2,LenRight1, LenRight2, Len1, Len2;

	local bool bShowStats;
	local XComGameState_HeadquartersXCom XComHQ;// ND
	local name tmpName;
	local float UnitLuck,DefLuck,TotalDefLuck,TotalOffLuck;
	local XComGameState_Unit Unit; // store current unit
	local bool bRightAlign;
	History = `XCOMHISTORY;

	

	Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	bShowStats=true;

	Value = "--";
	Label = "";
	

	
	//////////// Show Unit Stats ND Code
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	bRightAlign=true;
	for(i=0;i< XComHQ.Squad.Length;i++) //iterate through each unit
	{	
		Unit = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectId(XComHQ.Squad[i].ObjectID) );
		if(part1.Length<7){

			Labels.AddItem( Unit.GetName( eNameType_FullNick ) $ " " $ default.ND_Luck $ ":");
			// Do Luck related things
			tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_LUCK_OFF);
			UnitLuck=	Analytics.GetTacticalFloatValue( tmpName );
			part1.AddItem( class'UIUtilities'.static.FormatPercentage( UnitLuck, 0) ) ; 

			tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_LUCK_DEF);
			DefLuck=	Analytics.GetTacticalFloatValue( tmpName );
			part2.AddItem( class'UIUtilities'.static.FormatPercentage( DefLuck, 0) );
		}
		
	}
	
	// Add General info to the left
	MissionEndScreen.LeftList.ClearItems();
	ItemID = 'PostStatLeftRowItem';
	ItemContainer = MissionEndScreen.LeftList.ItemContainer;
	TotalOffLuck = Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_UNIT_LUCK_OFF );
	TotalDefLuck = Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_UNIT_LUCK_DEF );

	Label=Caps(default.ND_Total) @ Caps(default.ND_Luck) @ "[" $ Caps(default.ND_Offensive) $ " | " $ Caps(default.ND_Defensive) $ "]" ;

	Value =                 default.ND_Off_Abbr @ class'UIUtilities'.static.FormatPercentage( TotalOffLuck/XComHQ.Squad.Length, 0);
	Value = Value $ " | " $ default.ND_Def_Abbr @ class'UIUtilities'.static.FormatPercentage( TotalDefLuck/XComHQ.Squad.Length, 0); 
	// Display average luck
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);
	// Display Mission rating
	MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, default.ND_SoldierRating, GetMissionRating(TotalOffLuck/XComHQ.Squad.Length,TotalDefLuck/XComHQ.Squad.Length));

	LenLeft1=0;
	LenRight1=0;
	LenLeft2=0;
	LenRight2=0;
	// Calculate maximum length of strings
	for(index=0; index < part1.Length; index++)
	{
		if(index<4)
		{
			LenRight1=max(LenRight1,Len( part1[index]) );
			LenRight2=max(LenRight2,Len( part2[index]) );
		} else
		{
			LenLeft1=max(LenLeft1,Len(part1[index]));
			LenLeft2=max(LenLeft2,Len(part2[index]));
			
		}
	}

	// Start Filling List From the right
	MissionEndScreen.RightList.ClearItems();
	ItemID = 'PostStatRightRowItem';
	ItemContainer = MissionEndScreen.RightList.ItemContainer;
	bShowStats = true; 

	// Add Entries to list
	for (index=0; index < part1.Length; index++)
	{	
		if(index==4)
		{// Switch to left list
			ItemID = 'PostStatLeftRowItem';
			ItemContainer = MissionEndScreen.LeftList.ItemContainer;
			// SpaceHolder
			bRightAlign=false;
			
		}
		if(index < 4)
		{
			Len1=LenRight1;
			Len2=LenRight2;
		}
		else
		{
			Len1=LenLeft1;
			Len2=LenLeft2;
		}
		Value =  default.ND_Off_Abbr $ " " ;
		// Do zero adding for left part
		for(i=0; i<Len1-Len( part1[index] );i++  )
		{	Value= " " $ Value;	}

		Value=Value $ part1[index] $ " | " $ default.ND_Def_Abbr $ " ";

		for(i=0; i<Len2-Len( part2[index] );i++  )
		{	Value= " " $ Value ;	}

		Value=Value $ part2[index];
		MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Labels[index], Value, bRightAlign);
	}
}

////////////////////////////////////////////////////////
////////////////////// Get Mission Rating
////////////////////////////////////////////////////////
static function string GetMissionRating(float OffLuck, float DefLuck)
{
	//local int numDef, numOff;
	local int i, defValue, offValue;
	offValue=0;
	defValue=0;
	//numDef=default.DefensiveThreshold.Length;
	//numOff=default.OffensiveThreshold.Length;
	for (i=0; i < default.DefensiveThresholds.Length; i++)
	{
		if(OffLuck>default.OffensiveThresholds[i])
			offValue=offValue+1;
		if(DefLuck>default.DefensiveThresholds[i])
			defValue=defValue+1;
	}
	return default.ND_DefensiveAdjectives[defValue] $ " " $ default.ND_OffensiveNames[offValue];
}



////////////////////////////////////////////////////////
////////////////////// Show Shot Statistics
////////////////////////////////////////////////////////
simulated function ShowThirdScreen()
{
	local name ItemID;
	local string Label, Value;
	local UIPanel ItemContainer;
	local XComGameStateHistory History;
	local XComGameState_Analytics Analytics;

	local bool bShowStats;
	local XComGameState_HeadquartersXCom XComHQ;// ND
	local name tmpName;
	local float UnitShots,UnitHits,UnitOWHits,UnitOWShots;
	local float TotalShots,TotalOverwatchShots,ShotPercent;
	local XComGameState_Unit Unit; // store current unit
	local int numEntries;
	local bool bRightAlign;
	// Variables used for nicer layout
	local array<storage> part;
	local storage tmpPart;
	local int index, i;
	local array<int> LenLeft, LenRight, Leng;
	numEntries=0;
	History = `XCOMHISTORY;

	bShowStats = true; // bMissionSuccess; // for how Jake wants to play with them on all the time and see how much it makes sense to disable them on failure

	Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	////////////////////////////////////////////////////////
	////////////////////// Begin Loop
	////////////////////////////////////////////////////////
	

	Value = "--";
	Label = MissionEndScreen.m_strSuccessfulShotPercentage;
	if (bShowStats)
	{
		// Add General info to the left
		MissionEndScreen.LeftList.ClearItems();
		bRightAlign=false;
		ItemID = 'PostStatLeftRowItem';
		ItemContainer = MissionEndScreen.LeftList.ItemContainer;
		
		
		// Adding total shots/Overwatcht shots for team XCOM
		TotalShots =			Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_UNIT_SHOTS_TAKEN );
		TotalOverwatchShots =	Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_UNIT_OVERWATCH_SHOTS_TAKEN );

		Label=Caps(default.ND_Total) $ " " $ Caps(default.ND_Shots) $ " | " $ Caps(OverwatchStr) $ " " $ Caps(default.ND_Shots) $ ":";

		Value =  String( int(TotalShots)) $ " | " $  String( int(TotalOverwatchShots)) ; 
		MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);



		// Adding total shots/Overwatcht shots for team XCOM
		TotalShots =			Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_ALIEN_SHOTS_TAKEN );
		TotalOverwatchShots =	Analytics.GetTacticalFloatValue( class'ND_AnalyticsManager'.const.ND_ALIEN_OVERWATCH_SHOTS_TAKEN );

		Label="ALIEN "  $ Caps(default.ND_Total) $ " " $ Caps(default.ND_Shots) $ " | " $ Caps(OverwatchStr) $ " " $ Caps(default.ND_Shots) $ ":";

		Value =  String( int(TotalShots)) $ " | " $  String( int(TotalOverwatchShots)) ; 
		MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);


		
		//////////// Show Unit Stats ND Code
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		foreach History.IterateByClassType(class'XComGameState_Unit', Unit) //iterate through each unit
		{	
			

			if (XComHQ.IsUnitInSquad(Unit.GetReference())) //check if unit is Xcom
			{	
				numEntries=numEntries+1;
				
				if(numEntries<7){

				
					// Do Shot related things
					tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_SHOTS_TAKEN);
					UnitShots=	Analytics.GetTacticalFloatValue( tmpName );
					tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_SUCCESSFUL_SHOTS);
					UnitHits=	Analytics.GetTacticalFloatValue( tmpName );

					tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_OVERWATCH_SHOTS_TAKEN);
					UnitOWShots=	Analytics.GetTacticalFloatValue( tmpName );
					tmpName=name("UNIT_"$ Unit.ObjectID $"_"$ class'ND_AnalyticsManager'.const.ND_UNIT_SUCCESSFUL_OVERWATCH_SHOTS);
					UnitOWHits=	Analytics.GetTacticalFloatValue( tmpName );
					ShotPercent=0;
					tmpPart.A= String(int(UnitShots)) ;
					if (UnitShots > 0)
					{
						ShotPercent = UnitHits / UnitShots;
						tmpPart.B = class'UIUtilities'.static.FormatPercentage( Shotpercent * 100.0f , 0) ;
					} else
					{tmpPart.B="--%";}

					tmpPart.C = String(int(UnitOWShots));

					if (UnitOWShots > 0)
					{
						ShotPercent = UnitOWHits / UnitOWShots;
						tmpPart.D = class'UIUtilities'.static.FormatPercentage( Shotpercent * 100.0f , 0) ;
					} else
					{tmpPart.D="--%";}
					tmpPart.Label = Unit.GetName( eNameType_Full ) $ " " $ default.ND_Shots $ ":";
					part.AddItem(tmpPart);
				}
			}
		}
		//////////// End Show Unit Stats ND Code
	}


	for(i=0; i<4; i++)
	{
	LenLeft.AddItem(0);
	LenRight.AddItem(0);
	Leng.AddItem(0);
	}
	// Calculate maximum length of strings
	for(index=0; index < part.Length; index++)
	{
		if(index<4)
		{
			LenRight[0]=max(LenRight[0],Len(part[index].A));
			LenRight[1]=max(LenRight[1],Len(part[index].B));
			LenRight[2]=max(LenRight[2],Len(part[index].C));
			LenRight[3]=max(LenRight[3],Len(part[index].D));
		} else
		{
			LenLeft[0]=max(LenLeft[0],Len(part[index].A));
			LenLeft[1]=max(LenLeft[1],Len(part[index].B));
			LenLeft[2]=max(LenLeft[2],Len(part[index].C));
			LenLeft[3]=max(LenLeft[3],Len(part[index].D));
		}
	}

	// Start Filling List From the right
	MissionEndScreen.RightList.ClearItems();
	ItemID = 'PostStatRightRowItem';
	ItemContainer = MissionEndScreen.RightList.ItemContainer;
	bShowStats = true; 
	bRightAlign= true;
	// Add Entries to list
	for (index=0; index < part.Length; index++)
	{	
		if(index==4)
		{// Switch to left list
			
			ItemID = 'PostStatLeftRowItem';
			ItemContainer = MissionEndScreen.LeftList.ItemContainer;
			// SpaceHolder
			bRightAlign=false;
		}
		if(index < 4)
		{
			Leng=LenRight;
		}
		else
		{
			Leng=LenLeft;
		}

		// DO all the whitespace padding
		tmpPart=part[index];

		////////// A ///////
		for(i=0; i<Leng[0]-Len( part[index].A );i++  )
		{	tmpPart.A = " "  $ tmpPart.A;	}

		////////// B ///////

		// Brackets for first Percentage
		if(Len(tmpPart.B)>0) // Show Bracket only if there is something in brackets
		{	 tmpPart.B = " (" $ tmpPart.B $ ")";}
		else
		{	 tmpPart.B = "  " $ tmpPart.B $ " ";}

		for(i=0; i<Leng[1]-Len( part[index].B );i++  )
		{	tmpPart.B = " " $ tmpPart.B;	}

		////////// C ///////
		for(i=0; i<(Leng[2]-Len( part[index].C ));i++  )
		{	tmpPart.C = " " $  tmpPart.C;	}

		////////// D ///////

		// Brackets for first Percentage
		if(Len(tmpPart.D)>0) // Show Bracket only if there is something in brackets
		{	 tmpPart.D = " (" $ tmpPart.D $ ")";}
		else
		{	 // Work around white space trimming
			if(bRightAlign)
				tmpPart.D = "   ";
			else
				tmpPart.D = "   ";
		}
		
		for(i=0; i< (Leng[3]-Len( part[index].D ));i++  )
		{	tmpPart.D = " " $ tmpPart.D ;	}

		//`log("ND:-" $ tmpPart.A $ "--");
		//`log("ND:-" $ tmpPart.B $ "--");
		//`log("ND:-" $ tmpPart.C $ "--");
		//`log("ND:-" $ tmpPart.D $ "--");
		
		Value= tmpPart.A $ tmpPart.B $ " | " $ tmpPart.C $ tmpPart.D ;

		MissionEndScreen.Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, tmpPart.Label, Value, bRightAlign);
	}
}

defaultproperties
{
    ScreenClass = UIDropShipBriefing_MissionEnd;
}
