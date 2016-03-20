//---------------------------------------------------------------------------------------
//  FILE:    MAV_Category_TooOld
//  AUTHOR:  atamize
//  PURPOSE: Too Old For This Shit - highest ranked soldier got shot/damaged more than
//	the lowest rank soldier
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_TooOld extends MAV_BaseCategory config(MissionAwardVariety);

var config int MinimumRank;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, HighestRank, WoundHP, Rank, LowestRank, ShotsAgainst, ProGrief, JoeGrief, Index;
	local array<int> Pros, Joes;
	local XComGameState_Unit Unit;

	HighestRank = 0;
	LowestRank = MaxInt;

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Rank = MissionStats.Squad[i].GetSoldierRank();

		if (Rank > HighestRank)
			HighestRank = Rank;

		if (Rank < LowestRank)
			LowestRank = Rank;
	}

	// Only continue if there is a soldier eligible to be Too Old For This Shit
	if (HighestRank < MinimumRank || HighestRank == LowestRank)
		return;

	// Separate Pros from Joes
	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Unit = MissionStats.Squad[i];
		Rank = Unit.GetSoldierRank();
		
		if (Rank < HighestRank)
		{
			WoundHP = Unit.GetMaxStat(eStat_HP) - Unit.GetCurrentStat(eStat_HP);
			ShotsAgainst = MissionStats.UnitStats[i].ShotsAgainst;
			Joes.AddItem((WoundHP * 2) + ShotsAgainst);
		}
		else
		{
			Pros.AddItem(i);
		}
	}

	// Determine which Pros received more grief than Joes
	for (i = 0; i < Pros.Length; ++i)
	{
		Index = Pros[i];
		Unit = MissionStats.Squad[Index];
		WoundHP = Unit.GetMaxStat(eStat_HP) - Unit.GetCurrentStat(eStat_HP);
		ShotsAgainst = MissionStats.UnitStats[Index].ShotsAgainst;
		ProGrief = (WoundHP * 2) + ShotsAgainst;

		foreach Joes(JoeGrief)
		{
			if (ProGrief > JoeGrief)
			{
				Scores[Index] = ProGrief;
				break;
			}
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
