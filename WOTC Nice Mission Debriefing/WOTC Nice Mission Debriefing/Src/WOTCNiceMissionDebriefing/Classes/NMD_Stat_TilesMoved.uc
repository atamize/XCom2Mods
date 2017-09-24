class NMD_Stat_TilesMoved extends NMD_BaseStat;

const ID = 'TilesMoved';

var localized string m_strTilesMoved;

function string GetName()
{
	return m_strTilesMoved;
}

function name GetType()
{
	return ID;
}
