//  FILE:    MAV_Category_MostHigh
//  AUTHOR:  atamize
//  PURPOSE: Most High - Took the most shots with a height advantage
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_MostHigh extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].Elevation;
	}

	SetWinnerBasic(MissionStats.Squad);
}
