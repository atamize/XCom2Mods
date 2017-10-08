// This is really just a dummy screen whose sole purpose is to process controller input
// Workaround to overriding UIMissionSummary
class NMD_UIMissionSummary extends UIScreen;

var NMD_UIMissionSummaryListener SummaryListener;

function SetListener(NMD_UIMissionSummaryListener Listener)
{
	SummaryListener = Listener;
}

//simulated function OnReceiveFocus()
//{
	//`log("NMD - OnReceiveFocus");
	//SummaryListener.EnableMissionSummaryOnLoseFocus(true);
	//super.OnReceiveFocus();
//}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			SummaryListener.OpenStatsButton(none);
			return true;

		// Consume 'B' button here so there is no UI functionality in Mission Summary
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_START):
			// Consume
			return true;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_Y):
			if (!SummaryListener.MissionSummary.BattleData.IsMultiplayer() && !SummaryListener.MissionSummary.bAllSoldiersDead)
			{
				SummaryListener.OnMakePosterButton(none);
			}
			return true;

		// Consume the 'A' button so that it doesn't cascade down the input chain
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			CloseScreen();
			SummaryListener.MissionSummary.CloseScreen();
			return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}
