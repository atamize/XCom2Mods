class XComGameState_NMD_Unit extends XComGameState_BaseObject;

var array<name> StatTypes;
var array<StateObjectReference> StatsRefs;

// Help figure out fanfire damage -- TODO: figure out better way to handle this
var int multifireIndex;
var int multifireHistoryIndex;

function XComGameState_NMD_Unit InitComponent(XComGameState NewGameState, optional bool upgrade=false)
{
	CreateOrUpdateStat(class'NMD_PersistentStat_PosterData'.const.ID, class'NMD_PersistentStat_PosterData', NewGameState);

	CreateOrUpdateStat(class'NMD_Stat_TilesMoved'.const.ID, class'NMD_Stat_TilesMoved', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_DamageDealt'.const.ID, class'NMD_Stat_DamageDealt', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_ShotAccuracy'.const.ID, class'NMD_Stat_ShotAccuracy', NewGameState);
	CreateOrUpdateStat(class'NMD_Stat_Kills'.const.ID, class'NMD_Stat_Kills', NewGameState);
	return self;
}

function ClearMissionStats(XComGameState NewGameState)
{
	local NMD_BaseStat Stat;
	local int i;

	for (i = 0; i < StatsRefs.Length; ++i)
	{
		Stat = NMD_BaseStat(`XCOMHISTORY.GetGameStateForObjectID(StatsRefs[i].ObjectID));
		if (!Stat.IsPersistent)
		{
			Stat = NMD_BaseStat(NewGameState.CreateStateObject(class'NMD_BaseStat', Stat.ObjectID));
			Stat.InitComponent();
			//`log("NMD - clearing mission stat " $ Stat.GetType() $ " to value: " $ Stat.GetValue());
			NewGameState.AddStateObject(Stat);
		}
	}
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

function AddDamageDone(string catToAdd, int dealt, int negated, bool executed, bool isKill, int targetId, XComGameState NewGameState)
{
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
		`log("NMD - Kill should have been logged: " $ KillStat.GetValue());
	}
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
