// This is an Unreal Script
class NMD_UIMissionDebriefingScreen extends UIScreen;

var UIPanel Container;
var UIBGBox PanelBG;
var UIBGBox FullBG;
var UIX2PanelHeader TitleHeader;
//var UIButton BackToSummaryButton;
var UINavigationHelp NavHelp;
var UIImage SCImage;
var UIImage SoldierImage;
var UIStatList StatList;

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

	SCImage = Spawn(class'UIImage', Container).InitImage();
	SCImage.SetSize(80, 80);
	SCImage.SetPosition(10, 10);

	SoldierImage = Spawn(class'UIImage', Container).InitImage();
	SoldierImage.SetPosition(10, 100);

	TitleHeader = Spawn(class'UIX2PanelHeader', Container);
	TitleHeader.InitPanelHeader('', "", "");
	TitleHeader.SetPosition(10, 10);
	TitleHeader.SetHeaderWidth(Container.Width - TitleHeader.X - 10);

	StatList = Spawn(class'UIStatList', Container);
	StatList.InitStatList('StatList', , Container.Width / 2, 100, Width / 2, Height / 2);
	PopulateStats();

	//BackToSummaryButton = Spawn(class'UIButton', Container);
	//BackToSummaryButton.ResizeToText = false;
	//BackToSummaryButton.InitButton('backButton', "Back To Mission Summary", BackToSummary, eUIButtonStyle_HOTLINK_BUTTON);
	//BackToSummaryButton.SetPosition(20, Container.Height - BackToSummaryButton.Height - 10);
	//BackToSummaryButton.SetWidth(300);
	//BackToSummaryButton.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_B_CIRCLE);

	MissionSummary = UIMissionSummary(`PRES.ScreenStack.GetFirstInstanceOf(class'UIMissionSummary'));
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
	SoldierTexture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, Unit.ObjectID, 128, 128);
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

simulated function BackToSummary()
{
	`PRES.ScreenStack.PopFirstInstanceOfClass(class'NMD_UIMissionDebriefingScreen', false);
}

defaultproperties
{
	Width = 1300
	Height = 800

	bConsumeMouseEvents = true
}
