class NMD_Stat_TilesMoved extends NMD_BaseStat;

const ID = 'TilesMoved';

var localized string m_strTilesMoved;
var int NumTiles;

function InitComponent()
{
	NumTiles = 0;
}

function AddValue(int Tiles)
{
	NumTiles += Tiles;
}

function SetValue(int Tiles)
{
	NumTiles = Tiles;
}

function int GetValue(int UnitID)
{
	return NumTiles;
}

function string GetName()
{
	return m_strTilesMoved;
}

function string GetDisplayValue()
{
	return string(NumTiles);
}

function name GetType()
{
	return ID;
}
