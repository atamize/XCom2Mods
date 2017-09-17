class NMD_PersistentStat_PosterData extends NMD_BaseStat;

const ID = 'PosterData';

var int PosterIndex;

function InitComponent()
{
	PosterIndex = -1;
}

function SetIndex(int Index)
{
	PosterIndex = Index;
}

function int GetValue()
{
	return PosterIndex;
}

function string GetName() { return "POSTER INDEX"; }
function string GetDisplayValue() { return string(PosterIndex); }
function name GetType() { return ID; }
function bool IsVisible() { return false; }

defaultProperties
{
	IsPersistent=true
}