class NMD_Award_TooOld extends NMD_BaseAward config(WOTCNiceMissionDebriefing);

var config int MinimumRank;

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
	local XComGameState_Unit Unit;
	local XComGameState_Analytics Analytics;
	local int i, HighestRank, WoundHP, Rank, LowestRank, AttacksReceived, JoeGrief;
	local array<int> Pros, Joes, Grief;

	Info.IterateUnits(RankIterator, Scores);

	LowestRank = class'NMD_Utilities'.static.FindMin(ScoreIterator, Scores.Length, Joes);
	HighestRank = class'NMD_Utilities'.static.FindMax(ScoreIterator, Scores.Length, Pros);

	// Only continue if there is a soldier eligible to be Too Old For This Shit
	if (HighestRank < MinimumRank || HighestRank == LowestRank)
		return;
	
	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));

	// Separate Pros from Joes
	for (i = 0; i < Scores.Length; ++i)
	{
		Unit = Info.GetUnit(i);
		Rank = Unit.GetSoldierRank();
		Scores[i] = 0;
		AttacksReceived = int(Analytics.GetTacticalFloatValue("UNIT_" $ Unit.ObjectID $ "_ACC_UNIT_ABILITIES_RECEIVED"));
		WoundHP = Unit.GetMaxStat(eStat_HP) - Unit.GetCurrentStat(eStat_HP);
		Grief.AddItem((WoundHP * 2) + AttacksReceived);

		if (Rank < HighestRank)
		{
			Joes.AddItem(Grief[i]);
		}
		else
		{
			Pros.AddItem(i);
		}

		`log("NMD - grief for " $ Unit.GetFullName() $ ": " $ Grief[i]);
	}

	foreach Pros(i)
	{
		foreach Joes(JoeGrief)
		{
			if (Grief[i] > JoeGrief)
			{
				Scores[i] = Grief[i];
				break;
			}
		}
	}

	CalculateMinMax(Scores, Info);
}
