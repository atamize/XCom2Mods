class NMD_Stat_TilesMoved extends NMD_BaseStat;

const ID = 'TilesMoved';

function string GetName()
{
	return class'NMD_MissionInfo'.default.m_strTilesMoved;
}

function name GetType()
{
	return ID;
}
