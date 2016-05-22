//  FILE:    MAV_Category_PunchingAboveWeight
//  AUTHOR:  atamize
//  PURPOSE: Punching Above Weight - Highest kills to rank ratio
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_PunchingAboveWeight extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i, Rank, Kills;
	local MAV_DamageResult Result;

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		Rank = MissionStats.Squad[i].GetSoldierRank();
		Kills = 0;

		foreach MissionStats.UnitStats[i].EnemyStats(Result)
		{
			if (Result.Killed)
			{
				Kills++;
			}
		}
		
		//`log("    " $ MissionStats.Squad[i].GetFullName() @ "is Rank" @ Rank @ "with" @ Kills @ "kills");
		Scores[i] = max(0, Kills - (Rank + 1));
	}

	SetWinnerBasic(MissionStats.Squad);
}
