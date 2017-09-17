class NMD_Stat_Kills extends NMD_BaseStat;

const ID = 'Kills';

var localized string m_strKills;

var int Kills;

function InitComponent()
{
	Kills = 0;
}

function AddValue(int Amount)
{
	Kills += Amount;
}

function int GetValue()
{
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
