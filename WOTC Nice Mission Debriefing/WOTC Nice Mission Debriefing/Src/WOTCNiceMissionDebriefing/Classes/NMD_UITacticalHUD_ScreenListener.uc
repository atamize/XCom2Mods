class NMD_UITacticalHUD_ScreenListener extends UIScreenListener config(WOTCNiceMissionDebriefing);

var config float InitializeDelaySeconds;
var XComGameState_NMD_Root Root;

event OnInit(UIScreen Screen)
{
	Root = new class'XComGameState_NMD_Root';

	// Initialize everything after some buffer time
	`BATTLE.SetTimer(InitializeDelaySeconds, false, 'InitNMD', self);
}

function InitNMD()
{
	`log("[NMD] - NMD Initializing");

	//Root = class'NMD_Utilities'.static.CheckOrCreateRoot();
	Root.InitComponent();
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
