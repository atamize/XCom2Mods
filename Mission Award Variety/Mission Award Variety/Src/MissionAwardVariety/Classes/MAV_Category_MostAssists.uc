class MAV_Category_MostAssists extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local EnemyDamageCount DamageCount;
	local MAV_DamageResult Result;

	foreach MissionStats.EnemyDamageCounts(DamageCount)
	{
		// Want to check which enemies were damaged by more than 1 unit
		if (DamageCount.Results.Length < 2)
			continue;

		foreach DamageCount.Results(Result)
		{
			if (!Result.Killed)
			{
				Scores[Result.UnitID] += Result.Damage;
			}
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
