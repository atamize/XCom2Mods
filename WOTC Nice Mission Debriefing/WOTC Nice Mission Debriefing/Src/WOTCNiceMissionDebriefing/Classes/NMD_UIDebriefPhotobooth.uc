class NMD_UIDebriefPhotobooth extends UIArmory_Photobooth;

function CreatePosterCallback(StateObjectReference UnitRef)
{
	local NMD_UIMissionDebriefingScreen NMD;

	NMD = NMD_UIMissionDebriefingScreen(`ScreenStack.GetLastInstanceOf(class'NMD_UIMissionDebriefingScreen'));
	if (NMD != none)
	{
		NMD.SetLatestPhoto();
	}

	bWaitingOnPhoto = false;
	Movie.Pres.UICloseProgressDialog();
}
