class NMD_Utilities extends Object config (WOTCNiceMissionDebriefing);

const DEBUG=true;
const DEBUG2=true;

var config array<name> basicShotAbilities;
var config array<name> moveShotAbilities;

/**
	Generates and stores the NMD_Root GameState into History if it does not already exist
*/
static function XComGameState_NMD_Root checkOrCreateRoot()
{
	local XComGameState newGameState;
	local XComGameState_NMD_Root rootStats;
	rootStats = XComGameState_NMD_Root(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_NMD_Root', true));
	
	if( rootStats == none ) {
		newGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Root NMD");

		rootStats = XComGameState_NMD_Root(newGameState.CreateStateObject(class'XComGameState_NMD_Root'));		
		rootStats.InitComponent();
		
		newGameState.AddStateObject(rootStats);
		`XCOMHISTORY.AddGameStateToHistory(newGameState);
	} else updateVersion(rootStats);

	return rootStats;
}

/**
	Ensures that the mod is properly updated
*/
static function updateVersion(XComGameState_NMD_Root root) {
	/*
	local XComGameState newGameState;
	local XComGameStateContext_ChangeContainer changeContainer;
	local XComGameState_NMD_Root newRoot;
	
	if( root.modVersionId < 1 ) {
		changeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Checking/Adding RootStats");
		newGameState = `XCOMHISTORY.CreateNewGameState(true, changeContainer);
		newRoot = XComGameState_NMD_Root(newGameState.CreateStateObject(class'XComGameState_NMD_Root', root.ObjectID));
		newRoot.InitComponent();
		updateToV1(newGameState);
		
		newGameState.AddStateObject(newRoot);
		`XCOMHISTORY.AddGameStateToHistory(newGameState);
		
		if( DEBUG ) `log("==== UPDATED LIFETIME_ROOT FROM " $ root.modVersion $ " TO " $ newRoot.modVersion $ " ====");
	} else if( root.modVersionId < class'XComGameState_NMD_Root'.const.CURRENT_VERSION_ID ) {
		changeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Checking/Adding RootStats");
		newGameState = `XCOMHISTORY.CreateNewGameState(true, changeContainer);
		newRoot = XComGameState_NMD_Root(newGameState.CreateStateObject(class'XComGameState_NMD_Root', root.ObjectID));
		newRoot.InitComponent();
		
		newGameState.AddStateObject(newRoot);
		`XCOMHISTORY.AddGameStateToHistory(newGameState);
		
		if( DEBUG ) `log("==== UPDATED LIFETIME_ROOT FROM " $ root.modVersion $ " TO " $ newRoot.modVersion $ " ====");
	} else {
		if( DEBUG ) `log("==== LIFETIME_ROOT ALREADY AT VERSION " $ root.modVersion $ " ====");
	}
	*/
}

/**
	Ensures that all soldiers currently in HQ have UnitStats
*/
static function ensureAllHaveUnitStats() {
	local XComGameState_HeadquartersXCom HQ;
	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if( HQ == none )
		return;
		
	ensureHaveUnitStats(HQ.Crew);
}

/**
	Ensures that all soldiers currently in the Squad have UnitStats
*/
static function ensureSquadHasUnitStats() {
	local XComGameState_HeadquartersXCom HQ;
	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if( HQ == none )
		return;
		
	ensureHaveUnitStats(HQ.Squad);
}

/**
	Ensures that all soldiers int he given list have UnitStats
*/
static function ensureHaveUnitStats(array<StateObjectReference> units) {
	local XComGameState_Unit unit;
	local int i;

	// Update all in array
	for(i = 0; i < units.Length; i++) {
		unit = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectId(units[i].ObjectID) );
		EnsureHasUnitStats(unit);
	}
}

/**
	Ensures the given unit has UnitStats if he is a soldier
*/
static function XComGameState_NMD_Unit EnsureHasUnitStats(XComGameState_Unit unit) {
	// Shortcut variables
	local XComGameStateHistory History;

	// To perform the gamestate modification
	local XComGameState newGameState;
	local XComGameStateContext_ChangeContainer changeContainer;
	local XComGameState_NMD_Unit unitStats;
	local XComGameState_Unit newUnit;
	
	// Get shortcut vars
	History = `XCOMHISTORY;
	
	// If unit is not a soldier, return
	if( !unit.IsSoldier() )
		return none;
	
	// Check if unit has UnitStats
	unitStats = XComGameState_NMD_Unit( unit.FindComponentObject(class'XComGameState_NMD_Unit') );
	if( unitStats == none ) {
		// If not found, we need to add it
		if( DEBUG ) `log("=NMD= Adding UnitStats for " $ unit.GetFullName() $ " =======");
	
		// Setup new game state
		changeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding UnitStats to " $ unit.GetFullName());
		newGameState = History.CreateNewGameState(true, changeContainer);
		newUnit = XComGameState_Unit(newGameState.CreateStateObject(class'XComGameState_Unit', unit.ObjectID));
		
		// Create and add UnitStats
		unitStats = XComGameState_NMD_Unit(newGameState.CreateStateObject(class'XComGameState_NMD_Unit'));
		unitStats.InitComponent(newGameState);
		newUnit.AddComponentObject(unitStats);
		
		// Add new stats to history
		newGameState.AddStateObject(newUnit);
		newGameState.AddStateObject(unitStats);
		History.AddGameStateToHistory(newGameState);
	}// else unitStats = updateUnitToV1(unit);
	
	return unitStats;
}

/**
	As recommended by Amineri -- Based on her NexusMods post
*/
static function CleanupDismissedUnits() {
    local XComGameState newGameState;
    //local XComGameState_Unit unit;
    local XComGameState_NMD_Unit unitStats;
	
    newGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("NMD Cleanup");
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_NMD_Unit', unitStats, , true) {
        //check and see if the OwningObject is still alive and exists
        if( unitStats.OwningObjectId > 0 ) {
            newGameState.RemoveStateObject(unitStats.ObjectID);
        }
    }
	
    if( newGameState.GetNumGameStateObjects() > 0 )
        `GAMERULES.SubmitGameState(newGameState);
    else
        `XCOMHISTORY.CleanupPendingGameState(newGameState);
}

static function int getDamageResultIndexMod(name ability, out XComGameState_NMD_Unit stats, XComGameState sourceGameState)
{
	if( ability != 'fanfire' ) {
		stats.multifireHistoryIndex = -1;
		stats.multifireIndex = 1;
		return 1;
	}

	if( sourceGameState.HistoryIndex != stats.multifireHistoryIndex ) {
		stats.multifireHistoryIndex = sourceGameState.HistoryIndex;
		stats.multifireIndex = 1;
	}
	
	return stats.multifireIndex++;
}

static function bool isShotType(name type) {
	local name basicShotAbility;

	foreach default.basicShotAbilities(basicShotAbility) {
		if( type == basicShotAbility )
			return true;
	}
	
	return false;
}

static function bool isMoveType(name type) {
	local name moveShotAbility;
	
	foreach default.moveShotAbilities(moveShotAbility) {
		if( type == moveShotAbility )
			return true;
	}
	
	return false;
}

/*
static function updateToV1(XComGameState newGameState) {
	local XComGameState_Unit unit;
	
	`log("UPDATING TO MODULAR STATS (v1.0.0)");
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', unit,, true) {
		updateUnitToV1(unit, newGameState);
    }
}

static function XComGameState_NMD_Unit updateUnitToV1(XComGameState_Unit unit, optional XComGameState newGameState) {
	local XComGameStateContext_ChangeContainer changeContainer;
	local XComGameState_NMD_Unit unitStats, newUnitStats;
	local NMD_Stats stats;
	local XComGameState_Unit newUnit;

	unitStats = XComGameState_NMD_Unit( unit.FindComponentObject(class'XComGameState_NMD_Unit') );
	if( unitStats == none )
		return none;
	
	stats = unitStats.getMainStats();
	if( stats == none ) {
		if( newGameState == none ) {
			changeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Updating UnitStats to v1 for " $ unit.GetFullName());
			newGameState = `XCOMHISTORY.CreateNewGameState(true, changeContainer);
		}
		
		newUnit = XComGameState_Unit(newGameState.CreateStateObject(class'XComGameState_Unit', unit.ObjectID));
		newUnitStats = XComGameState_NMD_Unit(newGameState.CreateStateObject(class'XComGameState_NMD_Unit', unitStats.ObjectID));
		newUnitStats.InitComponent(newGameState, true);
		
		newGameState.AddStateObject(newUnit);
		newGameState.AddStateObject(newUnitStats);
		// Submit if we created
		if( changeContainer != none ) {
			`XCOMHISTORY.AddGameStateToHistory(newGameState);
		}
		
		`log("UPDATED " $ unit.GetFullName() $ " To v1");
		return newUnitStats;
	}
	
	return unitStats;
}
*/