class MAV_Category_TooOld extends MAV_BaseCategory config(MissionAwardVariety);

var config int MinimumRank;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, HighestRank, WoundHP, Rank, ShotsAgainst;
	local XComGameState_Unit Unit;

	HighestRank = 0;

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Rank = MissionStats.Squad[i].GetSoldierRank();

		if (Rank > HighestRank)
			HighestRank = Rank;
	}

	// Only continue if there is a soldier eligible to be Too Old For This Shit
	if (HighestRank < MinimumRank)
		return;

	// Of the eligible veterans, calculate how griefed they were
	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Unit = MissionStats.Squad[i];
		Rank = Unit.GetSoldierRank();
		
		if (Rank == HighestRank)
		{
			WoundHP = Unit.GetMaxStat(eStat_HP) - Unit.GetCurrentStat(eStat_HP);
			ShotsAgainst = MissionStats.UnitStats[i].ShotsAgainst;
			Scores[i] = (WoundHP * 2) + ShotsAgainst;
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
