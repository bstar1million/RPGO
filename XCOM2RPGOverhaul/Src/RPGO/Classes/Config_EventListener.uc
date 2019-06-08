//-----------------------------------------------------------
//	Class:	Config_EventListener
//	Author: Musashi
//	EventListener for tag value calculation
//-----------------------------------------------------------
class Config_EventListener extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'ConfigListenerTemplate');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('ConfigTagFunction', OnTagValue, ELD_Immediate);
	`LOG("Register Event ConfigTagFunction",, 'RPG');

	return Template;
}

static function EventListenerReturn OnTagValue(Object EventData, Object EventSource, XComGameState GameState, Name EventName, Object CallbackData)
{
	local LWTuple Tuple;
	local Config_TaggedConfigProperty Prop;
	local int Value;

	Tuple = LWTuple(EventData);
	Prop = Config_TaggedConfigProperty(EventSource);

	switch (Tuple.Id)
	{
		case 'TagValueToPercent':
			Value = int(float(Prop.GetValue()) * 100);
			break;
		case 'TagValueToPercentMinusHundred':
			Value = int(float(Prop.GetValue()) * 100 - 100);
			break;
		case 'TagValueMetersToTiles':
			Value = int(Prop.GetValue()) * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
			break;
		case 'TagValueTilesToMeters':
			Value = int(Prop.GetValue()) * class'XComWorldData'.const.WORLD_StepSize / class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER;
			break;
		case 'TagValueTilesToUnits':
			`LOG(default.class @ GetFuncName() @ int(Prop.GetValue()) @ class'XComWorldData'.const.WORLD_StepSize,, 'RPG');
			Value = int(Prop.GetValue()) * class'XComWorldData'.const.WORLD_StepSize;
			break;
		case 'TagValueLockDown':
			 Value = int(Prop.GetValue()) / (1 - class'X2AbilityToHitCalc_StandardAim'.default.REACTION_FINALMOD);
			 break;
		case 'TagValueParamAddition':
			 Value = int(Prop.GetValue()) + int(Prop.GetTagParam());
			 break;
		case 'TagValueParamMultiplication':
			 Value = int(Prop.GetValue()) * int(Prop.GetTagParam());
			 break;
		default:
			break;
	}

	Tuple.Data[0].s = string(Value);

	return ELR_NoInterrupt;
}
