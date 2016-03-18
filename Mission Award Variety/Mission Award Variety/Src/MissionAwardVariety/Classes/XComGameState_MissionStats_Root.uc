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

delegate AbilityDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState_MissionStats_Unit UnitStats);

function XComGameState_MissionStats_Root InitComponent()
{
	RegisterAbilityActivated();	
	ModVersion = CURRENT_VERSION;
	return self;
}

function RegisterAbilityActivated()
{
	local Object ThisObj;
	local X2EventManager EventMgr;

	ThisObj = self;
	
	EventMgr = `XEVENTMGR;
	EventMgr.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockStarted);
	EventMgr.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnUnitTookDamage, ELD_OnVisualizationBlockStarted);
	EventMgr.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted);
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit SourceUnit;
	local XComGameState_Ability AbilityState;
	local XComGameStateContext_Ability AbilityContext;
	local name TemplateName;
	local bool IsSoldier;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	TemplateName = AbilityState.GetMyTemplateName();
	IsSoldier = SourceUnit.IsSoldier() || SourceUnit.IsCivilian();

	if (class'MAV_Utilities'.static.IsShotType(TemplateName))
	{
		// Determine who the enemy was shooting at
		//`log("MAV Taking a shot: " $ TemplateName);
		if (!IsSoldier)
		{
			SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		}
		UpdateStats(SourceUnit, AbilityState, AbilityContext, ShotDelegate);
	}
	else if (IsSoldier)
	{
		//`log("MAV Not shooting, but doing " $ TemplateName);
		if (TemplateName == 'Overwatch' || TemplateName == 'HunkerDown')
			UpdateStats(SourceUnit, AbilityState, AbilityContext, TurtleDelegate);
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
	local int WoundHP;
	
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
		NewUnitStats.AddDamageToUnit(DamagedUnit.ObjectID, DamageResult.DamageAmount, DamagedUnit.IsDead());

		// Crit Damage
		if (Context.ResultContext.HitResult == eHit_Crit)
		{
			NewUnitStats.CritDamage += DamageResult.DamageAmount;
		}

		// Damage while wounded for "Ain't Got Time to Bleed"
		if (AttackingUnit.IsInjured())
		{
			WoundHP = AttackingUnit.GetMaxStat(eStat_HP) - AttackingUnit.GetCurrentStat(eStat_HP);
			NewUnitStats.WoundedDamage = WoundHP + DamageResult.DamageAmount;
		}
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

function XComGameState_MissionStats_Unit UpdateStats(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, delegate<AbilityDelegate> MyDelegate)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_MissionStats_Unit UnitStats, NewUnitStats;
	local XComGameState_Unit NewUnit;

	UnitStats = class'MAV_Utilities'.static.EnsureHasUnitStats(Unit);
	if (UnitStats == none)
	{
		return none;
	}

	History = `XCOMHISTORY;

	// Setup new game state
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Ability MAV UnitStats to " $ Unit.GetFullName());
	NewGameState = History.CreateNewGameState(true, changeContainer);
	NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		
	// Create and add UnitStats
	NewUnitStats = XComGameState_MissionStats_Unit(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Unit', UnitStats.ObjectID));

	MyDelegate(NewUnit, Ability, AbilityContext, NewUnitStats);

	`log("===============  AbilityStats  ====================");
	`log("Ability: " $ Ability.GetMyTemplateName());
	`log("Name: " $ NewUnit.GetFullName());
	`log("DamageDone: " $ NewUnitStats.DamageDealt);
	`log("Luck: " $ NewUnitStats.Luck);
	`log("WoundedDamage: " $ NewUnitStats.WoundedDamage);
	`log("Turtle: " $ NewUnitStats.Turtle);
	`log("Shots Against: " $ NewUnitStats.ShotsAgainst);
	
	NewGameState.AddStateObject(NewUnit);
	NewGameState.AddStateObject(NewUnitStats);
	`TACTICALRULES.SubmitGameState(NewGameState);
	
	return NewUnitStats;
}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit Unit;
	local TTile UnitTileLocation;
	local Vector UnitLocation;

	Unit = XComGameState_Unit(EventSource);
	if (Unit.IsSoldier() || Unit.IsCivilian())
	{
		Unit.GetKeystoneVisibilityLocation(UnitTileLocation);
		UnitLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);
		`log("===============  Unit Moved  ====================");
		`log("Name: " $ Unit.GetFullName());
		`log("Elevation: " $ UnitLocation.Z);
	}

	return ELR_NoInterrupt;
}

function ShotDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState_MissionStats_Unit UnitStats)
{
	local int Chance;

	// Calculate luck
	Chance = Clamp(AbilityContext.ResultContext.CalculatedHitChance, 0, 100);
	if (Unit.IsSoldier() || Unit.IsCivilian())
	{
		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Luck = UnitStats.Luck + (100 - Chance);
		}
		else
		{
			UnitStats.Unluck = UnitStats.Unluck + Chance;
		}
	}
	else
	{
		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Unluck = UnitStats.Unluck + (100 - Chance);
		}
		else
		{
			UnitStats.Luck = UnitStats.Luck + Chance;
		}

		UnitStats.ShotsAgainst++;
	}
}

function TurtleDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState_MissionStats_Unit UnitStats)
{
	local name TemplateName;
	TemplateName = Ability.GetMyTemplateName();

	if (TemplateName == 'Overwatch')
		UnitStats.Turtle++;
	else if (TemplateName == 'HunkerDown')
		UnitStats.Turtle += 2;
}

defaultproperties
{
	CURRENT_VERSION = "1.0.0";
}
