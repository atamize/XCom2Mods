class QBS_UISoldierBondScreen_Listener extends UIScreenListener;

struct BondInfo
{
	var UIPanel Panel;
	var UIImage Image;
	var StateObjectReference UnitRef;
};

var array<BondInfo> arrBondInfo;

var UISoldierBondScreen BondScreen;
var UIImage BondmateButton;

delegate OnClickedCallback(UIImage Image);

event OnInit(UIScreen Screen)
{
	BondScreen = UISoldierBondScreen(Screen);
	Refresh();
}

event OnReceiveFocus(UIScreen Screen)
{
	Refresh();
}

function Refresh()
{
	local XComGameState_HeadquartersXCom HQState;
	local StateObjectReference Ref;

	if (`ScreenStack.HasInstanceOf(class'UICovertActions'))
	{
		UpdateList(OnClickedCovertAction);
		return;
	}
	else if (`ScreenStack.HasInstanceOf(class'UISquadSelect'))
	{
		HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

		// Update list if there is an empty slot on the squad
		foreach HQState.Squad(Ref)
		{
			if (Ref.ObjectID == 0)
			{
				UpdateList(OnClickedSquadSelect);
				break;
			}
		}
	}
}

function UpdateList(delegate<OnClickedCallback> OnClicked)
{
	local UISoldierBondListItem ListItem;
	local array<UIPanel> arrItems;
	local int i, MinRank, MaxRank;
	local BondInfo Info;
	local UIImage SelectButton;
	local string ImagePath;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom HQState;
	local XComGameState_Unit Unit;
	local XComGameState_MissionSite MissionState;
	local GeneratedMissionData MissionData;
	local bool bHasRankLimits, bAllowWoundedSoldiers;
	local StateObjectReference BondmateRef;
	local SoldierBond BondData;

	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

	History = `XCOMHISTORY;
	MissionData = HQState.GetGeneratedMissionData(HQState.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(HQState.MissionRef.ObjectID));
	bHasRankLimits = MissionState.HasRankLimits(MinRank, MaxRank);

	BondScreen.List.ItemContainer.GetChildrenOfType(class'UISoldierBondListItem', arrItems);
	ImagePath = class'UIUtilities_Image'.static.ValidateImagePath(PathName(Texture2D'gfxComponents.resistance_icon'));

	`log("QBS - Refreshing with arrItems length: " $ arrItems.Length);
	arrBondInfo.Length = 0;

	// Update header
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(BondScreen.UnitRef.ObjectID));
	if (Unit.HasSoldierBond(BondmateRef, BondData))
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(BondmateRef.ObjectID));
		if (HQState.IsUnitInSquad(BondmateRef) || !Unit.CanGoOnMission(bAllowWoundedSoldiers) ||
			(bHasRankLimits && (Unit.GetRank() < MinRank || Unit.GetRank() > MaxRank)))
		{
			if (BondmateButton != none)
			{
				BondmateButton.Hide();
			}
		}
		else
		{
			if (BondmateButton == none)
			{
				BondmateButton = BondScreen.Spawn(class'UIImage', BondScreen);
				BondmateButton.InitImage('bondmateButton', ImagePath, OnClicked);
				BondmateButton.SetSize(64, 64);
				BondmateButton.SetPosition(800, 270);
				BondmateButton.SetTooltipText("Add to Squad");
			}

			Info.UnitRef = BondmateRef;
			Info.Image = BondmateButton;
			arrBondInfo.AddItem(Info);

			BondmateButton.Show();
		}
	}
	else if (BondmateButton != none)
	{
		BondmateButton.Hide();
	}

	// Update soldier list
	for (i = 0; i < arrItems.Length; ++i)
	{
		ListItem = UISoldierBondListItem(arrItems[i]);
		ListItem.BG.ProcessMouseEvents(OnListItemClicked);

		Unit = XComGameState_Unit(History.GetGameStateForObjectID(ListItem.UnitRef.ObjectID));

		Info.Panel = ListItem.BG;
		Info.UnitRef = ListItem.UnitRef;

		if (HQState.IsUnitInSquad(ListItem.UnitRef) || !Unit.CanGoOnMission(bAllowWoundedSoldiers) ||
			(bHasRankLimits && (Unit.GetRank() < MinRank || Unit.GetRank() > MaxRank)))
		{	
			arrBondInfo.AddItem(Info);
			continue;
		}

		SelectButton = ListItem.Spawn(class'UIImage', ListItem);
		SelectButton.InitImage('qbsButton', ImagePath, OnClicked);
		SelectButton.SetSize(64, 64);
		SelectButton.SetPosition(420, -7);
		SelectButton.SetTooltipText("Add to Squad");

		Info.Image = SelectButton;
		arrBondInfo.AddItem(Info);
	}
}

function StateObjectReference GetUnitRefForPanel(UIPanel Panel)
{
	local StateObjectReference NullRef;
	local int i;

	for (i = 0; i < arrBondInfo.Length; ++i)
	{
		if (arrBondInfo[i].Panel == Panel)
		{
			return arrBondInfo[i].UnitRef;
		}
	}

	return NullRef;
}

function StateObjectReference GetUnitRefForImage(UIImage Image)
{
	local StateObjectReference NullRef;
	local int i;

	for (i = 0; i < arrBondInfo.Length; ++i)
	{
		if (arrBondInfo[i].Image == Image)
		{
			return arrBondInfo[i].UnitRef;
		}
	}

	return NullRef;
}

function OnClickedSquadSelect(UIImage Image)
{
	local UISquadSelect SquadSelect;
	local UIScreen Screen;
	local XComGameState_HeadquartersXCom XComHQ;
	local int SlotIndex;
	local StateObjectReference UnitRef;

	UnitRef = GetUnitRefForImage(Image);

	Screen = `ScreenStack.GetFirstInstanceOf(class'UISquadSelect');
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (Screen != none)
	{
		`log("QBS found Squad Select");
		SquadSelect = UISquadSelect(Screen);

		// Find an empty slot
		for (SlotIndex = 0; SlotIndex < SquadSelect.SoldierSlotCount; ++SlotIndex)
		{
			if (SlotIndex == SquadSelect.SoldierSlotCount || XComHQ.Squad[SlotIndex].ObjectID == 0)
			{
				SquadSelect.m_iSelectedSlot = SlotIndex;
				SquadSelect.SnapCamera();
				SquadSelect.ChangeSlot(UnitRef);

				BondScreen.CloseScreen();
				`ScreenStack.PopUntil(SquadSelect);
				return;
			}
		}

		// Didn't find open slot
		BondScreen.OnSelectSoldier(UnitRef);
	}
}

function OnClickedCovertAction(UIImage Image)
{
	local UICovertActions CovertActions;
	local UIScreen Screen;
	local int SlotIndex;
	local StateObjectReference UnitRef;
	local QBS_UICovertActionStaffSlot StaffSlot;
	local int i;

	UnitRef = GetUnitRefForImage(Image);

	Screen = `ScreenStack.GetFirstInstanceOf(class'UICovertActions');

	if (Screen != none)
	{
		`log("QBS found Covert Actions");
		CovertActions = UICovertActions(Screen);

		// Find the slot what from we was called
		for (i = 0; i < CovertActions.SlotContainer.ActionSlots.Length; ++i)
		{
			StaffSlot = QBS_UICovertActionStaffSlot(CovertActions.SlotContainer.ActionSlots[i]);
			if (StaffSlot != none)
			{
				if (StaffSlot.bIsSelected)
				{
					StaffSlot.OnPersonnelRefSelected(UnitRef);
					BondScreen.CloseScreen();
					`ScreenStack.PopUntil(CovertActions);
					return;
				}
			}
		}

		// Didn't find open slot
		BondScreen.OnSelectSoldier(UnitRef);
	}
}

function OnListItemClicked(UIPanel Panel, int Cmd)
{
	local StateObjectReference UnitRef;
	
	if (Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		UnitRef = GetUnitRefForPanel(Panel);
		BondScreen.OnSelectSoldier(UnitRef);
		Refresh();
	}
}

defaultproperties
{
	ScreenClass = UISoldierBondScreen
}