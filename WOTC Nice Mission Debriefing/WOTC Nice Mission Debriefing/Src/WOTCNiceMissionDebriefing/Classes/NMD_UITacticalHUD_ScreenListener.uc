class NMD_UITacticalHUD_ScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	// Initialize everything after some buffer time
	`BATTLE.SetTimer(0.5, false, 'InitNMD', self);
}

function InitNMD()
{
	local XComGameState_NMD_Root root;

	`log("[NMD] - NMD Initializing");

	root = class'NMD_Utilities'.static.checkOrCreateRoot();
	root.registerAbilityActivated();
	
	// Make sure everyone on mission has UnitStats
	class'NMD_Utilities'.static.ensureSquadHasUnitStats();
}

defaultproperties
{
	ScreenClass = UITacticalHUD;
}
