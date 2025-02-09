class NMD_Stat_DamageDealt extends NMD_BaseStat;

const ID = 'DamageDealt';

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strDamageDealt;
}

function name GetType()
{
	return ID;
}
