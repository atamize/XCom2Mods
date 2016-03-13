class MAV_Category_PowerCouple extends MAV_BaseCategory;

struct PowerCouple
{
	var int Unit1;
	var int Unit2;
	var int Damage;
};

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, j, k, m, Unit1, Unit2, Winner;
	local array<PowerCouple> PowerCouples;
	local PowerCouple Couple;
	local bool Found;
	local array<MAV_DamageResult> Results;
	local EnemyDamageCount DamageCounts;
	local array<int> CoupleScores;

	foreach MissionStats.EnemyDamageCounts(DamageCounts)
	{
		Results = DamageCounts.Results;
		if (Results.Length < 2) // Only consider enemies damage by 2 or soldiers
			continue;

		for (j = 0; j < Results.Length; ++j)
		{
			Unit1 = Results[j].UnitID;
			Found = false;
			for (k = j + 1; k < Results.Length; ++k)
			{
				Unit2 = Results[k].UnitID;

				for (m = 0; m < PowerCouples.Length; ++m)
				{
					Couple = PowerCouples[m];
					if ((Couple.Unit1 == Unit1 && Couple.Unit2 == Unit2) ||
						(Couple.Unit2 == Unit1 && Couple.Unit1 == Unit2))
					{
						PowerCouples[m].Damage += Results[j].Damage + Results[k].Damage;
						Found = true;
						break;
					}
				}

				// Add new power couple
				if (!Found)
				{
					Couple.Unit1 = Unit1;
					Couple.Unit2 = Unit2;
					Couple.Damage = Results[j].Damage + Results[k].Damage;
					PowerCouples.AddItem(Couple);
				}
			}
		}
	}

	for (i = 0; i < PowerCouples.Length; ++i)
	{
		CoupleScores.AddItem(PowerCouples[i].Damage);
	}

	Winner = CalculateMax(CoupleScores);

	if (Winner >= 0)
	{
		Couple = PowerCouples[Winner];
		WinnerName = MissionStats.Squad[Couple.Unit1].GetFullName() $ " & " $ MissionStats.Squad[Couple.Unit2].GetFullName();
	}
}
