// This is an Unreal Script
class NYP_UITacticalHUD_Menu extends UIPanel config(NameYourPet);

const PET_NAME_MAX_CHARS       = 37;

var UITacticalHUD_SoldierInfo SoldierInfo;
var UITacticalHUD_PerkContainer Perks;
var XComGameState_Unit StateUnit;

var localized string m_strNYPButton;
var localized string m_strNYPInputTitle;

var config int ButtonWithoutPerksX;
var config int ButtonWithoutPerksY;
var config int ButtonWithPerksX;
var config int ButtonWithPerksY;

simulated function OnInit()
{
	local UIButton NYPButton;
	local Object ThisObj;

	super.OnInit();

	NYPButton = Spawn(class'UIButton', self);
	NYPButton.InitButton('NYPButton', m_strNYPButton, OnClickedNYP, eUIButtonStyle_NONE);

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalController(PC), 'm_kActiveUnit', self, Refresh);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, Refresh);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComPresentationLayer(Movie.Pres), 'm_kInventoryTactical', self, Refresh);

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockCompleted);
	`log("NYP OnInit");
}

function OnClickedNYP(UIButton Button)
{
	local TInputDialogData kData;

	kData.strTitle = m_strNYPInputTitle;
	kData.iMaxChars = PET_NAME_MAX_CHARS;
	kData.strInputBoxText = StateUnit.GetLastName();
	kData.fnCallback = OnNameInputBoxClosed;

	Movie.Pres.UIInputDialog(kData);
}

function OnNameInputBoxClosed(string text)
{
	StateUnit.SetUnitName(StateUnit.GetFirstName(), text, StateUnit.GetNickName(true));
	UpdateStats();
}

function string SetFlagNames()
{
	local string charName;

	if (StateUnit == none)
		return "";

	charName = StateUnit.GetLastName();
	if (len(charName) == 0)
		charName = StateUnit.GetMyTemplate().strCharacterName;

	`PRES.m_kUnitFlagManager.GetFlagForObjectID(StateUnit.ObjectID).SetNames(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(charName), "");

	return charName;
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit SourceUnit;

	if (StateUnit != none)
	{
		SourceUnit = XComGameState_Unit(EventSource);
		if (SourceUnit.ObjectID == StateUnit.ObjectID)
		{
			Refresh();
		}
	}

	return ELR_NoInterrupt;
}

function UpdateStats()
{
	local string charName, charNickname, charRank, charClass;
	local bool isLeader, isLeveledUp, showBonus, showPenalty;
	local float aimPercent;
	local array<UISummary_UnitEffect> BonusEffects, PenaltyEffects; 
	local X2SoldierClassTemplateManager SoldierTemplateManager;

	charName = SetFlagNames();

	charNickname = StateUnit.GetNickName();

	if( StateUnit.GetMyTemplateName() == 'AdvPsiWitchM2' )
	{
		charRank = "img:///UILibrary_Common.rank_fieldmarshall";
		SoldierTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		charClass = SoldierTemplateManager.FindSoldierClassTemplate('PsiOperative').IconImage;
		aimPercent = StateUnit.GetCurrentStat(eStat_Offense);
	}
	else 
	{
		aimPercent = -1;
	}

	// TODO:
	isLeader = false;
	isLeveledUp = false;
	
	BonusEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);
	PenaltyEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);

	showBonus = (BonusEffects.length > 0 ); 
	showPenalty = (PenaltyEffects.length > 0);

	SoldierInfo.AS_SetStats(charName, charNickname, charRank, charClass, isLeader, isLeveledUp, aimPercent, showBonus, showPenalty);
}

function Refresh()
{
	// Have to delay this otherwise our name will be overwritten by UITacticalHUD_SoldierInfo
	SetTimer(0.1f, false, nameof(RefreshForReal));
}

function RefreshForReal()
{
	local XGUnit        kActiveUnit;

	// If not shown or ready, leave.
	if( !bIsInited )
	{
		return;
	}

	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if( kActiveUnit == none )
	{
		Hide();
	}
	else
	{
		StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
		
		if (!StateUnit.IsSoldier() && !StateUnit.IsCivilian())
		{
			if (Perks.NumActivePerks > 0)
				SetPosition(ButtonWithPerksX, ButtonWithPerksY);
			else
				SetPosition(ButtonWithoutPerksX, ButtonWithoutPerksY);

			UpdateStats();
			Show();
		}
		else
		{
			Hide();
		}
	}
}
