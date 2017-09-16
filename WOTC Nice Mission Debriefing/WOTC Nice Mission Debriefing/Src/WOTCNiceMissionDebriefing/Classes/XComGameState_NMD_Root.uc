class XComGameState_NMD_Root extends XComGameState_BaseObject;

const CURRENT_VERSION = "0.0.1";
const CURRENT_VERSION_ID = 0;

var string ModVersion;
var int ModVersionId;

function XComGameState_NMD_Root InitComponent()
{
	ModVersion = CURRENT_VERSION;
	ModVersionId = CURRENT_VERSION_ID;
	return self;
}

function registerAbilityActivated()
{
	local Object selfObj;
	selfObj = self;
	
	`XEventMGR.RegisterForEvent(selfObj, 'ObjectMoved', OnMoved, ELD_PreStateSubmitted, 0, );
	`XEventMGR.RegisterForEvent(selfObj, 'AbilityActivated', onAbilityActivated, ELD_PreStateSubmitted, 0, );
	`XEventMGR.RegisterForEvent(selfObj, 'UnitTakeEffectDamage', onUnitTakeDamage, ELD_OnStateSubmitted, 0, );
}

function EventListenerReturn OnMoved(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object callbackData)
{
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;
	local XComGameStateContext_Ability AbilityContext;
	local NMD_Stat_TilesMoved Stat;

	Unit = XComGameState_Unit(EventSource);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	
	if( Unit == none || AbilityContext == none || AbilityContext.InputContext.MovementPaths.Length == 0 || !isFirstTile(Unit, AbilityContext))
		return ELR_NoInterrupt;
		
	if( !Unit.IsSoldier() )
		return ELR_NoInterrupt;
	
	UnitStats = class'NMD_Utilities'.static.ensureHasUnitStats(Unit);
	UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
	Stat = UnitStats.addTilesMoved( AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length-1, GameState );
	
	`log("NMD - unit " $ Unit.GetFullName() $ " moved " $ Stat.GetValue() $ " tiles");
	// Trigger EventData
	`XEventMGR.TriggerEvent('NMDUpdated', UnitStats, Unit, GameState);
	
	return ELR_NoInterrupt;
}

function EventListenerReturn onUnitTakeDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object callbackData) {
	local XComGameStateContext_Ability context;
	local XComGameState_NMD_Unit UnitStats;
	local XComGameState_Unit damagedUnit, attackingUnit, soldierUnit;
	local DamageResult damageResult;
	local int damageIndexMod;

	if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage ====================");
	
	context = XComGameStateContext_Ability(GameState.GetContext());
	if( context == none )
		return ELR_NoInterrupt;

	if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - context ====================");
	
	attackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(context.InputContext.SourceObject.ObjectID));
	damagedUnit = XComGameState_Unit(EventSource);
	
	if( attackingUnit == none || damagedUnit == none )
		return ELR_NoInterrupt;

	if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - Units ====================");
	
	if( attackingUnit.IsSoldier() )	UnitStats = class'NMD_Utilities'.static.ensureHasUnitStats(attackingUnit);
	else if( damagedUnit.IsSoldier() ) UnitStats = class'NMD_Utilities'.static.ensureHasUnitStats(damagedUnit);
	
	damageIndexMod = class'NMD_Utilities'.static.getDamageResultIndexMod(context.InputContext.AbilityTemplateName, UnitStats, GameState);
	if( attackingUnit == none || damagedUnit == none || damagedUnit.DamageResults.Length < damageIndexMod )
		return ELR_NoInterrupt;

	if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - index ====================");
	
	damageResult = damagedUnit.DamageResults[damagedUnit.DamageResults.Length-damageIndexMod];
	
	// Setup Unit stats for modification
	UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
	if( attackingUnit.IsSoldier() ) {
		// Update stats if we were the attacker
		UnitStats.addDamageDone(damagedUnit.getFullName(), damageResult.DamageAmount, damageResult.MitigationAmount, damageResult.bFreeKill, damagedUnit.IsDead(), damagedUnit.ObjectID, GameState);
		soldierUnit = attackingUnit;
	} else if( damagedUnit.IsSoldier() ) {
		// Update stats of we were the attacked
		UnitStats.addDamageTaken(attackingUnit.getFullName(), damageResult.DamageAmount, damageResult.MitigationAmount, GameState);
		soldierUnit = damagedUnit;
	} else return ELR_NoInterrupt;

	if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - done ====================");
	
	if( UnitStats != none ) {		
		// Trigger EventData
		`XEventMGR.TriggerEvent('NMDUpdated', UnitStats, soldierUnit, GameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn onAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData) {
	// Unit stats
	//local XComGameState_NMD_Unit UnitStats;
	
	// The user of this Ability and the Ability in question
	local XComGameState_Unit source;
	local XComGameState_Ability Ability;

	// The information about the Ability's results (and other things)
	local XComGameStateContext_Ability AbilityContext;
	local bool isShot, isMovement;

	// FileWriter for debugging Ability names
	//local FileWriter fileWriter;

	// Only activate on the 'real' GameState.  Don't really know why I need to do this, but otherwise it double fires this trigger...
	if( GameState.GetNumGameStateObjects() == 0 )
		return ELR_NoInterrupt;
	
	// Extract Ability and source Unit
	Ability = XComGameState_Ability(EventData);
	source = XComGameState_Unit(EventSource);
	
	// If not a soldier, skip
	if( !source.IsSoldier() )
		return ELR_NoInterrupt;
	
	//seqEvent_Abilitytriggered
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( Ability != none && source != none && AbilityContext != none ) {
		//if( logAbilities ) {
		//	`CHEATMGR.WriteToFilteredLogFile("LifetimeState[AbilityTriggered]: " $ Ability.GetMyTemplateName(), 'XCom_CombatLog');
		//}

		isShot = class'NMD_Utilities'.static.isShotType(Ability.GetMyTemplateName());
		isMovement = class'NMD_Utilities'.static.isMoveType(Ability.GetMyTemplateName()) && isFirstTile(source, AbilityContext);
		
		if( isShot || isMovement )
			updateStats(source, Ability, AbilityContext, GameState);
		//else
			//if( class'NMD_Utilities'.const.DEBUG ) `log("NMD - NotShotType: " $ Ability.GetMyTemplateName());
	}

	return ELR_NoInterrupt;
}

function XComGameState_NMD_Unit updateStats(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState GameState) {
	// To perform the GameState modification
	local XComGameState_NMD_Unit UnitStats;
	local XComGameState_Unit targetUnit;
	local ShotBreakdown breakdown, multiBreakdown;
	local AvailableTarget target;
	local int i;
	
	if( Unit == none || Ability == none || AbilityContext == none )
		return none;
	
	// Get/Create Unit stats for Unit
	UnitStats = class'NMD_Utilities'.static.ensureHasUnitStats(Unit);
	if( UnitStats == none )
		return none;

	// Setup Unitstats to be modified
	UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
		
	// Get Unit data
	target.PrimaryTarget = AbilityContext.InputContext.PrimaryTarget;
	target.AdditionalTargets = AbilityContext.InputContext.MultiTargets;
	Ability.GetShotBreakdown(target, breakdown);
	
	
		`log("===== Updating UnitStats for " $ Unit.GetFullName() $ " =======");
		`log("Ability: " $ Ability.GetMyTemplateName());
	
	
	// Update stats from primary shot
	targetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(target.PrimaryTarget.ObjectID));
	UnitStats.addShot(targetUnit.GetFullName(),
								AbilityContext.IsResultContextHit(),
								AbilityContext.ResultContext.HitResult,
								Clamp(breakdown.FinalHitChance, 0, 100),
								Clamp(breakdown.ResultTable[eHit_Crit], 0, 100),
								GameState);
			
	// Update stats from multi shots
	for(i=0; i<AbilityContext.InputContext.MultiTargets.Length; ++i) {
		target.PrimaryTarget = target.AdditionalTargets[i];
		Ability.GetShotBreakdown(target, multiBreakdown);
		
		targetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(target.PrimaryTarget.ObjectID));
		UnitStats.addShot(targetUnit.GetFullName(),
								AbilityContext.IsResultContextMultiHit(i),
								AbilityContext.ResultContext.MultiTargetHitResults[i],
								Clamp(multiBreakdown.FinalHitChance, 0, 100),
								Clamp(multiBreakdown.ResultTable[eHit_Crit], 0, 100),
								GameState);
	}
	
	// Trigger EventData
	`XEventMGR.TriggerEvent('NMDUpdated', UnitStats, Unit, GameState);
	return UnitStats;
}

function bool isFirstTile(XComGameState_Unit Unit, XComGameStateContext_Ability context) {
	local PathingResultData pathResults;
	local TTile currT, endT;
	
	if( context.ResultContext.PathResults.Length >= 1 ) {
		pathResults = context.ResultContext.PathResults[0];
	
		currT = Unit.TileLocation;
		endT = pathResults.PathTileData[0].EventTile;
		return currT.X == endT.X && currT.Y == endT.Y && currT.Z == endT.Z;
	}
	
	return false;
}
