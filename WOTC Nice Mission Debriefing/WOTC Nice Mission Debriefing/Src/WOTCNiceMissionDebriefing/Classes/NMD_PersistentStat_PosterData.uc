class NMD_PersistentStat_PosterData extends NMD_BaseStat;

const ID = 'PosterData';

var int PosterIndex;
var string Filename;

function InitComponent()
{
	PosterIndex = -1;
	Filename = "";
}

function SetIndex(int Index)
{
	PosterIndex = Index;
}

function int GetValue(int UnitID)
{
	return PosterIndex;
}

function SetFilename(string File)
{
	Filename = File;
}

function string GetName() { return Filename; }
function string GetDisplayValue() { return Filename; }
function name GetType() { return ID; }
function bool IsVisible() { return false; }
function bool IsPersistent() { return true; }
