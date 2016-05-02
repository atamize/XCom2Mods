//  FILE:    MAV_Category_HometownHero
//  AUTHOR:  atamize
//  PURPOSE: Unfinished Business - Dealt the most damage after a teammate was taken out of combat
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_UnfinishedBusiness extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Scores[i] = MissionStats.UnitStats[i].ShorthandedDamage;	
	}

	SetWinnerBasic(MissionStats.Squad);
}
