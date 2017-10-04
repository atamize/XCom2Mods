class NMD_Award_Overqualified extends NMD_BaseAward;

function int OverqualifiedIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local int Rank, Kills;

	Rank = Unit.GetSoldierRank();
	Kills = NMDUnit.GetStat(class'NMD_Stat_Kills'.const.ID).GetValue(Unit.ObjectID);

	return Max(0, Kills - (Rank + 1));
}

function DetermineWinners(NMD_MissionInfo Info)
{	
	Info.IterateUnits(OverqualifiedIterator, Scores);
	
	CalculateMinMax(Scores, Info);
}
