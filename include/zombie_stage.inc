/* Sublime AMXX Editor v2.2 */

#if defined _zombie_stage_included
	#endinput
#endif
#define _zombie_stage_included

/* Load custom module ?

#pragma reqlib LIBRARY_NAME
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib LIBRARY_NAME
#endif

*/
#pragma library zombie_stage

/**
 * Registers a custom class which will be added to the zombie classes menu of ZP.
 *
 * Note: The returned zombie class ID can be later used to identify
 * the class when calling the zp_get_user_zombie_class() natives.
 *
 * @param name			Caption to display on the menu.
 * @param model         Model file name , e.g  "zombie_swarm" = "zombie_sawrm/zombie_swarm"
 * @param health		Class health.
 * @param speed			Class maxspeed
 * @param gravity		Class gravity multiplier.
 * @return				An internal zombie class ID, or ZP_INVALID_ZOMBIE_CLASS on failure.
 */
native zs_class_zombie_register(const name[],const model[], health, Float:speed, Float:gravity, Float:knockback, showOnStage , hideOnStage, maxSpawnAllowed)

native zs_class_zombie_register_sound(iClassId, const szDeathPath[] , const szPainPath[] , const szPainPath_2[])

native zs_core_is_zombie(iPlayerId)

native zs_core_get_player_zombie_class(iPlayerId)

native Float:zs_core_get_zombie_class_knockback(iClassId)

native Float:zs_core_get_player_knockback(iPlayerId)

native zs_core_get_zombie_max_health(iPlayerId)

native zs_core_set_player_knockback(iPlayerId , Float:fKnockback)

native zs_core_is_active()