///---------------------------------------------------------------------------------------
//  FILE:    X2Ability_NameYourPet
//  AUTHOR:  atamize
//  PURPOSE: Defines the Name Your Pet ability
//--------------------------------------------------------------------------------------- 
class X2Ability_NameYourPet extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddNameYourPetAbility());

	return Templates;
}

static function X2AbilityTemplate AddNameYourPetAbility()
{
	local X2AbilityTemplate	Template;
	//local X2Effect_NameYourPet NameYourPetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'NameYourPet');
	
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_aidprotocol";
	Template.AbilitySourceName = 'NameYourPet';
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	//CollectorEffect = new class'X2Effect_Collector';
	//CollectorEffect.BuildPersistentEffect(1, true, true);
	//CollectorEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	//Template.AddTargetEffect(CollectorEffect);

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);  

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;  // deliberately no visualization
	return Template;
}
