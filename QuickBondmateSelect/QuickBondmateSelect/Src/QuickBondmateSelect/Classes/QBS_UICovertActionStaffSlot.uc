class QBS_UICovertActionStaffSlot extends UICovertActionStaffSlot;

var bool bIsSelected;
var UIButton BondButton;

function UICovertActionSlot InitStaffSlot(UICovertActionSlotContainer OwningContainer, StateObjectReference Action, int _MCIndex, int _SlotIndex, delegate<OnSlotUpdated> onSlotUpdatedDel)
{
	local UIPanel Panel;

	Panel = OwningContainer.ActionSlotPanels[_MCIndex];
	BondButton = Panel.Spawn(class'UIButton', Panel).InitButton('bondIconMC', "+ ADD BONDMATE", OnClickBondButton);
	BondButton.ResizeToText = false;
	BondButton.SetWidth(300);
	BondButton.SetPosition(120, 55);

	return super.InitStaffSlot(OwningContainer, Action, _MCIndex, _SlotIndex, onSlotUpdatedDel);
}

function UpdateData()
{
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;
	local int i;
	local UICovertActionStaffSlot StaffSlot;

	super.UpdateData();

	bIsSelected = false;
	History = `XCOMHISTORY;
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	`log("QBS - Update data");

	if (!StaffSlotState.IsSlotFilled())
	{
		for (i = 0; i < SlotContainer.ActionSlots.Length; ++i)
		{
			StaffSlot = UICovertActionStaffSlot(SlotContainer.ActionSlots[i]);
			if (StaffSlot != none)
			{
				StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlot.StaffSlotRef.ObjectID));
				if (StaffSlotState.IsSlotFilled())
				{
					BondButton.Show();
					return;
				}
			}
		}
	}

	BondButton.Hide();
}

function OnClickBondButton(UIButton Button)
{
	local XComGameState_Unit UnitState;
	local UICovertActionStaffSlot StaffSlot;
	local int i;

	for (i = 0; i < SlotContainer.ActionSlots.Length; ++i)
	{
		StaffSlot = UICovertActionStaffSlot(SlotContainer.ActionSlots[i]);
		if (StaffSlot != none)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(StaffSlot.UnitRef.ObjectID));

			if (UnitState.GetSoldierClassTemplate().bCanHaveBonds)
			{
				bIsSelected = true;
				`HQPRES.UIArmory_MainMenu(StaffSlot.UnitRef);
				`HQPRES.UISoldierBonds(StaffSlot.UnitRef);
				`log("QBS: Bond JAMES BOND");
			}
			break;
		}
	}
}

defaultproperties
{
	bIsSelected = false
}