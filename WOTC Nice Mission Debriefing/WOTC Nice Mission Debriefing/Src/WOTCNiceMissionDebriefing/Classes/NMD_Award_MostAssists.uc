class NMD_Award_MostAssists extends NMD_BaseAward;

function int AssistsIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local int i;
	local int Total;

	for (i = 0; i < NMDUnit.EnemyDamageResults.Length; ++i)
	{
		if (!NMDUnit.EnemyDamageResults[i].Killed)
		{
			Total += NMDUnit.EnemyDamageResults[i].Damage;
		}
	}

	return Total;
}

function DetermineWinners(NMD_MissionInfo Info)
{	
	Info.IterateUnits(AssistsIterator, Scores);

	CalculateMinMax(Scores, Info);
}
