class MAV_Category_Turtle extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, Value;

	for (i = 0; i < Scores.Length; ++i)
	{
		Value = MissionStats.UnitStats[i].Turtle;
		// There is minimum amount of turtling required to received this award
		// e.g. at least 2 hunkers or 4 overwatches
		if (Value > 3)
		{
			Scores[i] = Value;
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
