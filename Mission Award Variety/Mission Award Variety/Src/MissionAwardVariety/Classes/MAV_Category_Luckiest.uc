//  FILE:    MAV_Category_Luckiest
//  AUTHOR:  atamize
//  PURPOSE: Luckiest - Hit the least likely shots, dodged most likely shots
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_Luckiest extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].Luck;
	}

	SetWinnerBasic(MissionStats.Squad);
}
