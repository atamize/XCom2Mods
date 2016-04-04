//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionStats_Unit
//  AUTHOR:  atamize
//  PURPOSE: Store the mission stats of a given unit as a component to XComGameState_Unit
//
//--------------------------------------------------------------------------------------- 
class XComGameState_MissionStats_Unit extends XComGameState_BaseObject;

struct MAV_DamageResult
{
	var int UnitID;
	var int Damage;
	var bool Killed;
};

var int UnitID;
var int Luck;
var int DamageDealt;
var int Elevation;
var int CritDamage;
var int WoundedDamage; // For the "Ain't Got Time to Bleed" award
var int Turtle; // Sums overwatching and hunkers for Turtle award
var int ShotsAgainst;
var int CloseRangeValue; // Tiles + Damage for close range award
var array<MAV_DamageResult> EnemyStats;

function XComGameState_MissionStats_Unit InitComponent()
{
	Luck = 0;
	DamageDealt = 0;
	Elevation = 0;
	CritDamage = 0;
	WoundedDamage = 0;
	Turtle = 0;
	ShotsAgainst = 0;
	CloseRangeValue = 0;
	EnemyStats.Length = 0;

	return self;
}

function AddDamageToUnit(int MyUnitID, int DamageAmount, bool Killed)
{
	local MAV_DamageResult Entry;

	foreach EnemyStats(Entry)
	{
		if (Entry.UnitID == MyUnitID)
		{
			Entry.Damage += DamageAmount;
			Entry.Killed = Killed;
			return;
		}
	}

	Entry.UnitID = MyUnitID;
	Entry.Damage = DamageAmount;
	Entry.Killed = Killed;
	EnemyStats.AddItem(Entry);
}
