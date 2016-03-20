//  FILE:    MAV_Category_SoloSlayer
//  AUTHOR:  atamize
//  PURPOSE: Solo Slayer - Most damage to enemies without help from teammates
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_SoloSlayer extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local EnemyDamageCount DamageCount;
	local MAV_DamageResult Result;

	foreach MissionStats.EnemyDamageCounts(DamageCount)
	{
		if (DamageCount.Results.Length == 1) // This enemy received damage from a single Unit
		{
			Result = DamageCount.Results[0];
			Scores[Result.UnitID] += Result.Damage;
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
