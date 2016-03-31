//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionStats_Root
//  AUTHOR:  atamize
//  PURPOSE: Creates a root gamestate object to watch all ability triggers and capture/update units mission stats
//
//  Thanks to Kosmo and the Lifetime Stats mod on which this is based
//--------------------------------------------------------------------------------------- 
class XComGameState_MissionStats_Root extends XComGameState_BaseObject config(MissionAwardVariety);

var string CURRENT_VERSION;
var string ModVersion;

var config int TurtleScoreOverwatch;
var config int TurtleScoreHunkerDown;

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
	local int WoundHP, DamageAmount;
	local name TemplateName;
	
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (context == none)
		return ELR_NoInterrupt;
		
	AttackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	DamagedUnit = XComGameState_Unit(EventSource);
	if (AttackingUnit == none || DamagedUnit == none || DamagedUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;
	
	DamageResult = DamagedUnit.DamageResults[DamagedUnit.DamageResults.Length-1];
	TemplateName = DamagedUnit.GetMyTemplateName();
	`log("===============  UNIT TOOK DAMAGE  ====================");
	`log("Attacker: " $ AttackingUnit.GetFullName());
	`log("Damaged: " $ DamagedUnit.GetFullName() @ "-" @ TemplateName);
	`log("DamageAmt: " $ DamageResult.DamageAmount);
	
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Damage UnitStats for " $ AttackingUnit.GetFullName() $ " and " $ DamagedUnit.GetFullName());
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

	if (AttackingUnit.IsSoldier())
	{
		// Update stats if we were the attacker
		UnitStats = class'MAV_Utilities'.static.EnsureHasUnitStats(AttackingUnit);
		NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AttackingUnit.ObjectID));
		NewUnitStats = XComGameState_MissionStats_Unit(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Unit', UnitStats.ObjectID));
		DamageAmount = DamageResult.DamageAmount;

		// Civilian damage should count for a lot so they are properly shamed by Hates 'X' award
		if (TemplateName == 'Civilian' || TemplateName == 'HostileCivilian' || TemplateName == 'HostileVIPCivilian')
		{
			DamageAmount *= 1000;
		}

		NewUnitStats.DamageDealt = UnitStats.DamageDealt + DamageResult.DamageAmount;
		NewUnitStats.AddDamageToUnit(DamagedUnit.ObjectID, DamageAmount, DamagedUnit.IsDead());

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
	`log("Elevation: " $ NewUnitStats.Elevation);
	`log("WoundedDamage: " $ NewUnitStats.WoundedDamage);
	`log("Turtle: " $ NewUnitStats.Turtle);
	`log("Shots Against: " $ NewUnitStats.ShotsAgainst);
	
	NewGameState.AddStateObject(NewUnit);
	NewGameState.AddStateObject(NewUnitStats);
	`TACTICALRULES.SubmitGameState(NewGameState);
	
	return NewUnitStats;
}

function ShotDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState_MissionStats_Unit UnitStats)
{
	local int Chance;
	local XComGameState_Unit TargetUnit;

	// Calculate luck
	Chance = Clamp(AbilityContext.ResultContext.CalculatedHitChance, 0, 100);
	if (Unit.IsSoldier() || Unit.IsCivilian())
	{
		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Luck += (100 - Chance);
		}
		else
		{
			UnitStats.Luck -= Chance;
		}

		// Determine elevation for Most High award
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if (Unit.HasHeightAdvantageOver(TargetUnit, true))
		{
			UnitStats.Elevation += (Unit.TileLocation.Z - TargetUnit.TileLocation.Z);
		}
	}
	else
	{
		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Luck -= (100 - Chance);
		}
		else
		{
			UnitStats.Luck += Chance;
		}

		UnitStats.ShotsAgainst++;
	}
}

function TurtleDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState_MissionStats_Unit UnitStats)
{
	local name TemplateName;
	TemplateName = Ability.GetMyTemplateName();

	if (TemplateName == 'Overwatch')
		UnitStats.Turtle += TurtleScoreOverwatch;
	else if (TemplateName == 'HunkerDown')
		UnitStats.Turtle += TurtleScoreHunkerDown;
}

defaultproperties
{
	CURRENT_VERSION = "1.1.1";
}
