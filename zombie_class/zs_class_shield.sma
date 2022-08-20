/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <zombie_stage_const>
#include <zombie_stage>


#define VERSION "1.0"


// Classic Zombie Attributes
new const zombieclass1_name[] = "Shield Zombie"
new const zombieclass1_model[] = "zombie_terror"
const zombieclass1_health = 150
const Float:speed = 230.0
const Float:gravity = 1.0
const Float:knockback = 1.0
const iShowOnStage = STAGE_1;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;
new g_iClassId;
new bool:g_bIsShieldZombie[33]

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Shield", VERSION, "ZP Dev Team")
	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)

	RegisterHam(Ham_Killed,"player","Ham_Killed_Pre");
}

public Ham_Killed_Pre(id)
{
	if(g_bIsShieldZombie[id])
	{
		strip_user_weapons(id);
	}
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iClassId && is_user_alive(id))
	{
		g_bIsShieldZombie[id] = true;
		give_item(id, "weapon_shield")
	}
	else
	{
		g_bIsShieldZombie[id] = false;
	}
}
