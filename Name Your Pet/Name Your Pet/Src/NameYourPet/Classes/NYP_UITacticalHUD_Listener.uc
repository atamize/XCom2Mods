class NYP_UITacticalHUD_Listener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UITacticalHUD HUD;
	local UITacticalHUD_SoldierInfo SoldierInfo;
	local NYP_UITacticalHUD_Menu Menu;

	HUD = UITacticalHUD(Screen);
	SoldierInfo = HUD.m_kStatsContainer;	
	Menu = Screen.Spawn(class'NYP_UITacticalHUD_Menu', Screen);
	Menu.InitPanel('').SetPosition(70, -100);
	Menu.AnchorBottomLeft();
	Menu.SoldierInfo = SoldierInfo;
	Menu.Perks = HUD.m_kPerks;
	Menu.Hide();
}


defaultproperties
{
	ScreenClass = UITacticalHUD;
}
