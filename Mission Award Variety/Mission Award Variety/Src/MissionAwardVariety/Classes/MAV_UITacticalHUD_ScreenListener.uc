//---------------------------------------------------------------------------------------
//  FILE:    MAV_UITacticalHUD_ScreenListener
//  AUTHOR:  atamize
//  PURPOSE: Make sure the mission stat tracking object is initialized during a mission
//
//  Thanks to Kosmo and the Lifetime Stats mod on which this is based
//--------------------------------------------------------------------------------------- 
class MAV_UITacticalHUD_ScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UITacticalHUD Hud;

	Hud = UITacticalHUD(Screen);
	if (Hud == none)
		return;
	
	`log("MAV registering Tactical HUD");
	
	class'MAV_Utilities'.static.CheckOrCreateRoot();
	class'MAV_Utilities'.static.EnsureSquadHasUnitStats();
}

defaultProperties
{
    ScreenClass = UITacticalHUD
}
