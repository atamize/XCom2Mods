//  FILE:    MAV_Category_TimeToBleed
//  AUTHOR:  atamize
//  PURPOSE: Ain't Got Time To Bleed - Dealt most damage while wounded
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_TimeToBleed extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < Scores.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].WoundedDamage;
	}

	SetWinnerBasic(MissionStats.Squad);
}
