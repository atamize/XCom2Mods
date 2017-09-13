// This is an Unreal Script
class NMD_UIMissionDebriefingScreen extends UIScreen;

var UIPanel Container;
var UIBGBox PanelBG;
var UIBGBox FullBG;
var UIX2PanelHeader TitleHeader;
var UIImage SCImage;

var UIBGBox PhotoPanel;
var UIImage SoldierImage;
var UIButton CreatePhotoButton;
var UIButton SelectPhotoButton;
var UIButton PreviousButton;
var UIButton NextButton;

var UIStatList StatList;

var UINavigationHelp NavHelp;

var StateObjectReference UnitRef;
var array<XComGameState_Unit> SoldierList;
var int CurrentSoldierIndex;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIMissionSummary MissionSummary;

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
	PhotoPanel.InitBG('photoBG', 10, 100, 300, 500);	

	SoldierImage = Spawn(class'UIImage', Container).InitImage();
	SoldierImage.SetPosition(PhotoPanel.X + 20, PhotoPanel.Y + 20);

	CreatePhotoButton = Spawn(class'UIButton', Container);
	CreatePhotoButton.ResizeToText = false;
	CreatePhotoButton.InitButton('CreatePhotoButton', "Create Photo", OpenCreatePhoto, eUIButtonStyle_HOTLINK_BUTTON);
	CreatePhotoButton.SetWidth(175);
	CreatePhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	CreatePhotoButton.SetPosition(PhotoPanel.X, PhotoPanel.Y + PhotoPanel.Height - 50);

	SelectPhotoButton = Spawn(class'UIButton', Container);
	SelectPhotoButton.ResizeToText = false;
	SelectPhotoButton.InitButton('selectPhotoButton', "Select Photo", OpenPhotoboothReview, eUIButtonStyle_HOTLINK_BUTTON);
	SelectPhotoButton.SetWidth(175);
	SelectPhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	SelectPhotoButton.SetPosition(CreatePhotoButton.X + CreatePhotoButton.Width + 30, CreatePhotoButton.Y);

	// Navigation
	PreviousButton = Spawn(class'UIButton', Container);
	PreviousButton.ResizeToText = false;
	PreviousButton.InitButton('PreviousButton', "Previous", OnPreviousClick, eUIButtonStyle_HOTLINK_BUTTON);
	PreviousButton.SetWidth(150);
	PreviousButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_LB_L1);
	PreviousButton.SetPosition(Container.Width - 400, Container.Height - 50);

	NextButton = Spawn(class'UIButton', Container);
	NextButton.ResizeToText = false;
	NextButton.InitButton('NextButton', "Next", OnNextClick, eUIButtonStyle_HOTLINK_BUTTON);
	NextButton.SetWidth(150);
	NextButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_RB_R1);
	NextButton.SetPosition(PreviousButton.X + PreviousButton.Width + 30, PreviousButton.Y);

	// Stats
	StatList = Spawn(class'UIStatList', Container);
	StatList.InitStatList('StatList', , Container.Width / 2, 100, Width / 2, Height / 2);

	MissionSummary = UIMissionSummary(`ScreenStack.GetFirstInstanceOf(class'UIMissionSummary'));
	if (MissionSummary != none)
	{
		MissionSummary.BATTLE().GetHumanPlayer().GetOriginalUnits(SoldierList, true);

		CurrentSoldierIndex = 0;
		ShowStatsForUnit(SoldierList[CurrentSoldierIndex]);

		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
		NavHelp.AddContinueButton(MissionSummary.CloseScreenTakePhoto);
	}

	NavHelp.AddBackButton(BackToSummary);
}

function ShowStatsForUnit(XComGameState_Unit Unit)
{
	local X2SoldierClassTemplate SoldierClass;
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierTexture;
	local X2PhotoBooth_PhotoManager PhotoManager;
	local XComGameState_NMD_Unit NMDUnit;
	local NMD_PersistentData PersistentData;

	UnitRef = Unit.GetReference();

	SoldierClass = Unit.GetSoldierClassTemplate();
	if (SoldierClass != none)
	{
		SCImage.LoadImage(SoldierClass.IconImage);
		SCImage.Show();
	}

	TitleHeader.SetX(10 + SCImage.Width + 10);
	TitleHeader.SetWidth(Container.Width - TitleHeader.X - 10);
	TitleHeader.SetText(Unit.GetFullName(), Caps(SoldierClass != None ? SoldierClass.DisplayName : ""));
	TitleHeader.MC.FunctionVoid("realize");

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoManager = `XENGINE.m_kPhotoManager;

	NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));

	if (NMDUnit != none)
	{
		PersistentData = NMDUnit.GetPersistentData();
		`log("NMDUnit found with poster index " $ PersistentData.PosterIndex);
		if (PersistentData.PosterIndex >= 0 && PersistentData.PosterIndex < PhotoManager.GetNumOfPosterForCampaign(SettingsState.GameIndex, false))
		{
			SoldierTexture = PhotoManager.GetPosterTexture(SettingsState.GameIndex, PersistentData.PosterIndex);
		}
	} else `log("NMD Failed to find component");

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
	}

	SoldierImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierTexture)));

	PopulateStats(Unit);
}

function PopulateStats(XComGameState_Unit Unit)
{
	local array<UISummary_ItemStat> UnitStats;
	local UISummary_ItemStat AStat;
	local XComGameState_NMD_Unit NMDUnit;
	local NMD_Stats Stats;

	NMDUnit = class'NMD_Utilities'.static.EnsureHasUnitStats(Unit);
	if (NMDUnit != none)
	{
		Stats = NMDUnit.GetMainStats();

		AStat.Label = "KILLS";
		AStat.Value = string(Stats.numKills);
		UnitStats.AddItem( AStat );

		AStat.Label = "SHOTS";
		AStat.Value = string(Stats.numHits) @ "/" @ string(Stats.numShots);
		UnitStats.AddItem( AStat );

		AStat.Label = "DAMAGE DEALT";
		AStat.Value = string(Stats.damageDealt);
		UnitStats.AddItem( AStat );

		StatList.RefreshData(UnitStats);
	}
}

function OnPreviousClick(UIButton Button)
{
	CurrentSoldierIndex--;
	if (CurrentSoldierIndex < 0)
	{
		CurrentSoldierIndex = SoldierList.Length - 1;
	}
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	ShowStatsForUnit(SoldierList[CurrentSoldierIndex]);
}

function OnNextClick(UIButton Button)
{
	CurrentSoldierIndex = (CurrentSoldierIndex + 1) % SoldierList.Length;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	ShowStatsForUnit(SoldierList[CurrentSoldierIndex]);
}

function BackToSummary()
{
	`ScreenStack.PopFirstInstanceOfClass(class'NMD_UIMissionDebriefingScreen', false);
}

function OpenCreatePhoto(UIButton button)
{
	local NMD_UIDebriefPhotobooth Photobooth;

	if (`ScreenStack.IsNotInStack(class'NMD_UIDebriefPhotobooth'))
	{
		Photobooth = NMD_UIDebriefPhotobooth(`ScreenStack.Push(Spawn(class'NMD_UIDebriefPhotobooth', `PRES)));
		Photobooth.InitPropaganda(UnitRef);
	}
}

function OpenPhotoboothReview(UIButton button)
{
	if (`ScreenStack.IsNotInStack(class'UIPhotoboothReview'))
	{
		`ScreenStack.Push(Spawn(class'UIPhotoboothReview', `PRES));
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
}

function SavePosterIndex(int PosterIndex)
{
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit NMDUnit;
	local XComGameState NewGameState;

	Unit = SoldierList[CurrentSoldierIndex];
	NMDUnit = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));
	if (NMDUnit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Poster Index");
		NMDUnit = XComGameState_NMD_Unit(NewGameState.ModifyStateObject(class'XComGameState_NMD_Unit', NMDUnit.ObjectID));
		NMDUnit.SetPosterIndex(PosterIndex, NewGameState);
		`log("NMD Setting PosterIndex to " $ PosterIndex);
		`GAMERULES.SubmitGameState(NewGameState);
	} else `log("NMDUnit SavePosterIndex not found");
}

defaultproperties
{
	Width = 1300
	Height = 800

	bConsumeMouseEvents = true
}
