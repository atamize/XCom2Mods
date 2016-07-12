class MAV_Category_Sneakiest extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].ConcealedTiles;
	}
	
	SetWinnerBasic(MissionStats.Squad);
}
