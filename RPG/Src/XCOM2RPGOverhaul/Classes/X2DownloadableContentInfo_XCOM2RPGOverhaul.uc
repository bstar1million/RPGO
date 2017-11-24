class X2DownloadableContentInfo_XCOM2RPGOverhaul extends X2DownloadableContentInfo config (RPG);

struct AbilityWeaponCategoryRestriction
{
	var name AbilityName;
	var array<name> WeaponCategories;
};

var config array<AbilityWeaponCategoryRestriction> AbilityWeaponCategoryRestrictions;

var config int ShotgunAimBonus;
var config int ShotgunCritBonus;
var config int CannonDamageBonus;

// -----------------------------------------------
// --------------- DLCINFO Hooks -----------------
// -----------------------------------------------

// Double tactical ability points
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(StartState);

	XComHQ.BonusAbilityPointScalar *= 2.0;
}

static event OnLoadedSavedGameToStrategy()
{
	UpdateStorage();
}


static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local X2Condition_WeaponCategory WeaponCondition;
	local int Index, CategoryIndex;
	local name WeaponCategory;
	local EInventorySlot InvSlot;
	local array<XComGameState_Item> CurrentInventory;
	local XComGameState_Item InventoryItem;

	if (!UnitState.IsSoldier())
		return;

	`LOG(GetFuncName() @ UnitState.GetFullName(),, 'RPG');

	CurrentInventory = UnitState.GetAllInventoryItems(StartState);

	for(Index = 0; Index < SetupData.Length; Index++)
	{
		// Deactivate all ranged abilities
		if (IsPrimaryMelee(UnitState) && SetupData[Index].Template.DefaultSourceItemSlot == eInvSlot_PrimaryWeapon)
		{
			WeaponCondition = new class'X2Condition_WeaponCategory';
			WeaponCondition.ExcludeWeaponCategories.AddItem('sword');
			SetupData[Index].Template.AbilityTargetConditions.AddItem(WeaponCondition);
		}

		//`LOG(GetFuncName() @ UnitState.GetFullName() @ SetupData[Index].TemplateName @ SetupData[Index].Template.DefaultSourceItemSlot,, 'RPG');

		//if (SetupData[Index].Template.DefaultSourceItemSlot != eInvSlot_Unknown)
		//{
			CategoryIndex = default.AbilityWeaponCategoryRestrictions.Find('AbilityName', SetupData[Index].TemplateName);
			//`LOG(GetFuncName() @ SetupData[Index].TemplateName @ SetupData[Index].Template.DefaultSourceItemSlot @ Index,, 'RPG');
			if (CategoryIndex != INDEX_NONE)
			{
				foreach default.AbilityWeaponCategoryRestrictions[CategoryIndex].WeaponCategories(WeaponCategory)
				{
					InvSlot = FindInventorySlotForItemCategory(UnitState, WeaponCategory, InventoryItem, StartState);
					if (InvSlot != eInvSlot_Unknown)
					{
						//SetupData[Index].Template.DefaultSourceItemSlot = InvSlot;
						SetupData[Index].SourceWeaponRef = InventoryItem.GetReference();
						`LOG(GetFuncName() @ "Patching" @ SetupData[Index].TemplateName @ "setting DefaultSourceItemSlot to" @ InvSlot @ SetupData[Index].SourceWeaponRef.ObjectID,, 'RPG');
					}
				}
			}
		//}

		// Do this here again because the launch grenade ability is now on the grenade lanucher itself and not in earned soldier abilities
		if (SetupData[Index].Template.bUseLaunchedGrenadeEffects)
		{
			//  populate a version of the ability for every grenade in the inventory
			foreach CurrentInventory(InventoryItem)
			{
				if (InventoryItem.bMergedOut) 
					continue;

				if (X2GrenadeTemplate(InventoryItem.GetMyTemplate()) != none)
				{ 
					SetupData[Index].SourceAmmoRef = InventoryItem.GetReference();
				}
			}
		}
	}
}

static event OnPostTemplatesCreated()
{
	`LOG(GetFuncName(),, 'RPG');
	PatchAbilitiesWeaponCondition();
	PatchWeapons();
	PatchHolotargeting();
	PatchSquadSight();
	PatchSniperStandardFire();
	PatchStandardShot();
	PatchRemoteStart();
	PatchLongWatch();
	PatchSuppression();
	PatchSkirmisherGrapple();
	PatchThrowClaymore();
	PatchSwordSlice();
	PatchBladestormAttack();
	PatchCombatProtocol();
	PatchMedicalProtocol();
}

// -----------------------------------------------
// -------------- Helper functions ---------------
// -----------------------------------------------
static function XComGameState_HeadquartersXCom GetNewXComHQState(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom NewXComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', NewXComHQ)
	{
		break;
	}

	if(NewXComHQ == none)
	{
		NewXComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', NewXComHQ.ObjectID));
	}

	return NewXComHQ;
}

static function bool IsPrimaryMelee(XComGameState_Unit UnitState)
{
	// @TODO externalize in config
	return (X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate()).WeaponCat == 'sword');
}

static function EInventorySlot FindInventorySlotForItemCategory(XComGameState_Unit UnitState, name WeaponCategory, out XComGameState_Item FoundItemState, optional XComGameState StartState)
{
	local array<XComGameState_Item> CurrentInventory;
	local XComGameState_Item InventoryItem;
	local X2WeaponTemplate WeaponTemplate;

	CurrentInventory = UnitState.GetAllInventoryItems(StartState);
	foreach CurrentInventory(InventoryItem)
	{
		WeaponTemplate = X2WeaponTemplate(InventoryItem.GetMyTemplate());
		if (WeaponTemplate != none && WeaponTemplate.WeaponCat == WeaponCategory)
		{
			FoundItemState = InventoryItem;
			return InventoryItem.InventorySlot;
		}
	}
	return eInvSlot_Unknown;
}

static function PatchAbilitiesWeaponCondition()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;
	local X2Condition_WeaponCategory	WeaponCondition;
	local AbilityWeaponCategoryRestriction Restriction;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach default.AbilityWeaponCategoryRestrictions(Restriction)
	{
		Template = TemplateManager.FindAbilityTemplate(Restriction.AbilityName);
		if (Template != none)
		{
			WeaponCondition = new class'X2Condition_WeaponCategory';
			WeaponCondition.IncludeWeaponCategories = Restriction.WeaponCategories;
			Template.AbilityTargetConditions.AddItem(WeaponCondition);
		}
	}
}

static function PatchWeapons()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<name> TemplateNames;
	local array<X2DataTemplate> DifficultyVariants;
	local name TemplateName;
	local X2DataTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.GetTemplateNames(TemplateNames);

	foreach TemplateNames(TemplateName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);
		// Iterate over all variants
		
		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);
			if (WeaponTemplate != none)
			{
				switch (WeaponTemplate.WeaponCat)
				{
					case 'rifle':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'FullAutoFire');
						if (InStr(string(WeaponTemplate.DataName), "CV") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireConvA');
						if (InStr(string(WeaponTemplate.DataName), "MG") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireMagA');
						if (InStr(string(WeaponTemplate.DataName), "BM") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireBeamA');

						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'bullpup':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'FullAutoFire');
						AddAbilityToWeaponTemplate(WeaponTemplate, 'SkirmisherStrike');
						WeaponTemplate.iClipSize += 1;
						if (InStr(string(WeaponTemplate.DataName), "CV") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireConvA');
						if (InStr(string(WeaponTemplate.DataName), "MG") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireMagA');
						if (InStr(string(WeaponTemplate.DataName), "BM") != INDEX_NONE)
							WeaponTemplate.SetAnimationNameForAbility('FullAutoFire', 'FF_AutoFireBeamA');

						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'sniper_rifle':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'Squadsight');

						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'vektor_rifle':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'SilentKillPassive');

						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'shotgun':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'ShotgunDamageModifierCoverType');
						AddAbilityToWeaponTemplate(WeaponTemplate, 'ShotgunDamageModifierRange');
						
						WeaponTemplate.CritChance += default.ShotgunCritBonus;
						WeaponTemplate.Aim += default.ShotgunAimBonus;
						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'cannon':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'FullAutoFire');
						AddAbilityToWeaponTemplate(WeaponTemplate, 'Suppression');
						AddAbilityToWeaponTemplate(WeaponTemplate, 'HeavyWeaponMobilityPenalty');
						//AddAbilityToWeaponTemplate(WeaponTemplate, 'AutoFireShot');
						//AddAbilityToWeaponTemplate(WeaponTemplate, 'AutoFireOverwatch');
						
						WeaponTemplate.BaseDamage.Damage += default.CannonDamageBonus;
						WeaponTemplate.iClipSize += 2;
						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'pistol':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'PistolStandardShot');
						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'sword':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'SwordSlice');
						WeaponTemplate.NumUpgradeSlots = 3;
						break;
					case 'gremlin':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'IntrusionProtocol');
						break;
					case 'grenade_launcher':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'LaunchGrenade');
						break;
					case 'wristblade':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'SkirmisherGrapple');
						break;
					case 'claymore':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'ThrowClaymore');
						break;
					case 'gremlin':
						AddAbilityToWeaponTemplate(WeaponTemplate, 'AidProtocol');
						break;
				}
			}

			// Patch enviromental damage
			if (InStr(WeaponTemplate.DataName, "CV") != INDEX_NONE || InStr(WeaponTemplate.DataName, "T1") != INDEX_NONE)
			{
				//WeaponTemplate.BaseDamage
			}

			// Patch hero weapons
			if (WeaponTemplate.DataName == 'WristBlade_CV' ||
				WeaponTemplate.DataName == 'ShardGauntlet_CV' ||
				WeaponTemplate.DataName == 'VektorRifle_CV' ||
				WeaponTemplate.DataName == 'Bullpup_CV' ||
				WeaponTemplate.DataName == 'Reaper_Claymore' ||
				WeaponTemplate.DataName == 'Sidearm_CV')
			{
				WeaponTemplate.StartingItem = true;
				`LOG("Unlock" @ WeaponTemplate.DataName,, 'RPG');
			}
		}
	}
}

static function UpdateStorage()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateMgr;
	local array<X2ItemTemplate> ItemTemplates;
	local XComGameState_Item NewItemState;
	local int i;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Musashi: Updating HQ Storage to add Axes");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('WristBlade_CV'));
	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('ShardGauntlet_CV'));
	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('VektorRifle_CV'));
	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('Bullpup_CV'));
	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('Reaper_Claymore'));
	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('Sidearm_CV'));

	for (i = 0; i < ItemTemplates.Length; ++i)
	{
		if(ItemTemplates[i] != none)
		{
			if (!XComHQ.HasItem(ItemTemplates[i]))
			{
				`Log(ItemTemplates[i].GetItemFriendlyName() @ " not found, adding to inventory",, 'RPG');
				NewItemState = ItemTemplates[i].CreateInstanceFromTemplate(NewGameState);
				NewGameState.AddStateObject(NewItemState);
				XComHQ.AddItemToHQInventory(NewItemState);
				History.AddGameStateToHistory(NewGameState);
			} else {
				`Log(ItemTemplates[i].GetItemFriendlyName() @ " found, skipping inventory add",, 'RPG');
				History.CleanupPendingGameState(NewGameState);
			}
		}
	}
}

static function AddAbilityToWeaponTemplate(out X2WeaponTemplate Template, name Ability)
{
	if (Template.Abilities.Find(Ability) == INDEX_NONE)
	{
		//`LOG(GetFuncName() @ Template.DataName @ Ability,, 'RPG');
		Template.Abilities.AddItem(Ability);
	}
}

static function PatchMedicalProtocol()
{
	local X2AbilityTemplateManager				TemplateManager;
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPointsExtended	ActionPointCost;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	ActionPointCost = new class'X2AbilityCost_ActionPointsExtended';
	ActionPointCost.iNumPoints = 1;	
	ActionPointCost.FreeCostAbilities.AddItem('EmergencyProtocol');

	Template = TemplateManager.FindAbilityTemplate('GremlinHeal');
	Template.AbilityCosts[0] = ActionPointCost;

	Template = TemplateManager.FindAbilityTemplate('GremlinStabilize');
	Template.AbilityCosts[0] = ActionPointCost;
}


static function PatchHolotargeting()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;
	local X2Effect_TargetDefinition		Effect;
	local XMBCondition_SourceAbilities	RequiredAbilitiesCondition;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	RequiredAbilitiesCondition = new class'XMBCondition_SourceAbilities';
	RequiredAbilitiesCondition.AddRequireAbility('PermanentTracking', 'AA_AbilityRequired');

	Effect = new class'X2Effect_TargetDefinition';
	Effect.BuildPersistentEffect(1, true, false, false);
	//Effect.TargetConditions.AddItem(class'X2Ability'.default.LivingHostileUnitDisallowMindControlProperty);
	Effect.TargetConditions.AddItem(RequiredAbilitiesCondition);
	Template.AddTargetEffect(Effect);

	Template = TemplateManager.FindAbilityTemplate('Holotarget');
	Template.AddTargetEffect(Effect);

	Template = TemplateManager.FindAbilityTemplate('Rapidtargeting');
	Template.AddTargetEffect(Effect);

	Template = TemplateManager.FindAbilityTemplate('Multitargeting');
	Template.AddTargetEffect(Effect);
	Template.AddMultiTargetEffect(Effect);
	
	Template = TemplateManager.FindAbilityTemplate('BattleScanner');
	Template.AddMultiTargetEffect(Effect);
}

static function PatchSwordSlice()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('SwordSlice');
	Template.AdditionalAbilities.AddItem('BlueMoveSlash');
	Template.bUniqueSource = true;
}

static function PatchBladestormAttack()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('BladestormAttack');
	X2AbilityToHitCalc_StandardMelee(Template.AbilityToHitCalc).bReactionFire = false;

	Template = TemplateManager.FindAbilityTemplate('RetributionAttack');
	X2AbilityToHitCalc_StandardMelee(Template.AbilityToHitCalc).bReactionFire = false;
}

static function PatchThrowClaymore()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('ThrowClaymore');
	Template.bUniqueSource = true;
}


static function PatchSkirmisherGrapple()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('SkirmisherGrapple');
	Template.bUniqueSource = true;
}


static function PatchKillZone()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('KillZone');
	Template.IconImage = "img:///UILibrary_RPG.UIPerk_killzone";
}


static function PatchStandardShot()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('StandardShot');
	X2AbilityCost_ActionPoints(Template.AbilityCosts[0]).DoNotConsumeAllSoldierAbilities.AddItem('LightEmUp');
}

static function PatchRemoteStart()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('RemoteStart');
	X2AbilityCost_ActionPoints(Template.AbilityCosts[0]).DoNotConsumeAllSoldierAbilities.AddItem('AsymmetricWarfare');
}

static function PatchSniperStandardFire()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('SniperStandardFire');
	X2AbilityCost_ActionPoints(Template.AbilityCosts[0]).bAddWeaponTypicalCost = false;
}

static function PatchLongWatch()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('LongWatch');
	X2AbilityCost_ActionPoints(Template.AbilityCosts[0]).bAddWeaponTypicalCost = false;
}


static function PatchSuppression()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('Suppression');
	Template.AdditionalAbilities.AddItem('LockdownBonuses');
}

static function PatchCombatProtocol()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('CombatProtocol');
	Template.AdditionalAbilities.AddItem('CombatProtocolHackingBonus');
}


static function PatchSquadSight()
{
	local X2AbilityTemplateManager		TemplateManager;
	local X2AbilityTemplate				Template;
	local X2Effect_Squadsight			Squadsight;
	local X2Condition_UnitActionPoints	ActionPointCondition;
	local X2AbilityTrigger_EventListener EventTrigger;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = TemplateManager.FindAbilityTemplate('Squadsight');

	Template.AbilityTriggers.Length = 0;
	Template.AbilityTargetEffects.Length = 0;
	Template.Hostility = eHostility_Neutral;

	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventTrigger.ListenerData.EventID = 'PlayerTurnBegun';
	EventTrigger.ListenerData.Filter = eFilter_Player;
	EventTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventTrigger);

	ActionPointCondition = new class'X2Condition_UnitActionPoints';
	ActionPointCondition.AddActionPointCheck(0, class'X2CharacterTemplateManager'.default.StandardActionPoint, false, eCheck_GreaterThanOrEqual, 2, 0);

	Squadsight = new class'X2Effect_Squadsight';
	Squadsight.BuildPersistentEffect(1, false, true, true, eGameRule_PlayerTurnBegin);
	Squadsight.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Squadsight.TargetConditions.AddItem(ActionPointCondition);
	Template.AddTargetEffect(Squadsight);

	Template.AdditionalAbilities.AddItem('RemoveSquadSightOnMove');
}

/// <summary>
/// Called from XComGameState_Unit:CanAddItemToInventory & UIArmory_Loadout:GetDisabledReason
/// defaults to using the wrapper function below for calls from XCGS_U. Return false with a non-empty string in this function to show the disabled reason in UIArmory_Loadout
/// Note: due to how UIArmory_Loadout does its check, expect only Slot, ItemTemplate, and UnitState to be filled when trying to fill out a disabled reason. Hence the check for CheckGameState == none
/// </summary>
//static function bool CanAddItemToInventory_CH(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason)
//{
//	local X2WeaponTemplate WeaponTemplate;
//	local bool bEvaluate;
//	local array<name> ItemCategories;
//	local name Category;
//
//	If (UnitState.GetSoldierClassTemplateName() != 'UniversalSoldier')
//	{
//		return false;
//	}
//	
//	ItemCategories.AddItem('sniper_rifle');
//	ItemCategories.AddItem('shotgun');
//	ItemCategories.AddItem('cannon');
//	ItemCategories.AddItem('gremlin');
//	ItemCategories.AddItem('grenade_launcher');
//	ItemCategories.AddItem('sword');
//
//	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
//
//	foreach ItemCategories(Category)
//	{
//		if (MissesWeaponProficency(UnitState, WeaponTemplate, Category))
//		{
//			bCanAddItem = 0;
//			// @TODO get localization from ability
//			DisabledReason = "Soldier needs" @ ConvertToCamelCase(String(Category));
//			bEvaluate = true;
//			break;
//		}
//	}
//
//	if (bEvaluate)
//		`LOG(GetFuncName() @ DisabledReason @ bEvaluate,, 'RPG');
//
//	if(CheckGameState == none)
//		return !bEvaluate;
//
//	return bEvaluate;
//}

private static function bool MissesWeaponProficency(XComGameState_Unit UnitState, X2WeaponTemplate WeaponTemplate, name WeaponCategory)
{

	return (WeaponTemplate != none && WeaponTemplate.WeaponCat == WeaponCategory && !UnitState.HasSoldierAbility(GetProficiencyAbilityName(WeaponCategory)));
}

private static function name GetProficiencyAbilityName(name ItemCategory)
{
	return name(ConvertToCamelCase(string(ItemCategory)) $ "Proficiency");
}

private static function string ConvertToCamelCase(string StringToConvert)
{
	local array<string> Pieces;
	local string Token, Result;
	
	Pieces = SplitString(StringToConvert, "_");

	foreach Pieces(Token)
	{
		Result $= Caps(Left(Token, 1)) $ Caps(Right(Token, Len(Token) - 1));
	}

	return Result;
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local X2WeaponTemplate PrimaryWeaponTemplate, SecondaryWeaponTemplate;
	local AnimSet AnimSetIter;
	local int i;

	if (!UnitState.IsSoldier() || UnitState.GetSoldierClassTemplateName() == 'Templar')
	{
		return;
	}

	SecondaryWeaponTemplate = X2WeaponTemplate( UnitState.GetSecondaryWeapon().GetMyTemplate());
	PrimaryWeaponTemplate = X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate());

	`LOG(GetFuncName() @ UnitState.GetFullName() @ SecondaryWeaponTemplate.DataName @ PrimaryWeaponTemplate.DataName @ string(XComWeapon(Pawn.Weapon).ObjectArchetype),, 'RPG');

	if (SecondaryWeaponTemplate.WeaponCat == 'sidearm' &&
		InStr(string(XComWeapon(Pawn.Weapon).ObjectArchetype), "WP_TemplarAutoPistol") != INDEX_NONE)
	{
		for (i = 0; i < Pawn.Mesh.AnimSets.Length; i++)
		{
			if (string(Pawn.Mesh.AnimSets[i]) == "AS_TemplarAutoPistol")
			{
				`LOG(GetFuncName() @ UnitState.GetFullName() @ "Removing" @ Pawn.Mesh.AnimSets[i],, 'RPG');
				Pawn.Mesh.AnimSets.Remove(i, 1);
				break;
			}
		}
		AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("AutoPistol_ANIM.Anims.AS_AutoPistol")));

		Pawn.Mesh.UpdateAnimations();
	}

	if (InStr(string(XComWeapon(Pawn.Weapon).ObjectArchetype), "WP_SkirmisherGauntlet") != INDEX_NONE)
	{
		AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("skirmisher.Anims.AS_Skirmisher")));
	}

	if (PrimaryWeaponTemplate.WeaponCat == 'rifle' || PrimaryWeaponTemplate.WeaponCat == 'bullpup')
	{
		AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("AutoFire_ANIM.Anims.AS_AssaultRifleAutoFire")));
		Pawn.Mesh.UpdateAnimations();
	}

	
	foreach Pawn.Mesh.AnimSets(AnimSetIter)
	{
		`LOG(GetFuncName() @ UnitState.GetFullName() @ "current animsets: " @ AnimSetIter,, 'RPG');
	}
	`LOG(GetFuncName() @ UnitState.GetFullName() @ "------------------",, 'RPG');
}

static function AddAnimSet(XComUnitPawn Pawn, AnimSet AnimSetToAdd)
{
	if (Pawn.Mesh.AnimSets.Find(AnimSetToAdd) == INDEX_NONE)
	{
		Pawn.Mesh.AnimSets.AddItem(AnimSetToAdd);
		`LOG(GetFuncName() @ "adding" @ AnimSetToAdd,, 'RPG');
	}
}
