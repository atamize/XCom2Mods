//  FILE:    MAV_Category_TimeToBleed
//  AUTHOR:  atamize
//  PURPOSE: Ain't Got Time To Bleed - Dealt most damage while wounded
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_TimeToBleed extends MAV_BaseCategory;

var string AlternateLabel; // For robotic units

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].WoundedDamage;
	}

	SetWinnerBasic(MissionStats.Squad);

	if (Winners.Length > 0)
	{
		if (MissionStats.Squad[Winners[0]].IsRobotic())
		{
			Label = AlternateLabel;
		}
	}
}
