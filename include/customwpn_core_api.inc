#if defined _customwpn_core_api_included
  #endinput
#endif
#define _customwpn_core_api_included

#pragma library customwpn_core_api

#define GUN_TYPE ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_M249)| (1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))


/**
 * Get total Wpn loaded
 *
 * @return	Total Wpn loaded
 */
native api_core_get_wpn_count()

/**
 * Gives player Wpn of specific wpnId
 *
 * @param playerId	Player index.
 * @param wpnId		Wpn index.
 */
native api_core_give_wpn(playerId , wpnId)

/**
 * Resets the wpn player has , except knife
 *
 * @param playerId	Player index.
 */
native api_core_remove_all_player_wpn(playerId)


/**
 * Resets the Knife wpn the player own
 *
 * @param playerId	Player index.
 */
native api_core_reset_player_knife(playerId)

/**
 * Get Display name of Wpn
 *
 * @return	Display name of Wpn
 */
native api_core_get_wpn_display_name(wpnId , szBuffer[]);

/**
 * Get a random wpnid from Wpn pool
 *
 * @return	A random WpnId
 */
native api_core_get_random_wpnid()

/*
 * Find all Wpn of the required weapon category
 * 
 * @param type:	 The weapon type , check the define.
 * @return	 An Array of WpnIndex , remember to destroy the Array.
 *
 */
native Array:api_core_get_wpn_of_type(type)

native api_core_get_owned_wpnId(iPlayerId , iCswId)

native Float:api_core_get_wpn_knockback(iWpnId)

native bool:api_core_is_weapon_wpn(iPlayerId , iCswId)

/*
 * Gets the cswId of the wpn it replaces
 * 
 * @param wpnId		Wpn index.
 * *@return	 	wpn original cswId
 *
 */
native api_core_get_wpn_cswId(wpnId)

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n{\\ colortbl ;\\ red0\\ green0\\ blue0;}\n\\ viewkind4\\ uc1\\ pard\\ cf1\\ lang1041\\ f0\\ fs16 \n\\ par }
*/
