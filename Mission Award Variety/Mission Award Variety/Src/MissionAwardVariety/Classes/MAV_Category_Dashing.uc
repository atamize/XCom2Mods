class MAV_Category_Dashing extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].DashingTiles;
	}

	SetWinnerBasic(MissionStats.Squad);
}
