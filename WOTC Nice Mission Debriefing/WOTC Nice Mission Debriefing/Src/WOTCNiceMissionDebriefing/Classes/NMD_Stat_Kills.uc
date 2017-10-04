class NMD_Stat_Kills extends NMD_BaseStat;

const ID = 'Kills';

function InitComponent()
{
	Value = -1;
}

function int GetValue(int UnitID)
{
	local XComGameState_Analytics Analytics;

	if (Value < 0)
	{
		Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
		Value = int(Analytics.GetTacticalFloatValue("UNIT_" $ UnitID $ "_ACC_UNIT_KILLS"));
		`log("NMD - getting kills for Unit " $ UnitID);
	}

	return Value;
}

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strKills;
}

function name GetType()
{
	return ID;
}
