class NMD_UIDebriefPhotobooth extends UITactical_Photobooth;

var StateObjectReference m_kDefaultSoldierRef;

function InitPropaganda(StateObjectReference UnitRef)
{
	m_kDefaultSoldierRef = UnitRef;
}

function InitializeFormation()
{
	local array<X2PropagandaPhotoTemplate> arrFormations;
	local int i, FormationIndex;

	FormationIndex = INDEX_NONE;
	`PHOTOBOOTH.GetFormations(arrFormations);
	for (i = 0; i < arrFormations.Length; ++i)
	{
		if (arrFormations[i].DataName == name("Solo"))
		{
			FormationIndex = i;
			break;
		}
	}

	FormationIndex = FormationIndex != INDEX_NONE ? FormationIndex : `SYNC_RAND(arrFormations.Length);

	if (DefaultSetupSettings.FormationTemplate == none)
	{
		DefaultSetupSettings.FormationTemplate = arrFormations[FormationIndex];
	}

	SetFormation(FormationIndex);
}

function GenerateDefaultSoldierSetup()
{
	`PHOTOBOOTH.SetSoldier(0, m_kDefaultSoldierRef);

	if (DefaultSetupSettings.PossibleSoldiers.Length == 0)
		DefaultSetupSettings.PossibleSoldiers.AddItem(m_kDefaultSoldierRef);

	m_bInitialized = true;
	NeedsPopulateData();
}

function UpdateSoldierData()
{
	m_arrSoldiers.Length = 0;

	super.UpdateSoldierData();
}

function CreatePosterCallback(StateObjectReference UnitRef)
{
	local NMD_UIMissionDebriefingScreen NMD;

	NMD = NMD_UIMissionDebriefingScreen(`ScreenStack.GetLastInstanceOf(class'NMD_UIMissionDebriefingScreen'));
	if (NMD != none)
	{
		NMD.SetLatestPhoto();
	}

	bWaitingOnPhoto = false;
	Movie.Pres.UICloseProgressDialog();
	CloseScreen();
}

simulated function CloseScreen()
{
	Movie.Stack.Pop(self);
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}
