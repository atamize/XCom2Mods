class XComGameState_NMD_Unit extends XComGameState_BaseObject;

var array<name> StatTypes;
var array<StateObjectReference> StatsRefs;
var array<NMD_BaseStat> DynamicStats;

// Help figure out fanfire damage -- TODO: figure out better way to handle this
var int multifireIndex;
var int multifireHistoryIndex;

struct NMD_DamageResult
{
	var int UnitID;
	var int Damage;
	var bool Killed;
};

var array<NMD_DamageResult> EnemyDamageResults;

function XComGameState_NMD_Unit InitComponent(XComGameState NewGameState, optional bool upgrade=false)
{
	CreateOrUpdateStat(class'NMD_PersistentStat_PosterData'.const.ID, class'NMD_PersistentStat_PosterData', NewGameState);

	CreateOrUpdateStat(class'NMD_Stat_TilesMoved'.const.ID, class'NMD_Stat_TilesMoved', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_DamageDealt'.const.ID, class'NMD_Stat_DamageDealt', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_ShotAccuracy'.const.ID, class'NMD_Stat_ShotAccuracy', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_Kills'.const.ID, class'NMD_Stat_Kills', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_OverwatchAccuracy'.const._ID, class'NMD_Stat_OverwatchAccuracy', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_Headshots'.const.ID, class'NMD_Stat_Headshots', NewGameState);
	return self;
}

function ClearMissionStats(XComGameState NewGameState)
{
	local NMD_BaseStat Stat;
	local int i;

	for (i = 0; i < StatsRefs.Length; ++i)
	{
		Stat = NMD_BaseStat(`XCOMHISTORY.GetGameStateForObjectID(StatsRefs[i].ObjectID));
		if (!Stat.IsPersistent())
		{
			Stat = NMD_BaseStat(NewGameState.CreateStateObject(class'NMD_BaseStat', Stat.ObjectID));
			Stat.InitComponent();
			`log("NMD - clearing mission stat " $ Stat.GetType());
			NewGameState.AddStateObject(Stat);
		}
	}

	EnemyDamageResults.Length = 0;
}

function AddDynamicStat(NMD_BaseStat Stat)
{
	DynamicStats.AddItem(Stat);
}

function NMD_BaseStat GetStat(name StatType)
{
	local int i;

	for (i = 0; i < StatTypes.Length; ++i)
	{
		if (StatTypes[i] == StatType)
		{
			return NMD_BaseStat(`XCOMHISTORY.GetGameStateForObjectID(StatsRefs[i].ObjectID));	
		}
	}

	for (i = 0; i < DynamicStats.Length; ++i)
	{
		if (DynamicStats[i].GetType() == StatType)
		{
			return DynamicStats[i];
		}
	}

	return none;
}

function NMD_BaseStat CreateStat(name Type, class<NMD_BaseStat> StatClass, XComGameState NewGameState)
{
	local NMD_BaseStat ToReturn;

	ToReturn = NMD_BaseStat(NewGameState.CreateStateObject(StatClass));
	ToReturn.InitComponent();
	StatsRefs.AddItem(ToReturn.GetReference());
	StatTypes.AddItem(Type);
	
	NewGameState.AddStateObject(ToReturn);
	return ToReturn;
}

function NMD_BaseStat CreateOrUpdateStat(name Type, class<NMD_BaseStat> StatClass, XComGameState NewGameState)
{
	local NMD_BaseStat ToReturn;
	
	ToReturn = GetStat(Type);
	if (ToReturn == none)
		return CreateStat(Type, StatClass, NewGameState);

	return NMD_BaseStat(NewGameState.CreateStateObject(StatClass, ToReturn.ObjectID));
}

function AddShot(string catToAdd, bool isHit, EAbilityHitResult hitResult, float toHit, float toCrit, XComGameState NewGameState)
{
	local NMD_Stat_ShotAccuracy Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_ShotAccuracy'.const.ID, class'NMD_Stat_ShotAccuracy', NewGameState);

	Stat = NMD_Stat_ShotAccuracy(NewGameState.CreateStateObject(class'NMD_Stat_ShotAccuracy', BaseStat.ObjectID));
	Stat.AddShot(isHit);
	NewGameState.AddStateObject(Stat);
}

function AddOverwatchShot(bool isHit, XComGameState NewGameState)
{
	local NMD_Stat_OverwatchAccuracy Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_OverwatchAccuracy'.const._ID, class'NMD_Stat_OverwatchAccuracy', NewGameState);

	Stat = NMD_Stat_OverwatchAccuracy(NewGameState.CreateStateObject(class'NMD_Stat_OverwatchAccuracy', BaseStat.ObjectID));
	Stat.AddShot(isHit);
	NewGameState.AddStateObject(Stat);
}

function AddCloseRangeDamage(XComGameState_Unit AttackingUnit, XComGameState_Unit DamagedUnit, int DamageDealt, XComGameState NewGameState)
{
	local NMD_Stat_CloseRange Stat;
	local NMD_BaseStat BaseStat;
	local int Tiles;
	local int CloseRangeValue;

	BaseStat = CreateOrUpdateStat(class'NMD_Stat_CloseRange'.const.ID, class'NMD_Stat_CloseRange', NewGameState);

	Stat = NMD_Stat_CloseRange(NewGameState.CreateStateObject(class'NMD_Stat_CloseRange', BaseStat.ObjectID));

	Tiles = AttackingUnit.TileDistanceBetween(DamagedUnit);
	if (Tiles <= 2)
	{
		CloseRangeValue += (2 - Tiles + 1) + DamageDealt;
	}
	Stat.AddValue(CloseRangeValue);
	`log("NMD - Total close range damage for " $ AttackingUnit.GetFullName() $ ": " $ Stat.GetValue(0)); 
	NewGameState.AddStateObject(Stat);
}

function AddCriticalDamage(int DamageDealt, XComGameState NewGameState)
{
	local NMD_Stat_CriticalDamage Stat;
	local NMD_BaseStat BaseStat;

	BaseStat = CreateOrUpdateStat(class'NMD_Stat_CriticalDamage'.const.ID, class'NMD_Stat_CriticalDamage', NewGameState);

	Stat = NMD_Stat_CriticalDamage(NewGameState.CreateStateObject(class'NMD_Stat_CriticalDamage', BaseStat.ObjectID));

	Stat.AddValue(DamageDealt);
	NewGameState.AddStateObject(Stat);
}

function AddWoundedDamage(XComGameState_Unit Unit, int DamageDealt, XComGameState NewGameState)
{
	local NMD_Stat_WoundedDamage Stat;
	local NMD_BaseStat BaseStat;
	local int WoundHP;

	BaseStat = CreateOrUpdateStat(class'NMD_Stat_WoundedDamage'.const.ID, class'NMD_Stat_WoundedDamage', NewGameState);

	Stat = NMD_Stat_WoundedDamage(NewGameState.CreateStateObject(class'NMD_Stat_WoundedDamage', BaseStat.ObjectID));

	WoundHP = Unit.GetMaxStat(eStat_HP) - Unit.GetCurrentStat(eStat_HP);

	Stat.AddValue(WoundHP * DamageDealt);
	NewGameState.AddStateObject(Stat);
}

function AddShotFromElevation(XComGameState_Unit AttackingUnit, XComGameState_Unit TargetUnit, XComGameState NewGameState)
{
	local NMD_Stat_ShotsFromElevation Stat;
	local NMD_BaseStat BaseStat;
	local int Value;

	BaseStat = CreateOrUpdateStat(class'NMD_Stat_ShotsFromElevation'.const.ID, class'NMD_Stat_ShotsFromElevation', NewGameState);

	Stat = NMD_Stat_ShotsFromElevation(NewGameState.CreateStateObject(class'NMD_Stat_ShotsFromElevation', BaseStat.ObjectID));
	Value = AttackingUnit.TileLocation.Z - TargetUnit.TileLocation.Z;
	Stat.AddValue(Value);

	`log("NMD - Total elevation shot value for " $ AttackingUnit.GetFullName() $ ": " $ Stat.GetValue(0));
	NewGameState.AddStateObject(Stat);
}

function AddHeadshot(XComGameState_Unit Unit, XComGameState NewGameState)
{
	local NMD_Stat_Headshots Stat;
	local NMD_BaseStat BaseStat;

	BaseStat = CreateOrUpdateStat(class'NMD_Stat_Headshots'.const.ID, class'NMD_Stat_Headshots', NewGameState);

	Stat = NMD_Stat_Headshots(NewGameState.CreateStateObject(class'NMD_Stat_Headshots', BaseStat.ObjectID));
	Stat.AddValue(1);

	`log("NMD - Headshot damage for " $ Unit.GetFullName() $ ": " $ Stat.GetValue(0));
	NewGameState.AddStateObject(Stat);
}

function AddDamageDone(string catToAdd, int dealt, int negated, bool executed, bool isKill, XComGameState_Unit Attacker, XComGameState_Unit Unit, XComGameStateContext_Ability Context, XComGameState NewGameState)
{
	local int i;
	local bool Found;
	local NMD_DamageResult Result;
	
	Found = false;

	`log("NMD - " $ Attacker.GetFullName() $ " has damaged enemies: " $ EnemyDamageResults.Length);
	for (i = 0; i < EnemyDamageResults.Length; ++i)
	{
		if (Unit.ObjectID == EnemyDamageResults[i].UnitID)
		{
			EnemyDamageResults[i].Damage += Dealt;
			EnemyDamageResults[i].Killed = IsKill;

			`log("NMD - " $ catToAdd $ " dealt damage: " $ dealt $ "; total: " $ EnemyDamageResults[i].Damage);

			Found = true;
			break;
		}
	}

	if (!Found)
	{
		Result.UnitID = Unit.ObjectID;
		Result.Damage = Dealt;
		Result.Killed = IsKill;
		EnemyDamageResults.AddItem(Result);

		`log("NMD - " $ catToAdd $ " dealt damage: " $ dealt $ ", isKill? " $ isKill);
	}

	if (Context != none)
	{
		if (Context.ResultContext.HitResult == eHit_Crit)
		{
			AddCriticalDamage(Dealt, NewGameState);
		}

		AddCloseRangeDamage(Attacker, Unit, Dealt, NewGameState);

		if (IsKill)
		{
			if (Unit.GetMyTemplate().CharacterGroupName == 'TheLost')
			{
				if (class'X2Effect_TheLostHeadshot'.default.ValidHeadshotAbilities.Find(Context.InputContext.AbilityTemplateName) != INDEX_NONE)
				{
					AddHeadshot(Attacker, NewGameState);
				}
			}
		}
	}

	if (Attacker.IsInjured())
	{
		AddWoundedDamage(Attacker, Dealt, NewGameState);
	}

	if (class'NMD_Utilities'.static.IsAbilityAvailable(Attacker.GetReference(), 'Evac'))
	{
		AddEvacDamage(Dealt, NewGameState);
	}
	/*
	local NMD_Stat_DamageDealt Stat;
	local NMD_Stat_Kills KillStat;
	local NMD_BaseStat BaseStat;
	
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_DamageDealt'.const.ID, class'NMD_Stat_DamageDealt', NewGameState);

	Stat = NMD_Stat_DamageDealt(NewGameState.CreateStateObject(class'NMD_Stat_DamageDealt', BaseStat.ObjectID));
	Stat.AddValue(dealt);
	NewGameState.AddStateObject(Stat);
	
	`log("NMD - " $ catToAdd $ " dealt damage: " $ dealt $ ", isKill? " $ isKill);

	if (isKill)
	{
	
		BaseStat = CreateOrUpdateStat(class'NMD_Stat_Kills'.const.ID, class'NMD_Stat_Kills', NewGameState);
		KillStat = NMD_Stat_Kills(NewGameState.CreateStateObject(class'NMD_Stat_Kills', BaseStat.ObjectID));
		KillStat.AddValue(1);
		NewGameState.AddStateObject(KillStat);
		`log("NMD - Kill should have been logged: " $ KillStat.GetValue() $ " at ObjectID: " $ BaseStat.ObjectID);
		Kills = KillStat.GetValue();
	
	}
	*/
}

function addDamageTaken(string catToAdd, int taken, int absorbed, XComGameState NewGameState) {
	//local NMD_Stats subStats, MainStats;
	//
	//MainStats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', MainStatsRef.ObjectID));
	//subStats = createOrUpdateSubStats(catToAdd, NewGameState);
//
	//MainStats.addDamageTaken(taken, absorbed);
	//subStats.addDamageTaken(taken, absorbed);
	//NewGameState.AddStateObject(MainStats);
	//NewGameState.AddStateObject(subStats);
}

function NMD_Stat_TilesMoved AddTilesMoved(int Moved, XComGameState NewGameState)
{
	local NMD_Stat_TilesMoved Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_TilesMoved'.const.ID, class'NMD_Stat_TilesMoved', NewGameState);

	Stat = NMD_Stat_TilesMoved(NewGameState.CreateStateObject(class'NMD_Stat_TilesMoved', BaseStat.ObjectID));
	Stat.AddValue(Moved);
	NewGameState.AddStateObject(Stat);

	return Stat;
}

function NMD_Stat_ConcealedTiles AddConcealedTilesMoved(int Moved, XComGameState NewGameState)
{
	local NMD_Stat_ConcealedTiles Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_ConcealedTiles'.const.ID, class'NMD_Stat_ConcealedTiles', NewGameState);

	Stat = NMD_Stat_ConcealedTiles(NewGameState.CreateStateObject(class'NMD_Stat_ConcealedTiles', BaseStat.ObjectID));
	Stat.AddValue(Moved);
	NewGameState.AddStateObject(Stat);

	return Stat;
}

function NMD_Stat_OverwatchRuns AddOverwatchRun(bool IsHit, XComGameState NewGameState)
{
	local NMD_Stat_OverwatchRuns Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_OverwatchRuns'.const.ID, class'NMD_Stat_OverwatchRuns', NewGameState);

	Stat = NMD_Stat_OverwatchRuns(NewGameState.CreateStateObject(class'NMD_Stat_OverwatchRuns', BaseStat.ObjectID));

	if (IsHit)
		Stat.AddValue(1);
	else
		Stat.AddValue(2);

	NewGameState.AddStateObject(Stat);

	return Stat;
}

function NMD_Stat_Exposure AddExposure(int Value, XComGameState NewGameState)
{
	local NMD_Stat_Exposure Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_Exposure'.const.ID, class'NMD_Stat_Exposure', NewGameState);

	Stat = NMD_Stat_Exposure(NewGameState.CreateStateObject(class'NMD_Stat_Exposure', BaseStat.ObjectID));
	Stat.AddValue(Value);

	NewGameState.AddStateObject(Stat);

	return Stat;
}

function NMD_Stat_EnvironmentDamage AddEnvironmentDamage(int Value, XComGameState NewGameState)
{
	local NMD_Stat_EnvironmentDamage Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_EnvironmentDamage'.const.ID, class'NMD_Stat_EnvironmentDamage', NewGameState);

	Stat = NMD_Stat_EnvironmentDamage(NewGameState.CreateStateObject(class'NMD_Stat_EnvironmentDamage', BaseStat.ObjectID));
	Stat.AddValue(Value);

	NewGameState.AddStateObject(Stat);

	return Stat;
}

function NMD_Stat_EvacDamage AddEvacDamage(int Value, XComGameState NewGameState)
{
	local NMD_Stat_EvacDamage Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_Stat_EvacDamage'.const.ID, class'NMD_Stat_EvacDamage', NewGameState);

	Stat = NMD_Stat_EvacDamage(NewGameState.CreateStateObject(class'NMD_Stat_EvacDamage', BaseStat.ObjectID));
	Stat.AddValue(Value);

	NewGameState.AddStateObject(Stat);

	return Stat;
}

function SetPosterIndex(int Index, XComGameState NewGameState)
{
	local NMD_PersistentStat_PosterData Stat;
	local NMD_BaseStat BaseStat;
	
	BaseStat = CreateOrUpdateStat(class'NMD_PersistentStat_PosterData'.const.ID, class'NMD_PersistentStat_PosterData', NewGameState);

	Stat = NMD_PersistentStat_PosterData(NewGameState.CreateStateObject(class'NMD_PersistentStat_PosterData', BaseStat.ObjectID));
	Stat.SetIndex(Index);
	NewGameState.AddStateObject(Stat);
}

defaultproperties
{
	multifireIndex = 1;
	multifireHistoryIndex = -1;
}
