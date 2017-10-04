class NMD_UIPhotoboothReview extends UIPhotoboothReview;

var UILargeButton SelectPhotoButton;

simulated event OnInit()
{
	super.OnInit();

	m_FavoriteButton.Hide();
	m_DeleteButton.Hide();

	if (!`ISCONTROLLERACTIVE)
	{
		SelectPhotoButton = Spawn(class'UILargeButton', self);
		SelectPhotoButton.LibID = 'X2ContinueButton';
		SelectPhotoButton.InitLargeButton('SelectPhotoMC', "SELECT PHOTO", , SelectButton, eUILargeButtonStyle_READY);
		SelectPhotoButton.SetPosition(1325, 925);
	}

	MC.BeginFunctionOp("setScreenData");
	MC.QueueString(m_strPrevious);
	MC.QueueString(m_strNext);
	MC.EndOp();
}

function UpdateNavHelp()
{
	if (NavHelp == none)
	{
		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	}

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);

	//bsg-jneal (3.21.17): move controls to navigation help for controller
	if(`ISCONTROLLERACTIVE)
	{
		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericSelect, class'UIUtilities_Input'.const.ICON_A_X);
		NavHelp.AddRightHelp(m_strPrevious, class'UIUtilities_Input'.const.ICON_LB_L1);
		NavHelp.AddRightHelp(m_strNext, class'UIUtilities_Input'.const.ICON_RB_R1);
	}
	//bsg-jneal (3.21.17): end

	NavHelp.Show();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;
	
	switch (cmd)
	{
	case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
	case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
	case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
		SelectButton(none);
		return true;

	// Ignore these functions
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		FavoriteButton(none);
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		DeleteButton(none);
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

function SelectButton(UIButton Button)
{
	local int SelectedPosterIndex;
	local NMD_UIMissionDebriefingScreen NMD;

	SelectedPosterIndex = PosterIndices[m_CurrentPosterIndex-1];
	`log("NMD Selected poster: " $ SelectedPosterIndex);

	NMD = NMD_UIMissionDebriefingScreen(`ScreenStack.GetLastInstanceOf(class'NMD_UIMissionDebriefingScreen'));
	if (NMD != none)
	{
		NMD.SetPhoto(SelectedPosterIndex);
	}

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	CloseScreen();
}
