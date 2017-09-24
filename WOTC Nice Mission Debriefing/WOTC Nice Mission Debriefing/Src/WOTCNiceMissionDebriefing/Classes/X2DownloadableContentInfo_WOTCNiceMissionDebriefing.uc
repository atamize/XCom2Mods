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
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
	class'NMD_Utilities'.static.ResetMissionStats(StartGameState);
}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{
	`log("NMD - cleaning up units");
	class'NMD_Utilities'.static.CleanupDismissedUnits();
	//class'NMD_Utilities'.static.ResetMissionStats();
}
