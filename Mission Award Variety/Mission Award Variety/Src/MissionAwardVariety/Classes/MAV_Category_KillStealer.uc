//---------------------------------------------------------------------------------------
//  FILE:    MAV_Category_KillStealer
//  AUTHOR:  atamize
//  PURPOSE: Kill Stealer - Finished off the most enemies previously damaged by others
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_KillStealer extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local EnemyDamageCount DamageCount;
	local MAV_DamageResult Result;
	local int Winner;

	foreach MissionStats.EnemyDamageCounts(DamageCount)
	{
		// Want to check which enemies were damaged by more than 1 unit
		if (DamageCount.Results.Length < 2)
			continue;

		foreach DamageCount.Results(Result)
		{
			if (Result.Killed)
			{
				Scores[Result.UnitID] += Result.Damage;
			}
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
