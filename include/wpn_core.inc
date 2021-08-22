#if defined _wpn_core_included
  #endinput
#endif
#define _wpn_core_included

#pragma library wpn_core


#define GUN_TYPE ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_M249)| (1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

#define MAX_WPN 55

/**
 * Get total Wpn loaded
 *
 * @return	Total Wpn loaded
 */
native wpn_core_get_wpn_count()

/**
 * Gives player Wpn of specific wpnId
 *
 * @param playerId	Player index.
 * @param wpnId		Wpn index.
 */
native wpn_core_give_wpn(playerId , wpnId)

/**
 * Resets the wpn player has , except knife
 *
 * @param playerId	Player index.
 */
native wpn_core_remove_all_player_wpn(playerId)


/**
 * Resets the Knife wpn the player own
 *
 * @param playerId	Player index.
 */
native wpn_core_reset_player_knife(playerId)

/**
 * Get Display name of Wpn
 *
 * @return	Display name of Wpn
 */
native wpn_core_get_wpn_display_name(wpnId)

native wpn_core_get_wpn_display_name_2(wpnId , szBuffer[]);

/**
 * Get a random wpnid from Wpn pool
 *
 * @return	A random WpnId
 */
native wpn_core_get_random_wpnid()

/*
 * Find all Wpn of the required weapon category
 * 
 * @param type:	 The weapon type , check the define.
 * @return	 An Array of WpnIndex , remember to destroy the Array.
 *
 */
native Array:wpn_core_get_wpn_of_type(type)

/*
 * [ZS] Find all Wpn of the required weapon category
 * 
 * @param iTier:	 
 * @return
 *
 */
native Array:wpn_core_get_wpn_of_tier(iTier)

native wpn_core_get_wpn_z_subtype(iWpnId)

native wpn_core_get_owned_wpnId(iPlayerId , iCswId)

native Float:wpn_core_get_wpn_knockback(iWpnId)

native bool:wpn_core_is_weapon_wpn(iPlayerId , iCswId)

/*
 * Gets the cswId of the wpn it replaces
 * 
 * @param wpnId		Wpn index.
 * *@return	 	wpn original cswId
 *
 */
native wpn_core_get_wpn_cswId(wpnId)

native wpn_core_register_completed()

native wpn_core_register_wpn(
	const szWpnId[],
	const szWpnIdOld[],
	iWpnCswId,
	iImpulse,
	const szWpnDisplayName[],
	iWpnCost,
	bool:bAutoMode,
	bool:bOverride,
	Float:fWpnDmgMultiplier,
	Float:fWpnShootDelay,
	iWpnMoveSpeed,
	Float:fWpnRecoil,		
	Float:fWpnReloadTime,
	iWpnClip,
	bool:bClipReload,
	bool:bExternal
	 )

native wpn_core_register_wpn_resource(
	iWpnId,
	const szModel_V[],
	const szModel_P[],
	const szModel_W[],
	const szSprite[],
	const szWpnShootSound[],
	const szWpnShootSoundSilenced[] )

native wpn_core_register_wpn_sequence(
	iWpnId,
	iWpnShootSeqId,
	iWpnShootSecondaySeqId,
	iWpnReloadSeqId,
	iWpnDrawSeqId )

native wpn_core_register_knife_sound(
	iWpnId,
	const szKnifeHitSound[],
	const szKnifeHitWallSound[],
	const szKnifeSlashSound[],
	const szKnifeStabSound[] )

native wpn_core_register_wpn_zparam(
	iWpnId,
	Float:fWpnDmgMultiplierZ,
	Float:fWpnKnockback,
	iWpnZTier,
	iWpnZAmmoPack )

native wpn_core_register_wpn_sc(iWpnId, iEventScId)

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n{\\ colortbl ;\\ red0\\ green0\\ blue0;}\n\\ viewkind4\\ uc1\\ pard\\ cf1\\ lang1041\\ f0\\ fs16 \n\\ par }
*/
