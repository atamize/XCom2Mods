//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionStats_Root
//  AUTHOR:  atamize
//  PURPOSE: Creates a root gamestate object to watch all ability triggers and capture/update units mission stats
//
//  Thanks to Kosmo and the Lifetime Stats mod on which this is based
//--------------------------------------------------------------------------------------- 
class XComGameState_MissionStats_Root extends XComGameState_BaseObject config(MissionAwardVariety);

struct MAV_UnitStats
{
	var int UnitID;
	var int Luck;
	var int DamageDealt;
	var int Elevation;
	var int CritDamage;
	var int WoundedDamage; // For the "Ain't Got Time to Bleed" award
	var int Turtle; // Sums overwatching and hunkers for Turtle award
	var int ShotsAgainst;
	var int CloseRangeValue; // Tiles + Damage for close range award
	var int DashingTiles; // Tiles moved while dashing
	var int OverwatchTaken; // Overwatches ran + bonus for not getting hit
	var int ShorthandedDamage; // Damage dealt while teammate was taken out
	var int ShotsTaken;
	var int SuccessfulShots;
	var int ConcealedTiles; // Tiles moved while in concealment
	var int PropertyDamage;
	var int KillsThisTurn;
	var int MaxKillsInTurn;
	var int Exposure; // How exposed they are to the enemy at the end of a turn
	var int TurnsWithoutAmmo;
	var bool FiredPrimaryWeaponThisTurn;
	var int EvacDamageDealt;
	var int BurnDamageDealt;
	var int PoisonDamageDealt;
	var int AcidDamageDealt;
	var array<MAV_DamageResult> EnemyStats;
};

var string CURRENT_VERSION;
var string ModVersion;
var array<MAV_UnitStats> MAV_Stats;
var bool Shorthanded;

var config int TurtleScoreOverwatch;
var config int TurtleScoreHunkerDown;
var config int CloseRangeTiles;

delegate MAV_UnitStats AbilityDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, MAV_UnitStats UnitStats);

function XComGameState_MissionStats_Root InitComponent()
{
	MAV_Stats.Length = 0;
	RegisterAbilityActivated();	
	ModVersion = CURRENT_VERSION;
	`log("Initializing MAV at version: " $ ModVersion);
	return self;
}

function RegisterAbilityActivated()
{
	local Object ThisObj;
	local X2EventManager EventMgr;
	local XComGameState_Player PlayerState;

	// Only clear stats if we are starting a new mission (no turns taken)
	if (MAV_Stats.Length > 0)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if (PlayerState.GetTeam() == eTeam_XCom)
			{
				//`log("MAV PlayerTurnCount: " $ PlayerState.PlayerTurnCount);
				if (PlayerState.PlayerTurnCount < 2)
				{
					MAV_Stats.Length = 0;
				}
				break;
			}
		}
	}

	ThisObj = self;
	Shorthanded = false;
	
	EventMgr = `XEVENTMGR;
	EventMgr.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockStarted);
	EventMgr.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnUnitTookDamage, ELD_OnVisualizationBlockStarted);
	EventMgr.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(ThisObj, 'BreakWindow', OnBrokeWindow, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(ThisObj, 'BreakDoor', OnKickedDoor, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(ThisObj, 'OnEnvironmentalDamage', OnBlownUp, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(ThisObj, 'PlayerTurnEnded', OnPlayerTurnEnd, ELD_OnStateSubmitted);
}

function SubmitGameState(XComGameState NewState)
{
	`XCOMGAME.GameRuleset.SubmitGameState(NewState);
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

	// A random shot can be fired from nobody? Just ignore
	if (SourceUnit.GetMyTemplateName() == 'None')
		return ELR_NoInterrupt;

	TemplateName = AbilityState.GetMyTemplateName();
	IsSoldier = class'MAV_Utilities'.static.IsFriendly(SourceUnit);

	if (class'MAV_Utilities'.static.IsShotType(TemplateName))
	{
		// Determine who the enemy was shooting at
		//`log("MAV Taking a shot: " $ TemplateName);
		if (!IsSoldier)
		{
			SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

			// If enemy is shooting at another enemy, assume it's panicked and don't add to stats
			if (!class'MAV_Utilities'.static.IsFriendly(SourceUnit))
			{
				return ELR_NoInterrupt;
			}
		}
		UpdateStats(SourceUnit, AbilityState, AbilityContext, ShotDelegate);
	}
	else if (IsSoldier)
	{
		//`log("MAV Not shooting, but doing " $ TemplateName);
		switch (TemplateName)
		{
			case 'Overwatch':
			case 'HunkerDown':
				UpdateStats(SourceUnit, AbilityState, AbilityContext, TurtleDelegate);
				break;
		}
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Analytics Analytics;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;	
	local XComGameState_MissionStats_Root NewRoot;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local float Tiles;
	local int i;
	local name UnitMetric;

	Unit = XComGameState_Unit(EventData);
	if (Unit == none || !Unit.IsSoldier() || Unit.IsDead() || !Unit.IsConcealed())
	{
		return ELR_NoInterrupt;
	}

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	UnitMetric = name("UNIT_" $ Unit.ObjectID $ "_" $ class'XComGameState_Analytics'.const.ANALYTICS_UNIT_MOVEMENT);
	Tiles = Analytics.GetTacticalFloatValue(UnitMetric);
	
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Sneak UnitStats for " $ Unit.GetFullName());
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);	
	NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', self.ObjectID));

	i = NewRoot.GetStatsIndexForUnit(Unit.ObjectID);
	NewRoot.MAV_Stats[i].ConcealedTiles = Tiles;
	//`log("MAV: " $ Unit.GetFullName() $ " moved " $ Tiles $ " tiles in concealment");

	// Submit game state
	NewGameState.AddStateObject(NewRoot);
	SubmitGameState(NewGameState);
	
	return ELR_NoInterrupt;
}

function int GetStatsIndexForUnit(int UnitID)
{
	local int i;
	local MAV_UnitStats Stats;

	for (i = 0; i < MAV_Stats.Length; ++i)
	{
		if (MAV_Stats[i].UnitID == UnitID)
		{
			return i;
		}
	}

	Stats.UnitID = UnitID;
	i = MAV_Stats.Length;
	MAV_Stats.AddItem(Stats);

	return i;
}

function bool IsAbilityAvailable(StateObjectReference StateRef, name AbilityName)
{
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_Unit OutCachedAbilitiesInfo;
	local AvailableAction Action;
	local int Index;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	TacticalRules.GetGameRulesCache_Unit(StateRef, OutCachedAbilitiesInfo);
	
	for( Index = 0; Index < OutCachedAbilitiesInfo.AvailableActions.Length; ++Index )
	{		
		Action = OutCachedAbilitiesInfo.AvailableActions[Index];
		SelectedAbilityState = XComGameState_Ability( History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID) );
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();	

		//`log("    MAVAbility action: " $ SelectedAbilityTemplate.DataName $ ", code: " $ Action.AvailableCode); 
		if( SelectedAbilityTemplate.DataName == AbilityName && Action.AvailableCode == 'AA_Success' )
		{
			return true;
		}
	}

	return false;
}

function EventListenerReturn OnUnitTookDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;	
	local XComGameStateContext_Ability Context;
	local XComGameState_MissionStats_Root NewRoot;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit DamagedUnit, AttackingUnit;
	local DamageResult DamageResult;
	local int WoundHP, DamageAmount, i, j, Tiles;
	local name TemplateName;
	local MAV_DamageResult Entry;
	local bool Found, IsKilled;
	local array<XComGameState_Unit> OriginalUnits, PlayableUnits;
	local XComTacticalController kTacticalController;
	local X2EffectTemplateRef LookupEffect;
	local X2Effect SourceEffect;

	DamagedUnit = XComGameState_Unit(EventSource);

	if (DamagedUnit == none || DamagedUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;
	
	TemplateName = DamagedUnit.GetMyTemplateName();
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Damage UnitStats for " $ DamagedUnit.GetFullName());
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);	
	NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', self.ObjectID));

	DamageResult = DamagedUnit.DamageResults[DamagedUnit.DamageResults.Length-1];
	Context = XComGameStateContext_Ability(GameState.GetContext());

	if (Context == none)
	{
		// Elemental damage
		LookupEffect = DamageResult.SourceEffect.EffectRef;
		SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);

		if (X2Effect_ApplyWeaponDamage(SourceEffect) != none)
		{
			AttackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(DamageResult.SourceEffect.SourceStateObjectRef.ObjectID));
		}
	}
	else
	{	
		AttackingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	}

	//`log("===============  UNIT TOOK DAMAGE  ====================");
	//`log("Attacker: " $ AttackingUnit.GetFullName());
	//`log("Damaged: " $ DamagedUnit.GetFullName() @ "-" @ TemplateName);
	//`log("DamageAmt: " $ DamageResult.DamageAmount);

	if (AttackingUnit != none && class'MAV_Utilities'.static.IsFriendly(AttackingUnit))
	{
		// Update stats if we were the attacker
		i = NewRoot.GetStatsIndexForUnit(AttackingUnit.ObjectID);

		DamageAmount = DamageResult.DamageAmount;

		// Civilian damage should count for a lot so they are properly shamed by Hates 'X' award
		if (DamagedUnit.IsSoldier())
		{
			DamageAmount *= 2000;
		}
		else if (DamagedUnit.IsCivilian() || TemplateName == 'Civilian' || TemplateName == 'FriendlyVIPCivilian' || TemplateName == 'HostileCivilian' || TemplateName == 'HostileVIPCivilian')
		{
			DamageAmount *= 1000;
		}

		NewRoot.MAV_Stats[i].DamageDealt += DamageResult.DamageAmount;

		// Add damage entry to unit
		Found = false;
		IsKilled = DamagedUnit.IsDead();

		for (j = 0; j < NewRoot.MAV_Stats[i].EnemyStats.Length; ++j)
		{
			if (NewRoot.MAV_Stats[i].EnemyStats[j].UnitID == DamagedUnit.ObjectID)
			{
				NewRoot.MAV_Stats[i].EnemyStats[j].Damage += DamageAmount;
				NewRoot.MAV_Stats[i].EnemyStats[j].Killed = IsKilled;
				Found = true;
				break;
			}
		}

		if (IsKilled)
		{
			NewRoot.MAV_Stats[i].KillsThisTurn++;
			if (NewRoot.MAV_Stats[i].KillsThisTurn > NewRoot.MAV_Stats[i].MaxKillsInTurn)
			{
				NewRoot.MAV_Stats[i].MaxKillsInTurn = NewRoot.MAV_Stats[i].KillsThisTurn;
			}
			//`log("MAV max kills in turn for " $ AttackingUnit.GetFullName() $ ": " $ NewRoot.MAV_Stats[i].MaxKillsInTurn);
		}

		if (!Found)
		{
			Entry.UnitID = DamagedUnit.ObjectID;
			Entry.Damage = DamageAmount;
			Entry.Killed = IsKilled;
			NewRoot.MAV_Stats[i].EnemyStats.AddItem(Entry);
		}

		// Relevant when an ability was used, ie. not persistent elemental damage
		if (Context != none)
		{
			// Crit Damage
			if (Context.ResultContext.HitResult == eHit_Crit)
			{
				NewRoot.MAV_Stats[i].CritDamage += DamageResult.DamageAmount;
			}

			// Close range damage
			Tiles = AttackingUnit.TileDistanceBetween(DamagedUnit);
			if (Tiles <= CloseRangeTiles)
			{
				NewRoot.MAV_Stats[i].CloseRangeValue += (CloseRangeTiles - Tiles + 1) + DamageResult.DamageAmount;
			}
		}

		// Damage while wounded for "Ain't Got Time to Bleed"
		if (AttackingUnit.IsInjured())
		{
			WoundHP = AttackingUnit.GetMaxStat(eStat_HP) - AttackingUnit.GetCurrentStat(eStat_HP);
			NewRoot.MAV_Stats[i].WoundedDamage = WoundHP + DamageResult.DamageAmount;
		}

		// Damage while shorthanded for "Unfinished Business"
		if (!Shorthanded)
		{
			kTacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
			kTacticalController.m_XGPlayer.GetOriginalUnits(OriginalUnits, true);
			kTacticalController.m_XGPlayer.GetPlayableUnits(PlayableUnits, true);

			//`log("MAV O.G. Units:" @ OriginalUnits.Length @ ", Playable:" @ PlayableUnits.Length);

			if (PlayableUnits.Length < OriginalUnits.Length)
			{
				Shorthanded = true;
			}
		}

		if (Shorthanded)
		{
			NewRoot.MAV_Stats[i].ShorthandedDamage += DamageResult.DamageAmount;
		}

		// Damage while in evac zone for "Parting Gift"
		if (IsAbilityAvailable(AttackingUnit.GetReference(), 'Evac'))
		{
			NewRoot.MAV_Stats[i].EvacDamageDealt += DamageResult.DamageAmount;
			//`log("MAV: " $ AttackingUnit.GetFullName() $ " dealt evac damage: " $ DamageResult.DamageAmount);
		}

		// Elemental damage
		if (SourceEffect != none)
		{
			//`log("    " $ AttackingUnit.GetFullName() $ " applied source effect: " $ X2Effect_ApplyWeaponDamage(SourceEffect).EffectDamageValue.DamageType);
			switch (X2Effect_ApplyWeaponDamage(SourceEffect).EffectDamageValue.DamageType)
			{
				case 'Fire':
					NewRoot.MAV_Stats[i].BurnDamageDealt += DamageResult.DamageAmount;
					//`log("MAVburn: " $ AttackingUnit.GetFullName() $ " dealt burn damage: " $ DamageResult.DamageAmount);
					break;

				case 'Poison':
					NewRoot.MAV_Stats[i].PoisonDamageDealt += DamageResult.DamageAmount;
					//`log("MAVpoison: " $ AttackingUnit.GetFullName() $ " dealt poison damage: " $ DamageResult.DamageAmount);
					break;

				case 'Acid':
					NewRoot.MAV_Stats[i].AcidDamageDealt += DamageResult.DamageAmount;
					//`log("MAVacid: " $ AttackingUnit.GetFullName() $ " dealt acid damage: " $ DamageResult.DamageAmount);
					break;
			}
		}
	}
	
	if (NewRoot != none)
	{
		// Submit game state
		NewGameState.AddStateObject(NewRoot);
		SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnBrokeWindow(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit Unit;
	//`log("MAV - a window broke");

	Unit = XComGameState_Unit(EventSource);

	if (class'MAV_Utilities'.static.IsFriendly(Unit))
	{
		//`log("MAV - " $ Unit.GetFullName() $ " broke a damn window");
		UpdateStats(Unit, none, none, PropertyDamageDelegate);
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnKickedDoor(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit Unit;
	//`log("MAV - a door was kicked");

	Unit = XComGameState_Unit(EventSource);

	if (class'MAV_Utilities'.static.IsFriendly(Unit))
	{
		//`log("MAV - " $ Unit.GetFullName() $ " kicked a damn door");
		UpdateStats(Unit, none, none, PropertyDamageDelegate);
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn OnBlownUp(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Unit Unit;
	
	DamageEvent = XComGameState_EnvironmentDamage(EventSource);
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(DamageEvent.DamageCause.ObjectID));

	if (class'MAV_Utilities'.static.IsFriendly(Unit))
	{
		//`log("MAV - environmental damage caused by " $ Unit.GetFullName());
		UpdateStats(Unit, none, none, PropertyDamageDelegate);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;	
	local XComGameState_MissionStats_Root NewRoot;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local int i;

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Resetting kills this turn");
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);	
	NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', self.ObjectID));

	// Reset each soldier's kills made this turn
	for (i = 0; i < MAV_Stats.Length; ++i)
	{
		NewRoot.MAV_Stats[i].KillsThisTurn = 0;
		NewRoot.MAV_Stats[i].FiredPrimaryWeaponThisTurn = false;
	}

	//`log("MAV turn began");

	// Submit game state
	NewGameState.AddStateObject(NewRoot);
	SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn OnPlayerTurnEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;	
	local XComGameState_MissionStats_Root NewRoot;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local int i, NumVisibleEnemies, CoverValue;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;

	History = `XCOMHISTORY;

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Recording cover and ammo");
	NewGameState = History.CreateNewGameState(true, ChangeContainer);	
	NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', self.ObjectID));

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetTeam() == eTeam_XCom && !Unit.IsDead())
		{
			if (Unit.CanTakeCover() && !Unit.IsConcealed() && !Unit.IsInStasis())
			{
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
					i = GetStatsIndexForUnit(Unit.ObjectID);
					NewRoot.MAV_Stats[i].Exposure += CoverValue * NumVisibleEnemies;
					//`log("MAV: " $ Unit.GetFullName() $ " exposed to " $ NumVisibleEnemies $ " enemies, cover: " $ CoverValue);
				}
			}

			// Check amount of ammo for Who Needs Ammo award
			Weapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
			if (Weapon != none && Weapon.Ammo == 0 && !Weapon.HasInfiniteAmmo() && !NewRoot.MAV_Stats[i].FiredPrimaryWeaponThisTurn)
			{
				NewRoot.MAV_Stats[i].TurnsWithoutAmmo += Weapon.GetClipSize();
				//`log("MAV: " $ Unit.GetFullName() $ " ended turn with no ammo");
			}
		}
	}

	//`log("MAV turn ended");

	// Submit game state
	NewGameState.AddStateObject(NewRoot);
	SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

function MAV_UnitStats UpdateStats(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, delegate<AbilityDelegate> MyDelegate)
{
	local XComGameState NewGameState;
	local MAV_UnitStats UnitStats;
	local XComGameState_MissionStats_Root NewRoot;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local int i;

	// Setup new game state
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding Ability MAV UnitStats to " $ Unit.GetFullName());
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
	NewRoot = XComGameState_MissionStats_Root(NewGameState.CreateStateObject(class'XComGameState_MissionStats_Root', self.ObjectID));

	i = NewRoot.GetStatsIndexForUnit(Unit.ObjectID);
	UnitStats = MyDelegate(Unit, Ability, AbilityContext, NewRoot.MAV_Stats[i]);
	NewRoot.MAV_Stats[i] = UnitStats;

	//`log("===============  AbilityStats  ====================");
	//`log("Ability: " $ Ability.GetMyTemplateName());
	//`log("Name: " $ Unit.GetFullName());
	class'MAV_Utilities'.static.LogStats(UnitStats);
	
	NewGameState.AddStateObject(NewRoot);
	SubmitGameState(NewGameState);
	
	return UnitStats;
}

function MAV_UnitStats ShotDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, MAV_UnitStats UnitStats)
{
	local int Chance;
	local XComGameState_Unit OwnerUnit, TargetUnit;
	local bool IsOverwatch;
	local XComGameStateHistory History;
	local XComGameState_Item Weapon;

	History = `XCOMHISTORY;
	OwnerUnit = XComGameState_Unit(History.GetGameStateForObjectID(Ability.OwnerStateObject.ObjectID));

	// Calculate luck
	Chance = Clamp(AbilityContext.ResultContext.CalculatedHitChance, 0, 100);
	if (class'MAV_Utilities'.static.IsFriendly(OwnerUnit))
	{
		UnitStats.ShotsTaken++;

		Weapon = Ability.GetSourceWeapon();
		if (Weapon != none)
		{
			if (Weapon.InventorySlot == eInvSlot_PrimaryWeapon)
			{
				UnitStats.FiredPrimaryWeaponThisTurn = true;
			}
		}

		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Luck += (100 - Chance);
			UnitStats.SuccessfulShots++;
		}
		else
		{
			UnitStats.Luck -= Chance;
		}

		// Determine elevation for Most High award
		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if (OwnerUnit.HasHeightAdvantageOver(TargetUnit, true))
		{
			UnitStats.Elevation += (OwnerUnit.TileLocation.Z - TargetUnit.TileLocation.Z);
		}
	}
	else
	{
		IsOverwatch = (Ability.GetMyTemplateName() == 'OverwatchShot');
		
		if (IsOverwatch)
			UnitStats.OverwatchTaken++;

		if (AbilityContext.IsResultContextHit())
		{
			UnitStats.Luck -= (100 - Chance);
		}
		else
		{
			UnitStats.Luck += Chance;

			if (IsOverwatch)
				UnitStats.OverwatchTaken++;
		}

		UnitStats.ShotsAgainst++;
	}

	return UnitStats;
}

function MAV_UnitStats TurtleDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, MAV_UnitStats UnitStats)
{
	local name TemplateName;
	TemplateName = Ability.GetMyTemplateName();

	if (TemplateName == 'Overwatch')
		UnitStats.Turtle += TurtleScoreOverwatch;
	else if (TemplateName == 'HunkerDown')
		UnitStats.Turtle += TurtleScoreHunkerDown;

	return UnitStats;
}

function MAV_UnitStats PropertyDamageDelegate(XComGameState_Unit Unit, XComGameState_Ability Ability, XComGameStateContext_Ability AbilityContext, MAV_UnitStats UnitStats)
{
	UnitStats.PropertyDamage++;
	return UnitStats;
}

defaultproperties
{
	CURRENT_VERSION = "1.3.1";
}
