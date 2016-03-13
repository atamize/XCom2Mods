//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionStats_Root
//  AUTHOR:  atamize
//  PURPOSE: Creates a root gamestate object to watch all ability triggers and capture/update units mission stats
//
//  Thanks to Kosmo and the Lifetime Stats mod on which this is based
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
	`log("DamageAmt: " $ DamageResult.DamageAmount);
	
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
	}
	
	if (NewUnit != none && NewUnitStats != none)
	{
		// Submit game state
		NewGameState.AddStateObject(NewUnit);
		NewGameState.AddStateObject(NewUnitStats);
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
	CURRENT_VERSION = "1.0.0";
}
