class NMD_Award_KillStealer extends NMD_BaseAward;

function DetermineWinners(NMD_MissionInfo Info)
{	
	local EnemyDamageCount DamageCount;
	local NMD_DamageResult Result;

	foreach Info.EnemyDamageCounts(DamageCount)
	{
		if (DamageCount.Results.Length > 1)
		{
			foreach DamageCount.Results(Result)
			{
				if (Result.Killed)
				{
					Scores[Result.UnitID]++;
				}
			}
		}
	}

	CalculateMinMax(Scores, Info);
}
