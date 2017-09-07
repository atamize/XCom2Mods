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

var UIStatList StatList;

var UINavigationHelp NavHelp;

var StateObjectReference UnitRef;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIMissionSummary MissionSummary;
	local array<XComGameState_Unit> arrSoldiers;

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
	PhotoPanel.InitBG('photoBG', 20, 100, 300, 500);	

	SoldierImage = Spawn(class'UIImage', Container).InitImage();
	SoldierImage.SetPosition(PhotoPanel.X + 20, PhotoPanel.Y + 20);

	CreatePhotoButton = Spawn(class'UIButton', Container);
	CreatePhotoButton.ResizeToText = false;
	CreatePhotoButton.InitButton('CreatePhotoButton', "Create Photo", OpenCreatePhoto, eUIButtonStyle_HOTLINK_BUTTON);
	CreatePhotoButton.SetWidth(200);
	CreatePhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	CreatePhotoButton.SetPosition(PhotoPanel.X + 10, PhotoPanel.Y + PhotoPanel.Height - 50);

	SelectPhotoButton = Spawn(class'UIButton', Container);
	SelectPhotoButton.ResizeToText = false;
	SelectPhotoButton.InitButton('selectPhotoButton', "Select Photo", OpenPhotoboothReview, eUIButtonStyle_HOTLINK_BUTTON);
	SelectPhotoButton.SetWidth(200);
	SelectPhotoButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	SelectPhotoButton.SetPosition(CreatePhotoButton.X + CreatePhotoButton.Width + 30, CreatePhotoButton.Y);

	// Stats
	StatList = Spawn(class'UIStatList', Container);
	StatList.InitStatList('StatList', , Container.Width / 2, 100, Width / 2, Height / 2);
	PopulateStats();

	MissionSummary = UIMissionSummary(`ScreenStack.GetFirstInstanceOf(class'UIMissionSummary'));
	if (MissionSummary != none)
	{
		MissionSummary.BATTLE().GetHumanPlayer().GetOriginalUnits(arrSoldiers, true);

		ShowStatsForUnit(arrSoldiers[0]);

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
	SoldierTexture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, Unit.ObjectID, 256, 256);
	SoldierImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierTexture)));
}

function PopulateStats()
{
	local array<UISummary_ItemStat> UnitStats;
	local UISummary_ItemStat AStat;

	AStat.Label = "FARTS";
	AStat.Value = string(69);
	UnitStats.AddItem( AStat );

	AStat.Label = "BUTTS";
	AStat.Value = string(420) @ "/" @ string(99);
	UnitStats.AddItem( AStat );

	AStat.Label = "PIZZAS DELIVERED";
	AStat.Value = "Who the fuck knows";
	UnitStats.AddItem( AStat );

	StatList.RefreshData(UnitStats);
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
}

function SetLatestPhoto()
{
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierTexture;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	SoldierTexture = `XENGINE.m_kPhotoManager.GetLatestPoster(SettingsState.GameIndex);
	SetPhotoTexture(SoldierTexture);
}

function SetPhotoTexture(Texture2D SoldierTexture)
{
	SoldierImage.LoadImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierTexture)));
	SoldierImage.SetSize(280, 420);
}

defaultproperties
{
	Width = 1300
	Height = 800

	bConsumeMouseEvents = true
}
