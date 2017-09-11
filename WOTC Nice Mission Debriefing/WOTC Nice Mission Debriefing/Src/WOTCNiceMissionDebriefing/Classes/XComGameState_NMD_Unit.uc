class XComGameState_NMD_Unit extends XComGameState_BaseObject;// config (NMD);

var StateObjectReference MainStatsRef;
var array<string> Categories;
var array<StateObjectReference> subStatsRef;
var StateObjectReference PersistentDataRef;

// Help figure out fanfire damage -- TODO: figure out better way to handle this
var int multifireIndex;
var int multifireHistoryIndex;

function XComGameState_NMD_Unit InitComponent(XComGameState NewGameState, optional bool upgrade=false) {
	local NMD_Stats Stats;
	local NMD_PersistentData PersistentData;

	Stats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats'));
	Stats.initComponent("Main");
	
	MainStatsRef = Stats.GetReference();
	NewGameState.AddStateObject(Stats);

	PersistentData = NMD_PersistentData(NewGameState.CreateStateObject(class'NMD_PersistentData'));
	PersistentData.InitComponent();
	PersistentDataRef = PersistentData.GetReference();
	NewGameState.AddStateObject(PersistentData);
	return self;
}

function NMD_Stats GetMainStats() {
	return NMD_Stats(`XCOMHISTORY.GetGameStateForObjectID(MainStatsRef.ObjectID));
}

function NMD_Stats getSubStats(string catToGet) {
	local int i;
	
	for(i=0; i<Categories.Length; i++) {
		if( Categories[i] == catToGet )
			return NMD_Stats(`XCOMHISTORY.GetGameStateForObjectID(subStatsRef[i].ObjectID));
	}
	
	return none;
}

function NMD_PersistentData GetPersistentData()
{
	return NMD_PersistentData(`XCOMHISTORY.GetGameStateForObjectID(PersistentDataRef.ObjectID));
}

function NMD_Stats createSubStats(string catToGet, XComGameState NewGameState) {
	local NMD_Stats toReturn;
	
	toReturn = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats'));
	toReturn.initComponent(catToGet);
	subStatsRef.AddItem(toReturn.GetReference());
	Categories.AddItem(catToGet);
	
	NewGameState.AddStateObject(toReturn);
	return toReturn;
}

function NMD_Stats createOrUpdateSubStats(string catToGet, XComGameState NewGameState) {
	local NMD_Stats toReturn;
	
	toReturn = getSubStats(catToGet);
	if( toReturn == none )
		return createSubStats(catToGet, NewGameState);
	return NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', toReturn.ObjectID));
}

function addShot(string catToAdd, bool isHit, EAbilityHitResult hitResult, float toHit, float toCrit, XComGameState NewGameState) {
	local NMD_Stats subStats, MainStats;
	
	MainStats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', MainStatsRef.ObjectID));
	subStats = createOrUpdateSubStats(catToAdd, NewGameState);
	
	MainStats.addShot(isHit, hitResult, toHit, toCrit);
	subStats.addShot(isHit, hitResult, toHit, toCrit);
	NewGameState.AddStateObject(MainStats);
	NewGameState.AddStateObject(subStats);
}

function addDamageDone(string catToAdd, int dealt, int negated, bool executed, bool isKill, int targetId, XComGameState NewGameState) {
	local NMD_Stats subStats, MainStats;
	
	MainStats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', MainStatsRef.ObjectID));
	subStats = createOrUpdateSubStats(catToAdd, NewGameState);

	MainStats.addDamageDone(dealt, negated, executed, isKill, targetId);
	subStats.addDamageDone(dealt, negated, executed, isKill, targetId);
	NewGameState.AddStateObject(MainStats);
	NewGameState.AddStateObject(subStats);
}

function addDamageTaken(string catToAdd, int taken, int absorbed, XComGameState NewGameState) {
	local NMD_Stats subStats, MainStats;
	
	MainStats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', MainStatsRef.ObjectID));
	subStats = createOrUpdateSubStats(catToAdd, NewGameState);

	MainStats.addDamageTaken(taken, absorbed);
	subStats.addDamageTaken(taken, absorbed);
	NewGameState.AddStateObject(MainStats);
	NewGameState.AddStateObject(subStats);
}

function addTilesMoved(int moved, XComGameState NewGameState) {
	local NMD_Stats MainStats;
	
	MainStats = NMD_Stats(NewGameState.CreateStateObject(class'NMD_Stats', MainStatsRef.ObjectID));
	MainStats.addTilesMoved(moved);
	NewGameState.AddStateObject(MainStats);
}

function SetPosterIndex(int Index, XComGameState NewGameState)
{
	local NMD_PersistentData PersistentData;

	PersistentData = NMD_PersistentData(NewGameState.CreateStateObject(class 'NMD_PersistentData', PersistentDataRef.ObjectID));
	PersistentData.SetPosterIndex(Index);
	NewGameState.AddStateObject(PersistentData);
}

defaultproperties
{
	multifireIndex = 1;
	multifireHistoryIndex = -1;
}