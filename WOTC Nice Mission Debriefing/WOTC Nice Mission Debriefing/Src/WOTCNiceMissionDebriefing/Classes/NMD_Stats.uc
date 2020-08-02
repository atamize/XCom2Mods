class NMD_Stats extends XComGameState_BaseObject;

var string category;

// Stats pulled from AbilityActivated
var int numShots;
var int numHits;
var int numMisses;
var int numCrits;
var int numGrazed;
var float expectedHits;
var float expectedCrits;

// Stats created from AbilityActivated
var int currHitStreak;
var int bestHitStreak;
var int currMissStreak;
var int worstMissStreak;

// Stats pulled from OnUnitTakeEffectDamage
var int damageDealt;
var int damageTaken;
var int damageNegated;
var int damageAbsorbed;
var int numExecutions;
var int numKills;

// Stats pulled from ObjectMoved
var int tilesMoved;

// To prevent duplicate kills (mostly fanfire)
var int prevKillId;

function NMD_Stats initComponent(string statsCategory) {
	numShots = 0; numHits = 0; numMisses = 0; numCrits = 0; numGrazed = 0;
	expectedHits = 0; expectedCrits = 0;
	currHitStreak = 0; bestHitStreak = 0; currMissStreak = 0; worstMissStreak = 0;
	damageDealt = 0; damageTaken = 0; damageNegated = 0; damageAbsorbed = 0;
	numExecutions = 0;
	prevKillId = 0;
		
	category = statsCategory;	
	return self;
}

function addShot(bool isHit, EAbilityHitResult hitResult, float toHit, float toCrit) {
	numShots++;
	if( isHit ) {
		numHits++;
		currHitStreak++;
		bestHitStreak  = Max(bestHitStreak, currHitStreak);
		currMissStreak = 0;
	} else {
		numMisses++;
		currMissStreak++;
		worstMissStreak = Max(worstMissStreak, currMissStreak);
		currHitStreak   = 0;
	}
	
	numCrits  = (hitResult == eHit_Crit)  ? numCrits +1 : numCrits;
	numGrazed = (hitResult == eHit_Graze) ? numGrazed+1 : numGrazed;
	
	expectedHits  += toHit;
	expectedCrits += toCrit;

	if (class'NMD_Utilities'.default.bLog) `LOG("----NMD AddShot: " $ category $ " ----");
	if (class'NMD_Utilities'.default.bLog) `LOG("numHits     : " $ numHits);
	if (class'NMD_Utilities'.default.bLog) `LOG("numShots : " $ numShots);
	if (class'NMD_Utilities'.default.bLog) `LOG("numMisses     : " $ numMisses);
}

function addDamageDone(int dealt, int negated, bool executed, bool isDead, int targetId) {
	damageDealt   += dealt;
	damageNegated += negated;
	numExecutions  = executed ? numExecutions+1 : numExecutions;
	
	// fix for overkilling
	if( isDead ) {
		if( prevKillId != targetId )
			numKills++;
		prevKillId = targetId;
	}
	
	
		if (class'NMD_Utilities'.default.bLog) `LOG("----NMD DamageDone: " $ category $ " ----");
		if (class'NMD_Utilities'.default.bLog) `LOG("Dealt     : " $ damageDealt);
		if (class'NMD_Utilities'.default.bLog) `LOG("Mitigated : " $ damageNegated);
		if (class'NMD_Utilities'.default.bLog) `LOG("Kills     : " $ numKills);
	
}

function addDamageTaken(int taken, int absorbed) {
	damageTaken   += taken;
	damageAbsorbed = absorbed;
}

function addTilesMoved(int moved) {
	tilesMoved += moved;
}

function float getEHits() {
	return expectedHits/100;
}

function float getECrits() {
	return expectedCrits/100;
}

function string getLuckStr() {
	local float luck;
	if( numShots == 0 ) return "?";
	else {
		luck = 100 * Abs(numHits / getEHits() - 1);
		return Left(string(luck), 4);
	}
}

function string getAvgHitStr() {
	local float avgHit;
	if( numShots == 0 ) return "?";
	else {
		avgHit = expectedHits / numShots;
		return Left(string(avgHit), 4);
	}
}

function string getAvgCritStr() {
	local float avgCrit;
	if( numShots == 0 ) return "?";
	else {
		avgCrit = expectedCrits / numShots;
		return Left(string(avgCrit), 4);
	}
}

function bool isLucky() {
	return numHits >= getEHits();
}
