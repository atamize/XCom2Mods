class NMD_UITacticalHUD_ScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	// Initialize everything after some buffer time
	`BATTLE.SetTimer(0.5, false, 'InitNMD', self);
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
