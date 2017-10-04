class NMD_Award_SoloSlayer extends NMD_BaseAward;

function DetermineWinners(NMD_MissionInfo Info)
{	
	local EnemyDamageCount DamageCount;
	local NMD_DamageResult Result;

	foreach Info.EnemyDamageCounts(DamageCount)
	{
		if (DamageCount.Results.Length == 1) // This enemy received damage from a single Unit
		{
			Result = DamageCount.Results[0];
			Scores[Result.UnitID] += Result.Damage;
		}
	}

	CalculateMinMax(Scores, Info);
}
