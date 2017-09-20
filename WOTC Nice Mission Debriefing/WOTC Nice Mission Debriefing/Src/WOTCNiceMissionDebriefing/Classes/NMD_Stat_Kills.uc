class NMD_Stat_Kills extends NMD_BaseStat;

const ID = 'Kills';

var localized string m_strKills;

var int Kills;

function InitComponent()
{
	Kills = -1;
}

function AddValue(int Amount)
{
	Kills += Amount;
}

function int GetValue(int UnitID)
{
	local XComGameState_Analytics Analytics;

	if (Kills < 0)
	{
		Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
		Kills = int(Analytics.GetTacticalFloatValue("UNIT_" $ UnitID $ "_ACC_UNIT_KILLS"));
		`log("NMD - getting kills for Unit " $ UnitID);
	}

	return Kills;
}

function string GetName()
{
	return m_strKills;
}

function string GetDisplayValue()
{
	return string(Kills);
}

function name GetType()
{
	return ID;
}
