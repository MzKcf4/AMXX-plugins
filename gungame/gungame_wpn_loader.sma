#define MAX_WPN_PER_FAMILY 2
#define MAX_ALLOWED 25
#define KNIFE_COUNT 4

enum _:WpnCount
{
	KNIFE = 0,
	PISTOL,
	SHOTGUN,
	SMG,
	RIFLE,
	BOLT_SNIPER,
	AUTO_SNIPER,
	MG
}

new g_iWpnLoadCount[WpnCount]

new Array:g_ary_iWpnImpluse
new Array:g_ary_szWpnId;
new Array:g_ary_szWpnFamilyName
new Array:g_ary_bForceAppear
new Array:g_ary_bUniqueWpn

new Array:g_ary_szWpnFamilyNameUnique
new Array:g_ary_iWpnFamilyDeployed

new Array:g_ary_iWpnCswId

public read_weapon_list_gungame()
{
	new iWpnTotal = 0;
	g_ary_iAllowedWpnImpluse = ArrayCreate();
	g_ary_iWpnImpluse = ArrayCreate();
	g_ary_szWpnId = ArrayCreate(32);
	g_ary_szWpnFamilyName = ArrayCreate(32);
	g_ary_bForceAppear = ArrayCreate();
	g_ary_bUniqueWpn = ArrayCreate();
	g_ary_szWpnFamilyNameUnique = ArrayCreate(32);
	g_ary_iWpnFamilyDeployed = ArrayCreate();
	g_ary_iWpnCswId = ArrayCreate();
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
		ArrayPushCell(g_ary_iWpnImpluse, json_object_get_number(entryJsonObj, JSON_IMPULSE_ID));

		// WpnId
		json_object_get_string(entryJsonObj, JSON_WPN_ID, strBuffer, charsmax(strBuffer));
		ArrayPushString(g_ary_szWpnId, strBuffer)

		// Family name
		json_object_get_string(entryJsonObj, JSON_WPN_FAMILY, strBuffer, charsmax(strBuffer));
		ArrayPushString(g_ary_szWpnFamilyName, strBuffer);

		// bForceAppear
		ArrayPushCell(g_ary_bForceAppear, json_object_get_bool(entryJsonObj, JSON_FORCE_ROLL));

		// CswId
		ArrayPushCell(g_ary_iWpnCswId , json_object_get_number(entryJsonObj, JSON_CSW_ID));


		// Unique weapon or has family
		ArrayGetString(g_ary_szWpnFamilyName, iWpnTotal, strBuffer , charsmax(strBuffer));
		if(equali(strBuffer , "null"))
		{
			ArrayPushCell(g_ary_bUniqueWpn , true);
		}
		else	
		{
			// Has Family
			ArrayPushCell(g_ary_bUniqueWpn , false);
			// Find which family it belongs to , and then register & add count to that unique family
			new idx = ArrayFindString(g_ary_szWpnFamilyNameUnique, strBuffer);
			if(idx < 0)	// New Family name , add to unique 
			{
				// console_print(0, "New Family id : %i for %s" , iWpnFamilyCount , strBuffer);
				ArrayPushString(g_ary_szWpnFamilyNameUnique, strBuffer);
				ArrayPushCell(g_ary_iWpnFamilyDeployed , 0);
				// iWpnFamilyCount++;
			}
		}

		iWpnTotal++
		json_free(entryJsonObj);
	}
	json_free(rootJsonObj);
}

roll_weapons_gungame()
{
	initWpnTypeCount();
	pick_wpn();
}

post_weapon_load_gungame()
{
	ArrayDestroy(g_ary_iWpnImpluse)
	ArrayDestroy(g_ary_szWpnFamilyName)
	ArrayDestroy(g_ary_bForceAppear)
	ArrayDestroy(g_ary_bUniqueWpn)
	ArrayDestroy(g_ary_szWpnFamilyNameUnique)
	ArrayDestroy(g_ary_iWpnCswId)
}

initWpnTypeCount()
{
	g_iWpnLoadCount[KNIFE] = KNIFE_COUNT
	g_iWpnLoadCount[PISTOL] = 3
	g_iWpnLoadCount[SHOTGUN] = 3
	g_iWpnLoadCount[SMG] = 4
	g_iWpnLoadCount[RIFLE] = 4
	g_iWpnLoadCount[BOLT_SNIPER] = 2
	g_iWpnLoadCount[AUTO_SNIPER] = 2
	g_iWpnLoadCount[MG] = 2
}


pick_wpn()
{
	console_print(0 , "---Picking Knife--")
	pick_wpn_of_type( (1 << CSW_KNIFE) , KNIFE)
	console_print(0 , "---Picking Pistol--")
	pick_wpn_of_type(PISTOL_TYPE , PISTOL)
	console_print(0 , "---Picking Shotgun--")
	pick_wpn_of_type(SHOTGUN_TYPE , SHOTGUN)
	console_print(0 , "---Picking Smg--")
	pick_wpn_of_type(SMG_TYPE , SMG)
	console_print(0 , "---Picking Rifle--")
	pick_wpn_of_type(RIFLE_TYPE , RIFLE)
	console_print(0 , "---Picking Bolt-Sniper--")
	pick_wpn_of_type(BOLT_SNIPER_TYPE , BOLT_SNIPER)
	console_print(0 , "---Picking Auto-Sniper--")
	pick_wpn_of_type(AUTO_SNIPER_TYPE , AUTO_SNIPER)
	console_print(0 , "---Picking MG--")
	pick_wpn_of_type( (1 << CSW_M249) , MG)
	
	/*
	for(new i = 0 ; i < ArraySize(g_ary_iAllowedWpnImpluse) ; i++)
	{
		console_print(0, "Added impulse : %i" , ArrayGetCell(g_ary_iAllowedWpnImpluse , i));
	}
	*/
}

pick_wpn_of_type(iCswType , iWpnAryIdx)
{
	new Array:ary_iWpnIdx = get_wpn_idx_of_type(iCswType)
	new Array:ary_iWpnTaken = ArrayCreate();
	new szFamilyName[32];
	
	// Loop forced wpn first
	for(new i = 0 ; i < ArraySize(ary_iWpnIdx) ; i++)
	{
		new iWpnIdx = ArrayGetCell(ary_iWpnIdx , i);
		if(!ArrayGetCell(g_ary_bForceAppear,iWpnIdx)) continue;
		
		// Check if this is unique weapon , if yes , just let it pass
		if( !ArrayGetCell(g_ary_bUniqueWpn, iWpnIdx))
		{
			// Not unique , get the family idx
			ArrayGetString(g_ary_szWpnFamilyName, iWpnIdx, szFamilyName , charsmax(szFamilyName));
			new iFamilyIdx = ArrayFindString(g_ary_szWpnFamilyNameUnique, szFamilyName);
			
			// Add 1 to family deployed
			new iFamilyDeployed = ArrayGetCell(g_ary_iWpnFamilyDeployed , iFamilyIdx);
			iFamilyDeployed++;
			ArraySetCell(g_ary_iWpnFamilyDeployed , iFamilyIdx , iFamilyDeployed);
		}
		
		new iWpnImpluse = ArrayGetCell(g_ary_iWpnImpluse,iWpnIdx);
		ArrayPushCell(g_ary_iAllowedWpnImpluse , iWpnImpluse);
		g_iWpnLoadCount[iWpnAryIdx]--
		
		// Records which idx has taken , remove them.
		ArrayPushCell(ary_iWpnTaken , i)
	}
	
	// Remove the processed wpn from array
	for(new i = 0 ; i < ArraySize(ary_iWpnTaken) ; i++)
	{
		new iCellIdx = ArrayGetCell(ary_iWpnTaken , i);
		ArrayDeleteItem(ary_iWpnIdx, iCellIdx);
	}
	ArrayDestroy(ary_iWpnTaken);
	
	// ===Now process the remaining non-forced===
	new iWpnInPool = ArraySize(ary_iWpnIdx)
	for(new i = 0 ; i < iWpnInPool ; i++)
	{
		// new iWpnIdx = ArrayGetCell(ary_iWpnIdx , i)
		// console_print(0 , "wpnId in pool : %i , impulse : %i" , iWpnIdx , ArrayGetCell(g_ary_iWpnImpluse , iWpnIdx));
	}
	
	while(iWpnInPool > 0 && g_iWpnLoadCount[iWpnAryIdx] > 0)
	{
		
		// Pick random cell , & the corresponding iWpnIdx
		new iRndCellIdx = random_num(0 , ArraySize(ary_iWpnIdx) - 1);
		new iWpnIdx = ArrayGetCell(ary_iWpnIdx , iRndCellIdx);
		new bool:bAdd = true;
		
		// Check if this is unique weapon , if yes , just let it pass
		if( !ArrayGetCell(g_ary_bUniqueWpn, iWpnIdx))
		{
			// Not unique , get the family idx
			ArrayGetString(g_ary_szWpnFamilyName, iWpnIdx, szFamilyName , charsmax(szFamilyName));
			new iFamilyIdx = ArrayFindString(g_ary_szWpnFamilyNameUnique, szFamilyName);
			new iFamilyDeployed = ArrayGetCell(g_ary_iWpnFamilyDeployed , iFamilyIdx);
			
			// if all family taken , skip , else mark the family taken and take the weapon.
			if(iFamilyDeployed < MAX_WPN_PER_FAMILY)
			{
				// Add 1 to family deployed
				new iFamilyDeployed = ArrayGetCell(g_ary_iWpnFamilyDeployed , iFamilyIdx);
				// iFamilyDeployed++;
				ArraySetCell(g_ary_iWpnFamilyDeployed , iFamilyIdx , ++iFamilyDeployed);
			} 
			else
			{
				bAdd = false;
			}
		}
		
		if(bAdd)
		{
			new iWpnImpluse = ArrayGetCell(g_ary_iWpnImpluse,iWpnIdx);
			ArrayPushCell(g_ary_iAllowedWpnImpluse , iWpnImpluse);
		}
		
		ArrayDeleteItem(ary_iWpnIdx , iRndCellIdx);
		iWpnInPool = ArraySize(ary_iWpnIdx)
		g_iWpnLoadCount[iWpnAryIdx]--;
	}
	
	ArrayDestroy(ary_iWpnIdx);
}

// Returns the index of the wpn in main array.
public Array:get_wpn_idx_of_type(iType)
{
	new Array:ary_iWpnIdx = ArrayCreate();
	for(new i = 0 ; i < ArraySize(g_ary_iWpnImpluse) ; i++)
	{
		new iWpnCswId = ArrayGetCell(g_ary_iWpnCswId , i);
		
		// Type match or Exact match
		if(iType & (1 << iWpnCswId))
		{
			ArrayPushCell(ary_iWpnIdx , i)
		}
	}
	return ary_iWpnIdx;
}


