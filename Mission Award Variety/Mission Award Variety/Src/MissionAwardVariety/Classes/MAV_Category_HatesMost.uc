class MAV_Category_HatesMost extends MAV_BaseCategory;

struct HateCount
{
	var name Type;
	var int Damage;
};

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local name MostHated;
	local bool Found;
	local EnemyDamageCount DamageCount;
	local array<HateCount> HateCounts;
	local HateCount NewHateCount;
	local int i, Winner;
	local array<int> HateScores;
	local MAV_DamageResult Result;
	local string HatedName;

	foreach MissionStats.EnemyDamageCounts(DamageCount)
	{
		foreach DamageCount.Results(Result)
		{
			for (i = 0; i < HateCounts.Length; ++i)
			{
				if (HateCounts[i].Type == DamageCount.Type)
				{
					HateCounts[i].Damage += Result.Damage;
					Found = true;
					break;
				}
			}

			if (!Found)
			{
				NewHateCount.Type = DamageCount.Type;
				NewHateCount.Damage = Result.Damage;
				HateCounts.AddItem(NewHateCount);
			}
		}
	}

	for (i = 0; i < HateCounts.Length; ++i)
	{
		HateScores.AddItem(HateCounts[i].Damage);
	}

	MostHated = '';

	// Which enemy type was the damaged the most?
	Winner = CalculateMax(HateScores);

	if (Winner < 0)
	{
		Label = repl(Label, "#Unit", "AYYS");
		return;
	}

	MostHated = HateCounts[Winner].Type;

	// Get damage counts for each Squad member for the most damaged enemy
	foreach MissionStats.EnemyDamageCounts(DamageCount)
	{
		if (DamageCount.Type == MostHated)
		{
			foreach DamageCount.Results(Result)
			{
				Scores[Result.UnitID] += Result.Damage;
			}
		}
	}

	Winner = CalculateMax(Scores);

	// 'FACELESS' doesn't retain capitalization, probably because a non-capitalized version
	// already exists and Unrealscript names aren't case-sensitive. Just hack in the name here
	HatedName = string(MostHated);
	if (MostHated == 'FACELESS')
		HatedName = "FACELESS";

	WinnerName = MissionStats.Squad[Winner].GetName(eNameType_FullNick);
	Label = repl(Label, "#Unit", HatedName);
}