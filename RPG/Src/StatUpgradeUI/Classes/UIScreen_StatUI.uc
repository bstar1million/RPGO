class UIScreen_StatUI extends UIArmory config(UI);

var UIPanel Container;
var UIBGBox PanelBG;
var UIBGBox FullBG;
var UIX2PanelHeader TitleHeader;
var UIImage SCImage;
var UIButton SaveButton;
var UIText AbilityPointsText;
var array<UIPanel_StatUI_StatLine> StatLines;
var bool bLog;

var XComGameState_Unit UnitState;
var int AbilityPointCostSum, FontSize;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	local int RunningHeaderOffsetX;

	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	Container = Spawn(class'UIPanel', self).InitPanel('theContainer');
	Container.Width = Width;
	Container.Height = Height;
	Container.SetPosition((Movie.UI_RES_X - Container.Width) / 2, (Movie.UI_RES_Y- Container.Height) / 2);
	
	FullBG = Spawn(class'UIBGBox', Container);
	FullBG.InitBG('', 0, 0, Container.Width, Container.Height);

	PanelBG = Spawn(class'UIBGBox', Container);
	PanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	PanelBG.InitBG('theBG', 0, 0, Container.Width, Container.Height);

	RunningHeaderOffsetX = 40;

	SCImage = Spawn(class'UIImage', Container).InitImage();
	SCImage.SetSize(80, 80);
	SCImage.SetPosition(RunningHeaderOffsetX, RunningHeaderOffsetX);

	TitleHeader = Spawn(class'UIX2PanelHeader', Container);
	TitleHeader.InitPanelHeader('', "", "");
	TitleHeader.SetPosition(SCImage.Width + RunningHeaderOffsetX + 10, 40);
	TitleHeader.SetWidth(Container.Width - TitleHeader.X - RunningHeaderOffsetX);
	TitleHeader.SetHeaderWidth(Container.Width - TitleHeader.X - RunningHeaderOffsetX);

	AbilityPointsText = Spawn(class'UIText', Container).InitText('AbilityPointsText');
	AbilityPointsText.SetPosition(RunningHeaderOffsetX, 130);

	SaveButton = Spawn(class'UIButton', Container).InitButton('SaveButton', "SAVE", Save);
	SaveButton.SetFontSize(FontSize);
	SaveButton.SetResizeToText(true);
	SaveButton.SetWidth(150);
	SaveButton.SetPosition(Width / 2 - SaveButton.Width / 2, Height - SaveButton.Height - 30);

	InitStatLines();

	PopulateHeaderData();
	PopulateSoldierAP();

	`LOG(self.class.name @ GetFuncName() @ UnitState.GetFullName(), bLog, 'RPG');
}

function InitStatLines()
{
	local UIPanel_StatUI_StatLine StatLine;
	local int Index, OffsetX, OffsetY;

	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_HP, int(UnitState.GetMaxStat(eStat_HP)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Mobility, int(UnitState.GetMaxStat(eStat_Mobility)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Offense, int(UnitState.GetMaxStat(eStat_Offense)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Will, int(UnitState.GetMaxStat(eStat_Will)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_ArmorMitigation, int(UnitState.GetMaxStat(eStat_ArmorMitigation)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Dodge, int(UnitState.GetMaxStat(eStat_Dodge)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Defense, int(UnitState.GetMaxStat(eStat_Defense)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_Hacking, int(UnitState.GetMaxStat(eStat_Hacking)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);
	
	StatLine = Spawn(class'UIPanel_StatUI_StatLine', Container).InitStatLine(eStat_PsiOffense, int(UnitState.GetMaxStat(eStat_PsiOffense)), OnClickedIncrease, OnClickedDecrease);
	StatLines.AddItem(StatLine);

	Index = 0;
	foreach StatLines(StatLine)
	{
		OffsetX = 40;
		OffsetY = 30;
		StatLine.SetPosition(OffsetX, 100 + (OffsetY * Index));
		`LOG(self.class.name @ GetFuncName() @ StatLine.MCName @ FontSize, bLog, 'RPG');
		Index++;
	}
}


function PopulateHeaderData()
{
	local X2SoldierClassTemplate SoldierClass;

	SoldierClass = UnitState.GetSoldierClassTemplate();

	if (SoldierClass != none)
	{
		SCImage.LoadImage(SoldierClass.IconImage);
		SCImage.Show();
	}

	TitleHeader.SetText(UnitState.GetName(eNameType_FullNick), Caps(SoldierClass != None ? SoldierClass.DisplayName : ""));
	TitleHeader.MC.FunctionVoid("realize");
}

function PopulateSoldierAP()
{
	local int CurrentAP;

	CurrentAP = GetSoldierAP() - AbilityPointCostSum;

	AbilityPointsText.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_PromotionHero'.default.m_strSoldierAPLabel @ string(CurrentAP), eUIState_Normal, FontSize));
}

function int GetSoldierAP()
{
	return UnitState.AbilityPoints;
}

function Save(UIButton Button)
{
	`LOG(self.Class.name @ GetFuncName(), bLog, 'RPG');
	OnAccept();
}

simulated function OnCancel()
{
	super.OnCancel();
}

simulated function OnAccept()
{
	if (AbilityPointCostSum > 0)
		ConfirmStatUpgrade();
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
}

simulated function ConfirmStatUpgrade()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = class'UIArmory_WeaponUpgrade'.default.m_strConfirmDialogTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ComfirmStatUpgradeCallback;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function ComfirmStatUpgradeCallback(Name Action)
{
	local XComGameStateHistory History;
	local XComGameState UpdateState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit UpdatedUnit;
	local UIPanel_StatUI_StatLine StatLine;

	if (Action == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Upgrade Stats in StatUI");
		UpdateState = History.CreateNewGameState(true, ChangeContainer);

		UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		foreach StatLines(StatLine)
		{
			if (StatLine.StatValue > int(UnitState.GetMaxStat(StatLine.StatType)))
			{
				UpdatedUnit.SetBaseMaxStat(StatLine.StatType, float(StatLine.StatValue), ECSMAR_Additive);
			}
		}

		UpdatedUnit.AbilityPoints -= AbilityPointCostSum;
		UpdatedUnit.SpentAbilityPoints += AbilityPointCostSum;
		`XEVENTMGR.TriggerEvent('AbilityPointsChange', UpdatedUnit, , UpdateState);

		`GAMERULES.SubmitGameState(UpdateState);

		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
		super.OnCancel();
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
	}
}


function bool OnClickedIncrease(ECharStatType StatType, int NewStatValue, int StatCost)
{
	local bool bCanIncrease;
	local int AbilityPointsLeft;
	
	`LOG(self.Class.name @ GetFuncName() @ StatType @ NewStatValue, bLog, 'RPG');
	
	AbilityPointsLeft = GetSoldierAP() - AbilityPointCostSum - StatCost;
	bCanIncrease = (AbilityPointsLeft) >= 0;
	if (bCanIncrease)
	{
		AbilityPointCostSum += StatCost;
		PopulateSoldierAP();
	}

	`LOG(self.Class.name @ GetFuncName() @ GetSoldierAP() @ StatCost @ AbilityPointCostSum @ AbilityPointsLeft @ bCanIncrease, bLog, 'RPG');

	return bCanIncrease;
}

function bool OnClickedDecrease(ECharStatType StatType, int NewStatValue, int StatCost)
{
	local bool bCanDecrease;
	
	`LOG(self.Class.name @ GetFuncName() @ StatType @ NewStatValue @ StatCost, bLog, 'RPG');

	bCanDecrease = (NewStatValue >=  int(UnitState.GetMaxStat(StatType)));

	if (bCanDecrease)
	{
		AbilityPointCostSum -= StatCost;
		PopulateSoldierAP();
	}

	return bCanDecrease;
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local UIScreen_StatUI StatUIScreen;
	local UIScreenStack ScreenStack;

	ScreenStack = `SCREENSTACK;
	StatUIScreen = UIScreen_StatUI(ScreenStack.GetScreen(class'UIScreen_StatUI'));

	if(StatUIScreen != none)
	{
		StatUIScreen.InitArmory(NewRef);
	}
	
	super.CycleToSoldier(NewRef);
}

defaultproperties
{
	FontSize=32
	Width=1120
	Height=800
	bLog=true
}