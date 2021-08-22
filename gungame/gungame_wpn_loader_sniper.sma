/*


Loader only loads wpn by request , then it register the wpn in customwpn_core.

Loader should destroy all ArrayHandles once resource arrays are loaded.

*/

#pragma dynamic 10240

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <wpn_const>
#include <wpn_core>
#include <wpn_loader>

#define PLUGIN "Wpn Loader"
#define VERSION "1.0"
#define AUTHOR "shanaO12"

#define MAX_WPN_PER_FAMILY 2

#define MAX_ALLOWED 20
#define KNIFE_COUNT 3


enum _:WpnCount
{
	KNIFE = 0,
	PISTOL,
	SHOTGUN,
	SMG,
	RIFLE,
	SNIPER,
	MG
}

new Float:g_fWpnRatio[] = { 0.0 , 0.0 , 0.0 , 0.0 , 0.0 , 1.0 , 0.0}

new g_iWpnLoadCount[WpnCount]
new Array:g_ary_iAllowedWpnImpluse 				// The wpn id marked by other plugins to load


new Array:g_ary_iWpnImpluse
new Array:g_ary_szWpnId;
new Array:g_ary_szWpnFamilyName
new Array:g_ary_bForceAppear
new Array:g_ary_bUniqueWpn

new Array:g_ary_szWpnFamilyNameUnique
new Array:g_ary_iWpnFamilyDeployed

new Array:g_ary_iWpnCswId


new bool:g_bReady = false


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache() 
{    
	g_ary_iAllowedWpnImpluse = ArrayCreate();
	
	g_ary_iWpnImpluse = ArrayCreate();
	g_ary_szWpnId = ArrayCreate(32);
	g_ary_szWpnFamilyName = ArrayCreate(32);
	g_ary_bForceAppear = ArrayCreate();
	g_ary_bUniqueWpn = ArrayCreate();
	g_ary_szWpnFamilyNameUnique = ArrayCreate(32);
	g_ary_iWpnFamilyDeployed = ArrayCreate();
	g_ary_iWpnCswId = ArrayCreate();
	
	// ==== GunGame load config ==== //
	loadWpnList();
	initWpnTypeCount();
	InitRotation();

	
	pick_wpn_to_loader();
	wpn_loader_register_allowed_wpn();

	ArrayDestroy(g_ary_iWpnImpluse)
	ArrayDestroy(g_ary_szWpnFamilyName)
	ArrayDestroy(g_ary_bForceAppear)
	ArrayDestroy(g_ary_bUniqueWpn)
	ArrayDestroy(g_ary_szWpnFamilyNameUnique)
	ArrayDestroy(g_ary_iWpnCswId)
	// ============================= //
			
}

public plugin_end(){
	ArrayDestroy(g_ary_iAllowedWpnImpluse);	
}

initWpnTypeCount()
{
	new iKnife, iPistol , iShotGun , iSmg , iRifle, iSniper , iMg

	iKnife = KNIFE_COUNT;

	iPistol = floatround(floatmul(g_fWpnRatio[PISTOL] , float(MAX_ALLOWED)))
	iShotGun = floatround(floatmul(g_fWpnRatio[SHOTGUN] , float(MAX_ALLOWED)))
	iSmg = floatround( floatmul(g_fWpnRatio[SMG]  , float(MAX_ALLOWED)))
	iRifle = floatround( floatmul(g_fWpnRatio[RIFLE] , float(MAX_ALLOWED)))
	iSniper = floatround( floatmul(g_fWpnRatio[SNIPER] , float(MAX_ALLOWED)))
	iMg = floatround( floatmul(g_fWpnRatio[MG] , float(MAX_ALLOWED)))
	
	// console_print(0 , "%i %i %i %i %i %i" , iPistol , iShotGun, iSmg, iRifle, iSniper, iMg)
	
	g_iWpnLoadCount[KNIFE] = iKnife
	g_iWpnLoadCount[PISTOL] = iPistol
	g_iWpnLoadCount[SHOTGUN] = iShotGun
	g_iWpnLoadCount[SMG] = iSmg
	g_iWpnLoadCount[RIFLE] = iRifle
	g_iWpnLoadCount[SNIPER] = iSniper
	g_iWpnLoadCount[MG] = iMg
}

loadWpnList()
{
	// get path from amxx config dir
	new path[128]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn.ini", path) // store complete path to file
	new iWpnTotal = 0;
		
	new tempBuffer[16];

	// check if file exists
	if (file_exists(path))
	{
		new szLineData[512]
		
		// open the file
		new file = fopen(path, "rt")
		
		// check if file valid open, if not stop here
		if (!file) return
		
		// file is not ended
		while (!feof(file))
		{
			new pos;
			// read one line
			fgets(file, szLineData, charsmax(szLineData))
			
			// replace newlines with a null character to prevent headaches
			replace(szLineData, charsmax(szLineData), "^n", "")
			
			// comment or blank line = continue, read a new line!
			if (szLineData[0] == ';' || !szLineData[0]) continue
			
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			ArrayPushCell(g_ary_iWpnImpluse, str_to_num(tempBuffer));
			
			// WpnId
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			ArrayPushString(g_ary_szWpnId, tempBuffer)
			
			// Family name
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			ArrayPushString(g_ary_szWpnFamilyName, tempBuffer);
			
			// bForceAppear
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			ArrayPushCell(g_ary_bForceAppear, str_to_num(tempBuffer));
			
			// Old name , not used
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			
			// CswId
			pos = argparse(szLineData , pos , tempBuffer , charsmax(tempBuffer));
			ArrayPushCell(g_ary_iWpnCswId , str_to_num(tempBuffer));
			
			// Unique or Family
			ArrayGetString(g_ary_szWpnFamilyName, iWpnTotal, tempBuffer , charsmax(tempBuffer));
			if(equali(tempBuffer , "null"))
			{
				ArrayPushCell(g_ary_bUniqueWpn , true);
			}
			else	// Has Family
			{
				ArrayPushCell(g_ary_bUniqueWpn , false);
				// Find which family it belongs to , and then register & add count to that unique family
				new idx = ArrayFindString(g_ary_szWpnFamilyNameUnique, tempBuffer);
				// console_print(0 , "idx : %i for %s" , idx , tempBuffer);
				if(idx < 0)	// New Family name , add to unique 
				{
					// console_print(0, "New Family id : %i for %s" , iWpnFamilyCount , tempBuffer);
					ArrayPushString(g_ary_szWpnFamilyNameUnique, tempBuffer);
					ArrayPushCell(g_ary_iWpnFamilyDeployed , 0);
					// iWpnFamilyCount++;
				}
			}
			
			// next wpn
			iWpnTotal++
		}
		fclose(file)
	}
}

InitRotation()
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
	console_print(0 , "---Picking Sniper--")
	pick_wpn_of_type(SNIPER_TYPE , SNIPER)
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
		new iWpnIdx = ArrayGetCell(ary_iWpnIdx , i)
		console_print(0 , "wpnId in pool : %i , impulse : %i" , iWpnIdx , ArrayGetCell(g_ary_iWpnImpluse , iWpnIdx));
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

pick_wpn_to_loader()
{
	for(new i = 0 ; i < ArraySize(g_ary_iAllowedWpnImpluse) ; i++)
	{
		new iImpulse = ArrayGetCell(g_ary_iAllowedWpnImpluse, i)
		wpn_loader_add_allowed_wpn(iImpulse)
	}
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
			console_print(0 , "WpnId : %i --- %i , %i" , i , iType & (1 << iWpnCswId) , iType == iWpnCswId)
			ArrayPushCell(ary_iWpnIdx , i)
		}
	}
	return ary_iWpnIdx;
}


