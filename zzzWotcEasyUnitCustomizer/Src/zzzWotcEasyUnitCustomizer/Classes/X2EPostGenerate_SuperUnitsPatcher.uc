class X2EPostGenerate_SuperUnitsPatcher extends Object config(SuperCustomizer);

struct UnitAbilityModify
{
	var name UnitTemplateName;
	var array<name> AddAbilities;
	var array<name> RemoveAbilities;
};

enum ItemChangableState
{
	eIStat_Range,
	eIStat_Aim,
	eIStat_CritChance,
	eIStat_SoundRange,
	eIStat_ENVDamage,
	eIStat_ClipSize,
	eIStat_Radius
};

struct ItemCustomStats
{
	var ItemChangableState Stat;
	var int Value;
};

struct ItemGrantedStats
{
	var ECharStatType StatType;
	var int Value;
};

struct ItemStatModify
{
	var name ItemTemplateName;
	
	var bool ChangeWeaponDamage;
	var WeaponDamageValue BaseDamage;
	var array<ItemCustomStats> StatChanges;
	var array<name> AddItemAbilities;
	var array<name> RemoveItemAbilities;
};

struct ArmorStatModify
{
	var name ItemTemplateName;

	var bool GrantExtraUtility;
	var bool AllowHeavyWeapon;
	var bool RemoveAllExistingAbilitiesAndStatBonuses;
	var array<ItemGrantedStats> GrantedStats;
	var array<name> AddItemAbilities;
};

struct UtilityItemModify
{
	var name ItemTemplateName;

	var array<ItemGrantedStats> GrantedStats;
	var array<name> AddItemAbilities;
	var array<name> RemoveItemAbilities;
};

var config bool LoggingEnabled;
var config array<ItemStatModify> ModifyItems;
var config array<UnitAbilityModify> ModifyUnitAbilities;
var config array<ArmorStatModify> ModifyArmors;
var config array<UtilityItemModify> ModifyUtilities;

static function string GetLabel(ECharStatType StatType)
{
	switch(StatType)
	{
		case eStat_HP:
			return class'XLocalizedData'.default.HealthLabel;
		case eStat_Offense:
			return class'XLocalizedData'.default.AimLabel;
		case eStat_Hacking:
			return class'XLocalizedData'.default.TechLabel; 
		case eStat_Will:
			return class'XLocalizedData'.default.WillLabel; 
		case eStat_ArmorMitigation:
			return class'XLocalizedData'.default.ArmorLabel;
		case eStat_Dodge:
			return class'XLocalizedData'.default.DodgeLabel;
		case eStat_PsiOffense:
			return class'XLocalizedData'.default.PsiOffenseLabel; 
		case eStat_Defense:
			return class'XLocalizedData'.default.DefenseLabel; 
		case eStat_Mobility:
			return class'XLocalizedData'.default.MobilityLabel;
		case eStat_CritChance:
			return class'XLocalizedData'.default.CritChanceLabel;
		case eStat_ArmorPiercing:
			return class'XLocalizedData'.default.PierceLabel;
	}
	return "";
}

static function PostPatch()
{
	//Ensure units have ability
	local X2CharacterTemplateManager CharacterTemplateManager;
	local name TName;
	local X2CharacterTemplate CurrentTemplate;
	
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate ItemTemplate;
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2DataTemplate> NewTemplates;
	local X2DataTemplate DataTemplate;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ArmorTemplate ArmorTemplate;

	local ItemStatModify ModifyItem;
	local ItemCustomStats StatChange;

	local ArmorStatModify ModifyArmor;
	local ItemGrantedStats ItemStatPair;
	local X2AbilityTemplate AbilityTemplate;	
	local X2AbilityTrigger AbilityTrigger;
	local X2AbilityTarget_Self AbilityTargetStyle;
	local X2Effect_PersistentStatChange AbilityPersistentStatChangeEffect;

	local UtilityItemModify ModifyUtility;

	local UnitAbilityModify ModifyUnitAbility;

	`log("==========SECOND PASS Patches started==========", default.LoggingEnabled, 'EasyCustomizer');
	
	CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	//Modify item here
	foreach default.ModifyItems(ModifyItem)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(ModifyItem.ItemTemplateName, NewTemplates);
		
		`log("~~~Modifying" @ ModifyItem.ItemTemplateName $ "~~~", default.LoggingEnabled, 'EasyCustomizer');
		foreach NewTemplates(DataTemplate)
		{
			`log("~~ModItemTemplate:" @ DataTemplate.GetPackageName() $ "." $ DataTemplate.Name $ "~~", default.LoggingEnabled, 'EasyCustomizer');
			ItemTemplate = X2WeaponTemplate(DataTemplate);
			if (ItemTemplate != none)
			{
				foreach ModifyItem.StatChanges(StatChange)
				{
					GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);
					if (GrenadeTemplate == none)
						class'X2FinalTemplatePreValidation'.static.WeaponStatChange(ItemTemplate, StatChange);
					else
						class'X2FinalTemplatePreValidation'.static.GrenadeStatChange(GrenadeTemplate, StatChange);
				}
				if (ModifyItem.ChangeWeaponDamage)
				{
					`log("~DamageChanged~", default.LoggingEnabled, 'EasyCustomizer');
					ItemTemplate.BaseDamage = ModifyItem.BaseDamage;
				}
				foreach ModifyItem.AddItemAbilities(TName)
				{
					`log("~AddAbility:" $ TName $ "~", default.LoggingEnabled, 'EasyCustomizer');
					if (ItemTemplate.Abilities.Find(TName) == INDEX_NONE)
						ItemTemplate.Abilities.AddItem(TName);
				}
				foreach ModifyItem.RemoveItemAbilities(TName)
				{
					`log("~RemoveAbility:" $ TName $ "~", default.LoggingEnabled, 'EasyCustomizer');
					if (ItemTemplate.Abilities.Find(TName) != INDEX_NONE)
						ItemTemplate.Abilities.RemoveItem(TName);
				}
			}
			else
			{
				`redscreen(ModifyItem.ItemTemplatename @ "not found (weapon)!");
				continue;
			}
			ItemTemplateManager.AddItemTemplate(ItemTemplate, true);
		}
	}

	//Modify utility item here
	foreach default.ModifyUtilities(ModifyUtility)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(ModifyUtility.ItemTemplateName, NewTemplates);

		
		foreach NewTemplates(DataTemplate)
		{
			EquipmentTemplate = X2EquipmentTemplate(DataTemplate);
			if (EquipmentTemplate != none)
			{
				// Stat changes
				if (ModifyUtility.GrantedStats.Length > 0)
				{
					if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(name(ModifyUtility.ItemTemplateName $ "_EUCStat")) == none)
					{
						`CREATE_X2ABILITY_TEMPLATE(AbilityTemplate, name(ModifyUtility.ItemTemplateName $ "_EUCStat"));
						// Template.IconImage  -- no icon needed for armor stats

						AbilityTemplate.AbilitySourceName = 'eAbilitySource_Item';
						AbilityTemplate.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
						AbilityTemplate.Hostility = eHostility_Neutral;
						AbilityTemplate.bDisplayInUITacticalText = false;
	
						AbilityTemplate.AbilityToHitCalc = new class'X2AbilityToHitCalc_DeadEye';
	
						AbilityTargetStyle = new class'X2AbilityTarget_Self';
						AbilityTemplate.AbilityTargetStyle = AbilityTargetStyle;

						AbilityTrigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
						AbilityTemplate.AbilityTriggers.AddItem(AbilityTrigger);

						AbilityPersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
						AbilityPersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
						foreach ModifyUtility.GrantedStats(ItemStatPair)
						{
							AbilityPersistentStatChangeEffect.AddPersistentStatChange(ItemStatPair.StatType, ItemStatPair.Value);
							if (ItemStatPair.StatType == eStat_ArmorMitigation)
								AbilityPersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, 100);
						}
						AbilityTemplate.AddTargetEffect(AbilityPersistentStatChangeEffect);
						AbilityTemplate.BuildNewGameStateFn = class'X2Ability'.static.TypicalAbility_BuildGameState;
						class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().AddAbilityTemplate(AbilityTemplate);
					}
					EquipmentTemplate.Abilities.AddItem(name(ModifyUtility.ItemTemplateName $ "_EUCStat"));
					foreach ModifyUtility.GrantedStats(ItemStatPair)
					{
						if (GetLabel(ItemStatPair.StatType) != "")
							EquipmentTemplate.SetUIStatMarkup(GetLabel(ItemStatPair.StatType), ItemStatPair.StatType, ItemStatPair.Value, true);
					}
				}
				foreach ModifyUtility.AddItemAbilities(TName)
				{
					if (EquipmentTemplate.Abilities.Find(TName) == INDEX_NONE)
						EquipmentTemplate.Abilities.AddItem(TName);
				}
				foreach ModifyUtility.RemoveItemAbilities(TName)
				{
					if (EquipmentTemplate.Abilities.Find(TName) != INDEX_NONE)
						EquipmentTemplate.Abilities.RemoveItem(TName);
				}
			}
			else
			{
				`redscreen(ModifyUtility.ItemTemplatename @ "not found (utility)!");
				continue;
			}
			ItemTemplateManager.AddItemTemplate(EquipmentTemplate, true);
		}
	}

	//Modify armor here
	foreach default.ModifyArmors(ModifyArmor)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(ModifyArmor.ItemTemplateName, NewTemplates);

		foreach NewTemplates(DataTemplate)
		{
			ArmorTemplate = X2ArmorTemplate(DataTemplate);
			if (ArmorTemplate != none)
			{
				if (ModifyArmor.RemoveAllExistingAbilitiesAndStatBonuses)
				{
					ArmorTemplate.Abilities.Length = 0;
					ArmorTemplate.UIStatMarkups.Length = 0;
				}
				// Stat changes
				if (ModifyArmor.GrantedStats.Length > 0)
				{
					if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(name(ModifyArmor.ItemTemplateName $ "_EUCStat")) == none)
					{
						`CREATE_X2ABILITY_TEMPLATE(AbilityTemplate, name(ModifyArmor.ItemTemplateName $ "_EUCStat"));
						// Template.IconImage  -- no icon needed for armor stats

						AbilityTemplate.AbilitySourceName = 'eAbilitySource_Item';
						AbilityTemplate.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
						AbilityTemplate.Hostility = eHostility_Neutral;
						AbilityTemplate.bDisplayInUITacticalText = false;
	
						AbilityTemplate.AbilityToHitCalc = new class'X2AbilityToHitCalc_DeadEye';
	
						AbilityTargetStyle = new class'X2AbilityTarget_Self';
						AbilityTemplate.AbilityTargetStyle = AbilityTargetStyle;

						AbilityTrigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
						AbilityTemplate.AbilityTriggers.AddItem(AbilityTrigger);

						AbilityPersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
						AbilityPersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
						foreach ModifyArmor.GrantedStats(ItemStatPair)
						{
							AbilityPersistentStatChangeEffect.AddPersistentStatChange(ItemStatPair.StatType, ItemStatPair.Value);
							if (ItemStatPair.StatType == eStat_ArmorMitigation)
								AbilityPersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, 100);
						}
						AbilityTemplate.AddTargetEffect(AbilityPersistentStatChangeEffect);
						AbilityTemplate.BuildNewGameStateFn = class'X2Ability'.static.TypicalAbility_BuildGameState;
						class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().AddAbilityTemplate(AbilityTemplate);
					}
					ArmorTemplate.Abilities.AddItem(name(ModifyArmor.ItemTemplateName $ "_EUCStat"));
					foreach ModifyArmor.GrantedStats(ItemStatPair)
					{
						if (GetLabel(ItemStatPair.StatType) != "")
							ArmorTemplate.SetUIStatMarkup(GetLabel(ItemStatPair.StatType), ItemStatPair.StatType, ItemStatPair.Value, true);
					}
				}
				foreach ModifyArmor.AddItemAbilities(TName)
				{
					if (ArmorTemplate.Abilities.Find(TName) == INDEX_NONE)
						ArmorTemplate.Abilities.AddItem(TName);
				}

				ArmorTemplate.bHeavyWeapon = ModifyArmor.AllowHeavyWeapon;
				ArmorTemplate.bAddsUtilitySlot = ModifyArmor.GrantExtraUtility;
			}
			else
			{
				`redscreen(ModifyArmor.ItemTemplatename @ "not found (armor)!");
				continue;
			}
			ItemTemplateManager.AddItemTemplate(ArmorTemplate, true);
		}
	}

	//UnitAbilityModify
	foreach default.ModifyUnitAbilities(ModifyUnitAbility)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(ModifyUnitAbility.UnitTemplateName, NewTemplates);
		`log("~~~Modifying" @ ModifyUnitAbility.UnitTemplateName $ "~~~", default.LoggingEnabled, 'EasyCustomizer');
		foreach NewTemplates(DataTemplate)
		{
			`log("~~ModUnitTemplate~~", default.LoggingEnabled, 'EasyCustomizer');
			CurrentTemplate = X2CharacterTemplate(DataTemplate);
			if (CurrentTemplate == none)
			{
				`redscreen(ModifyUnitAbility.UnitTemplateName @ "not found (unit)!");
				continue;
			}
			foreach ModifyUnitAbility.AddAbilities(TName)
			{
				`log("~AddAbility:" $ TName $ "~", default.LoggingEnabled, 'EasyCustomizer');
				if (CurrentTemplate.Abilities.Find(TName) == INDEX_NONE)
					CurrentTemplate.Abilities.AddItem(TName);
			}
			foreach ModifyUnitAbility.RemoveAbilities(TName)
			{
				`log("~RemoveAbility:" $ TName $ "~", default.LoggingEnabled, 'EasyCustomizer');
				if (CurrentTemplate.Abilities.Find(TName) != INDEX_NONE)
					CurrentTemplate.Abilities.RemoveItem(TName);
			}
			CharacterTemplateManager.AddCharacterTemplate(CurrentTemplate, true);
		}
	}

	`log("==========SECOND PASS Patches ended==========", default.LoggingEnabled, 'EasyCustomizer');
}