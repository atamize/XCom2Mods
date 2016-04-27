//  FILE:    MAV_Category_HometownHero
//  AUTHOR:  atamize
//  PURPOSE: Hometown Hero - Dealt the most damage amongst compatriots of the country 
//	in which the mission took place
//
//--------------------------------------------------------------------------------------- 
class MAV_Category_HometownHero extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local XComGameState_BattleData BattleData;
	local array<string> Strings;
	local string Country;
	local int i;

	BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	Strings = splitstring(BattleData.m_strLocation);
	Country = caps(repl(Strings[Strings.Length - 1], " ", ""));

	`log("Country is " $ Country);

	for (i = 0; i < MissionStats.Squad.Length; ++i)
	{
		`log("    " $ MissionStats.Squad[i].GetFullName() @ "is from" @ MissionStats.Squad[i].GetCountry());
		if (caps(MissionStats.Squad[i].GetCountry()) == Country)
		{
			Scores[i] = MissionStats.UnitStats[i].DamageDealt;
		}
	}

	SetWinnerBasic(MissionStats.Squad);
}
