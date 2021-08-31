#include <amxmodx>
#include <amxmisc>
#include <ini_file>
#include <customwpn_loader_api>
#include <customwpn_json_const>
#include <wpn_const>
#include <json>

#define PLUGIN "CustomWpn Loader - General"
#define VERSION "1.0"
#define AUTHOR "MzKc"


new g_iKnifeLoadCount = 3;
new g_iPistolLoadCount = 3;
new g_iShotgunLoadCount = 3;
new g_iSmgLoadCount = 3;
new g_iRifleLoadCount = 3;
new g_iBoltSniperLoadCount = 2;
new g_iAutoSniperLoadCount = 2;
new g_iMgLoadCount = 2;

new Trie:g_trie_szWpnFamilyLoadCount;
new Trie:g_trie_iWpnTypeLoadCount;
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
	read_count_from_setting();
	g_trie_szWpnFamilyLoadCount = TrieCreate();
	g_trie_iWpnTypeLoadCount = TrieCreate();
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
	TrieDestroy( g_trie_szWpnFamilyLoadCount );
	TrieDestroy( g_trie_iWpnTypeLoadCount );
	json_free(g_json_pickedWpn);
}

read_count_from_setting()
{
	new const SETTING_FILENAME[] = "customwpn_settings";

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "KNIFE", g_iKnifeLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "KNIFE", g_iKnifeLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "PISTOL", g_iPistolLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "PISTOL", g_iPistolLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "SHOTGUN", g_iShotgunLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "SHOTGUN", g_iShotgunLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "SMG", g_iSmgLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "SMG", g_iSmgLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "RIFLE", g_iRifleLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "RIFLE", g_iRifleLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "BOLT_SNIPER", g_iBoltSniperLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "BOLT_SNIPER", g_iBoltSniperLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "AUTO_SNIPER", g_iAutoSniperLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "AUTO_SNIPER", g_iAutoSniperLoadCount)

	if (!ini_read_int(SETTING_FILENAME, "LOADER_COUNT", "MG", g_iMgLoadCount))
		ini_write_int(SETTING_FILENAME, "LOADER_COUNT", "MG", g_iMgLoadCount)
}


pick_wpn(JSON:jFullWpnObj)
{
	pick_wpn_of_type(jFullWpnObj,  (1 << CSW_KNIFE) , g_iKnifeLoadCount)
	pick_wpn_of_type(jFullWpnObj, PISTOL_TYPE , g_iPistolLoadCount)
	pick_wpn_of_type(jFullWpnObj, SHOTGUN_TYPE ,g_iShotgunLoadCount)
	pick_wpn_of_type(jFullWpnObj, SMG_TYPE , g_iSmgLoadCount)
	pick_wpn_of_type(jFullWpnObj, RIFLE_TYPE , g_iRifleLoadCount)
	pick_wpn_of_type(jFullWpnObj, BOLT_SNIPER_TYPE , g_iBoltSniperLoadCount)
	pick_wpn_of_type(jFullWpnObj, AUTO_SNIPER_TYPE , g_iAutoSniperLoadCount)
	pick_wpn_of_type(jFullWpnObj, (1 << CSW_M249) , g_iMgLoadCount)
}

pick_wpn_of_type(JSON:jFullWpnObj, iTargetCswType, iLoadCount)
{
	new JSON:jWpnOfType = get_wpn_of_type(jFullWpnObj, iTargetCswType)
	new JSON:jWpnEntry;	

	new Array:ary_iLoadedIdx = ArrayCreate();
	new strBuffer[32];
	new iEntryCount = json_array_get_count(jWpnOfType);

	// The 1st loop loads wpn that are marked "Force Load".  *ForceLoad WILL ignore the load limit.
	for(new i = 0 ; i < iEntryCount ; i++)
	{
		jWpnEntry = json_array_get_value(jWpnOfType , i)

		// if there is not enough entry , just load all.
		if(iEntryCount < iLoadCount || json_object_get_bool(jWpnEntry, JSON_FORCE_ROLL))
		{
			json_object_get_string(jWpnEntry, JSON_WPN_FAMILY, strBuffer, charsmax(strBuffer));
			add_wpn_to_trie(strBuffer);

			json_array_append_value(g_json_pickedWpn , jWpnEntry);
			// Add loaded idx to array for removal.
			ArrayPushCell(ary_iLoadedIdx, i)
		}
	}

	// 2nd load , with wpnFamily check
	if(iEntryCount > iLoadCount)
	{
		
		// Remove the loaded idx for next loop
		for(new i = 0 ; i < ArraySize(ary_iLoadedIdx) ; i++)
		{
			new idx = ArrayGetCell(ary_iLoadedIdx , i);
			json_array_remove(jWpnOfType, idx);
		}

		// An array storing the available wpn json index for random pick.
		new Array:ary_availableIdx = ArrayCreate();
		for(new i = 0 ; i < json_array_get_count(jWpnOfType) ; i++)
		{
			ArrayPushCell(ary_availableIdx, i);
		}
		

		new iLoaded = ArraySize(ary_iLoadedIdx);
		while(iLoaded < iLoadCount && ArraySize(ary_availableIdx) > 0)
		{
			// Pick a random index from the jWpnType
			new iRndCellIdx = random_num(0 , ArraySize(ary_availableIdx) - 1);
			new iJdx = ArrayGetCell(ary_availableIdx , iRndCellIdx);
			// Remove the picked ary idx
			ArrayDeleteItem(ary_availableIdx, iRndCellIdx);

			jWpnEntry = json_array_get_value(jWpnOfType , iJdx)

			// Check if can add this wpn
			json_object_get_string(jWpnEntry, JSON_WPN_FAMILY, strBuffer, charsmax(strBuffer));
			if(can_pick_wpn(strBuffer))
			{
				iLoaded++;
				add_wpn_to_trie(strBuffer);
				json_object_get_string(jWpnEntry, JSON_DISPLAY_NAME, strBuffer, charsmax(strBuffer));
				json_array_append_value(g_json_pickedWpn , jWpnEntry);
			}


		}
		ArrayDestroy(ary_availableIdx);
	}
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

add_wpn_to_trie(const szWpnFamily[])
{
	if(equali(szWpnFamily , "null"))
		return;

	if(TrieKeyExists(g_trie_szWpnFamilyLoadCount, szWpnFamily))
	{
		new iCount;
		TrieGetCell(g_trie_szWpnFamilyLoadCount , szWpnFamily, iCount);
		iCount++;
		TrieSetCell(g_trie_szWpnFamilyLoadCount, szWpnFamily, iCount);
	}
	else
	{
		TrieSetCell(g_trie_szWpnFamilyLoadCount, szWpnFamily, 1);		
	}
}

bool:can_pick_wpn(const szWpnFamily[])
{
	if(!TrieKeyExists(g_trie_szWpnFamilyLoadCount, szWpnFamily))
		return true;

	new iCount;
	TrieGetCell(g_trie_szWpnFamilyLoadCount , szWpnFamily, iCount);
	return iCount > 2;
}

