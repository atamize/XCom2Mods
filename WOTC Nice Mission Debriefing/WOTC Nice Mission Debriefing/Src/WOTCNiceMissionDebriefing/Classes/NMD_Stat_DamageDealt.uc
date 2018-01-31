class NMD_Stat_DamageDealt extends NMD_BaseStat;

const ID = 'DamageDealt';

var int DamageDealt;

function InitComponent()
{
	DamageDealt = -1;
	Value = 0;
}

function AddValue(int Amount)
{
	
}

function int GetValue(int UnitID)
{
	local XComGameState_Analytics Analytics;

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	Value = int(Analytics.GetTacticalFloatValue("UNIT_" $ UnitID $ "_ACC_UNIT_DEALT_DAMAGE"));
	
	return Value;
}

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strDamageDealt;
}

function name GetType()
{
	return ID;
}
