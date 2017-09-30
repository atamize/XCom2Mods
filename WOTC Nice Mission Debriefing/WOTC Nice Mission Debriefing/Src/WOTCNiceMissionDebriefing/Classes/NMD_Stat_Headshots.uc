class NMD_Stat_Headshots extends NMD_BaseStat;

const ID = 'Headshots';

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strHeadshots;
}

function name GetType()
{
	return ID;
}

function bool HideStatIfNoWinner()
{
	return true;
}
