class MAV_Category_CloseRange extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].CloseRangeValue;
	}
	
	SetWinnerBasic(MissionStats.Squad);
}
