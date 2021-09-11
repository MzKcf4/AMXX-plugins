#include <amxmodx>
#include <amxmisc>
#include <customwpn_loader_api>
#include <customwpn_json_const>
#include <customwpn_const>
#include <json>
#include <zombie_stage_const>

#define PLUGIN "CustomWpn Loader - General"
#define VERSION "1.0"
#define AUTHOR "MzKc"

new JSON:g_json_pickedWpn;

public plugin_natives()
{
	// ToDo:
	// For zombie mode , there is no need to precache W weapons , as they should be disappeared.
	// --> so , maybe we manually modify it to "null" when loading, so that precacher will skip it.
	//     or , can indicate in config file (e.g load_w_models = true/false)
}

public plugin_precache()
{
	g_json_pickedWpn = json_init_array();

	api_load_all_wpn();
	new JSON:jLoadedWpnObj = api_get_loaded_wpn();
	pick_wpn(jLoadedWpnObj);

	// Now we rolled all the weapons that will load. Save them back to loader-api
	new JSON:jTempEntry;
	json_array_clear(jLoadedWpnObj);
	for(new i = 0 ; i < json_array_get_count(g_json_pickedWpn) ; i++)
	{
		jTempEntry = json_array_get_value(g_json_pickedWpn , i)
		json_array_append_value(jLoadedWpnObj, jTempEntry);
	}

	// Do not free jLoadedWpnObj , as it's actually a reference to the one in loader-api !
	json_free(jTempEntry);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_end()
{
	json_free(g_json_pickedWpn);
}

// For each Z-Tier , roll 1 weapon for each weapon type
pick_wpn(JSON:jFullWpnObj)
{
	pick_wpn_of_type(jFullWpnObj,  (1 << CSW_KNIFE))
	pick_wpn_of_type(jFullWpnObj, SHOTGUN_TYPE)
	pick_wpn_of_type(jFullWpnObj, SMG_TYPE)
	pick_wpn_of_type(jFullWpnObj, RIFLE_TYPE)
	pick_wpn_of_type(jFullWpnObj, BOLT_SNIPER_TYPE)
	pick_wpn_of_type(jFullWpnObj, AUTO_SNIPER_TYPE)
	pick_wpn_of_type(jFullWpnObj, (1 << CSW_M249))

	pick_pistol(jFullWpnObj , ZSubType_SUP);
	pick_pistol(jFullWpnObj , ZSubType_DMG);
}

pick_wpn_of_type(JSON:jFullWpnObj, iTargetCswType)
{
	new JSON:jWpnOfType = get_wpn_of_type(jFullWpnObj, iTargetCswType)
	new JSON:jWpnEntry;	

	new Array:ary_iIdxOfTierAndType = ArrayCreate();
	new iEntryCount = json_array_get_count(jWpnOfType);

	// 
	for(new iZTier = 1 ; iZTier <= MAX_ZTIER ; iZTier++)
	{
		ArrayDestroy(ary_iIdxOfTierAndType);
		ary_iIdxOfTierAndType = ArrayCreate();

		for(new i = 0 ; i < iEntryCount ; i++)
		{
			jWpnEntry = json_array_get_value(jWpnOfType , i)
			new iWpnTier = json_object_get_number(jWpnEntry, JSON_Z_TIER);
			if(!(iWpnTier == iZTier))
				continue;

			ArrayPushCell(ary_iIdxOfTierAndType , i);
		}

		// Now we have wpn list with all wpn of type in that tier.	( e.g all AR in Tier 4)
		// Pick 1 random cell & the corresponding iWpnIdx
		if(ArraySize(ary_iIdxOfTierAndType) > 0)
		{
			new iRndCellIdx = random_num(0 , ArraySize(ary_iIdxOfTierAndType) - 1);
			new iWpnIdx = ArrayGetCell(ary_iIdxOfTierAndType , iRndCellIdx);

			jWpnEntry = json_array_get_value(jWpnOfType , iWpnIdx)
			// Override the weapon damage multiplier with ZDamage : 
			new Float:fZDmgMultiplier = json_object_get_real(jWpnEntry, JSON_Z_DMG_MULTIPLIER); 
			json_object_set_real(jWpnEntry, JSON_DMG_MULTIPLIER, fZDmgMultiplier)

			json_array_append_value(g_json_pickedWpn , jWpnEntry);
		}
	}

	ArrayDestroy(ary_iIdxOfTierAndType);
	json_free(jWpnOfType);
	json_free(jWpnEntry);
}

pick_pistol(JSON:jFullWpnObj , iTargetSubType)
{
	new JSON:jWpnOfType = get_wpn_of_type(jFullWpnObj, PISTOL_TYPE)
	new JSON:jWpnEntry;

	new Array:ary_iIdxOfTierAndType = ArrayCreate();
	new iEntryCount = json_array_get_count(jWpnOfType);

	// 
	for(new iZTier = 1 ; iZTier <= MAX_ZTIER ; iZTier++)
	{
		if(iZTier == 3 || iZTier == 5 || iZTier == 7)
			continue;

		ArrayDestroy(ary_iIdxOfTierAndType);
		ary_iIdxOfTierAndType = ArrayCreate();

		for(new i = 0 ; i < iEntryCount ; i++)
		{
			jWpnEntry = json_array_get_value(jWpnOfType , i)
			new iWpnTier = json_object_get_number(jWpnEntry, JSON_Z_TIER);
			if(!(iWpnTier == iZTier))
				continue;

			// Don't filter T1
			if(iZTier > 1)
			{
				new iSubType = json_object_get_number(jWpnEntry, JSON_Z_SUBTYPE);
				if(iSubType != iTargetSubType)
					continue;
			}

			ArrayPushCell(ary_iIdxOfTierAndType , i);
		}

		// Now we have wpn list with all wpn of type in that tier.	( e.g all AR in Tier 4)
		// Pick 1 random cell & the corresponding iWpnIdx
		if(ArraySize(ary_iIdxOfTierAndType) > 0)
		{
			new iRndCellIdx = random_num(0 , ArraySize(ary_iIdxOfTierAndType) - 1);
			new iWpnIdx = ArrayGetCell(ary_iIdxOfTierAndType , iRndCellIdx);

			jWpnEntry = json_array_get_value(jWpnOfType , iWpnIdx)
			// Override the weapon damage multiplier with ZDamage : 
			new Float:fZDmgMultiplier = json_object_get_real(jWpnEntry, JSON_Z_DMG_MULTIPLIER); 
			json_object_set_real(jWpnEntry, JSON_DMG_MULTIPLIER, fZDmgMultiplier)
			
			json_array_append_value(g_json_pickedWpn , jWpnEntry);
		}
	}

	ArrayDestroy(ary_iIdxOfTierAndType);
	json_free(jWpnOfType);
	json_free(jWpnEntry);
}

JSON:get_wpn_of_type(JSON:jFullWpnObj, iTargetCswType)
{
	new JSON:jWpnOfType = json_init_array();

	new JSON:jWpnEntry;
	new iWpnCswType;
	new iEntryCount = json_array_get_count(jFullWpnObj);
	for(new i = 0 ; i < iEntryCount ; i++)
	{
		jWpnEntry = json_array_get_value(jFullWpnObj , i)
		iWpnCswType = 1 << json_object_get_number(jWpnEntry, JSON_CSW_ID);
		
		if(iWpnCswType & iTargetCswType)
			json_array_append_value(jWpnOfType, jWpnEntry);
	}

	json_free(jWpnEntry);
	return jWpnOfType;
}
