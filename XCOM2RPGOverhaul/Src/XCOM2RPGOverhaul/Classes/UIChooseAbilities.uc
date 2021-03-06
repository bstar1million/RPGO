class UIChooseAbilities extends UIChooseCommodity;

var array<X2AbilityTemplate> AbilitiesPool;
var array<X2AbilityTemplate> AbilitiesChosen;

simulated function InitChooseAbiltites(
	StateObjectReference UnitRef,
	int MaxAbilities,
	array<X2AbilityTemplate> AvailableAbilities,
	optional array<X2AbilityTemplate> OwnedAbiltites,
	optional delegate<AcceptAbilities> OnAccept
)
{
	super.InitChooseCommoditiesScreen(
		UnitRef,
		MaxAbilities,
		ConvertToCommodities(OwnedAbiltites),
		OnAccept
	);

	AbilitiesChosen = OwnedAbiltites;
	CommoditiesChosen = ConvertToCommodities(AbilitiesChosen);
	
	AbilitiesPool.Length = 0;
	AbilitiesPool = AvailableAbilities;
	AbilitiesPool.Sort(SortAbiltiesByName);
	CommodityPool = ConvertToCommodities(AbilitiesPool);

	PopulateData();
}




simulated function OnContinueButtonClick()
{
	local UIArmory_PromotionHero HeroScreen;
	
	if (AbilitiesChosen.Length - OwnedItems.Length == MaxChooseItem)
	{
		OnAllAbiltiesSelected();
		
		Movie.Stack.Pop(self);
		HeroScreen = UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory_PromotionHero'));
		if (HeroScreen != none)
		{
			HeroScreen.CycleToSoldier(UnitReference);
		}
	}
	else
	{
		PlayNegativeSound();
	}
}

function bool OnAllAbiltiesSelected()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate Ability;
	
	UnitState = GetUnit();

	foreach AbilitiesChosen(Ability)
	{
		`log(default.class @ GetFuncName() @
			"Add Ability for" @ UnitState.SummaryString() @ 
			Ability.LocFriendlyName
		,, 'RPG');
	}

	NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding chosen starting abilities to unit");
	
	class'X2SecondWaveConfigOptions'.static.AddStartingAbilities(NewGameState, UnitState, AbilitiesChosen);
	
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.SetUnitFloatValue('SecondWaveCommandersChoiceAbilityChosen', 1, eCleanup_Never);

	class'X2SoldierClassTemplatePlugin'.static.AssignSpecializations(UnitState, NewGameState);
	
	`GAMERULES.SubmitGameState(NewGameState);
	
	if (AcceptAbilities != none)
	{
		AcceptAbilities(self);
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Recruit_Soldier");
	
	return true;
}

simulated function array<Commodity> ConvertToCommodities(array<X2AbilityTemplate> Abilities)
{
	local X2AbilityTemplate AbilityTemplate;
	local array<Commodity> Commodities;
	local Commodity Comm;

	foreach Abilities(AbilityTemplate)
	{
		Comm.Title = AbilityTemplate.LocFriendlyName;
		Comm.Desc = AbilityTemplate.GetMyLongDescription();
		Comm.Image = AbilityTemplate.IconImage;
		Comm.OrderHours = -1;
		
		Commodities.AddItem(Comm);
	}

	return Commodities;
}

function int SortAbiltiesByName(X2AbilityTemplate a, X2AbilityTemplate b)
{	
	if (a.LocFriendlyName < b.LocFriendlyName)
		return 1;
	else if (a.LocFriendlyName > b.LocFriendlyName)
		return -1;
	else
		return 0;
}

simulated function AddToChosenList(int Index)
{
	AbilitiesChosen.AddItem(AbilitiesPool[Index]);
	CommoditiesChosen = ConvertToCommodities(AbilitiesChosen);
}

simulated function RemoveFromChosenList(int ChosenIndex, int PoolIndex)
{
	AbilitiesChosen.RemoveItem(AbilitiesChosen[ChosenIndex]);
	CommoditiesChosen = ConvertToCommodities(AbilitiesChosen);
}

defaultproperties
{
	ListItemClass = class'UIInventory_AbilityListItem'
	ConfirmButtonOffset = 90
}