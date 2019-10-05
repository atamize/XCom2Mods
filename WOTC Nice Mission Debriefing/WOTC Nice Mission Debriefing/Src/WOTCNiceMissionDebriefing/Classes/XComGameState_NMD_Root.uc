class XComGameState_NMD_Root extends XComGameState_BaseObject;

const CURRENT_VERSION = "1.1.0b";
const CURRENT_VERSION_ID = 0;

var string ModVersion;
var int ModVersionId;
var bool HasClearedStats;

function XComGameState_NMD_Root InitComponent()
{
	ModVersion = CURRENT_VERSION;
	ModVersionId = CURRENT_VERSION_ID;
	HasClearedStats = false;
	return self;
}

function RegisterAbilityActivated()
{
	local X2EventManager EventMgr;
	local Object selfObj;

	selfObj = self;
	
	EventMgr = `XEventMGR;
	EventMgr.RegisterForEvent(selfObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted, 0, );
	EventMgr.RegisterForEvent(selfObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockStarted, 0, );
	EventMgr.RegisterForEvent(selfObj, 'UnitTakeEffectDamage', OnUnitTakeDamage, ELD_OnVisualizationBlockStarted, 0, );
	EventMgr.RegisterForEvent(selfObj, 'UnitChangedTeam', OnUnitChangedTeam, ELD_OnStateSubmitted, 0, );
	EventMgr.RegisterForEvent(selfObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnVisualizationBlockCompleted, 0);
	EventMgr.RegisterForEvent(selfObj, 'PlayerTurnEnded', OnPlayerTurnEnd, ELD_OnStateSubmitted, 0);
	EventMgr.RegisterForEvent(selfObj, 'BreakWindow', OnBrokeWindow, ELD_OnStateSubmitted, 0);
	EventMgr.RegisterForEvent(selfObj, 'BreakDoor', OnKickedDoor, ELD_OnStateSubmitted, 0);
	EventMgr.RegisterForEvent(selfObj, 'OnEnvironmentalDamage', OnBlownUp, ELD_OnStateSubmitted, 0);
}

function ClearStatsOnFirstTurn()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Player PlayerState;
	local XComTacticalController kTacticalController;
	local array<XComGameState_Unit> PlayableUnits;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;

	History = `XCOMHISTORY;

	// Only clear stats if we are starting a new mission (no turns taken)
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
		{
			//`log("NMD PlayerTurnCount: " $ PlayerState.PlayerTurnCount);
			if (PlayerState.PlayerTurnCount > 1)
			{
				return;
			}
			break;
		}
	}

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Clearing mission stats");
	NewGameState = History.CreateNewGameState(true, ChangeContainer);
	
	kTacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	kTacticalController.m_XGPlayer.GetPlayableUnits(PlayableUnits, true);

	foreach PlayableUnits(Unit)
	{
		NMDUnit = class'NMD_Utilities'.static.FindUnitStats(Unit);
		if (NMDUnit != none)
		{
			//`log("NMD Clearing mission stats for " $ Unit.GetFullName());
			NMDUnit = XComGameState_NMD_Unit(NewGameState.ModifyStateObject(class'XComGameState_NMD_Unit', NMDUnit.ObjectID));
			NMDUnit.ClearMissionStats(NewGameState);
		}
	}

	History.AddGameStateToHistory(NewGameState);
}

function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object callbackData)
{
	local XComTacticalController kTacticalController;
	local array<XComGameState_Unit> PlayableUnits;
	local XComGameState_Unit Unit;	
	//local XComGameState_Player PlayerState;
	//local XComGameStateHistory History;
	//local XComGameState_NMD_Root RootStats, NewRoot;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnPlayerTurnBegun"))
	{
		return ELR_NoInterrupt;
	}

	kTacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	kTacticalController.m_XGPlayer.GetPlayableUnits(PlayableUnits, true);

	//`log("NMD - Turn began with playable units: " $ PlayableUnits.Length);
	foreach PlayableUnits(Unit)
	{
		class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
	}

	return ELR_NoInterrupt;
}


function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object callbackData)
{
	local XComGameState_Analytics Analytics;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;
	local int Tiles, OldTiles;
	//local NMD_Stat_TilesMoved Stat;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnUnitMoveFinished"))
	{
		return ELR_NoInterrupt;
	}

	Unit = XComGameState_Unit(EventData);
	if (Unit == none || !Unit.IsSoldier() || Unit.IsDead() || Unit.GetMyTemplate().bIsCosmetic)
	{
		return ELR_NoInterrupt;
	}

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	Tiles = int(Analytics.GetTacticalFloatValue("UNIT_" $ Unit.ObjectID $ "_ACC_UNIT_MOVEMENT"));

	UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
	UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));

	OldTiles = UnitStats.GetStat(class'NMD_Stat_TilesMoved'.const.ID).GetValue(Unit.ObjectID);
	UnitStats.SetTilesMoved(Tiles, GameState);

	if (Unit.IsConcealed())
	{
		UnitStats.AddConcealedTilesMoved(Tiles - OldTiles, GameState);
		GameState.AddStateObject(UnitStats);
		//`log("NMD - unit " $ Unit.GetFullName() $ " moved " $ (Tiles - OldTiles) $ " tiles in concealment");
	}
	
	//`log("NMD - unit " $ Unit.GetFullName() $ " moved " $ Stat.GetValue(Unit.ObjectID) $ " tiles total. Also " $ UnitStats.GetStat(class'NMD_Stat_Kills'.const.ID).GetValue(Unit.ObjectID) $ " Kills. and Damage Stats Length: " $ UnitStats.EnemyDamageResults.Length);

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitTakeDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object callbackData)
{
	local XComGameStateContext_Ability Context;
	local XComGameState_NMD_Unit UnitStats;
	local XComGameState_Unit DamagedUnit, AttackingUnit;
	local DamageResult DamageResult;
	local int DamageIndexMod;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnUnitTakeDamage"))
	{
		return ELR_NoInterrupt;
	}
	//if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage ====================");
	
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (Context == none)
		return ELR_NoInterrupt;

	//if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - context ====================");
	
	AttackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	DamagedUnit = XComGameState_Unit(EventSource);
	
	if (AttackingUnit == none || DamagedUnit == none)
		return ELR_NoInterrupt;

	//if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - Units ====================");
	
	if (AttackingUnit.IsSoldier())
		UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(AttackingUnit);
	else
		return ELR_NoInterrupt;

	DamageIndexMod = class'NMD_Utilities'.static.getDamageResultIndexMod(Context.InputContext.AbilityTemplateName, UnitStats, GameState);
	if (AttackingUnit == none || DamagedUnit == none || DamagedUnit.DamageResults.Length < DamageIndexMod)
		return ELR_NoInterrupt;

	//if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - index ====================");
	
	DamageResult = DamagedUnit.DamageResults[DamagedUnit.DamageResults.Length - DamageIndexMod];
	
	// Setup Unit stats for modification
	UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
	if (AttackingUnit.IsSoldier())
	{
		// Update stats if we were the attacker
		UnitStats.AddDamageDone(DamagedUnit.GetFullName(), DamageResult.DamageAmount, DamageResult.MitigationAmount, DamageResult.bFreeKill, DamagedUnit.IsDead(), AttackingUnit, damagedUnit, Context, GameState);		
	}

	//if( class'NMD_Utilities'.const.DEBUG ) `log("===============  onUnitTakeDamage - done ====================");

	return ELR_NoInterrupt;
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{
	// The user of this Ability and the Ability in question
	local XComGameState_Unit Source;
	local XComGameState_Ability Ability;

	// The information about the Ability's results (and other things)
	local XComGameStateContext_Ability AbilityContext;
	local bool isShot, isMovement;

	// FileWriter for debugging Ability names
	//local FileWriter fileWriter;

	// Only activate on the 'real' GameState.  Don't really know why I need to do this, but otherwise it double fires this trigger...
	if (GameState.GetNumGameStateObjects() == 0)
		return ELR_NoInterrupt;
	
	// Extract Ability and source Unit
	Ability = XComGameState_Ability(EventData);
	source = XComGameState_Unit(EventSource);

	//seqEvent_Abilitytriggered
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (Ability != none && source != none && AbilityContext != none)
	{
		//if( logAbilities ) {
		//	`CHEATMGR.WriteToFilteredLogFile("LifetimeState[AbilityTriggered]: " $ Ability.GetMyTemplateName(), 'XCom_CombatLog');
		//}

		isShot = class'NMD_Utilities'.static.isShotType(Ability.GetMyTemplateName());
		isMovement = class'NMD_Utilities'.static.isMoveType(Ability.GetMyTemplateName()) && isFirstTile(source, AbilityContext);
		
		if (isShot || isMovement)
			updateStats(source, Ability, AbilityContext, GameState);
		//else
			//if( class'NMD_Utilities'.const.DEBUG ) `log("NMD - NotShotType: " $ Ability.GetMyTemplateName());
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitChangedTeam(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{
	local XComGameState_Unit Source;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnUnitChangedTeam"))
	{
		return ELR_NoInterrupt;
	}

	Source = XComGameState_Unit(EventSource);

	//`log("NMD - Unit " $ Source.GetFullName() $ " changing teams");
	
	if (Source.GetTeam() == eTeam_XCom && Source.IsSoldier())
	{
		//`log("    Ensuring has stats");
		class'NMD_Utilities'.static.EnsureHasUnitStats(Source);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnPlayerTurnEnd(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{	
	local int NumVisibleEnemies, CoverValue;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnPlayerTurnEnd"))
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() == eTeam_XCom && !Unit.IsDead())
		{
			if (Unit.CanTakeCover() && !Unit.IsConcealed() && !Unit.IsInStasis())
			{
				UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
				if (UnitStats == none)
					continue;

				// Check cover and visible enemies for Most Exposed award
				switch (Unit.GetCoverTypeFromLocation())
				{
					case CT_None:		CoverValue = 3; break;
					case CT_MidLevel:	CoverValue = 2; break;
					case CT_Standing:	CoverValue = 1; break;
				}
				NumVisibleEnemies = class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(Unit.ObjectID);

				if (NumVisibleEnemies > 0)
				{
					//`log("NMD: " $ Unit.GetFullName() $ " exposed to " $ NumVisibleEnemies $ " enemies, cover: " $ CoverValue);
					UnitStats.AddExposure(CoverValue * NumVisibleEnemies, GameState);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function XComGameState_NMD_Unit UpdateStats(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, XComGameState GameState)
{
	// To perform the GameState modification
	local XComGameState_NMD_Unit UnitStats;
	local XComGameState_Unit targetUnit;
	local ShotBreakdown breakdown, multiBreakdown;
	local AvailableTarget target;
	local int i;
	local bool IsFriendly;

	if (Unit == none || Ability == none || AbilityContext == none)
		return none;
	
	IsFriendly = class'NMD_Utilities'.static.IsFriendly(Unit);
	
	if (IsFriendly)
	{
		// Get/Create Unit stats for Unit
		UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
		if (UnitStats == none)
			return none;

		// Setup Unitstats to be modified
		UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
		
		// Get Unit data
		Target.PrimaryTarget = AbilityContext.InputContext.PrimaryTarget;
		Target.AdditionalTargets = AbilityContext.InputContext.MultiTargets;
		Ability.GetShotBreakdown(target, breakdown);
	
			//`log("===== Updating UnitStats for " $ Unit.GetFullName() $ " =======");
			//`log("Ability: " $ Ability.GetMyTemplateName());
	
		// Update stats from primary shot
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
		UnitStats.AddShot(targetUnit.GetFullName(),
									AbilityContext.IsResultContextHit(),
									AbilityContext.ResultContext.HitResult,
									Clamp(breakdown.FinalHitChance, 0, 100),
									Clamp(breakdown.ResultTable[eHit_Crit], 0, 100),
									GameState);
	
		if (Ability.GetMyTemplateName() == 'OverwatchShot' || Ability.GetMyTemplateName() == 'PistolOverwatchShot')
		{
			UnitStats.AddOverwatchShot(AbilityContext.IsResultContextHit(), GameState);
		}

		if (Unit.HasHeightAdvantageOver(TargetUnit, true))
		{
			UnitStats.AddShotFromElevation(Unit, TargetUnit, GameState);
		}

		// Update stats from multi shots
		for(i=0; i<AbilityContext.InputContext.MultiTargets.Length; ++i) {
			Target.PrimaryTarget = Target.AdditionalTargets[i];
			Ability.GetShotBreakdown(target, multiBreakdown);
		
			TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
			UnitStats.AddShot(targetUnit.GetFullName(),
									AbilityContext.IsResultContextMultiHit(i),
									AbilityContext.ResultContext.MultiTargetHitResults[i],
									Clamp(multiBreakdown.FinalHitChance, 0, 100),
									Clamp(multiBreakdown.ResultTable[eHit_Crit], 0, 100),
									GameState);

			if (Unit.HasHeightAdvantageOver(TargetUnit, true))
			{
				UnitStats.AddShotFromElevation(Unit, TargetUnit, GameState);
			}
		}

		GameState.AddStateObject(UnitStats);
	}
	else
	{
		if (Ability.GetMyTemplateName() == 'OverwatchShot' || Ability.GetMyTemplateName() == 'PistolOverwatchShot')
		{
			TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

			//`log("NMD - " $ TargetUnit.GetFullName() $ " taking overwatch from " $ Unit.GetFullName());

			UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(TargetUnit);
			if (UnitStats == none)
				return none;

			// Setup Unitstats to be modified
			UnitStats = XComGameState_NMD_Unit(GameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));

			UnitStats.AddOverwatchRun(AbilityContext.IsResultContextHit(), GameState);
			GameState.AddStateObject(UnitStats);
		}
	}
	
	return UnitStats;
}

function bool IsFirstTile(XComGameState_Unit Unit, XComGameStateContext_Ability Context)
{
	local PathingResultData pathResults;
	local TTile currT, endT;
	
	if (Context.ResultContext.PathResults.Length >= 1) {
		pathResults = Context.ResultContext.PathResults[0];
	
		currT = Unit.TileLocation;
		endT = pathResults.PathTileData[0].EventTile;
		return currT.X == endT.X && currT.Y == endT.Y && currT.Z == endT.Z;
	}
	
	return false;
}

function EventListenerReturn OnBrokeWindow(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;

	//`log("NMD - a window broke");
	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnBrokeWindow"))
	{
		return ELR_NoInterrupt;
	}

	Unit = XComGameState_Unit(EventSource);

	if (class'NMD_Utilities'.static.IsFriendly(Unit))
	{
		UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
		if (UnitStats == none)
			return ELR_NoInterrupt;

		//`log("NMD - " $ Unit.GetFullName() $ " broke a damn window");
		UnitStats.AddEnvironmentDamage(1, GameState);
		GameState.AddStateObject(UnitStats);
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnKickedDoor(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;

	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnKickedDoor"))
	{
		return ELR_NoInterrupt;
	}
	//`log("NMD - a door was kicked");

	Unit = XComGameState_Unit(EventSource);

	if (class'NMD_Utilities'.static.IsFriendly(Unit))
	{
		UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
		if (UnitStats == none)
			return ELR_NoInterrupt;

		//`log("NMD - " $ Unit.GetFullName() $ " kicked a damn door");
		UnitStats.AddEnvironmentDamage(1, GameState);
		GameState.AddStateObject(UnitStats);
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnBlownUp(Object EventData, Object EventSource, XComGameState GameState, Name inEventID, Object callbackData)
{
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats;
	
	if (class'NMD_Utilities'.static.IsGameStateInterrupted(GameState, "OnBlownUp"))
	{
		return ELR_NoInterrupt;
	}

	if (GameState.GetNumGameStateObjects() == 0)
	{
		`log("NMD - OnBlownUp NO game state objects");
		return ELR_NoInterrupt;
	}

	DamageEvent = XComGameState_EnvironmentDamage(EventSource);
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(DamageEvent.DamageCause.ObjectID));

	if (class'NMD_Utilities'.static.IsFriendly(Unit))
	{
		UnitStats = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
		if (UnitStats == none)
			return ELR_NoInterrupt;

		//`log("NMD - environmental damage caused by " $ Unit.GetFullName() $ " of magnitude " $ DamageEvent.DamageAmount);
		UnitStats.AddEnvironmentDamage(DamageEvent.DamageAmount, GameState);
		GameState.AddStateObject(UnitStats);
	}

	return ELR_NoInterrupt;
}

defaultproperties
{
	HasClearedStats = false
}