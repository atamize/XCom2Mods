//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTCNiceMissionDebriefing.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTCNiceMissionDebriefing extends X2DownloadableContentInfo;

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
//static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
//{
	//class'NMD_Utilities'.static.ResetMissionStats(StartGameState);
//}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
//static event OnExitPostMissionSequence()
//{
//	if (class'NMD_Utilities'.default.bLog) `LOG("NMD - cleaning up units");
//	class'NMD_Utilities'.static.CleanupDismissedUnits();
//	//class'NMD_Utilities'.static.ResetMissionStats();
//}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	local XComGameState NewGameState;
    local XComGameState_Unit Unit;
    local XComGameState_NMD_Unit UnitStats;
	local NMD_BaseStat Stat;
	local XComGameState_HeadquartersXCom HQ;
	local int i;

	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (HQ == none)
		return;
	
	if (class'NMD_Utilities'.default.bLog) `LOG("NMD - Converting old photo data to use new photo data");
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("NMD Convert old photo data to new system");

	for (i = 0; i < HQ.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectId(HQ.Crew[i].ObjectID));
		UnitStats = XComGameState_NMD_Unit(Unit.FindComponentObject(class'XComGameState_NMD_Unit'));

		if (UnitStats != none)
		{
			Stat = UnitStats.GetStat(class'NMD_PersistentStat_PosterData'.const.ID);
			if (Stat != none)
			{
				if (Len(Stat.GetName()) > 2)
				{
					if (class'NMD_Utilities'.default.bLog) `LOG("NMD - save filename " $ Stat.GetName());
					class'NMD_Utilities'.static.SavePhotoWithFilenameForUnit(Unit.ObjectId, Stat.GetName(), NewGameState, false);
				}
			}

			NewGameState.RemoveStateObject(UnitStats.ObjectID);
		}
    }

	if (NewGameState.GetNumGameStateObjects() > 0)
        `GAMERULES.SubmitGameState(NewGameState);
    else
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
}
