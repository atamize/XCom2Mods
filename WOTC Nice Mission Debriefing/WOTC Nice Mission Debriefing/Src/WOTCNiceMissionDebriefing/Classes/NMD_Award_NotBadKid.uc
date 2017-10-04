class NMD_Award_NotBadKid extends NMD_BaseAward;

function int RankIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	return Unit.GetSoldierRank();
}

function int ScoreIterator(int i)
{
	return Scores[i];
}

function DetermineWinners(NMD_MissionInfo Info)
{	
	local int i, LowestRank, HighestRank, Value, Damage;
	local array<int> Pros, Joes;
	local XComGameState_Unit Unit;

	Info.IterateUnits(RankIterator, Scores);

	LowestRank = class'NMD_Utilities'.static.FindMin(ScoreIterator, Scores.Length, Joes);
	HighestRank = class'NMD_Utilities'.static.FindMax(ScoreIterator, Scores.Length, Pros);

	// Only continue if there are higher ranked soldiers in the squad
	if (LowestRank == HighestRank)
		return;

	Pros.Length = 0;

	for (i = 0; i < Scores.Length; ++i)
	{
		Unit = Info.GetUnit(i);

		if (Unit.GetSoldierRank() > LowestRank)
		{
			Value = Info.GetNMDUnit(i).GetStat(class'NMD_Stat_DamageDealt'.const.ID).GetValue(Unit.ObjectID);
			Pros.AddItem(Value);
		}

		Scores[i] = 0;
	}

	// Determine which Joes did more damage than any Pros
	for (i = 0; i < Joes.Length; ++i)
	{
		Unit = Info.GetUnit(Joes[i]);
		Value = Info.GetNMDUnit(Joes[i]).GetStat(class'NMD_Stat_DamageDealt'.const.ID).GetValue(Unit.ObjectID);

		foreach Pros(Damage)
		{
			if (Value > Damage)
			{
				Scores[Joes[i]] = Value;
				break;
			}
		}
	}

	CalculateMinMax(Scores, Info);
}
