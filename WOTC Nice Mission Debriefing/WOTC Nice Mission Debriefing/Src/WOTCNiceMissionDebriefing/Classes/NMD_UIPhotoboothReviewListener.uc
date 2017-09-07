class NMD_UIPhotoboothReviewListener extends UIScreenListener;

var UIPhotoboothReview PhotoboothReview;

event OnInit(UIScreen Screen)
{
	if (`ScreenStack.HasInstanceOf(class'NMD_UIMissionDebriefingScreen') == false)
		return;

	PhotoboothReview = UIPhotoboothReview(Screen);
	
	PhotoboothReview.m_FavoriteButton.Hide();
	PhotoboothReview.m_DeleteButton.OnClickedDelegate = SelectButton;

	PhotoboothReview.MC.BeginFunctionOp("setScreenData");
	PhotoboothReview.MC.QueueString(PhotoboothReview.m_strPrevious);
	PhotoboothReview.MC.QueueString(PhotoboothReview.m_strNext);
	PhotoboothReview.MC.QueueString("SELECT PHOTO");
	PhotoboothReview.MC.EndOp();
}

function SelectButton(UIButton Button)
{
	local int SelectedPosterIndex;
	local NMD_UIMissionDebriefingScreen NMD;

	SelectedPosterIndex = PhotoboothReview.PosterIndices[PhotoboothReview.m_CurrentPosterIndex-1];
	`log("NMD Selected poster: " $ SelectedPosterIndex);

	NMD = NMD_UIMissionDebriefingScreen(`ScreenStack.GetLastInstanceOf(class'NMD_UIMissionDebriefingScreen'));
	if (NMD != none)
	{
		NMD.SetPhoto(SelectedPosterIndex);
	}

	PhotoboothReview.CloseScreen();
}

defaultProperties
{
	ScreenClass = UIPhotoboothReview
}
