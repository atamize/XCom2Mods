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

// weak ref to the screen
// config is just so we can write to it via default.
var config string screen_path;

exec function NMD_OnF2Press()
{
	
}

exec function NMD_OnF2Release()
{
	PushNMDScreen();
}

function PushNMDScreen()
{
	local XComTacticalInput TI;
	local XComGameStateVisualizationMgr VisMgr;
	local UIScreen TempScreen;
	local XComPresentationLayer Pres;
	local UIScreenStack ScreenStack;
	local StateObjectReference Target;
	local XComGameState_BaseObject TargetState;

	Pres = `PRES;

	VisMgr = `XCOMVISUALIZATIONMGR;
	ScreenStack = Pres.ScreenStack;
	TempScreen = ScreenStack.GetFirstInstanceOf(class'NMD_UIMissionDebriefingScreen');
	if (TempScreen != none && ScreenStack.GetCurrentScreen() == TempScreen)
	{
		TempScreen.CloseScreen();
		return;
	}
	
	// don't show when paused or showing popups
	if (Pres.UIIsBusy())
	{
		return;
	}

	// if we are neither targeting nor able to control our current unit, abort
	if (Pres != none && Pres.m_kTacticalHUD.m_kAbilityHUD.TargetingMethod != none)
	{
		Target.ObjectID = Pres.m_kTacticalHUD.m_kAbilityHUD.TargetingMethod.GetTargetedObjectID();
		TargetState = `XCOMHISTORY.GetGameStateForObjectID(Target.ObjectID);
		if (XComGameState_Unit(TargetState) == none)
		{
			`SOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
			return;
		}
	}
	else if (TI.IsInState('ActiveUnit_Moving') && TI.GetActiveUnit() != none && !VisMgr.IsActorBeingVisualized(TI.GetActiveUnit()) && !VisMgr.VisualizerBlockingAbilityActivation())
	{
		Target.ObjectID = TI.GetActiveUnit().ObjectID;
	}
	else
	{
		return;
	}

	TempScreen = GetScreen();
	ScreenStack.Push(TempScreen, Pres.Get2DMovie());
}

static function NMD_UIMissionDebriefingScreen GetScreen()
{
	local NMD_UIMissionDebriefingScreen TempScreen;
	local XComPresentationLayer Pres;

	Pres = `PRES;

	TempScreen = NMD_UIMissionDebriefingScreen(FindObject(default.screen_path, class'NMD_UIMissionDebriefingScreen'));
	if (TempScreen == none)
	{
		TempScreen = Pres.Spawn(class'NMD_UIMissionDebriefingScreen', Pres);
		TempScreen.InitScreen(XComPlayerController(Pres.Owner), Pres.Get2DMovie());
		TempScreen.Movie.LoadScreen(TempScreen);
		default.screen_path = PathName(TempScreen);
	}
	return TempScreen;
}
