//  FILE:    MAV_Category_MostKillsInTurn
//  AUTHOR:  atamize
//  PURPOSE: Most Kills in a single turn
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_MostKillsInTurn extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		if (MissionStats.UnitStats[i].MaxKillsInTurn > 1)
		{
			Scores[i] = MissionStats.UnitStats[i].MaxKillsInTurn;
		}
	}

	SetWinnerBasic(MissionStats.Squad);

	if (Winners.Length > 0)
	{
		Label = repl(Label, "#Kills", Scores[Winners[0]]);
	}
}
