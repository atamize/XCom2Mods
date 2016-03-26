//  FILE:    MAV_Category_Unluckiest
//  AUTHOR:  atamize
//  PURPOSE: Unluckiest - Missed most likely shots, got hit by least likely shots
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_Unluckiest extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, Winner;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].Luck;
	}

	Winner = CalculateMin(Scores);
	if (Winner >= 0)
	{
		WinnerName = MissionStats.Squad[Winner].GetName(eNameType_FullNick);
		Winners.AddItem(Winner);
	}
}
