//  FILE:    MAV_Category_AlrightKid
//  AUTHOR:  atamize
//  PURPOSE: Not Bad, Kid - Lowest ranked soldier did more damage than a higher ranked soldier
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_AlrightKid extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, LowestRank, HighestRank, Value, Damage;
	local array<int> Pros, Joes;

	LowestRank = MaxInt;
	HighestRank = 0;

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Value = MissionStats.Squad[i].GetSoldierRank();
		if (Value < LowestRank)
		{
			if (MissionStats.Squad[i].GetMyTemplateName() != 'MimicBeacon')
			{
				LowestRank = Value;
			}
		}

		if (Value > HighestRank)
			HighestRank = Value;
	}

	// Only continue if there are higher ranked soldiers in the squad
	if (LowestRank == HighestRank)
		return;

	// Separate pros from joes
	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Value = MissionStats.Squad[i].GetSoldierRank();

		if (Value == LowestRank)
		{
			Joes.AddItem(i);
		}
		else
		{
			Value = MissionStats.UnitStats[i].DamageDealt;
			Pros.AddItem(Value);
		}
	}

	// Determine which Joes did more damage than any Pros
	for (i = 0; i < Joes.Length; ++i)
	{
		Value = MissionStats.UnitStats[Joes[i]].DamageDealt;
		foreach Pros(Damage)
		{
			if (Value > Damage)
			{
				Scores[Joes[i]] = Value;
				break;
			}
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
