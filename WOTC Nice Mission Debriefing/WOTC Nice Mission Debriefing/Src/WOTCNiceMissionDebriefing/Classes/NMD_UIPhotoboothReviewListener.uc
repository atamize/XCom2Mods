class NMD_UIPhotoboothReviewListener extends UIScreenListener;

var UIPhotoboothReview PhotoboothReview;
var UILargeButton SelectPhotoButton;

event OnInit(UIScreen Screen)
{
	PhotoboothReview = UIPhotoboothReview(Screen);

	if (`ScreenStack.HasInstanceOf(class'NMD_UIMissionDebriefingScreen'))
	{
		PhotoboothReview.m_FavoriteButton.Hide();
		PhotoboothReview.m_DeleteButton.Hide();

		if (!`ISCONTROLLERACTIVE)
		{
			SelectPhotoButton = Screen.Spawn(class'UILargeButton', Screen);
			SelectPhotoButton.LibID = 'X2ContinueButton';
			SelectPhotoButton.InitLargeButton('SelectPhotoMC', "SELECT PHOTO", , SelectButton, eUILargeButtonStyle_READY);
			SelectPhotoButton.SetPosition(1325, 925);
		}

		PhotoboothReview.MC.BeginFunctionOp("setScreenData");
		PhotoboothReview.MC.QueueString(PhotoboothReview.m_strPrevious);
		PhotoboothReview.MC.QueueString(PhotoboothReview.m_strNext);
		PhotoboothReview.MC.EndOp();
	}
	else
	{
		PhotoboothReview.m_DeleteButton.OnClickedDelegate = OnDelete;
	}
}

function OnDelete(UIButton Button)
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle  = PhotoboothReview.m_strDeletePhotoTitle;
	kConfirmData.strText   = PhotoboothReview.m_strDeletePhotoBody;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	kConfirmData.fnCallback = OnDestructiveActionPopupExitDialog;

	PhotoboothReview.Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDestructiveActionPopupExitDialog(Name eAction)
{
	local int DeletedPosterIndex;
	
	DeletedPosterIndex = PhotoboothReview.m_CurrentPosterIndex - 1;
	PhotoboothReview.OnDestructiveActionPopupExitDialog(eAction);

	`log("NMD - Destructive action on poster index " $ DeletedPosterIndex);
	if (eAction == 'eUIAction_Accept')
	{
		RearrangeSoldierPhotoIndices(DeletedPosterIndex);
	}
}

function RearrangeSoldierPhotoIndices(int DeletedPosterIndex)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom HQ;
	local StateObjectReference Ref;
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;
	local XComGameStateHistory History;
	local NMD_BaseStat BaseStat;
	local int SoldierPosterIndex;

	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (HQ == none)
		return;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rearrange soldier photo indices");

	foreach HQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectId(Ref.ObjectID));
		NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));
		if (NMDUnit != none)
		{
			NMDUnit = XComGameState_NMD_Unit(NewGameState.ModifyStateObject(class'XComGameState_NMD_Unit', NMDUnit.ObjectID));
			BaseStat = NMDUnit.GetStat(class'NMD_PersistentStat_PosterData'.const.ID);
			SoldierPosterIndex = BaseStat.GetValue(Unit.ObjectID);

			`log("NMD - " $ Unit.GetFullName() $ " has poster index " $ SoldierPosterIndex);

			if (SoldierPosterIndex < DeletedPosterIndex)
				continue;

			if (SoldierPosterIndex == DeletedPosterIndex)
			{
				NMDUnit.SetPosterIndex(-1, NewGameState);
				`log("NMD - " $ Unit.GetFullName() $ " had Poster Index " $ DeletedPosterIndex $ " deleted");
			}
			else if (SoldierPosterIndex > DeletedPosterIndex)
			{
				NMDUnit.SetPosterIndex(SoldierPosterIndex - 1, NewGameState);
				`log("NMD - " $ Unit.GetFullName() $ " had Poster Index " $ SoldierPosterIndex $ ", now " $ SoldierPosterIndex-1);
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else    
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
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
