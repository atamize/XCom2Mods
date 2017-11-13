class NMD_UITacticalHUD_ScreenListener extends UIScreenListener config(WOTCNiceMissionDebriefing);

var config float InitializeDelaySeconds;

event OnInit(UIScreen Screen)
{
	// Initialize everything after some buffer time
	`BATTLE.SetTimer(InitializeDelaySeconds, false, 'InitNMD', self);
}

function InitNMD()
{
	local XComGameState_NMD_Root Root;

	`log("[NMD] - NMD Initializing");

	Root = class'NMD_Utilities'.static.CheckOrCreateRoot();
	Root.RegisterAbilityActivated();

	`log("[NMD] - NMD at version: " $ Root.ModVersion);

	//Root.ClearStatsOnFirstTurn();
	
	// Make sure everyone on mission has UnitStats
	class'NMD_Utilities'.static.EnsureSquadHasUnitStats();
}

defaultproperties
{
	ScreenClass = UITacticalHUD;
}
