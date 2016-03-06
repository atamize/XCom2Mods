//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionStats_Root
//  AUTHOR:  atamize
//
//  PURPOSE: Creates a root gamestate object to watch all ability triggers and capture/update units mission stats
//
//--------------------------------------------------------------------------------------- 
class XComGameState_MissionStats_Root extends XComGameState_BaseObject;

var string CURRENT_VERSION;
var string ModVersion;

function XComGameState_MissionStats_Root InitComponent()
{
	RegisterAbilityActivated();	
	ModVersion = CURRENT_VERSION;
	return self;
}

function RegisterAbilityActivated()
{
	local Object ThisObj;
	ThisObj = self;
	
	`log("Force Registered MissionStats_Root to AbilityActivated");
	`XEVENTMGR.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockStarted);
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnUnitTookDamage, ELD_OnVisualizationBlockStarted);
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit SourceUnit;
	local XComGameState_Ability AbilityState;
	local XComGameStateContext_Ability AbilityContext;

	AbilityState = XComGameState_Ability(EventData);
	SourceUnit = XComGameState_Unit(EventSource);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState != none && SourceUnit != none && AbilityContext != none)
	{
		if (class'MAV_Utilities'.static.IsShotType(AbilityState.GetMyTemplateName()))
		{
			UpdateStats(SourceUnit, AbilityState, AbilityContext);
		}
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitTookDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState NewGameState;	
	local XComGameStateContext_Ability Context;
	local XComGameState_MissionStats_Unit UnitStats, NewUnitStats;
	local XComGameState_Unit DamagedUnit, AttackingUnit, NewUnit;
	local DamageResult DamageResult;
	
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (context == none)
		return ELR_NoInterrupt;
		
	AttackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	DamagedUnit = XComGameState_Unit(EventSource);
	if (AttackingUnit == none || DamagedUnit == none || DamagedUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;
	
	DamageResult = DamagedUnit.DamageResults[DamagedUnit.DamageResults.Length-1];
	`log("===============  UNIT TOOK DAMAGE  ====================");
	`log("Attacker: " $ AttackingUnit.GetFullName());
	`log("Damaged: " $ DamagedUnit.GetFullName());
	//`log("Executed: " $ damageResult.bFreeKill);
	`log("DamageAmt: " $ DamageResult.DamageAmount);
	//`log("MitigationAmt: " $ damageResult.MitigationAmount);
	//`log("ShieldHP: " $ damageResult.ShieldHP);
	//`log("Shred: " $ damageResult.Shred);
	
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Damage UnitStats for " $ AttackingUnit.GetFullName() $ " and " $ DamagedUnit.GetFullName());
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

	if (AttackingUnit.IsSoldier())
	{
		// Update stats if we were the attacker
		UnitStats = class'MAV_Utilities'.static.EnsureHasUnitStats(AttackingUnit);
		NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AttackingUnit.ObjectID));
		NewUnitStats = XComGameState_MissionStats_Unit(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Unit', UnitStats.ObjectID));
		
		NewUnitStats.DamageDealt = UnitStats.DamageDealt + DamageResult.DamageAmount;
		NewUnitStats.AddDamageToUnit(DamagedUnit.ObjectID, DamageResult.DamageAmount);
		//NewUnitStats.DamageNegated = UnitStats.damageNegated + DamageResult.MitigationAmount;
		//NewUnitStats.NumExecutions = UnitStats.numExecutions + (DamageResult.bFreeKill ? 1 : 0);
	}
	/*
	else if (DamagedUnit.IsSoldier())
	{
		// Update stats of we were the attacked
		unitStats = class'MAV_Utilities'.static.ensureHasUnitStats(damagedUnit);
		newUnit = XComGameState_Unit(newGameState.CreateStateObject(class'XComGameState_Unit', damagedUnit.ObjectID));
		newUnitStats = XComGameState_MissionStats_Unit(newGameState.CreateStateObject(class'XComGameState_MissionStats_Unit', unitStats.ObjectID));
		
		newUnitStats.damageTaken = unitStats.damageTaken + damageResult.DamageAmount;
		newUnitStats.damageAbsorbed = unitStats.damageAbsorbed + damageResult.MitigationAmount;
	}
	*/
	
	if (NewUnit != none && NewUnitStats != none)
	{
		`log("===============  DamageStats  ====================");
		`log("Name: " $ NewUnit.GetFullName());
		`log("DamageDone: " $ NewUnitStats.DamageDealt);
		//`log("DamageTaken: " $ newUnitStats.damageTaken);
		//`log("DamageNegated: " $ newUnitStats.damageNegated);
		//`log("DamageAbsorbed: " $ newUnitStats.damageAbsorbed);
		//`log("Executions: " $ newUnitStats.numExecutions);
		
		// Submit game state
		NewGameState.AddStateObject(NewUnit);
		NewGameState.AddStateObject(NewUnitStats);
		
		// Trigger eventData
		//`XEVENTMGR.TriggerEvent('MissionStatsUpdated', newUnitStats, newUnit, newGameState);
		
		// Submit gamestate
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

function XComGameState_MissionStats_Unit UpdateStats(XComGameState_Unit SourceUnit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_MissionStats_Unit UnitStats;
	local XComGameState_MissionStats_Unit NewUnitStats;
	local XComGameState_Unit Unit, NewUnit;
	local bool IsSoldier;
	local int Chance;
	
	if (SourceUnit == none || Ability == none || AbilityContext == none)
	{
		return none;
	}
	
	History = `XCOMHISTORY;
	Unit = SourceUnit;

	// Determine who the enemy was shooting at
	IsSoldier = Unit.IsSoldier() || Unit.IsCivilian();
	if (!IsSoldier)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	}

	UnitStats = class'MAV_Utilities'.static.EnsureHasUnitStats(Unit);
	if (UnitStats == none)
	{
		return none;
	}

	// Setup new game state
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Ability MAV UnitStats to " $ Unit.GetFullName());
	NewGameState = History.CreateNewGameState(true, changeContainer);
	NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		
	// Create and add UnitStats
	NewUnitStats = XComGameState_MissionStats_Unit(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Unit', UnitStats.ObjectID));

	`log("===== Updating UnitStats for " $ Unit.GetFullName() $ " =======");

	// Calculate luck
	Chance = Clamp(AbilityContext.ResultContext.CalculatedHitChance, 0, 100);
	if (IsSoldier)
	{
		if (AbilityContext.IsResultContextHit())
		{
			NewUnitStats.Luck = NewUnitStats.Luck + (100 - Chance);
		}
	}
	else
	{
		if (!AbilityContext.IsResultContextHit())
		{
			NewUnitStats.Luck = NewUnitStats.Luck + Chance;
		}
	}

	/*
	// Calculating new values
	NewUnitStats.numShots = unitStats.numShots + 1;
	NewUnitStats.numHits = unitStats.numHits;
	NewUnitStats.numMisses = unitStats.numMisses;
	NewUnitStats.expectedHits = unitStats.expectedHits + Clamp(abilityContext.ResultContext.CalculatedHitChance, 0, 100);
	
	// Update hit/miss
	if( abilityContext.IsResultContextHit() ) newUnitStats.numHits++;
	else newUnitStats.numMisses++;
	
	// Update crit
	if( abilityContext.ResultContext.HitResult == eHit_Crit )
		newUnitStats.numCrits++;
		
	// Update Dodge
	if( abilityContext.Resultcontext.HitResult == eHit_Graze )
		newUnitStats.numGrazed++;
		
	// Add new stats to nwe gamestate
	newGameState.AddStateObject(newUnit);
	newGameState.AddStateObject(newUnitStats);
	
	// Trigger eventData
	`XEVENTMGR.TriggerEvent('MissionStatsUpdated', newUnitStats, newUnit, newGameState);
	*/
	`log("===============  AbilityStats  ====================");
	`log("Name: " $ NewUnit.GetFullName());
	`log("DamageDone: " $ NewUnitStats.DamageDealt);
	`log("Luck: " $ NewUnitStats.Luck);
	
	NewGameState.AddStateObject(NewUnit);
	NewGameState.AddStateObject(NewUnitStats);
	`TACTICALRULES.SubmitGameState(NewGameState);
	
	return NewUnitStats;
}

defaultproperties
{
	CURRENT_VERSION = "0.0.1";
}
