class NMD_UIMissionSummaryListener extends UIScreenListener;

var UIMissionSummary MissionSummary;
var UIButton StatsButton;

event OnInit(UIScreen Screen)
{
	MissionSummary = UIMissionSummary(Screen);
	if (MissionSummary.BattleData.IsMultiplayer())
		return;
	
	MissionSummary.m_PosterButton.SetPosition(600, MissionSummary.m_PosterButton.Y);

	StatsButton = MissionSummary.Spawn(class'UIButton', MissionSummary);
	StatsButton.ResizeToText = false;
	StatsButton.InitButton('missionStatsButton', "View Soldier Stats", OpenStatsButton, eUIButtonStyle_HOTLINK_BUTTON);
	StatsButton.SetPosition(940, MissionSummary.m_PosterButton.Y);
	StatsButton.SetWidth(MissionSummary.m_PosterButton.Width);
	StatsButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_X_SQUARE);
}

simulated function OpenStatsButton(UIButton button)
{
	local UIScreen TempScreen;
	local XComPresentationLayer Pres;
	local UIScreenStack ScreenStack;
	local XComTacticalController LocalController;

	LocalController = XComTacticalController(MissionSummary.BATTLE().GetALocalPlayerController());
	if (LocalController != none && LocalController.PlayerCamera != none && LocalController.PlayerCamera.bEnableFading)
	{
		LocalController.ClientSetCameraFade(false);
	}

	MissionSummary.HideObscuringParticleSystems();

	Pres = `PRES;
	ScreenStack = Pres.ScreenStack;

	if (Pres.m_kTacticalHUD != none )
		Pres.m_kTacticalHUD.Hide();

	TempScreen = Pres.Spawn(class'NMD_UIMissionDebriefingScreen', Pres);
	ScreenStack.Push(TempScreen);
}

defaultProperties
{
    ScreenClass = UIMissionSummary
}
