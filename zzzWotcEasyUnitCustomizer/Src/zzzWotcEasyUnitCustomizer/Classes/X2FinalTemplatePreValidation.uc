class X2FinalTemplatePreValidation extends Object config(SuperCustomizer);

struct UnitCreate
{
	var name NewTemplateName;
	var name TemplateToCopy;
	var name LoadoutName;
	var array<name> Abilities;
	var bool UseNewAbilities;
	var string AIBT;
	var string PanicBT;
	var string ScamperBT;
};

struct WeaponCreate
{
	var name ItemTemplateName;
	var name ItemToClone;
	var WeaponDamageValue BaseDamage;
	var array<ItemCustomStats> StatChanges;
	var name CloneEffectFrom;
	var array<name> Abilities;
	var bool UseNewAbilities;
	var bool IsStartingItem;
	var bool IsInfinite;
	var bool CanBeManufactured;
	var bool IsExperimentalGrenade;
	var array<name> TechRequirements;
	var StrategyCost Cost;
};

struct ArmorCreate
{
	var name ItemTemplateName;
	var name ItemToClone;
	var array<name> Abilities;
	var bool UseNewAbilities;
	var array<ItemGrantedStats> GrantedStats;
	var bool GrantExtraUtility;
	var bool AllowHeavyWeapon;
	var bool IsStartingItem;
	var bool IsInfinite;
	var bool CanBeManufactured;
	var bool IsExperimentalGrenade;
	var array<name> TechRequirements;
	var StrategyCost Cost;
};

struct UtilityCreate
{
	var name ItemTemplateName;
	var name ItemToClone;
	var array<name> Abilities;
	var bool UseNewAbilities;
	var array<ItemGrantedStats> GrantedStats;
	var bool IsStartingItem;
	var bool IsInfinite;
	var bool CanBeManufactured;
	var bool IsExperimentalGrenade;
	var array<name> TechRequirements;
	var StrategyCost Cost;
};

var config array<WeaponCreate> NewWeapons;
var config array<WeaponCreate> NewGrenades;
var config array<ArmorCreate> NewArmors;
var config array<UtilityCreate> NewUtilities;
var config array<UnitCreate> NewUnits;

static function CreateTemplates()
{
	local WeaponCreate NewWeapon;
	local UnitCreate NewUnit;
	local ArmorCreate NewArmor;
	local UtilityCreate NewUtility;
  
	foreach default.NewWeapons(NewWeapon)
	{
		CreateWeaponTemplate(NewWeapon);
	}
	foreach default.NewGrenades(NewWeapon)
	{
		CreateGrenadeTemplate(NewWeapon);
	}
	foreach default.NewUnits(NewUnit)
	{
		CreateUnitTemplate(NewUnit);
	}
	foreach default.NewArmors(NewArmor)
	{
		CreateArmorTemplate(NewArmor);
	}
	foreach default.NewUtilities(NewUtility)
	{
		CreateUtilityTemplate(NewUtility);
	}
}

static function WeaponStatChange(out X2WeaponTemplate Weapon, ItemCustomStats StatChange)
{
	switch(StatChange.Stat)
	{
		case eIStat_Range:
			Weapon.iRange = StatChange.Value;
			break;
		case eIStat_Aim:
			Weapon.Aim = StatChange.Value;
			break;
		case eIStat_CritChance:
			Weapon.CritChance = StatChange.Value;
			break;
		case eIStat_SoundRange:
			Weapon.iSoundRange = StatChange.Value;
			break;
		case eIStat_ENVDamage:
			Weapon.iEnvironmentDamage = StatChange.Value;
			break;
		case eIStat_ClipSize:
			Weapon.iClipSize = StatChange.Value;
			break;
	}
}

static function GrenadeStatChange(out X2GrenadeTemplate Weapon, ItemCustomStats StatChange)
{
	local int FindIndex;
	switch(StatChange.Stat)
	{
		case eIStat_Range:
			Weapon.iRange = StatChange.Value;
			FindIndex = Weapon.UIStatMarkups.Find('StatLabel', class'XLocalizedData'.default.RangeLabel);
			if (FindIndex != INDEX_NONE)
			{
				Weapon.UIStatMarkups.RemoveItem(Weapon.UIStatMarkups[FindIndex]);
				Weapon.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , StatChange.Value);
			}
			break;
		case eIStat_SoundRange:
			Weapon.iSoundRange = StatChange.Value;
			break;
		case eIStat_ENVDamage:
			Weapon.iEnvironmentDamage = StatChange.Value;
			break;
		case eIStat_ClipSize:
			Weapon.iClipSize = StatChange.Value;
			break;
		case eIStat_Radius:
			Weapon.iRadius = StatChange.Value;
			FindIndex = Weapon.UIStatMarkups.Find('StatLabel', class'XLocalizedData'.default.RadiusLabel);
			if (FindIndex != INDEX_NONE)
			{
				Weapon.UIStatMarkups.RemoveItem(Weapon.UIStatMarkups[FindIndex]);
				Weapon.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , StatChange.Value);
			}
			break;
	}
}

static function CreateArmorTemplate(ArmorCreate NewArmor)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ArmorTemplate ItemTemplate, ItemToClone;
	local ItemGrantedStats StatChange;
	local array<X2DataTemplate> NewTemplates;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;	
	local X2AbilityTrigger AbilityTrigger;
	local X2AbilityTarget_Self AbilityTargetStyle;
	local X2Effect_PersistentStatChange AbilityPersistentStatChangeEffect;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties(NewArmor.ItemToClone, NewTemplates);

	foreach NewTemplates(DataTemplate)
	{
		ItemToClone = X2ArmorTemplate(DataTemplate);
		if (ItemToClone != none)
		{
			ItemTemplate = new(None, string(NewArmor.ItemTemplateName), 0) class'X2ArmorTemplate' (ItemToClone);
			ItemTemplate.SetTemplateName(NewArmor.ItemTemplateName);
			
			ItemTemplate.bHeavyWeapon = NewArmor.AllowHeavyWeapon;
			ItemTemplate.bAddsUtilitySlot = NewArmor.GrantExtraUtility;

			ItemTemplate.CanBeBuilt = NewArmor.CanBeManufactured;
			ItemTemplate.StartingItem = NewArmor.IsStartingItem;
			ItemTemplate.bInfiniteItem = NewArmor.IsInfinite;
			ItemTemplate.Requirements.RequiredTechs = NewArmor.TechRequirements;

			if (NewArmor.Cost.ResourceCosts.Length > 0 || NewArmor.Cost.ArtifactCosts.Length > 0)
				ItemTemplate.Cost = NewArmor.Cost;

			if (NewArmor.UseNewAbilities)
			{
				ItemTemplate.Abilities = NewArmor.Abilities;
				ItemTemplate.UIStatMarkups.Length = 0;
			}

			if (NewArmor.GrantedStats.Length > 0)
			{
				if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(name(NewArmor.ItemTemplateName $ "_EUCStat")) == none)
				{
					`CREATE_X2ABILITY_TEMPLATE(AbilityTemplate, name(NewArmor.ItemTemplateName $ "_EUCStat"));
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
					foreach NewArmor.GrantedStats(StatChange)
					{
						AbilityPersistentStatChangeEffect.AddPersistentStatChange(StatChange.StatType, StatChange.Value);
						if (StatChange.StatType == eStat_ArmorMitigation)
							AbilityPersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, 100);
					}
					AbilityTemplate.AddTargetEffect(AbilityPersistentStatChangeEffect);

					AbilityTemplate.BuildNewGameStateFn = class'X2Ability'.static.TypicalAbility_BuildGameState;
					class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().AddAbilityTemplate(AbilityTemplate);
				}
				ItemTemplate.Abilities.AddItem(name(NewArmor.ItemTemplateName $ "_EUCStat"));
				foreach NewArmor.GrantedStats(StatChange)
				{
					if (class'X2EPostGenerate_SuperUnitsPatcher'.static.GetLabel(StatChange.StatType) != "")
						ItemTemplate.SetUIStatMarkup(class'X2EPostGenerate_SuperUnitsPatcher'.static.GetLabel(StatChange.StatType), StatChange.StatType, StatChange.Value, true);
				}
			}

			ItemTemplateManager.AddItemTemplate(ItemTemplate);
		}
		else
		{
			`redscreen(NewArmor.ItemToClone @ "not found (armor)!");
		}
	}
	`log("Armor template added:"@string(ItemTemplate.DataName),, 'EasyUnitCustomizer');
}


static function CreateUtilityTemplate(UtilityCreate NewUtility)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate ItemTemplate, ItemToClone;
	local ItemGrantedStats StatChange;
	local array<X2DataTemplate> NewTemplates;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;	
	local X2AbilityTrigger AbilityTrigger;
	local X2AbilityTarget_Self AbilityTargetStyle;
	local X2Effect_PersistentStatChange AbilityPersistentStatChangeEffect;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties(NewUtility.ItemToClone, NewTemplates);

	foreach NewTemplates(DataTemplate)
	{
		ItemToClone = X2EquipmentTemplate(DataTemplate);
		if (ItemToClone != none)
		{
			ItemTemplate = new(None, string(NewUtility.ItemTemplateName), 0) class'X2EquipmentTemplate' (ItemToClone);
			ItemTemplate.SetTemplateName(NewUtility.ItemTemplateName);

			ItemTemplate.CanBeBuilt = NewUtility.CanBeManufactured;
			ItemTemplate.StartingItem = NewUtility.IsStartingItem;
			ItemTemplate.bInfiniteItem = NewUtility.IsInfinite;
			ItemTemplate.Requirements.RequiredTechs = NewUtility.TechRequirements;

			if (NewUtility.Cost.ResourceCosts.Length > 0 || NewUtility.Cost.ArtifactCosts.Length > 0)
				ItemTemplate.Cost = NewUtility.Cost;

			if (NewUtility.UseNewAbilities)
			{
				ItemTemplate.Abilities = NewUtility.Abilities;
				ItemTemplate.UIStatMarkups.Length = 0;
			}

			if (NewUtility.GrantedStats.Length > 0)
			{
				if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(name(NewUtility.ItemTemplateName $ "_EUCStat")) == none)
				{
					`CREATE_X2ABILITY_TEMPLATE(AbilityTemplate, name(NewUtility.ItemTemplateName $ "_EUCStat"));
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
					foreach NewUtility.GrantedStats(StatChange)
					{
						AbilityPersistentStatChangeEffect.AddPersistentStatChange(StatChange.StatType, StatChange.Value);
						if (StatChange.StatType == eStat_ArmorMitigation)
							AbilityPersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, 100);
					}
					AbilityTemplate.AddTargetEffect(AbilityPersistentStatChangeEffect);
					AbilityTemplate.BuildNewGameStateFn = class'X2Ability'.static.TypicalAbility_BuildGameState;
					class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().AddAbilityTemplate(AbilityTemplate);
				}
				ItemTemplate.Abilities.AddItem(name(NewUtility.ItemTemplateName $ "_EUCStat"));
				foreach NewUtility.GrantedStats(StatChange)
				{
					if (class'X2EPostGenerate_SuperUnitsPatcher'.static.GetLabel(StatChange.StatType) != "")
						ItemTemplate.SetUIStatMarkup(class'X2EPostGenerate_SuperUnitsPatcher'.static.GetLabel(StatChange.StatType), StatChange.StatType, StatChange.Value, true);
				}
			}

			ItemTemplateManager.AddItemTemplate(ItemTemplate);
		}
		else
		{
			`redscreen(NewUtility.ItemToClone @ "not found (utility)!");
		}
	}
	`log("Utility template added:"@string(ItemTemplate.DataName),, 'EasyUnitCustomizer');
}

static function CreateWeaponTemplate(WeaponCreate NewWeapon)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate ItemTemplate, ItemToClone;
	local ItemCustomStats StatChange;
	local array<X2DataTemplate> NewTemplates;
	local X2DataTemplate DataTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties(NewWeapon.ItemToClone, NewTemplates);

	foreach NewTemplates(DataTemplate)
	{
		ItemToClone = X2WeaponTemplate(DataTemplate);
		if (ItemToClone != none)
		{
			ItemTemplate = new(None, string(NewWeapon.ItemTemplateName), 0) class'X2WeaponTemplate' (ItemToClone);
			ItemTemplate.SetTemplateName(NewWeapon.ItemTemplateName);
			ItemTemplate.BaseDamage = NewWeapon.BaseDamage;
			ItemTemplate.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , NewWeapon.BaseDamage.Shred);

			foreach NewWeapon.StatChanges(StatChange)
			{
				WeaponStatChange(ItemTemplate, StatChange);
			}

			if (NewWeapon.CloneEffectFrom != '')
			{
				ItemToClone = X2WeaponTemplate(ItemTemplateManager.FindItemTemplate(NewWeapon.CloneEffectFrom));
				if (ItemToClone == none)
				{
					`redscreen(NewWeapon.ItemToClone @ "not found (weapon)!");
				}
				else
				{
					ItemTemplate.BonusWeaponEffects = ItemToClone.BonusWeaponEffects;
				}
			}

			ItemTemplate.CanBeBuilt = NewWeapon.CanBeManufactured;
			ItemTemplate.StartingItem = NewWeapon.IsStartingItem;
			ItemTemplate.bInfiniteItem = NewWeapon.IsInfinite;
			ItemTemplate.Requirements.RequiredTechs = NewWeapon.TechRequirements;

			if (NewWeapon.Cost.ResourceCosts.Length > 0 || NewWeapon.Cost.ArtifactCosts.Length > 0)
				ItemTemplate.Cost = NewWeapon.Cost;

			if (NewWeapon.UseNewAbilities)
				ItemTemplate.Abilities = NewWeapon.Abilities;

			ItemTemplateManager.AddItemTemplate(ItemTemplate);
		}
		else
		{
			`redscreen(NewWeapon.ItemToClone @ "not found (weapon)!");
		}
	}
	`log("Weapon template added:"@string(ItemTemplate.DataName),, 'EasyUnitCustomizer');
}

static function CreateGrenadeTemplate(WeaponCreate NewWeapon)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2GrenadeTemplate ItemTemplate, ItemToClone;
	local ItemCustomStats StatChange;
	local array<X2DataTemplate> NewTemplates;
	local X2DataTemplate DataTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties(NewWeapon.ItemToClone, NewTemplates);
	foreach NewTemplates(DataTemplate)
	{
		ItemToClone = X2GrenadeTemplate(DataTemplate);
		if (ItemToClone != none)
		{
			ItemTemplate = new(None, string(NewWeapon.ItemTemplateName), 0) class'X2GrenadeTemplate' (ItemToClone);

			ItemTemplate.SetTemplateName(NewWeapon.ItemTemplateName);
			ItemTemplate.BaseDamage = NewWeapon.BaseDamage;

			foreach NewWeapon.StatChanges(StatChange)
			{
				GrenadeStatChange(ItemTemplate, StatChange);
			}

			if (NewWeapon.IsExperimentalGrenade)
			{
				ItemTemplate.RewardDecks.AddItem('ExperimentalGrenadeRewards');
			}
			else
			{
				ItemTemplate.RewardDecks.RemoveItem('ExperimentalGrenadeRewards');
			}
			ItemTemplate.CanBeBuilt = NewWeapon.CanBeManufactured;
			ItemTemplate.StartingItem = NewWeapon.IsStartingItem;
			ItemTemplate.bInfiniteItem = NewWeapon.IsInfinite;
			ItemTemplate.Requirements.RequiredTechs = NewWeapon.TechRequirements;
			
			if (NewWeapon.Cost.ResourceCosts.Length > 0 || NewWeapon.Cost.ArtifactCosts.Length > 0)
				ItemTemplate.Cost = NewWeapon.Cost;

			`log("Grenade template added:"@string(ItemTemplate.DataName),, 'EasyUnitCustomizer');

			ItemTemplateManager.AddItemTemplate(ItemTemplate);
		}
		else
		{
			`redscreen(NewWeapon.ItemToClone @ "not found (grenade)!");
		}
	}
}

static function CreateUnitTemplate(UnitCreate NewUnit)
{
	local X2CharacterTemplateManager CharacterTemplateManager;
	local X2CharacterTemplate Template, TemplateToClone;

	//Difficulty stuffs
	local int DifficultyIndex;

	CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		
	TemplateToClone = CharacterTemplateManager.FindCharacterTemplate(NewUnit.TemplateToCopy);

	if (TemplateToClone == none)
	{
		`redscreen(NewUnit.TemplateToCopy @ "not found (unit)!");
		return;
	}

	TemplateToClone = new(None, string(NewUnit.NewTemplateName), 0) class'X2CharacterTemplate' (TemplateToClone);

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
	{
		`log("Difficulty:"@string(DifficultyIndex),, 'EasyUnitCustomizer');

		Template = new(None, NewUnit.NewTemplateName $ "_Diff_" $ DifficultyIndex, 0) class'X2CharacterTemplate' (TemplateToClone);
		Template.SetDifficulty(DifficultyIndex);

		Template.SetTemplatename(NewUnit.NewTemplateName);

		if (NewUnit.LoadoutName != '')
		{
			Template.DefaultLoadout=NewUnit.LoadoutName;
		}

		if (NewUnit.AIBT != "")
		{
			Template.strBehaviorTree = NewUnit.AIBT;
		}

		if (NewUnit.PanicBT != "")
		{
			Template.strPanicBT = NewUnit.PanicBT;
		}

		if (NewUnit.ScamperBT != "")
		{
			Template.strScamperBT = NewUnit.ScamperBT;
		}

		if (NewUnit.UseNewAbilities)
			Template.Abilities = NewUnit.Abilities;

		CharacterTemplateManager.AddCharacterTemplate(Template);
		`log("Character template added:"@string(Template.DataName)@"for difficulty index"@DifficultyIndex,, 'EasyUnitCustomizer');
	}
}