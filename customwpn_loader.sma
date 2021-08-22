#include <customwpn_mode_api>
#include "gungame/gungame_wpn_loader.sma"
#include "zombie_stage/zombie_stage_wpn_loader.sma"

#define MAX_WPN_PER_FAMILY 2

// Arrays for wpn precache
new Array:g_ary_WpnEventSc			// The event object held after hooking the event/xxx.sc
new Array:g_ary_iHookedWpnEventSc	// The hooked eventid

// Gun sound override based on weapon shoot event (sc)
public fw_PrecacheEvent_Post(type, const name[])
{
	new szBuffer[64];
	for(new i = 0 ; i < ArraySize(g_ary_WpnEventSc) ; i++)
	{
		ArrayGetString(g_ary_WpnEventSc , i , szBuffer , charsmax(szBuffer));
		if(equali(szBuffer , name))
		{
			g_iWpnEventScId[i] = get_orig_retval();
			// wpn_core_register_wpn_sc(i , get_orig_retval())
		}
	}	
}

loader_load_weapons()
{
	g_ary_iAllowedWpnImpluse = ArrayCreate();
	g_ary_WpnEventSc = ArrayCreate(64);
	g_ary_iHookedWpnEventSc = ArrayCreate();

	read_weapon_list();
	roll_weapons();
	/*
	for(new i = 0 ; i < ArraySize(g_ary_iAllowedWpnImpluse) ; i++)
	{
		console_print(0 , "%i" , ArrayGetCell(g_ary_iAllowedWpnImpluse, i))
	}
	*/
	load_chosen_resource_json();
	// load_chosen_resource_knife_json();
	precache_resources();
	post_load();

	ArrayDestroy(g_ary_iAllowedWpnImpluse);	
}

read_weapon_list()
{
	new iGameMode = wpn_mode_get();
	if (iGameMode == WPN_MODE_NORMAL || iGameMode == WPN_MODE_GUNGAME)
	{
		console_print(0 , "Current Loader GameMode : GunGame (%i)" , iGameMode)
		read_weapon_list_gungame();		// "wpn_loader_gungame"
	}
	else if (iGameMode == WPN_MODE_GUNGAME_SNIPER)
		read_weapon_list_gungame();
	else if (iGameMode == WPN_MODE_ZOMBIE)
	{
		console_print(0 , "Current Loader GameMode : Zombie (%i)" , iGameMode)
		read_weapon_list_zombie_stage();
	}
}

roll_weapons()
{
	new iGameMode = wpn_mode_get();
	if (iGameMode == WPN_MODE_NORMAL || iGameMode == WPN_MODE_GUNGAME)
		roll_weapons_gungame();
	else if (iGameMode == WPN_MODE_GUNGAME_SNIPER)
		roll_weapons_gungame();
	else if (iGameMode == WPN_MODE_ZOMBIE)
		roll_weapons_zombie_stage();
}

public load_chosen_resource_json()
{
	console_print(0 , "Total impulse to load : %i" , ArraySize(g_ary_iAllowedWpnImpluse))
	g_iWpnCount = 0;

	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn_json.ini", path) // store complete path to file
	new JSON:rootJsonObj = json_parse(path, true);

	new JSON:entryJsonObj;
	new iEntryCount = json_array_get_count(rootJsonObj);
	new iImpulse = 0;
	
	new Array:ary_JsonKeySets = get_json_key_set();
	new strBuffer[64];
	for(new i = 0 ; i < iEntryCount ; i++)
	{
		entryJsonObj = json_array_get_value(rootJsonObj , i)
		for(new j = 0 ; j < ArraySize(ary_JsonKeySets) ; j++){

			ArrayGetString(ary_JsonKeySets, j, strBuffer , charsmax(strBuffer));
			if(!json_object_has_value(entryJsonObj , strBuffer))
				console_print(0 , "%s is not found " , strBuffer)
		}
		// ------- Basic Info ------- //
		iImpulse = json_object_get_number(entryJsonObj, JSON_IMPULSE_ID);
		if( ArrayFindValue(g_ary_iAllowedWpnImpluse , iImpulse) == -1)
			continue;
		console_print(0 , "%i = %i" , g_iWpnCount , iImpulse);
		g_iImpulse[g_iWpnCount] = iImpulse;
		/* g_szWpnId[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_WPN_ID, g_szWpnId[g_iWpnCount], charsmax(g_szWpnId[]));
		/* g_szWpnIdOld[g_iWpnCount] = */json_object_get_string(entryJsonObj, JSON_CSW_WPN_ID, g_szWpnIdOld[g_iWpnCount], charsmax(g_szWpnIdOld[]));
		g_iWpnCswId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_CSW_ID);
		/* g_szWpnDisplayName[g_iWpnCount] = */json_object_get_string(entryJsonObj, JSON_DISPLAY_NAME, g_szWpnDisplayName[g_iWpnCount], charsmax(g_szWpnDisplayName[]));
		g_iWpnSpecialId[g_iWpnCount]  = json_object_get_number(entryJsonObj, JSON_SPECIAL_ID);

		// ------- Attributes ------- //
		g_bAutoMode[g_iWpnCount] = json_object_get_bool(entryJsonObj, JSON_AUTO_SHOOT);
		g_bClipReload[g_iWpnCount] = json_object_get_bool(entryJsonObj, JSON_CLIP_RELOAD);

		g_iWpnCost[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_COST);
		g_fWpnDmgMultiplier[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_DMG_MULTIPLIER);
		g_fWpnShootDelay[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_SHOOT_INTERVAL);
		g_iWpnMoveSpeed[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_MOVE_SPEED);
		g_fWpnRecoil[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_RECOIL_MULTIPLIER);
		g_fWpnReloadTime[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_RELOAD_TIME);
		g_iWpnClip[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_CLIP_SIZE);

		// ------------- Model ------------ //
		// --- Sprite --- //
		formatex(strBuffer, charsmax(strBuffer) , "%s%s%s", SPRITE_PREFIX , g_szWpnId[g_iWpnCount], SPRITE_EXT);
		g_szSprite[g_iWpnCount] = strBuffer;

		// ----v----
		json_object_get_string(entryJsonObj, JSON_V_MODEL, strBuffer, charsmax(strBuffer));
		if(equali(strBuffer , "null"))
			formatex(g_szModel_V[g_iWpnCount], charsmax(g_szModel_V[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_V_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_V[g_iWpnCount], charsmax(g_szModel_V[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);
		// ----p----
		json_object_get_string(entryJsonObj, JSON_P_MODEL, strBuffer, charsmax(strBuffer));
		if(equali(strBuffer , "null"))
			formatex(g_szModel_P[g_iWpnCount], charsmax(g_szModel_P[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_P_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_P[g_iWpnCount], charsmax(g_szModel_P[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);
		// ----w----
		json_object_get_string(entryJsonObj, JSON_W_MODEL, strBuffer, charsmax(strBuffer));
		// --Zombie mod doesn't need W model as weapons will disappear upon drop/death
		if(wpn_mode_get() == WPN_MODE_ZOMBIE || equali(strBuffer , "null"))
			formatex(g_szModel_W[g_iWpnCount], charsmax(g_szModel_W[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_W_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_W[g_iWpnCount], charsmax(g_szModel_W[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);

		// ------------- Shoot Sound ------------------ //
		g_bOverride[g_iWpnCount] =  json_object_get_bool(entryJsonObj, JSON_OVERRIDE_SHOOT_SOUND);
		/* g_szWpnShootSound[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_SHOOT_SOUND_PATH, g_szWpnShootSound[g_iWpnCount], charsmax(g_szWpnShootSound[]));
		/* g_szWpnShootSoundSilenced[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_SHOOT_SOUND_SLICENCED_PATH, g_szWpnShootSoundSilenced[g_iWpnCount], charsmax(g_szWpnShootSoundSilenced[]));

		if(g_bOverride[g_iWpnCount])
			formatex(strBuffer, charsmax(strBuffer) , "%s%s%s", SC_PREFIX , g_CSW_SC[g_iWpnCswId[g_iWpnCount]], SC_EXT);
		else
			strBuffer = "null";
		console_print(0 , "%s" , strBuffer);
		ArrayPushString(g_ary_WpnEventSc  , strBuffer);
		ArrayPushCell(g_ary_iHookedWpnEventSc , -1);

		// ---------- Ani Seq ------------ //
		g_iWpnShootSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_SHOOT_SEQ);
		g_iWpnShootSecondaySeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_SHOOT_SEQ_SPECIAL);
		g_iWpnReloadSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_RELOAD_SEQ);
		g_iWpnDrawSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_DRAW_SEQ);

		// ----------- Zombie related param ----------- //
		g_fWpnDmgMultiplierZ[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_Z_DMG_MULTIPLIER);
		g_fWpnKnockback[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_Z_KNOCKBACK);
		g_iWpnZTier[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_Z_TIER);
		g_iWpnZSubType[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_Z_SUBTYPE);

		if(g_iWpnCswId[g_iWpnCount] == CSW_KNIFE)
			load_chosen_resource_knife(g_iImpulse[g_iWpnCount] , g_iWpnCount);
		g_iWpnCount++;

		json_free(entryJsonObj);
    }
    ArrayDestroy(ary_JsonKeySets);
    json_free(rootJsonObj);
}

load_chosen_resource_knife_json()
{
	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn_knife_json.ini", path) // store complete path to file
	new JSON:rootJsonObj = json_parse(path, true);

	new JSON:entryJsonObj;
	new iEntryCount = json_array_get_count(rootJsonObj);
	new iImpulse = 0;
	
	new Array:ary_JsonKeySets = get_json_key_set();
	new strBuffer[64];
	for(new i = 0 ; i < iEntryCount ; i++)
	{
		entryJsonObj = json_array_get_value(rootJsonObj , i)
		for(new j = 0 ; j < ArraySize(ary_JsonKeySets) ; j++){

			ArrayGetString(ary_JsonKeySets, j, strBuffer , charsmax(strBuffer));
			if(!json_object_has_value(entryJsonObj , strBuffer))
				console_print(0 , "%s is not found " , strBuffer)
		}
		// ------- Basic Info ------- //
		iImpulse = json_object_get_number(entryJsonObj, JSON_IMPULSE_ID);
		if( ArrayFindValue(g_ary_iAllowedWpnImpluse , iImpulse) == -1)
			continue;
		console_print(0 , "%i = %i" , g_iWpnCount , iImpulse);
		g_iImpulse[g_iWpnCount] = iImpulse;
		/* g_szWpnId[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_WPN_ID, g_szWpnId[g_iWpnCount], charsmax(g_szWpnId[]));
		/* g_szWpnIdOld[g_iWpnCount] = */json_object_get_string(entryJsonObj, JSON_CSW_WPN_ID, g_szWpnIdOld[g_iWpnCount], charsmax(g_szWpnIdOld[]));
		g_iWpnCswId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_CSW_ID);
		/* g_szWpnDisplayName[g_iWpnCount] = */json_object_get_string(entryJsonObj, JSON_DISPLAY_NAME, g_szWpnDisplayName[g_iWpnCount], charsmax(g_szWpnDisplayName[]));
		g_iWpnSpecialId[g_iWpnCount]  = json_object_get_number(entryJsonObj, JSON_SPECIAL_ID);

		// ------- Attributes ------- //
		g_bAutoMode[g_iWpnCount] = json_object_get_bool(entryJsonObj, JSON_AUTO_SHOOT);
		g_bClipReload[g_iWpnCount] = json_object_get_bool(entryJsonObj, JSON_CLIP_RELOAD);

		g_iWpnCost[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_COST);
		g_fWpnDmgMultiplier[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_DMG_MULTIPLIER);
		g_fWpnShootDelay[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_SHOOT_INTERVAL);
		g_iWpnMoveSpeed[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_MOVE_SPEED);
		g_fWpnRecoil[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_RECOIL_MULTIPLIER);
		g_fWpnReloadTime[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_RELOAD_TIME);
		g_iWpnClip[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_CLIP_SIZE);

		// ------------- Model ------------ //
		// --- Sprite --- //
		formatex(strBuffer, charsmax(strBuffer) , "%s%s%s", SPRITE_PREFIX , g_szWpnId[g_iWpnCount], SPRITE_EXT);
		g_szSprite[g_iWpnCount] = strBuffer;

		// ----v----
		json_object_get_string(entryJsonObj, JSON_V_MODEL, strBuffer, charsmax(strBuffer));
		if(equali(strBuffer , "null"))
			formatex(g_szModel_V[g_iWpnCount], charsmax(g_szModel_V[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_V_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_V[g_iWpnCount], charsmax(g_szModel_V[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);
		// ----p----
		json_object_get_string(entryJsonObj, JSON_P_MODEL, strBuffer, charsmax(strBuffer));
		if(equali(strBuffer , "null"))
			formatex(g_szModel_P[g_iWpnCount], charsmax(g_szModel_P[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_P_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_P[g_iWpnCount], charsmax(g_szModel_P[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);
		// ----w----
		json_object_get_string(entryJsonObj, JSON_W_MODEL, strBuffer, charsmax(strBuffer));
		// --Zombie mod doesn't need W model as weapons will disappear upon drop/death
		if(wpn_mode_get() == WPN_MODE_ZOMBIE || equali(strBuffer , "null"))
			formatex(g_szModel_W[g_iWpnCount], charsmax(g_szModel_W[]) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_W_PREFIX , MDL_DEFAULT[g_iWpnCswId[g_iWpnCount]], MDL_EXT);
		else
			formatex(g_szModel_W[g_iWpnCount], charsmax(g_szModel_W[]) , "%s%s%s", MDL_PREFIX , strBuffer, MDL_EXT);

		// ------------- Shoot Sound ------------------ //
		g_bOverride[g_iWpnCount] =  json_object_get_bool(entryJsonObj, JSON_OVERRIDE_SHOOT_SOUND);
		/* g_szWpnShootSound[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_SHOOT_SOUND_PATH, g_szWpnShootSound[g_iWpnCount], charsmax(g_szWpnShootSound[]));
		/* g_szWpnShootSoundSilenced[g_iWpnCount] = */ json_object_get_string(entryJsonObj, JSON_SHOOT_SOUND_SLICENCED_PATH, g_szWpnShootSoundSilenced[g_iWpnCount], charsmax(g_szWpnShootSoundSilenced[]));

		if(g_bOverride[g_iWpnCount])
			formatex(strBuffer, charsmax(strBuffer) , "%s%s%s", SC_PREFIX , g_CSW_SC[g_iWpnCswId[g_iWpnCount]], SC_EXT);
		else
			strBuffer = "null";
		console_print(0 , "%s" , strBuffer);
		ArrayPushString(g_ary_WpnEventSc  , strBuffer);
		ArrayPushCell(g_ary_iHookedWpnEventSc , -1);

		// ---------- Ani Seq ------------ //
		g_iWpnShootSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_SHOOT_SEQ);
		g_iWpnShootSecondaySeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_SHOOT_SEQ_SPECIAL);
		g_iWpnReloadSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_RELOAD_SEQ);
		g_iWpnDrawSeqId[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_DRAW_SEQ);

		// ----------- Zombie related param ----------- //
		g_fWpnDmgMultiplierZ[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_Z_DMG_MULTIPLIER);
		g_fWpnKnockback[g_iWpnCount] = json_object_get_real(entryJsonObj, JSON_Z_KNOCKBACK);
		g_iWpnZTier[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_Z_TIER);
		g_iWpnZSubType[g_iWpnCount] = json_object_get_number(entryJsonObj, JSON_Z_SUBTYPE);

		if(g_iWpnCswId[g_iWpnCount] == CSW_KNIFE)
			load_chosen_resource_knife(g_iImpulse[g_iWpnCount] , g_iWpnCount);
		g_iWpnCount++;

		json_free(entryJsonObj);
    }
    ArrayDestroy(ary_JsonKeySets);
    json_free(rootJsonObj);
}


public load_chosen_resource_knife(iTargetImpulse , iWpnId)
{
	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn_knife.ini", path) // store complete path to file
	
	// check if file exists
	if (file_exists(path))
	{
		new szLineData[512]
		
		// open the file
		new file = fopen(path, "rt")
		
		// check if file valid open, if not stop here
		if (!file) return PLUGIN_HANDLED;
		
		new tempNumBuffer[64];
		// file is not ended
		while (!feof(file))
		{
			new pos;

			new iImpulse;
			new szHitSound[64];
			new szHitWallSound[64];
			new szSlashSound[64];
			new szStabSound[64];

			// read one line
			fgets(file, szLineData, charsmax(szLineData))
			
			// replace newlines with a null character to prevent headaches
			replace(szLineData, charsmax(szLineData), "^n", "")
			
			// comment or blank line = continue, read a new line!
			if (szLineData[0] == ';' || !szLineData[0]) continue
			
			// Find the impulse
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iImpulse = str_to_num(tempNumBuffer);
			if(iTargetImpulse != iImpulse)
				continue;
			
			// DisplayName: Not used
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));

			pos = argparse(szLineData , pos , szHitSound , charsmax(szHitSound));	
			pos = argparse(szLineData , pos , szHitWallSound , charsmax(szHitWallSound));
			pos = argparse(szLineData , pos , szSlashSound , charsmax(szSlashSound));
			pos = argparse(szLineData , pos , szStabSound , charsmax(szStabSound));

			if(strlen(szHitSound) > 0 && !equali( szHitSound, "null")){
				formatex(g_szKnifeHitSound[iWpnId], charsmax(g_szKnifeHitSound[]), "weapons/knife/%s", szHitSound)
			}

			if(strlen(szHitWallSound) > 0 && !equali( szHitWallSound, "null")){
				formatex(g_szKnifeHitWallSound[iWpnId], charsmax(g_szKnifeHitWallSound[]), "weapons/knife/%s", szHitWallSound)
			}
			
			if(strlen(szSlashSound) > 0 && !equali( szSlashSound, "null")){
				formatex(g_szKnifeSlashSound[iWpnId], charsmax(g_szKnifeSlashSound[]), "weapons/knife/%s", szSlashSound)
			}
			
			if(strlen(szStabSound) > 0 && !equali( szStabSound, "null")){
				formatex(g_szKnifeStabSound[iWpnId], charsmax(g_szKnifeStabSound[]), "weapons/knife/%s", szStabSound)
			}
		}
		
		// close the file
		fclose(file)
	}
	return PLUGIN_HANDLED;
}

precache_resources()
{
	console_print(0 , "Precaching %i wpns" , g_iWpnCount)
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		precache_model(g_szModel_V[i])
		precache_model(g_szModel_P[i])
		precache_model(g_szModel_W[i])
		precache_generic(g_szSprite[i]);

		if(!equali( g_szWpnShootSound[i], "null"))
			precache_sound(g_szWpnShootSound[i]);

		if(!equali( g_szWpnShootSoundSilenced[i], "null"))
			precache_sound(g_szWpnShootSoundSilenced[i]);

		// ------------------ Knives ------------------------- // 
		if(strlen(g_szKnifeHitSound[i]) > 0 && !equali( g_szKnifeHitSound[i], "null"))
			precache_sound(g_szKnifeHitSound[i]);
		
		if(strlen(g_szKnifeHitWallSound[i]) > 0 && !equali( g_szKnifeHitWallSound[i], "null"))
			precache_sound(g_szKnifeHitWallSound[i]);
		
		if(strlen(g_szKnifeSlashSound[i]) > 0 && !equali( g_szKnifeSlashSound[i], "null"))
			precache_sound(g_szKnifeSlashSound[i]);

		if(strlen(g_szKnifeStabSound[i]) > 0 && !equali( g_szKnifeStabSound[i], "null"))
			precache_sound(g_szKnifeStabSound[i]);
	}
	console_print(0 , "Precaching %i wpns....DONE" , g_iWpnCount)
}

/*
precache_special(iSpecialId)
{
	if(iSpecialId == -1)
		return;

	if(iSpecialId == SPECIAL_STARCHASERSR)
		CStarchaserSR_Precache();
	else if(iSpecialId == )
		precache_Balrog9
	
}
*/
post_load()
{
	post_weapon_load_gungame();
	post_weapon_load_zombie_stage();
}

public Array:get_json_key_set()
{
	new Array:ary_JsonKeys = ArrayCreate(32);
	ArrayPushString(ary_JsonKeys, JSON_IMPULSE_ID);
	ArrayPushString(ary_JsonKeys, JSON_WPN_ID);
	ArrayPushString(ary_JsonKeys, JSON_WPN_FAMILY);
	ArrayPushString(ary_JsonKeys, JSON_FORCE_ROLL);
	ArrayPushString(ary_JsonKeys, JSON_CSW_ID);
	ArrayPushString(ary_JsonKeys, JSON_CSW_WPN_ID);
	ArrayPushString(ary_JsonKeys, JSON_DISPLAY_NAME);
	ArrayPushString(ary_JsonKeys, JSON_SPECIAL_ID);
	ArrayPushString(ary_JsonKeys, JSON_V_MODEL);
	ArrayPushString(ary_JsonKeys, JSON_P_MODEL);
	ArrayPushString(ary_JsonKeys, JSON_W_MODEL);
	ArrayPushString(ary_JsonKeys, JSON_AUTO_SHOOT);
	ArrayPushString(ary_JsonKeys, JSON_CLIP_RELOAD);
	ArrayPushString(ary_JsonKeys, JSON_OVERRIDE_SHOOT_SOUND);
	ArrayPushString(ary_JsonKeys, JSON_SHOOT_SOUND_PATH);
	ArrayPushString(ary_JsonKeys, JSON_SHOOT_SOUND_SLICENCED_PATH);
	ArrayPushString(ary_JsonKeys, JSON_COST);
	ArrayPushString(ary_JsonKeys, JSON_CLIP_SIZE);
	ArrayPushString(ary_JsonKeys, JSON_DMG_MULTIPLIER);
	ArrayPushString(ary_JsonKeys, JSON_RELOAD_TIME);
	ArrayPushString(ary_JsonKeys, JSON_SHOOT_INTERVAL);
	ArrayPushString(ary_JsonKeys, JSON_MOVE_SPEED);
	ArrayPushString(ary_JsonKeys, JSON_RECOIL_MULTIPLIER);
	ArrayPushString(ary_JsonKeys, JSON_SHOOT_SEQ);
	ArrayPushString(ary_JsonKeys, JSON_SHOOT_SEQ_SPECIAL);
	ArrayPushString(ary_JsonKeys, JSON_RELOAD_SEQ);
	ArrayPushString(ary_JsonKeys, JSON_DRAW_SEQ);
	ArrayPushString(ary_JsonKeys, JSON_Z_DMG_MULTIPLIER);
	ArrayPushString(ary_JsonKeys, JSON_Z_TIER);
	ArrayPushString(ary_JsonKeys, JSON_Z_KNOCKBACK);
	ArrayPushString(ary_JsonKeys, JSON_Z_SUBTYPE);
	return ary_JsonKeys;
}




/*
public load_chosen_resource()
{
	console_print(0 , "Total impulse to load : %i" , ArraySize(g_ary_iAllowedWpnImpluse))
	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn.ini", path) // store complete path to file
	
	// check if file exists
	if (file_exists(path))
	{
		new szLineData[512]
		
		// open the file
		new file = fopen(path, "rt")
		
		// check if file valid open, if not stop here
		if (!file) return PLUGIN_HANDLED;
		
		new tempNumBuffer[64];
		// file is not ended
		while (!feof(file))
		{
			new pos;

			new szWpnId[32];
			new szWpnIdOld[32];
			new iCswId;
			new iImpulse;
			new szWpnDisplayName[32];
			new szModel_V[64];
			new szModel_P[64];
			new szModel_W[64];
			new szSprite[32];
			new iWpnCost;
			new bool:bAutoMode;
			new bool:bOverride;
			new szShootSound[64];
			new szShootSoundSilenced[64];
			new Float:fWpnReloadTime;
			new Float: fWpnShootDelay;
			new iWpnMoveSpeed
			new Float:fWpnRecoil
			new iWpnShootSeqId
			new iWpnShootSecondaySeqId
			new iWpnReloadSeqId
			new iWpnDrawSeqId

			new weaponid[32];
			new szCharBuffer[64]

			// read one line
			fgets(file, szLineData, charsmax(szLineData))
			
			// replace newlines with a null character to prevent headaches
			replace(szLineData, charsmax(szLineData), "^n", "")
			
			// comment or blank line = continue, read a new line!
			if (szLineData[0] == ';' || !szLineData[0]) continue
			
			// Impulse
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iImpulse = str_to_num(tempNumBuffer);
			
			if( ArrayFindValue(g_ary_iAllowedWpnImpluse , iImpulse) == -1)
			{
				continue;
			}
			console_print(0 , "Loading params for Impulse %i ... " , iImpulse);

			pos = argparse(szLineData , pos , szWpnId , charsmax(szWpnId));	// weaponid
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));	// weapon family
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));	// force appear
			pos = argparse(szLineData , pos , szWpnIdOld , charsmax(szWpnIdOld));	// old weaponid
			
			// CswId
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iCswId = str_to_num(tempNumBuffer)

			// DisplayName: Not used
			pos = argparse(szLineData , pos , szWpnDisplayName , charsmax(szWpnDisplayName));
			
			
			// ======== Models ==========
			// ----v----
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			if(equali(tempNumBuffer , "null"))
				formatex(szModel_V, charsmax(szModel_V) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_V_PREFIX , MDL_DEFAULT[iCswId], MDL_EXT);
			else
				formatex(szModel_V, charsmax(szModel_V) , "%s%s%s", MDL_PREFIX , tempNumBuffer, MDL_EXT);
			
			// ----p----
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			if(equali(tempNumBuffer , "null"))
				formatex(szModel_P, charsmax(szModel_P) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_P_PREFIX , MDL_DEFAULT[iCswId], MDL_EXT);
			else
				formatex(szModel_P, charsmax(szModel_P) , "%s%s%s", MDL_PREFIX , tempNumBuffer, MDL_EXT);
			
			// ----w----
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			// --Zombie mod doesn't need W model as weapons will disappear upon drop/death
			if(wpn_mode_get() == WPN_MODE_ZOMBIE || equali(tempNumBuffer , "null"))
				formatex(szModel_W, charsmax(szModel_W) , "%s%s%s%s", MDL_PREFIX_DEFAULT , MDL_W_PREFIX , MDL_DEFAULT[iCswId], MDL_EXT);
			else
				formatex(szModel_W, charsmax(szModel_W) , "%s%s%s", MDL_PREFIX , tempNumBuffer, MDL_EXT);

			// Sprite
			formatex(szSprite, charsmax(szSprite) , "%s%s%s", SPRITE_PREFIX , weaponid, SPRITE_EXT);
			
			// Cost
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iWpnCost = str_to_num(tempNumBuffer)

			// IsExternal plugin?
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new bool: bExternal = str_to_num(tempNumBuffer) == 1;

			// Auto pistol
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			bAutoMode = str_to_num(tempNumBuffer) == 1;

			// Clip reload
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new bool:bClipReload = str_to_num(tempNumBuffer) == 1;

			// Override Sound?
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			bOverride = str_to_num(tempNumBuffer) == 1;
			
			// Shoot Sound
			pos = argparse(szLineData , pos , szShootSound , charsmax(szShootSound));
			
			// Shoot Sound Silenced
			pos = argparse(szLineData , pos , szShootSoundSilenced , charsmax(szShootSoundSilenced));
			
			if(bOverride)
				formatex(szCharBuffer, charsmax(szCharBuffer) , "%s%s%s", SC_PREFIX , g_CSW_SC[iCswId], SC_EXT);
			else
				szCharBuffer = "null";
			ArrayPushString(g_ary_WpnEventSc  , szCharBuffer);
			ArrayPushCell(g_ary_iHookedWpnEventSc , -1);

			// Damage
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new Float:fWpnDmgMultiplier = str_to_float(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			fWpnReloadTime = str_to_float(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			fWpnShootDelay = str_to_float(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));		////////
			iWpnMoveSpeed = str_to_num(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));		////////
			fWpnRecoil = str_to_float(tempNumBuffer);
			// ==================== Sequences ============================ //
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iWpnShootSeqId = str_to_num(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iWpnShootSecondaySeqId= str_to_num(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iWpnReloadSeqId = str_to_num(tempNumBuffer);
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			iWpnDrawSeqId = str_to_num(tempNumBuffer);

			// ================== Clip size ========================= //
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new iWpnClip = str_to_num(tempNumBuffer)

			// =================== Zombie mode only =================== //
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new Float:fWpnDmgMultiplierZ = str_to_float(tempNumBuffer)

			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new Float:fWpnKnockback = str_to_float(tempNumBuffer)
			
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new iWpnZTier = str_to_num(tempNumBuffer)

			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new iWpnZSubType = str_to_num(tempNumBuffer)

			// =======================================================// 
			pos = argparse(szLineData , pos , tempNumBuffer , charsmax(tempNumBuffer));
			new iWpnSpecialId = str_to_num(tempNumBuffer)


			// ----------From customwpn_variables----------------- //
			g_szWpnId[g_iWpnCount] = szWpnId;
			g_szWpnIdOld[g_iWpnCount] = szWpnIdOld
			g_iWpnCswId[g_iWpnCount] = iCswId
			g_iImpulse[g_iWpnCount] = iImpulse
			g_szWpnDisplayName[g_iWpnCount] = szWpnDisplayName
			g_iWpnCost[g_iWpnCount] =  iWpnCost
			g_bAutoMode[g_iWpnCount] =  bAutoMode
			g_bOverride[g_iWpnCount] =  bOverride
			g_fWpnDmgMultiplier[g_iWpnCount] = fWpnDmgMultiplier
			g_fWpnShootDelay[g_iWpnCount] = fWpnShootDelay
			g_iWpnMoveSpeed[g_iWpnCount] = iWpnMoveSpeed
			g_fWpnRecoil[g_iWpnCount] = fWpnRecoil
			g_fWpnReloadTime[g_iWpnCount] = fWpnReloadTime
			g_iWpnClip[g_iWpnCount] = iWpnClip
			g_bClipReload[g_iWpnCount] = bClipReload
			g_bWpnExternal[g_iWpnCount] = (bExternal == 1)
			g_iWpnSpecialId[g_iWpnCount]  = iWpnSpecialId;

			// ------------- Model ------------ //
			g_szModel_V[g_iWpnCount] = szModel_V;
			g_szModel_P[g_iWpnCount] = szModel_P;
			g_szModel_W[g_iWpnCount] = szModel_W;
			g_szSprite[g_iWpnCount] = szSprite;
			g_szWpnShootSound[g_iWpnCount] = szShootSound;
			g_szWpnShootSoundSilenced[g_iWpnCount] = szShootSoundSilenced

			// ------------ Wpn Ani Seq --------------- //
			g_iWpnShootSeqId[g_iWpnCount] = iWpnShootSeqId
			g_iWpnShootSecondaySeqId[g_iWpnCount] = iWpnShootSecondaySeqId
			g_iWpnReloadSeqId[g_iWpnCount] = iWpnReloadSeqId
			g_iWpnDrawSeqId[g_iWpnCount] = iWpnDrawSeqId

			// ----------- Zombie related param ----------- //
			g_fWpnDmgMultiplierZ[g_iWpnCount] = fWpnDmgMultiplierZ
			g_fWpnKnockback[g_iWpnCount] = fWpnKnockback
			g_iWpnZTier[g_iWpnCount] = iWpnZTier
			g_iWpnZSubType[g_iWpnCount] = iWpnZSubType

			// ----------- Additional resource for Knife -------------- //
			if(iCswId == CSW_KNIFE)
				load_chosen_resource_knife(iImpulse , g_iWpnCount);
			g_iWpnCount++;
			console_print(0 , "Loading params for Impulse %i ... DONE!" , iImpulse);
		}
		
		// close the file
		fclose(file)
	}
	return PLUGIN_HANDLED;
}
*/