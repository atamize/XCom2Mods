class NMD_Utilities extends Object config (WOTCNiceMissionDebriefing);

const DEBUG=true;
const DEBUG2=true;
const METRIC_PHOTO_INDEX="NMD_PHOTO_INDEX";

var config array<name> basicShotAbilities;
var config array<name> moveShotAbilities;

/**
	Generates and stores the NMD_Root GameState into History if it does not already exist
*/
static function XComGameState_NMD_Root CheckOrCreateRoot()
{
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_NMD_Root RootStats, NewRoot;

	RootStats = XComGameState_NMD_Root(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_NMD_Root', true));
	
	if (RootStats == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Root NMD");

		RootStats = XComGameState_NMD_Root(NewGameState.CreateStateObject(class'XComGameState_NMD_Root'));		
		RootStats.InitComponent();
		
		NewGameState.AddStateObject(RootStats);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
	else
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Checking/Adding RootStats");
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		NewRoot = XComGameState_NMD_Root(NewGameState.CreateStateObject(class'XComGameState_NMD_Root', RootStats.ObjectID));
		NewRoot.InitComponent();
		
		NewGameState.AddStateObject(NewRoot);
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);

		if (RootStats.ModVersion != class'XComGameState_NMD_Root'.const.CURRENT_VERSION)
			`log("NMD - UPDATED NMD_ROOT FROM " $ RootStats.ModVersion $ " TO " $ NewRoot.ModVersion $ " ====");
		else
			`log("NMD - Already at version " $ RootStats.ModVersion $ " ====");
	}

	return RootStats;
}

/**
	Ensures that all soldiers currently in HQ have UnitStats
*/
static function EnsureAllHaveUnitStats()
{
	local XComGameState_HeadquartersXCom HQ;
	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if( HQ == none )
		return;
		
	ensureHaveUnitStats(HQ.Crew);
}

/**
	Ensures that all soldiers currently in the Squad have UnitStats
*/
static function EnsureSquadHasUnitStats()
{
	local XComGameState_HeadquartersXCom HQ;
	local ReserveSquad Reserve;

	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if( HQ == none )
		return;
		
	foreach HQ.AllSquads(Reserve)
	{
		EnsureHaveUnitStats(Reserve.SquadMembers);
	}
}

/**
	Ensures that all soldiers int he given list have UnitStats
*/
static function EnsureHaveUnitStats(array<StateObjectReference> Units)
{
	local XComGameState_Unit Unit;
	local int i;

	// Update all in array
	for (i = 0; i < Units.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectId(Units[i].ObjectID));
		EnsureHasUnitStats(Unit);
	}
}

static function XComGameState_NMD_Unit FindUnitStats(XComGameState_Unit Unit)
{
	local XComGameStateHistory History;
	local XComGameState_NMD_Unit UnitStats;

	if (!Unit.IsSoldier())
		return none;
	
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_NMD_Unit', UnitStats)
	{
		if (Unit.GetReference().ObjectID == UnitStats.OwnerID)
		{
			return UnitStats;
		}
	}

	return none;
}

/**
	Ensures the given unit has UnitStats if he is a soldier
*/
static function XComGameState_NMD_Unit EnsureHasUnitStats(XComGameState_Unit Unit)
{
	// Shortcut variables
	//local XComGameStateHistory History;

	// To perform the gamestate modification
	local XComGameState NewGameState;
	local XComGameState_NMD_Unit UnitStats;
	
	// If unit is not a soldier, return
	if (!Unit.IsSoldier())
		return none;
	
	// Check if unit has UnitStats
	UnitStats = class'NMD_Utilities'.static.FindUnitStats(Unit);
	
	if (UnitStats == none)
	{
		// If not found, we need to add it
		//if( DEBUG ) `log("=NMD= Adding UnitStats for " $ unit.GetFullName() $ " =======");
		// Get shortcut vars
		//History = `XCOMHISTORY;

		// Setup new game state
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding UnitStats to " $ unit.GetFullName());
		
		// Create and add UnitStats
		UnitStats = XComGameState_NMD_Unit(NewGameState.CreateNewStateObject(class'XComGameState_NMD_Unit'));
		UnitStats.InitComponent(NewGameState, Unit.GetReference().ObjectID);
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	return UnitStats;
}

static function ResetMissionStats(XComGameState NewGameState)
{
	local XComGameState_Unit Unit;
	local XComGameState_NMD_Unit UnitStats, NMDUnit;
	local XComGameState_HeadquartersXCom HQ;
	local XComGameStateHistory History;
	local StateObjectReference Ref;

	// Setup shortcut vars
	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (HQ == none)
		return;

	History = `XCOMHISTORY;

    foreach HQ.Crew(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
        
		if (Unit != none)
		{
			UnitStats = FindUnitStats(Unit);
			if (UnitStats != none)
			{
				`log("NMD - clearing stats for unit " $ Unit.GetFullName());
				NMDUnit = XComGameState_NMD_Unit(NewGameState.ModifyStateObject(class'XComGameState_NMD_Unit', UnitStats.ObjectID));
				NMDUnit.ClearMissionStats(NewGameState);
			}
        }
    }
}

/**
	As recommended by Amineri -- Based on her NexusMods post
*/
static function CleanupDismissedUnits()
{
    local XComGameState NewGameState;
    local XComGameState_Unit Unit;
    local XComGameState_NMD_Unit UnitStats;
	
	//`log("NMD - Cleanup dismissed units");
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("NMD Cleanup");
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_NMD_Unit', unitStats, , true)
	{
        //check and see if the OwningObject is still alive and exists
        if (UnitStats.OwnerId > 0)
		{
            Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(unitStats.OwnerID));
            if (Unit == none)
			{
                // Remove disconnected officer state
                NewGameState.RemoveStateObject(UnitStats.ObjectID);
            }
            else
			{
                if (Unit.bRemoved)
				{
                    NewGameState.RemoveStateObject(UnitStats.ObjectID);
                }
            }
        }
    }
	
    if (NewGameState.GetNumGameStateObjects() > 0)
        `GAMERULES.SubmitGameState(NewGameState);
    else
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

static function int GetDamageResultIndexMod(name Ability, out XComGameState_NMD_Unit Stats, XComGameState SourceGameState)
{
	if (Ability != 'fanfire')
	{
		Stats.multifireHistoryIndex = -1;
		Stats.multifireIndex = 1;
		return 1;
	}

	if (sourceGameState.HistoryIndex != Stats.multifireHistoryIndex)
	{
		Stats.multifireHistoryIndex = SourceGameState.HistoryIndex;
		Stats.multifireIndex = 1;
	}
	
	return Stats.multifireIndex++;
}

static function bool IsShotType(name Type)
{
	local name BasicShotAbility;

	foreach default.basicShotAbilities(BasicShotAbility)
	{
		if (type == basicShotAbility)
			return true;
	}
	
	return false;
}

static function bool IsMoveType(name Type)
{
	local name MoveShotAbility;
	
	foreach default.MoveShotAbilities(MoveShotAbility)
	{
		if (Type == MoveShotAbility)
			return true;
	}
	
	return false;
}

static delegate int IntArrayDelegate(int i);

static function int FindMax(delegate<IntArrayDelegate> Del, int Length, optional out array<int> Output)
{
	local int i, MaxValue, Value;

	MaxValue = -1;

	for (i = 0; i < Length; ++i)
	{
		Value = Del(i);
		if (Value > MaxValue)
			MaxValue = Value;
	}

	for (i = 0; i < Length; ++i)
	{
		Value = Del(i);
		if (Value == MaxValue)
			Output.AddItem(i);
	}

	return MaxValue;
}

static function int FindMin(delegate<IntArrayDelegate> Del, int Length, optional out array<int> Output)
{
	local int i, MinValue, Value;

	MinValue = MaxInt;

	for (i = 0; i < Length; ++i)
	{
		Value = Del(i);
		if (Value < MinValue)
			MinValue = Value;
	}

	for (i = 0; i < Length; ++i)
	{
		Value = Del(i);
		if (Value == MinValue)
			Output.AddItem(i);
	}

	return MinValue;
}

static function bool IsFriendly(XComGameState_Unit Unit)
{
	local name TemplateName;

	if (Unit == none)
		return false;

	if (Unit.GetTeam() == eTeam_XCom || Unit.IsMindControlled())
		return true;

	TemplateName = Unit.GetMyTemplateName();

	switch(TemplateName)
	{
	case 'Soldier_VIP':
	case 'Scientist_VIP':
	case 'Engineer_VIP':
	case 'FriendlyVIPCivilian':
	case 'HostileVIPCivilian':
	case 'CommanderVIP':
	case 'Engineer':
	case 'Scientist':
		return true;
	}

	return false;
}

static function bool IsAbilityAvailable(StateObjectReference StateRef, name AbilityName)
{
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_Unit OutCachedAbilitiesInfo;
	local AvailableAction Action;
	local int Index;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	TacticalRules.GetGameRulesCache_Unit(StateRef, OutCachedAbilitiesInfo);
	
	for (Index = 0; Index < OutCachedAbilitiesInfo.AvailableActions.Length; ++Index)
	{		
		Action = OutCachedAbilitiesInfo.AvailableActions[Index];
		SelectedAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();	

		//`log("    MAVAbility action: " $ SelectedAbilityTemplate.DataName $ ", code: " $ Action.AvailableCode); 
		if (SelectedAbilityTemplate.DataName == AbilityName && Action.AvailableCode == 'AA_Success')
		{
			return true;
		}
	}

	return false;
}

static function bool IsGameStateInterrupted(XComGameState GameState, optional string Message)
{
	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		if (len(Message) > 0)
		{
			`log("NMD - Game state was interrupted: " $ Message);
		}
		return true;
	}
	return false;
}

static function string GetFilenameFromPhotoIndex(int Index)
{
	local array<CampaignPhotoData> PhotoDatabase;
	local int i;
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoDatabase = `XENGINE.m_kPhotoManager.m_PhotoDatabase;

	for (i = 0; i < PhotoDatabase.Length; ++i)
	{
		if (PhotoDatabase[i].CampaignID == SettingsState.GameIndex)
		{
			if (Index < PhotoDatabase[i].Posters.Length)
			{
				return PhotoDatabase[i].Posters[Index].PhotoFilename;
			}
		}
	}

	return "";
}

static function Texture2D GetTextureFromPhotoFilename(string Filename)
{
	local array<CampaignPhotoData> PhotoDatabase;
	local int i, j;
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoDatabase = `XENGINE.m_kPhotoManager.m_PhotoDatabase;

	for (i = 0; i < PhotoDatabase.Length; ++i)
	{
		if (PhotoDatabase[i].CampaignID == SettingsState.GameIndex)
		{
			for (j = 0; j < PhotoDatabase[i].Posters.Length; ++j)
			{
				if (PhotoDatabase[i].Posters[j].PhotoFilename == Filename)
				{
					return `XENGINE.m_kPhotoManager.GetPosterTexture(SettingsState.GameIndex, j);
				}
			}
		}
	}

	return none;
}

static function Texture2D GetPhotoForUnit(int UnitID)
{
	local string UnitMetric, Suffix, Filename;
	local XComGameState_Analytics Analytics;
	local array<CampaignPhotoData> PhotoDatabase;
	local int i, j, SuffixLength, Zeroes;
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	PhotoDatabase = `XENGINE.m_kPhotoManager.m_PhotoDatabase;

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));

	UnitMetric = "UNIT_" $ UnitID $ "_" $ METRIC_PHOTO_INDEX;
	Suffix = Analytics.GetValueAsString(UnitMetric, "");
	SuffixLength = Len(Suffix);

	if (SuffixLength > 0)
	{
		Zeroes = 3 - SuffixLength;
		for (i = 0; i < Zeroes; ++i)
		{
			Suffix = "0" $ Suffix;
		}

		for (i = 0; i < PhotoDatabase.Length; ++i)
		{
			if (PhotoDatabase[i].CampaignID == SettingsState.GameIndex)
			{
				for (j = 0; j < PhotoDatabase[i].Posters.Length; ++j)
				{
					Filename = PhotoDatabase[i].Posters[j].PhotoFilename;
					if (Mid(Filename, Len(Filename) - 7, 3) == Suffix)
					{
						if (PhotoDatabase[i].Posters[j].CharacterIDs.Length == 1 && PhotoDatabase[i].Posters[j].CharacterIDs[0] == UnitID)
						{
							`log("NMD - found photo for Unit " $ UnitID $ " at index: " $ Suffix);
							return `XENGINE.m_kPhotoManager.GetPosterTexture(SettingsState.GameIndex, j);
						}
						else
						{
							break;
						}
					}
				}
			}
		}
	}

	// Didn't find a suitable photo, so do this
	for (i = 0; i < PhotoDatabase.Length; ++i)
	{
		if (PhotoDatabase[i].CampaignID == SettingsState.GameIndex)	
		{
			// Go in reverse order because we want the latest photo taken of this character
			for (j = PhotoDatabase[i].Posters.Length - 1; j >= 0; --j)
			{
				if (PhotoDatabase[i].Posters[j].CharacterIDs.Length == 1 && PhotoDatabase[i].Posters[j].CharacterIDs[0] == UnitID)
				{
					`log("NMD - found fallback photo for Unit " $ UnitID);
					return `XENGINE.m_kPhotoManager.GetPosterTexture(SettingsState.GameIndex, j);
				}
			}
		}
	}
		
	`log("NMD - Couldn't find photo for Unit " $ UnitID $ " at index: " $ Suffix);
	return none;
}

static function SavePhotoForUnit(int UnitID, int PhotoIndex)
{
	local string Filename;
	local XComGameState NewGameState;

	Filename = GetFilenameFromPhotoIndex(PhotoIndex);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Analytics Save Photo Index");
	SavePhotoWithFilenameForUnit(UnitID, Filename, NewGameState);
}

static function SavePhotoWithFilenameForUnit(int UnitID, string Filename, XComGameState NewGameState, optional bool Submit = true)
{
	local string UnitMetric;
	local int Index;
	local XComGameState_Analytics Analytics, AnalyticsObject;

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	AnalyticsObject = XComGameState_Analytics(NewGameState.ModifyStateObject(class'XComGameState_Analytics', Analytics.ObjectID));

	Index = int(Mid(FileName, Len(Filename) - 6, 3));
	`log("NMD - saving photo for Unit " $ UnitID $ " with filename " $ Filename $ ", at index: " $ Index);
	UnitMetric = "UNIT_" $ UnitID $ "_" $ METRIC_PHOTO_INDEX;
	AnalyticsObject.SetValue(UnitMetric, Index);

	if (Submit)
	{
		Analytics.SubmitGameState(NewGameState, AnalyticsObject);
	}
}
