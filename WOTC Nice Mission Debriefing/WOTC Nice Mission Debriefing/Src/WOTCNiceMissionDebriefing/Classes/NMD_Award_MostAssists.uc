class NMD_Award_MostAssists extends NMD_BaseAward;

function int AssistsIterator(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local int i;
	
	for (i = 0; i < NMDUnit.EnemyDamageResults.Length; ++i)
	{
		if (!NMDUnit.EnemyDamageResults[i].Killed)
		{
			return NMDUnit.EnemyDamageResults[i].Damage;
		}
	}

	return 0;
}

function DetermineWinners(NMD_MissionInfo Info)
{	
	Info.IterateUnits(AssistsIterator, Scores);

	CalculateMinMax(Scores, Info);
}
