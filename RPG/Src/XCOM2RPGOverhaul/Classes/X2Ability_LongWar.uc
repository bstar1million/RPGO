class X2Ability_LongWar extends XMBAbility config(RPG);

var config int INTERFERENCE_CV_CHARGES;
var config int INTERFERENCE_MG_CHARGES;
var config int INTERFERENCE_BM_CHARGES;
var config int INTERFERENCE_ACTION_POINTS;

var config int CUTTHROAT_BONUS_CRIT_CHANCE;
var config int CUTTHROAT_BONUS_CRIT_DAMAGE;

var config int RESCUE_CV_CHARGES;
var config int RESCUE_MG_CHARGES;
var config int RESCUE_BM_CHARGES;

var config int RAPID_TARGETING_COOLDOWN;
var config int MULTI_TARGETING_COOLDOWN;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(Lethal());
	Templates.AddItem(CloseCombatSpecialist());
	Templates.AddItem(BringEmOn());
	Templates.AddItem(AddCloseEncountersAbility());
	Templates.AddItem(AddCloseandPersonalAbility());
	Templates.AddItem(AddLightEmUpAbility());
	Templates.AddItem(AddLockdownAbility());
	Templates.AddItem(LockdownBonuses());
	Templates.AddItem(AddCutthroatAbility());
	Templates.AddItem(AddInterferenceAbility());
	Templates.AddItem(Aggression());
	Templates.AddItem(TacticalSense());
	Templates.AddItem(AddRescueProtocol());
	Templates.AddItem(AddRapidTargeting());
	Templates.AddItem(AddMultiTargeting());
	Templates.AddItem(PurePassive('HDHolo', "img:///UILibrary_RPG.LW_AbilityHDHolo", true));
	Templates.AddItem(PurePassive('IndependentTracking', "img:///UILibrary_RPG.LW_AbilityIndependentTracking", true));
	Templates.AddItem(PurePassive('VitalPointTargeting', "img:///UILibrary_RPG.LW_AbilityVitalPointTargeting", true));
	Templates.AddItem(PurePassive('RapidTargeting_Passive', "img:///UILibrary_RPG.LW_AbilityRapidTargeting", true));


	return Templates;
}

static function X2AbilityTemplate Lethal()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.AddDamageModifier(2);
	Effect.AbilityTargetConditions.AddItem(default.MatchingWeaponCondition);

	return Passive('Lethal', "img:///Texture2D'UILibrary_RPG.LW_AbilityKinetic'", true, Effect);
}

static function X2AbilityTemplate CloseCombatSpecialist()
{
	local X2AbilityTemplate Template;
	local X2AbilityToHitCalc_StandardAim ToHit;

	Template = Attack('CloseCombatSpecialist', "img:///Texture2D'UILibrary_RPG.LW_AbilityCloseCombatSpecialist'", false, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_None);
	
	HidePerkIcon(Template);
	AddIconPassive(Template);

	ToHit = new class'X2AbilityToHitCalc_StandardAim';
	ToHit.bReactionFire = true;
	Template.AbilityToHitCalc = ToHit;
	Template.AbilityTriggers.Length = 0;
	AddMovementTrigger(Template);
	Template.AbilityTargetConditions.AddItem(TargetWithinTiles(4));
	AddPerTargetCooldown(Template, 1);

	return Template;
}

static function X2AbilityTemplate BringEmOn()
{
	local XMBEffect_ConditionalBonus Effect;
	local XMBValue_Visibility Value;
	 
	Value = new class'XMBValue_Visibility';
	Value.bCountEnemies = true;
	Value.bSquadsight = true;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.AddDamageModifier(1);
	Effect.ScaleValue = Value;
	Effect.ScaleMax = 8;

	return Passive('BringEmOn', "img:///Texture2D'UILibrary_RPG.LW_AbilityBringEmOn'", true, Effect);
}

static function X2AbilityTemplate AddCloseEncountersAbility()
{
	local X2AbilityTemplate							Template;
	local X2Effect_CloseEncounters					ActionEffect;
	
	`CREATE_X2ABILITY_TEMPLATE (Template, 'CloseEncounters');
	Template.IconImage = "img:///Texture2D'UILibrary_RPG.LW_AbilityCloseEncounters'";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	//Template.bIsPassive = true;  // needs to be off to allow perks
	ActionEffect = new class 'X2Effect_CloseEncounters';
	ActionEffect.SetDisplayInfo (ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	ActionEffect.BuildPersistentEffect(1, true, false);
	Template.AddTargetEffect(ActionEffect);
	Template.bCrossClassEligible = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Visualization handled in Effect
	return Template;
}

static function X2AbilityTemplate AddCloseandPersonalAbility()
{
	local X2AbilityTemplate						Template;
	local X2Effect_CloseandPersonal				CritModifier;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CloseandPersonal');
	Template.IconImage = "img:///Texture2D'UILibrary_RPG.LW_AbilityCloseAndPersonal'";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;
	CritModifier = new class 'X2Effect_CloseandPersonal';
	CritModifier.BuildPersistentEffect (1, true, false);
	CritModifier.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (CritModifier);
	Template.bCrossClassEligible = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate AddInterferenceAbility()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2AbilityCharges_Interference         Charges;
	local X2AbilityCost_Charges                 ChargeCost;
	local X2Condition_Visibility                VisCondition;
	local X2Effect_Interference					ActionPointsEffect;
	local X2Condition_UnitActionPoints			ValidTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Interference');

	Template.IconImage = "img:///UILibrary_RPG.LW_AbilityInterference";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;
	Template.bLimitTargetIcons = true;
	Template.DisplayTargetHitChance = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.bStationaryWeapon = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bSkipPerkActivationActions = true;
	Template.bCrossClassEligible = false;

	Charges = new class 'X2AbilityCharges_Interference';
	Charges.CV_Charges = default.INTERFERENCE_CV_CHARGES;
	Charges.MG_Charges = default.INTERFERENCE_MG_CHARGES;
	Charges.BM_Charges = default.INTERFERENCE_BM_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.INTERFERENCE_ACTION_POINTS;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bRequireGameplayVisible = true;
	VisCondition.bActAsSquadsight = true;
	Template.AbilityTargetConditions.AddItem(VisCondition);
	
	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(1,class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint,true,eCheck_GreaterThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ActionPointsEffect = new class'X2Effect_Interference';
	Template.AddTargetEffect (ActionPointsEffect);
	
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.CustomSelfFireAnim = 'NO_CombatProtocol';
	Template.CinescriptCameraType = "Specialist_CombatProtocol";
	Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_SpecialistAbilitySet'.static.GremlinSingleTarget_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate Aggression()
{
	local XMBEffect_ConditionalBonus Effect;
	local XMBValue_Visibility Value;
	 
	// Create a value that will count the number of visible units
	Value = new class'XMBValue_Visibility';
	Value.bCountEnemies = true;

	// Create a conditional bonus effect
	Effect = new class'XMBEffect_ConditionalBonus';

	// The effect adds +3 defense per enemy unit
	Effect.AddToHitModifier(5, eHit_Crit);

	// The effect scales with the number of visible enemy units, to a maximum of 6 (for +30 Crit).
	Effect.ScaleValue = Value;
	Effect.ScaleMax = 6;

	// Create the template using a helper function
	return Passive('RpgAggression', "img:///UILibrary_RPG.LW_AbilityAggression", true, Effect);
}


static function X2AbilityTemplate TacticalSense()
{
	local XMBEffect_ConditionalBonus Effect;
	local XMBValue_Visibility Value;
	 
	// Create a value that will count the number of visible units
	Value = new class'XMBValue_Visibility';
	Value.bCountEnemies = true;

	// Create a conditional bonus effect
	Effect = new class'XMBEffect_ConditionalBonus';

	// The effect adds +10 Dodge per enemy unit
	Effect.AddToHitAsTargetModifier(3, eHit_Success);

	// The effect scales with the number of visible enemy units, to a maximum of 5 (for +15 Defense).
	Effect.ScaleValue = Value;
	Effect.ScaleMax = 5;

	// Create the template using a helper function
	return Passive('RpgTacticalSense', "img:///UILibrary_RPG.LW_AbilityTacticalSense", true, Effect);
}


static function X2AbilityTemplate AddCutthroatAbility()
{
	local X2AbilityTemplate					Template;
	local X2Effect_Cutthroat				ArmorPiercingBonus;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RpgCutthroat');
	Template.IconImage = "img:///UILibrary_RPG.LW_AbilityCutthroat";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;
	Template.bCrossClassEligible = false;
	ArmorPiercingBonus = new class 'X2Effect_Cutthroat';
	ArmorPiercingBonus.BuildPersistentEffect (1, true, false);
	ArmorPiercingBonus.Bonus_Crit_Chance = default.CUTTHROAT_BONUS_CRIT_CHANCE;
	ArmorPiercingBonus.Bonus_Crit_Damage = default.CUTTHROAT_BONUS_CRIT_DAMAGE;
	ArmorPiercingBonus.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (ArmorPiercingBonus);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;	
	//no visualization
	return Template;		
}

static function X2AbilityTemplate AddLightEmUpAbility()
{
	local X2AbilityTemplate				Template;

	Template = PurePassive('LightEmUp', "img:///UILibrary_RPG.LW_AbilityLightEmUp");

	return Template;
}


//static function X2AbilityTemplate AddLightEmUpAbility()
//{
//	local X2AbilityTemplate					Template;
//	local X2Condition_WeaponCategory		WeaponCondition;
//
//	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('LightEmUp');
//	Template.IconImage = "img:///UILibrary_RPG.LW_AbilityLightEmUp";
//	X2AbilityCost_ActionPoints(Template.AbilityCosts[0]).bConsumeAllPoints = false;
//
//	WeaponCondition = new class'X2Condition_WeaponCategory';
//	WeaponCondition.ExcludeWeaponCategories.AddItem('sniper_rifle');
//	Template.AbilityTargetConditions.AddItem(WeaponCondition);
//
//	Template.OverrideAbilities.AddItem('StandardShot');
//
//	return Template;	
//}

static function X2AbilityTemplate AddLockdownAbility()
{
	local X2AbilityTemplate                 Template;	

	Template = PurePassive('Lockdown', "img:///UILibrary_RPG.LW_AbilityLockdown", false, 'eAbilitySource_Perk');
	Template.bCrossClassEligible = false;

	return Template;
}

static function X2AbilityTemplate LockdownBonuses()
{
	local X2Effect_LockdownDamage			DamageEffect;
	local X2AbilityTemplate                 Template;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LockdownBonuses');
	Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITooltip = false;
	Template.bIsASuppressionEffect = true;
	//  Effect code checks whether unit has Lockdown before providing aim and damage bonuses
	DamageEffect = new class'X2Effect_LockdownDamage';
	DamageEffect.BuildPersistentEffect(1,true,false,false,eGameRule_PlayerTurnBegin);
	Template.AddTargetEffect(DamageEffect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

static function X2AbilityTemplate AddRescueProtocol()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCost_Charges				ChargeCost;
	local X2AbilityCharges_RescueProtocol	Charges;
	local X2Condition_UnitEffects			CommandRestriction;
	local X2Effect_GrantActionPoints		ActionPointEffect;
	local X2Effect_Persistent				ActionPointPersistEffect;
	local X2Condition_UnitProperty			UnitPropertyCondition;
	local X2Condition_UnitActionPoints		ValidTargetCondition;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'RescueProtocol');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_defensiveprotocol";
	Template.Hostility = eHostility_Neutral;
	Template.bLimitTargetIcons = true;
	Template.DisplayTargetHitChance = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.bStationaryWeapon = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.bSkipPerkActivationActions = true;
	Template.bCrossClassEligible = false;

	Charges = new class 'X2AbilityCharges_RescueProtocol';
	Charges.CV_Charges = default.RESCUE_CV_CHARGES;
	Charges.MG_Charges = default.RESCUE_MG_CHARGES;
	Charges.BM_Charges = default.RESCUE_BM_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint,true,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,'Suppression',true,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2Ability_SharpshooterAbilitySet'.default.KillZoneReserveType,true,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint,true,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.StandardActionPoint,false,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint,true,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.RunAndGunActionPoint,false,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	ValidTargetCondition = new class'X2Condition_UnitActionPoints';
	ValidTargetCondition.AddActionPointCheck(0,class'X2CharacterTemplateManager'.default.MoveActionPoint,false,eCheck_LessThanOrEqual);
	Template.AbilityTargetConditions.AddItem(ValidTargetCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
    UnitPropertyCondition.ExcludeDead = true;
    UnitPropertyCondition.ExcludeFriendlyToSource = false;
    UnitPropertyCondition.ExcludeUnrevealedAI = true;
	UnitPropertyCondition.ExcludeConcealed = true;
	UnitPropertyCondition.TreatMindControlledSquadmateAsHostile = true;
	UnitPropertyCondition.ExcludeAlive = false;
    UnitPropertyCondition.ExcludeHostileToSource = true;
    UnitPropertyCondition.RequireSquadmates = true;
    UnitPropertyCondition.ExcludePanicked = true;
	UnitPropertyCondition.ExcludeRobotic = false;
	UnitPropertyCondition.ExcludeStunned = true;
	UnitPropertyCondition.ExcludeNoCover = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.ExcludeCivilian = false;
	UnitPropertyCondition.ExcludeTurret = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	CommandRestriction = new class'X2Condition_UnitEffects';
	CommandRestriction.AddExcludeEffect('Command', 'AA_UnitIsCommanded');
	CommandRestriction.AddExcludeEffect('Rescued', 'AA_UnitIsCommanded');
	CommandRestriction.AddExcludeEffect('HunkerDown', 'AA_UnitIsCommanded');
    CommandRestriction.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_UnitIsImpaired');
	Template.AbilityTargetConditions.AddItem(CommandRestriction);

	ActionPointEffect = new class'X2Effect_GrantActionPoints';
    ActionPointEffect.NumActionPoints = 1;
    ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;
    Template.AddTargetEffect(ActionPointEffect);

	ActionPointPersistEffect = new class'X2Effect_Persistent';
    ActionPointPersistEffect.EffectName = 'Rescued';
    ActionPointPersistEffect.BuildPersistentEffect(1, false, true, false, 8);
    ActionPointPersistEffect.bRemoveWhenTargetDies = true;
    Template.AddTargetEffect(ActionPointPersistEffect);

	//Template.bSkipFireAction = true;

	Template.bShowActivation = true;

	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.CustomSelfFireAnim = 'NO_CombatProtocol';
	Template.ActivationSpeech = 'DefensiveProtocol';
	Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_SpecialistAbilitySet'.static.GremlinSingleTarget_BuildVisualization;

	return Template;
}


static function X2AbilityTemplate AddRapidTargeting()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_LWHoloTarget				Effect;
	local X2AbilityCooldown                 Cooldown;
	local X2Condition_Visibility			TargetVisibilityCondition;
	local X2Condition_UnitEffects			SuppressedCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Rapidtargeting');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_RPG.LW_AbilityRapidTargeting";
	Template.bHideOnClassUnlock = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	//Template.AbilityConfirmSound = "TacticalUI_SwordConfirm";

	Template.bDisplayInUITooltip = true;
    Template.bDisplayInUITacticalText = true;
    Template.DisplayTargetHitChance = true;
	Template.bShowActivation = false;
	Template.bSkipFireAction = false;
	Template.ConcealmentRule = eConceal_Always;

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.RAPID_TARGETING_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Targeting Details
	// Can only shoot visible enemies
	TargetVisibilityCondition = new class'X2Condition_Visibility';
    TargetVisibilityCondition.bRequireGameplayVisible = true;
    TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);


	// Can't target dead; Can't target friendlies, can't target inanimate objects
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	// Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	// Only at single targets that are in range.
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	
	Template.AddShooterEffectExclusions();

	// Holotarget Effect
	Effect = new class'X2Effect_LWHoloTarget';
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, class'X2Effect_LWHolotarget'.default.HoloTargetEffectName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Effect.bRemoveWhenTargetDies = true;
	Effect.bUseSourcePlayerState = true;
	Effect.bApplyOnHit = true;
	Effect.bApplyOnMiss = true;
	Template.AddTargetEffect(Effect);

	Template.AdditionalAbilities.AddItem('RapidTargeting_Passive');

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate AddMultiTargeting()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityMultiTarget_Radius		RadiusMultiTarget;
	local X2Effect_LWHoloTarget				Effect;
	local X2Condition_Visibility			TargetVisibilityCondition;
	local X2AbilityCooldown                 Cooldown;
	local X2Condition_UnitEffects			SuppressedCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Multitargeting');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_RPG.LW_AbilityMultiTargeting";
	Template.bHideOnClassUnlock = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	//Template.AbilityConfirmSound = "TacticalUI_SwordConfirm";
	Template.Hostility = eHostility_Neutral;

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.MULTI_TARGETING_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.bDisplayInUITooltip = true;
    Template.bDisplayInUITacticalText = true;
    Template.DisplayTargetHitChance = true;
	Template.bShowActivation = false;
	Template.bSkipFireAction = false;
	Template.ConcealmentRule = eConceal_Always;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	// Can only shoot visible enemies
	TargetVisibilityCondition = new class'X2Condition_Visibility';
    TargetVisibilityCondition.bRequireGameplayVisible = true;
    TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Can't target dead; Can't target friendlies, can't target inanimate objects
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	// Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	// Only at single targets that are in range.
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AddShooterEffectExclusions();

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	//RadiusMultiTarget.NumTargetsRequired = 1; 
	RadiusMultiTarget.bIgnoreBlockingCover = true; 
	RadiusMultiTarget.bAllowDeadMultiTargetUnits = false; 
	RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	RadiusMultiTarget.bUseWeaponRadius = true; 
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Holotarget Effect
	Effect = new class'X2Effect_LWHoloTarget';
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, class'X2Effect_LWHolotarget'.default.HoloTargetEffectName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Effect.bRemoveWhenTargetDies = true;
	Effect.bUseSourcePlayerState = true;
	Effect.bApplyOnHit = true;
	Effect.bApplyOnMiss = true;
	Template.AddTargetEffect(Effect);
	Template.AddMultiTargetEffect(Effect);

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	//Template.OverrideAbilities.AddItem('Holotarget'); // add the multi-targeting as a separate ability, so as not to render RapidTargeting useless

	return Template;
}
