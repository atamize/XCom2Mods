class NMD_UIArmory_ScreenListener extends UIScreenListener;

event OnRemoved(UIScreen Screen)
{
	if (UIArmory_MainMenu(Screen) == none)
		return;

	class'NMD_Utilities'.static.CleanupDismissedUnits();
}

defaultproperties
{
	ScreenClass = none
}