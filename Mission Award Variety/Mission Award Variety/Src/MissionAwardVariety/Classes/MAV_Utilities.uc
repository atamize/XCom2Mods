//---------------------------------------------------------------------------------------
//  FILE:    MAV_Utilities
//  AUTHOR:  atamize
//
//  PURPOSE: Provide some helper functions for working with the stats objects
//
//--------------------------------------------------------------------------------------- 
class MAV_Utilities extends Object config (MissionAwardVariety);

var config array<name> BasicShotAbilities;

static function XComGameState_MissionStats_Root CheckOrCreateRoot()
{
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_MissionStats_Root RootStats;

	RootStats = XComGameState_MissionStats_Root(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionStats_Root', true));
	
	if (RootStats == none)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Checking/Adding MAV RootStats");
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		RootStats = XComGameState_MissionStats_Root(newGameState.CreateStateObject(class'XComGameState_MissionStats_Root'));
		RootStats.InitComponent();
		
		NewGameState.AddStateObject(RootStats);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		
		`log("==== Added RootStats ====");
	}
	else
	{
		UpdateVersion(RootStats);
	}

	return RootStats;
}

static function UpdateVersion(XComGameState_MissionStats_Root Root)
{
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_MissionStats_Root NewRoot;
	
	if (Root.ModVersion != class'XComGameState_MissionStats_Root'.default.CURRENT_VERSION)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Checking/Adding MAV RootStats");
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', Root.ObjectID));
		NewRoot.InitComponent();
		
		NewGameState.AddStateObject(NewRoot);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		//`log("==== UPDATED Mission_ROOT FROM " $ Root.ModVersion $ " TO " $ NewRoot.ModVersion $ " ====");
	}
	else
	{
		//`log("==== Mission_ROOT ALREADY AT VERSION " $ Root.ModVersion $ " ====");
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Validating MAV RootStats");
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', Root.ObjectID));
		NewRoot.RegisterAbilityActivated();
		
		NewGameState.AddStateObject(NewRoot);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
}

static function EnsureSquadHasUnitStats()
{
	local XComGameState_HeadquartersXCom HQ;
	
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (HQ == none)
		return;
		
	EnsureHaveUnitStats(HQ.Squad, true);
}

static function EnsureHaveUnitStats(array<StateObjectReference> Units, optional bool ShouldReset = false)
{
	local XComGameState_Unit unit;
	local int i;

	for (i = 0; i < Units.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectId(Units[i].ObjectID));
		EnsureHasUnitStats(Unit, ShouldReset);
	}
}

static function XComGameState_MissionStats_Unit EnsureHasUnitStats(XComGameState_Unit Unit, optional bool ShouldReset = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_MissionStats_Unit UnitStats;
	local XComGameState_Unit NewUnit;
	
	History = `XCOMHISTORY;
	
	if (!Unit.IsSoldier())
		return none;
	
	// Check if unit has UnitStats
	UnitStats = XComGameState_MissionStats_Unit(Unit.FindComponentObject(class'XComGameState_MissionStats_Unit'));
	if (UnitStats == none)
	{
		`log("===== Adding UnitStats for " $ Unit.GetFullName() $ " =======");
	
		// Setup new game state
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding UnitStats to " $ unit.GetFullName());
		NewGameState = History.CreateNewGameState(true, ChangeContainer);
		NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		
		// Create and add UnitStats
		UnitStats = XComGameState_MissionStats_Unit(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Unit'));
		UnitStats.InitComponent();
		NewUnit.AddComponentObject(UnitStats);
		
		// Add new stats to history
		NewGameState.AddStateObject(NewUnit);
		NewGameState.AddStateObject(UnitStats);
		History.AddGameStateToHistory(NewGameState);
	}
	else if (ShouldReset)
	{
		UnitStats.InitComponent();
	}
	
	return UnitStats;
}

static function bool IsShotType(name Type)
{
	local name BasicShotAbility;
	`log("Checking shot types length: " $ default.BasicShotAbilities.Length);
	foreach default.BasicShotAbilities(BasicShotAbility)
	{
		if (Type == BasicShotAbility)
			return true;
	}
	
	return false;
}
