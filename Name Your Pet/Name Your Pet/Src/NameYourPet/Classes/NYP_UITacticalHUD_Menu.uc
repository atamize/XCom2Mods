// This is an Unreal Script
class NYP_UITacticalHUD_Menu extends UIPanel;

const PET_NAME_MAX_CHARS       = 37;

var UITacticalHUD_SoldierInfo SoldierInfo;
var UITacticalHUD_PerkContainer Perks;
var XComGameState_Unit StateUnit;

simulated function OnInit()
{
	local UIButton NYPButton;

	super.OnInit();

	NYPButton = Spawn(class'UIButton', self);
	NYPButton.InitButton('NYPButton', "Rename", OnClickedNYP, eUIButtonStyle_NONE);

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalController(PC), 'm_kActiveUnit', self, Refresh);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, Refresh);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComPresentationLayer(Movie.Pres), 'm_kInventoryTactical', self, Refresh);
}

function OnClickedNYP(UIButton Button)
{
	local TInputDialogData kData;

	`log("You clicked NYP");
	kData.strTitle = "Name Your Pet";
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

function UpdateStats()
{
	local string charName, charNickname, charRank, charClass;
	local bool isLeader, isLeveledUp, showBonus, showPenalty;
	local float aimPercent;
	local array<UISummary_UnitEffect> BonusEffects, PenaltyEffects; 
	local X2SoldierClassTemplateManager SoldierTemplateManager;

	charName = StateUnit.GetLastName();
	if (len(charName) == 0)
		charName = StateUnit.GetMyTemplate().strCharacterName;

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

	`PRES.m_kUnitFlagManager.GetFlagForObjectID(StateUnit.ObjectID).SetNames(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(charName), "");
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
		return;
	
	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if( kActiveUnit == none )
	{
		Hide();
	}
	else
	{
		StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
		//`log("NYP info position: " @ SoldierInfo.Y @ ", Size: " $ SoldierInfo.Width @ "x" @ SoldierInfo.Height);
		
		if (!StateUnit.IsSoldier() && !StateUnit.IsCivilian())
		{
			if (Perks.NumActivePerks > 0)
				SetPosition(70, -160);
			else
				SetPosition(70, -100);

			UpdateStats();
			Show();
		}
		else
		{
			Hide();
		}
	}
}
