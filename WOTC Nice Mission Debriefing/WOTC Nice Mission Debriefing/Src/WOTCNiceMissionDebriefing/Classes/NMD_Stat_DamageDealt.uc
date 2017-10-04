class NMD_Stat_DamageDealt extends NMD_BaseStat;

const ID = 'DamageDealt';

var int DamageDealt;

function InitComponent()
{
	DamageDealt = -1;
}

function AddValue(int Amount)
{
	DamageDealt += Amount;
}

function int GetValue(int UnitID)
{
	local XComGameState_Analytics Analytics;

	if (DamageDealt < 0)
	{
		Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
		DamageDealt = int(Analytics.GetTacticalFloatValue("UNIT_" $ UnitID $ "_ACC_UNIT_DEALT_DAMAGE"));
	}
	return DamageDealt;
}

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strDamageDealt;
}

function string GetDisplayValue()
{
	return string(DamageDealt);
}

function name GetType()
{
	return ID;
}
