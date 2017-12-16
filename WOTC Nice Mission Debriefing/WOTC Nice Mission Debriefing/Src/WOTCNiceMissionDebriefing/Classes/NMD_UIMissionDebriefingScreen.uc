class NMD_UIMissionDebriefingScreen extends UIScreen config (WOTCNiceMissionDebriefing);

var config array<name> StatsOrder;

var localized string m_strAwards;
var localized string m_strStats;
var localized string m_strCreatePhoto;
var localized string m_strSelectPhoto;
var localized string m_strPrevious;
var localized string m_strNext;
var localized string m_strMVP;

var UIPanel Container;
var UIBGBox PanelBG;
var UIBGBox FullBG;
var UIX2PanelHeader TitleHeader;
var UIImage SCImage;

var UIPanel MVPPanel;
var UIImage MVPImage;
var UIText MVPText;

var UIBGBox PhotoPanel;
var UIImage SoldierImage;
var UIButton CreatePhotoButton;
var UIButton SelectPhotoButton;
var UIButton PreviousButton;
var UIButton NextButton;

var UIPanel StatsPanel;
var UIStatList StatList;

var UIPanel AwardsPanel;
var UIList AwardsList;

var UINavigationHelp NavHelp;

var StateObjectReference UnitRef;
var int CurrentSoldierIndex;

var NMD_MissionInfo MissionInfo;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIMissionSummary MissionSummary;
	local array<XComGameState_Unit> MissionUnits;
	local Texture2D MVPTexture;

	super.InitScreen(InitController, InitMovie, InitName);

	Container = Spawn(class'UIPanel', self).InitPanel('theContainer');
	Container.Width = Width;
	Container.Height = Height;
	Container.SetPosition((Movie.UI_RES_X - Container.Width) / 2, (Movie.UI_RES_Y - Container.Height) / 2);

	FullBG = Spawn(class'UIBGBox', Container);
	FullBG.InitBG('', 0, 0, Container.Width, Container.Height);

	PanelBG = Spawn(class'UIBGBox', Container);
	PanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	PanelBG.InitBG('theBG', 0, 0, Container.Width, Container.Height);

	// Header
	TitleHeader = Spawn(class'UIX2PanelHeader', Container);
	TitleHeader.InitPanelHeader('', "", "");
	TitleHeader.SetPosition(10, 10);
	TitleHeader.SetHeaderWidth(Container.Width - TitleHeader.X - 10);

	SCImage = Spawn(class'UIImage', Container).InitImage();
	SCImage.SetSize(80, 80);
	SCImage.SetPosition(10, 10);

	// Photo Panel
	PhotoPanel = Spawn(class'UIBGBox', Container);
	PhotoPanel.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	PhotoPanel.InitBG('photoBG', 30, 100, 300, 500);	
	PhotoPanel.X = 30;

	SoldierImage = Spawn(class'UIImage', Container).InitImage();
	SoldierImage.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + 20);

	CreatePhotoButton = Spawn(class'UIButton', Container);
	CreatePhotoButton.ResizeToText = false;
	CreatePhotoButton.InitButton('CreatePhotoButton', m_strCreatePhoto, OpenCreatePhoto, eUIButtonStyle_HOTLINK_BUTTON);
	CreatePhotoButton.SetWidth(130);
	CreatePhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_X_SQUARE);
	CreatePhotoButton.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + PhotoPanel.Height - 50);

	SelectPhotoButton = Spawn(class'UIButton', Container);
	SelectPhotoButton.ResizeToText = false;
	SelectPhotoButton.InitButton('selectPhotoButton', m_strSelectPhoto, OpenPhotoboothReview, eUIButtonStyle_HOTLINK_BUTTON);
	SelectPhotoButton.SetWidth(130);
	SelectPhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	SelectPhotoButton.SetPosition(CreatePhotoButton.X + CreatePhotoButton.Width + 20, CreatePhotoButton.Y);

	// MVP Panel
	MVPPanel = Spawn(class'UIPanel', Container).InitPanel('MVPPanel');
	MVPPanel.SetSize(PhotoPanel.Width, Height);
	MVPPanel.SetPosition(SoldierImage.X + 140 - (MVPPanel.Width / 2), SoldierImage.Y + 490);

	MVPImage = Spawn(class'UIImage', MVPPanel).InitImage();
	MVPTexture = Texture2D'gfxEndGameStats.EndGameStats_I36';
	MVPImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(MVPTexture)));
	MVPImage.SetSize(128, 128);
	MVPImage.SetPosition((MVPPanel.Width / 2) - (MVPImage.Width / 2), 0);

	MVPText = Spawn(class'UIText', MVPPanel);
	MVPText.InitText('mvpptext');
	MVPText.SetPosition(-Width - 15, MVPImage.Y + MVPImage.Height);
	MVPText.SetCenteredText(class'UIUtilities_Text'.static.GetSizedText(m_strMVP, 42));

	// Stats
	InitStatsPanel();

	// Awards Panel
	InitAwardsPanel();
	
	// Navigation
	PreviousButton = Spawn(class'UIButton', Container);
	PreviousButton.ResizeToText = false;
	PreviousButton.InitButton('PreviousButton', m_strPrevious, OnPreviousClick, eUIButtonStyle_HOTLINK_BUTTON);
	PreviousButton.SetWidth(180);
	PreviousButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_LB_L1);
	PreviousButton.SetPosition(AwardsPanel.X + 30, Container.Height - 50);

	NextButton = Spawn(class'UIButton', Container);
	NextButton.ResizeToText = false;
	NextButton.InitButton('NextButton', m_strNext, OnNextClick, eUIButtonStyle_HOTLINK_BUTTON);
	NextButton.SetWidth(180);
	NextButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_RB_R1);
	NextButton.SetPosition(PreviousButton.X + PreviousButton.Width + 30, PreviousButton.Y);

	MissionSummary = UIMissionSummary(`ScreenStack.GetFirstInstanceOf(class'UIMissionSummary'));
	if (MissionSummary != none)
	{
		MissionSummary.BATTLE().GetHumanPlayer().GetOriginalUnits(MissionUnits, true);

		MissionInfo = new class'NMD_MissionInfo';
		MissionInfo.Initialize(MissionUnits);

		CurrentSoldierIndex = 0;
		ShowStatsForUnit(CurrentSoldierIndex);

		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
		NavHelp.AddContinueButton(MissionSummary.CloseScreenTakePhoto);
	}

	NavHelp.AddBackButton(BackToSummary);
}

function InitStatsPanel()
{
	local UIX2PanelHeader StatsHeader;
	local UIBGBox StatsBG;

	StatsPanel = Spawn(class'UIPanel', Container).InitPanel('StatsPanel');
	StatsPanel.SetPosition(360, PhotoPanel.Y);
	StatsPanel.SetSize(Container.Width - StatsPanel.X, Container.Height / 2 - 50);

	StatsBG = Spawn(class'UIBGBox', StatsPanel);
	StatsBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	StatsBG.InitBG('StatsBG', 0, 0, StatsPanel.Width, StatsPanel.Height);

	StatsHeader = Spawn(class'UIX2PanelHeader', StatsPanel).InitPanelHeader('', m_strStats, "");
	StatsHeader.SetPosition(10, 10);
	StatsHeader.SetHeaderWidth(StatsPanel.Width - StatsHeader.X - 10);

	StatList = Spawn(class'UIStatList', StatsPanel);
	StatList.InitStatList('StatList', , 0, StatsHeader.Height, StatsPanel.Width - 20, StatsPanel.Height - 20);
}

function InitAwardsPanel()
{
	local UIX2PanelHeader AwardsHeader;
	local UIBGBox AwardsBG;

	AwardsPanel = Spawn(class'UIPanel', Container).InitPanel('AwardsPanel');
	AwardsPanel.SetPosition(StatsPanel.X, StatsPanel.Y + StatsPanel.Height + 10);
	AwardsPanel.SetSize(StatsPanel.Width, Container.Height - AwardsPanel.Y - 70);

	AwardsBG = Spawn(class'UIBGBox', AwardsPanel);
	AwardsBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	AwardsBG.InitBG('StatsBG', 0, 0, AwardsPanel.Width, AwardsPanel.Height);

	AwardsHeader = Spawn(class'UIX2PanelHeader', AwardsPanel).InitPanelHeader('', m_strAwards, "");
	AwardsHeader.SetPosition(10, 10);
	AwardsHeader.SetHeaderWidth(AwardsPanel.Width - AwardsHeader.X - 10);

	AwardsList = Spawn(class'UIList', AwardsPanel).InitList('AwardsList');
	AwardsList.SetPosition(20, AwardsHeader.Height);
	AwardsList.SetSize(AwardsPanel.Width - 50, AwardsPanel.Height - AwardsList.Y - 30);
}

function ShowStatsForUnit(int SoldierIndex)
{
	local X2SoldierClassTemplate SoldierClass;
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierTexture;
	local X2PhotoBooth_PhotoManager PhotoManager;
	local XComGameState_NMD_Unit NMDUnit;
	local NMD_PersistentStat_PosterData PosterData;
	local NMD_BaseAward Award;
	local int PosterIndex;
	local XComGameState_Unit Unit;

	Unit = MissionInfo.GetUnit(SoldierIndex);
	UnitRef = Unit.GetReference();

	SoldierClass = Unit.GetSoldierClassTemplate();
	if (SoldierClass != none)
	{
		SCImage.LoadImage(SoldierClass.IconImage);
		SCImage.Show();
	}

	TitleHeader.SetX(10 + SCImage.Width + 10);
	TitleHeader.SetWidth(Container.Width - TitleHeader.X - 10);
	TitleHeader.SetText(Unit.GetName(eNameType_FullNick), Caps(SoldierClass != None ? SoldierClass.DisplayName : ""));
	TitleHeader.MC.FunctionVoid("realize");

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoManager = `XENGINE.m_kPhotoManager;

	NMDUnit = MissionInfo.GetNMDUnit(SoldierIndex);

	if (NMDUnit != none)
	{
		PosterData = NMD_PersistentStat_PosterData(NMDUnit.GetStat(class'NMD_PersistentStat_PosterData'.const.ID));

		if (len(PosterData.GetName()) > 0)
		{
			`log("NMD attempting to get poster for filename " $ PosterData.GetName());
			SoldierTexture = class'NMD_Utilities'.static.GetTextureFromPhotoFilename(PosterData.GetName());
		}

		if (SoldierTexture == none)
		{
			PosterIndex = PosterData.GetValue(Unit.ObjectID);
			`log("NMD - NMDUnit found with poster index " $ PosterIndex);
			if (PosterIndex >= 0 && PosterIndex < PhotoManager.GetNumOfPosterForCampaign(SettingsState.GameIndex, false))
			{
				SoldierTexture = PhotoManager.GetPosterTexture(SettingsState.GameIndex, PosterIndex);
			}
		}
	}

	if (SoldierTexture == none)
	{
		if (PhotoManager.HeadshotExistsAndIsCurrent(SettingsState.GameIndex, Unit.ObjectID, Unit))
		{
			SoldierTexture = PhotoManager.GetHeadshotTexture(SettingsState.GameIndex, Unit.ObjectID, 256, 256);
		}
		else
		{
			SoldierTexture = Texture2D'gfxComponents.UIXcomEmblem';
		}
		SoldierImage.SetSize(256, 256);
		SoldierImage.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + (PhotoPanel.Height / 2) - (SoldierImage.Height / 2) - 50);
	}
	else
	{
		SoldierImage.SetSize(280, 420);
		SoldierImage.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + 20);
	}

	SoldierImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierTexture)));

	if (CurrentSoldierIndex == MissionInfo.MVPIndex)
	{
		MVPPanel.Show();
		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	}
	else
	{
		MVPPanel.Hide();
	}
	PopulateStats(Unit, NMDUnit);

	// Show awards
	AwardsList.ClearItems();

	foreach MissionInfo.Awards(Award)
	{
		if (Award.IsVisible && Award.IsWinner(CurrentSoldierIndex))
		{
			Spawn(class'UIListItemString', AwardsList.ItemContainer).InitListItem(Award.GetLabel(Unit)).SetTooltipText(Award.Tooltip);
		}
	}
}

function PopulateStats(XComGameState_Unit Unit, XComGameState_NMD_Unit NMDUnit)
{
	local array<UISummary_ItemStat> UnitStats;
	local UISummary_ItemStat AStat;
	local NMD_BaseStat Stat;
	local string StatValue, Label;
	local NMD_BaseAward Award;
	local name StatType;
	local int Value, i;
	local bool AlreadyAdded;

	foreach StatsOrder(StatType)
	{
		Stat = NMDUnit.GetStat(StatType);
		if (Stat == none)
		{
			continue;
		}

		if (!Stat.IsVisible())
			continue;

		Label = Stat.GetName();
		AlreadyAdded = false;
		for (i = 0; i < UnitStats.Length; ++i)
		{
			if (Label == UnitStats[i].Label)
			{
				AlreadyAdded = true;
				break;
			}
		}

		if (AlreadyAdded)
			continue;

		AStat.Label = Label;

		Value = Stat.GetValue(Unit.ObjectID);
		StatValue = Stat.GetDisplayValue();

		//`log("NMD Displaying Stats for " $ Unit.GetFullName() $ ", type: " $ Stat.GetType() $ ", value: " $ Value $ ", ObjectID: " $ Unit.ObjectID);

		Award = MissionInfo.GetAwardForStat(Stat.GetType());
		if (Award != none)
		{	
			if (Award.HasWinner())
			{
				if (Value == Award.MaxValue)
				{
					StatValue = class'UIUtilities_Text'.static.GetColoredText(StatValue, eUIState_Good);
				}
				else if (Value == Award.MinValue)
				{
					StatValue = class'UIUtilities_Text'.static.GetColoredText(StatValue, eUIState_Bad);
				}
			}
			else if (Award.HideStatIfNoWinner())
			{
				continue;
			}
		}

		AStat.Value = StatValue;
		UnitStats.AddItem(AStat);

		if (UnitStats.Length >= 12)
			break;
	}

	StatList.RefreshData(UnitStats);
}

function OnPreviousClick(UIButton Button)
{
	CurrentSoldierIndex--;
	if (CurrentSoldierIndex < 0)
	{
		CurrentSoldierIndex = MissionInfo.GetSquadSize() - 1;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	ShowStatsForUnit(CurrentSoldierIndex);
}

function OnNextClick(UIButton Button)
{
	CurrentSoldierIndex = (CurrentSoldierIndex + 1) % MissionInfo.GetSquadSize();
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	ShowStatsForUnit(CurrentSoldierIndex);
}

function BackToSummary()
{
	local NMD_UIMissionSummary MissionSummary;

	`ScreenStack.PopFirstInstanceOfClass(class'NMD_UIMissionDebriefingScreen', false);

	MissionSummary = NMD_UIMissionSummary(`ScreenStack.GetFirstInstanceOf(class'NMD_UIMissionSummary'));
	if (MissionSummary != none)
	{
		MissionSummary.SummaryListener.EnableMissionSummaryOnLoseFocus(true);
	}
}

function OpenCreatePhoto(UIButton button)
{
	local NMD_UIDebriefPhotobooth Photobooth;
	local XComPresentationLayer Pres;
	local XComWorldData WorldData;
	local array<XComGameState_Unit> playerUnits;
	local int i;

	if (`ScreenStack.IsNotInStack(class'NMD_UIDebriefPhotobooth'))
	{
		Pres = `PRES;
		if (Pres.m_kTacticalHUD != none)
			Pres.m_kTacticalHUD.Hide();

		Photobooth = NMD_UIDebriefPhotobooth(`ScreenStack.Push(Spawn(class'NMD_UIDebriefPhotobooth', Pres)));
		Photobooth.InitPropaganda(UnitRef);

		XGBattle_SP(`BATTLE).GetHumanPlayer().GetOriginalUnits(playerUnits, true, false);

		for (i = 0; i < playerUnits.Length; i++)
		{
			XGUnit(playerUnits[i].GetVisualizer()).GetPawn().SetVisible(false);
		}

		XGBattle_SP(`BATTLE).GetCivilianPlayer().GetUnits(playerUnits);

		for (i = 0; i < playerUnits.Length; i++)
		{
			XGUnit(playerUnits[i].GetVisualizer()).GetPawn().SetVisible(false);
		}

		Pres.ScreenStack.PopFirstInstanceOfClass(class'UISpecialMissionHUD', false);
		Pres.ScreenStack.PopFirstInstanceOfClass(class'UIUnitFlagManager', false);
		Pres.GetActionIconMgr().ShowIcons(false);

		WorldData = class'XComWorldData'.static.GetWorldData();
		if (WorldData != none && WorldData.Volume != none)
		{
			WorldData.Volume.BorderComponent.SetCustomHidden(TRUE);
			WorldData.Volume.BorderComponentDashing.SetCustomHidden(TRUE);
		}
	}
}

function OpenPhotoboothReview(UIButton button)
{
	if (`ScreenStack.IsNotInStack(class'NMD_UIPhotoboothReview'))
	{
		`ScreenStack.Push(Spawn(class'NMD_UIPhotoboothReview', `PRES));
	}
}

function SetPhoto(int Index)
{
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierTexture;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	SoldierTexture = `XENGINE.m_kPhotoManager.GetPosterTexture(SettingsState.GameIndex, Index);
	SetPhotoTexture(SoldierTexture);

	SavePosterIndex(Index);
}

function SetLatestPhoto()
{
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierTexture;
	local X2PhotoBooth_PhotoManager PhotoManager;
	local int PosterIndex;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoManager = `XENGINE.m_kPhotoManager;
	PosterIndex = PhotoManager.GetNumOfPosterForCampaign(SettingsState.GameIndex, false) - 1;
	SoldierTexture = PhotoManager.GetLatestPoster(SettingsState.GameIndex);
	SetPhotoTexture(SoldierTexture);

	SavePosterIndex(PosterIndex);
}

function SetPhotoTexture(Texture2D SoldierTexture)
{
	SoldierImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierTexture)));
	SoldierImage.SetSize(280, 420);
	SoldierImage.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + 20);
}

function SavePosterIndex(int PosterIndex)
{
	local XComGameState_NMD_Unit NMDUnit;
	local XComGameState NewGameState;
	local string Filename;

	NMDUnit = MissionInfo.GetNMDUnit(CurrentSoldierIndex);
	if (NMDUnit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Poster Index");
		NMDUnit = XComGameState_NMD_Unit(NewGameState.ModifyStateObject(class'XComGameState_NMD_Unit', NMDUnit.ObjectID));
		Filename = class'NMD_Utilities'.static.GetFilenameFromPhotoIndex(PosterIndex);
		NMDUnit.SetPosterFilename(Filename, NewGameState);
		//NMDUnit.SetPosterIndex(PosterIndex, NewGameState);
		//`log("NMD Setting PosterIndex to " $ PosterIndex);
		`log("NMD Setting photo filename to " $ Filename);
		`GAMERULES.SubmitGameState(NewGameState);
	}// else `log("NMDUnit SavePosterIndex not found");
}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
			BackToSummary();
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			OpenCreatePhoto(none);
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_Y):
			OpenPhotoboothReview(none);
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			CloseScreen();
			NavHelp.OnClickedContinueDelegate();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			OnPreviousClick(none);
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			OnNextClick(none);
			return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}

defaultproperties
{
	Width = 800
	Height = 800

	bConsumeMouseEvents = true
}
