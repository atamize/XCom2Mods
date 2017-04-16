class MAV_Category_MostLootPickedUp extends MAV_BaseCategory;

function CalculateWinner(MAV_MissionStats MissionStats)
{
	local int i;
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> BackpackItems; 

	for (i = 0; i < Scores.Length; ++i)
	{
		Unit = MissionStats.Squad[i];
		if (Unit.HasBackpack())
		{
			BackpackItems = Unit.GetAllItemsInSlot(eInvSlot_Backpack);
			if (BackpackItems.length > 1)
			{
				Scores[i] = BackpackItems.length;
			}
		}
	}
	
	SetWinnerBasic(MissionStats.Squad);
}
