class NMD_Stat_OverwatchAccuracy extends NMD_Stat_ShotAccuracy;

const _ID = 'OverwatchAccuracy';

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strOverwatchAccuracy;
}

function name GetType()
{
	return _ID;
}
