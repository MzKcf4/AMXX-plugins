#include <wpn_const>

#define MAX_TIER 7

new Array:ary_iWpnZSubType
new Array:ary_iWpnZTier
new Array:ary_iWpnCswId
new Array:ary_iWpnImpulse

const WPN_AR = ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG552))
const WPN_SHOTGUN = ((1<<CSW_M3)|(1<<CSW_XM1014))
const WPN_SEMI_SNIPER = ((1<<CSW_SCOUT) | (1 << CSW_AWP))
const WPN_AUTO_SNIPER = ((1<<CSW_SG550)|(1<<CSW_G3SG1))
const WPN_MELEE = (1<<CSW_KNIFE)
const WPN_SMG = ((1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_M249))
const WPN_PISTOL = ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

public read_weapon_list_zombie_stage()
{
	new iWpnTotal = 0;
	ary_iWpnImpulse = ArrayCreate();
	ary_iWpnCswId = ArrayCreate();
	ary_iWpnZSubType = ArrayCreate();
	ary_iWpnZTier = ArrayCreate();
	new strBuffer[32];

	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn_json.ini", path) // store complete path to file
	new JSON:rootJsonObj = json_parse(path, true);
	new JSON:entryJsonObj;
	new iEntryCount = json_array_get_count(rootJsonObj);

	for(new i = 0 ; i < iEntryCount ; i++)
	{
		entryJsonObj = json_array_get_value(rootJsonObj , i)
		// Impulse
		ArrayPushCell(ary_iWpnImpulse, json_object_get_number(entryJsonObj, JSON_IMPULSE_ID));

		// CswId
		ArrayPushCell(ary_iWpnCswId , json_object_get_number(entryJsonObj, JSON_CSW_ID));
		ArrayPushCell(ary_iWpnZTier , json_object_get_number(entryJsonObj, JSON_Z_TIER));
		ArrayPushCell(ary_iWpnZSubType , json_object_get_number(entryJsonObj, JSON_Z_SUBTYPE));

		iWpnTotal++
		json_free(entryJsonObj);
	}
	json_free(rootJsonObj);
}

roll_weapons_zombie_stage()
{
	console_print(0 , "---Picking Knife--")
	zs_pick_wpn_of_type( (1 << CSW_KNIFE))
	console_print(0 , "---Picking Shotgun--")
	zs_pick_wpn_of_type(WPN_SHOTGUN)
	console_print(0 , "---Picking Smg--")
	zs_pick_wpn_of_type(WPN_SMG)
	console_print(0 , "---Picking Rifle--")
	zs_pick_wpn_of_type(WPN_AR)
	console_print(0 , "---Picking BS--")
	zs_pick_wpn_of_type(WPN_SEMI_SNIPER)
	console_print(0 , "---Picking AS--")
	zs_pick_wpn_of_type(WPN_AUTO_SNIPER)

	console_print(0 , "---Picking Pistol (DMG)--")
	zs_pick_pistol(ZSubType_DMG)
	console_print(0 , "---Picking Pistol (SUP)--")
	zs_pick_pistol(ZSubType_SUP)
}

// For each ZTier , roll 1 weapon for each wpn type.
zs_pick_wpn_of_type(iRequiredCswType)
{
	new Array:ary_iWpnIdOfWpnType = ArrayCreate();

	for(new tier = 1 ; tier <= MAX_TIER ; tier++)
	{
		ArrayDestroy(ary_iWpnIdOfWpnType)
		ary_iWpnIdOfWpnType = ArrayCreate();

		for(new idx = 0 ; idx < ArraySize(ary_iWpnImpulse) ; idx++)
		{
			new iTier = ArrayGetCell(ary_iWpnZTier, idx)
			if(iTier != tier)
				continue;
			new iCswId = ArrayGetCell(ary_iWpnCswId , idx)
			// Don't include HG , it has special rolling logic
			if((1 << iCswId) & WPN_PISTOL)
				continue;

			// Type match or Exact match
			if (!((1 << iCswId) & iRequiredCswType))
				continue;

			
			ArrayPushCell(ary_iWpnIdOfWpnType, idx)
		}
		// Now we have wpn list with all wpn of type in that tier.	( e.g all AR in Tier 4)
		// Pick random cell & the corresponding iWpnIdx
		if(ArraySize(ary_iWpnIdOfWpnType) > 0)
		{
			new iRndCellIdx = random_num(0 , ArraySize(ary_iWpnIdOfWpnType) - 1);
			new iWpnIdx = ArrayGetCell(ary_iWpnIdOfWpnType , iRndCellIdx);
			// Get the impulse by WpnId
			new iWpnImpulse = ArrayGetCell(ary_iWpnImpulse , iWpnIdx);
			// Add to load list
			console_print(0 , "Pushed wpn : (%i)" , iWpnImpulse);
			ArrayPushCell(g_ary_iAllowedWpnImpluse, iWpnImpulse)
		}
	}
}

zs_pick_pistol(iRequiredSubType)
{
	new Array:ary_iWpnIdOfWpnType = ArrayCreate();

	for(new tier = 1 ; tier <= MAX_TIER ; tier++)
	{
		if(tier == 3 || tier == 5 || tier == 7)
			continue;

		ArrayDestroy(ary_iWpnIdOfWpnType)
		ary_iWpnIdOfWpnType = ArrayCreate();

		for(new idx = 0 ; idx < ArraySize(ary_iWpnImpulse) ; idx++)
		{
			new iTier = ArrayGetCell(ary_iWpnZTier, idx)
			if(iTier != tier)
				continue;

			// Don't filter T1
			if(tier > 1)
			{
				new iSubType = ArrayGetCell(ary_iWpnZSubType, idx)
				if(iSubType != iRequiredSubType)
					continue;
			}

			new iCswId = ArrayGetCell(ary_iWpnCswId , idx)
			// HG only
			if( !((1 << iCswId) & WPN_PISTOL))
				continue;

			ArrayPushCell(ary_iWpnIdOfWpnType, idx)
		}
		// Now we have wpn list with all wpn of type in that tier.	( e.g all AR in Tier 4)
		// Pick random cell & the corresponding iWpnIdx
		if(ArraySize(ary_iWpnIdOfWpnType) > 0)
		{
			new iRndCellIdx = random_num(0 , ArraySize(ary_iWpnIdOfWpnType) - 1);
			new iWpnIdx = ArrayGetCell(ary_iWpnIdOfWpnType , iRndCellIdx);
			// Get the impulse by WpnId
			new iWpnImpulse = ArrayGetCell(ary_iWpnImpulse , iWpnIdx);
			// Add to load list
			console_print(0 , "Pushed wpn : (%i)" , iWpnImpulse);
			ArrayPushCell(g_ary_iAllowedWpnImpluse, iWpnImpulse)
		}
	}
}

post_weapon_load_zombie_stage()
{
	ArrayDestroy(ary_iWpnImpulse);
	ArrayDestroy(ary_iWpnCswId);
	ArrayDestroy(ary_iWpnZTier);
	ArrayDestroy(ary_iWpnZSubType)
}