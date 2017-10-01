class NMD_UIMissionSummary extends UIMissionSummary config(WOTCNiceMissionDebriefing);

//var config bool EnableTeamPosterWarning;

var localized string m_strViewStatsButton;
//var localized string m_strWarningTitle;
//var localized string m_strWarningBody;

var UIButton StatsButton;

var bool HasSeenStats;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	HasSeenStats = false;

	m_PosterButton.SetPosition(940, m_PosterButton.Y);
	//m_PosterButton.OnClickedDelegate = OnMakePosterButton;

	StatsButton = Spawn(class'UIButton', self);
	StatsButton.ResizeToText = false;
	StatsButton.InitButton('missionStatsButton', m_strViewStatsButton, OpenStatsButton, eUIButtonStyle_HOTLINK_BUTTON);
	StatsButton.SetPosition(600, m_PosterButton.Y);
	StatsButton.SetWidth(m_PosterButton.Width);
	StatsButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_X_SQUARE);
}

/*
function OnMakePosterButton(UIButton Button)
{
	local TDialogueBoxData kConfirmData;

	if (EnableTeamPosterWarning && !HasSeenStats)
	{
		kConfirmData.strTitle = m_strWarningTitle;
		kConfirmData.strText = m_strWarningBody;
		kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

		kConfirmData.fnCallback = OnDestructiveActionPopupExitDialog;

		Movie.Pres.UIRaiseDialog(kConfirmData);
	}
	else
	{
		CloseThenOpenPhotographerScreen();
	}
}

function OnDestructiveActionPopupExitDialog(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		CloseThenOpenPhotographerScreen();
	}
}
*/

simulated function OpenStatsButton(UIButton button)
{
	local UIScreen TempScreen;
	local XComPresentationLayer Pres;
	local UIScreenStack ScreenStack;
	local XComTacticalController LocalController;

	LocalController = XComTacticalController(BATTLE().GetALocalPlayerController());
	if (LocalController != none && LocalController.PlayerCamera != none && LocalController.PlayerCamera.bEnableFading)
	{
		LocalController.ClientSetCameraFade(false);
	}

	HideObscuringParticleSystems();

	Pres = `PRES;
	ScreenStack = Pres.ScreenStack;

	if (Pres.m_kTacticalHUD != none )
		Pres.m_kTacticalHUD.Hide();

	TempScreen = Pres.Spawn(class'NMD_UIMissionDebriefingScreen', Pres);
	ScreenStack.Push(TempScreen);

	HasSeenStats = true;
}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			OpenStatsButton(none);
			return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}

defaultProperties
{
	HasSeenStats = false
}