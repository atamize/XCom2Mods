class NMD_PersistentData extends XComGameState_BaseObject;

var int PosterIndex;

function InitComponent()
{
	PosterIndex = -1;
}

function SetPosterIndex(int Index)
{
	PosterIndex = Index;
}
