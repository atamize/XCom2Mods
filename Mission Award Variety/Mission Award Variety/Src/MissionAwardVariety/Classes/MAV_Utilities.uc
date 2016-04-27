//---------------------------------------------------------------------------------------
//  FILE:    MAV_Utilities
//  AUTHOR:  atamize
//  PURPOSE: Provide some helper functions for working with the stats objects
//
//  Thanks to Kosmo and the Lifetime Stats mod on which this is based
//--------------------------------------------------------------------------------------- 
class MAV_Utilities extends Object dependson(XComGameState_MissionStats_Root) config (MissionAwardVariety);

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
		RootStats = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root'));
		RootStats.InitComponent();
		
		NewGameState.AddStateObject(RootStats);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
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

static function bool IsShotType(name Type)
{
	local name BasicShotAbility;
	foreach default.BasicShotAbilities(BasicShotAbility)
	{
		if (Type == BasicShotAbility)
			return true;
	}
	
	return false;
}

static function bool IsFriendly(XComGameState_Unit Unit)
{
	local name TemplateName;

	if (Unit.GetTeam() == eTeam_XCom || Unit.IsMindControlled())
		return true;

	TemplateName = Unit.GetMyTemplateName();

	switch(TemplateName)
	{
	case 'Soldier_VIP':
	case 'Scientist_VIP':
	case 'Engineer_VIP':
	case 'FriendlyVIPCivilian':
	case 'HostileVIPCivilian':
	case 'CommanderVIP':
	case 'Engineer':
	case 'Scientist':
	case 'MimicBeacon':
		return true;
	}

	return false;
}

static function LogStats(MAV_UnitStats UnitStats)
{
	/*
	`log("DamageDone: " $ UnitStats.DamageDealt);
	`log("Luck: " $ UnitStats.Luck);
	`log("Elevation: " $ UnitStats.Elevation);
	`log("WoundedDamage: " $ UnitStats.WoundedDamage);
	`log("Turtle: " $ UnitStats.Turtle);
	`log("Shots Against: " $ UnitStats.ShotsAgainst);
	`log("Close Range: " $ UnitStats.CloseRangeValue);
	`log("Dashing: " $ UnitStats.DashingTiles);
	`log("OverwatchTaken: " $ UnitStats.OverwatchTaken);
	*/
}

