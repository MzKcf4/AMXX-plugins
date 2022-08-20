/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <cstrike>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Normal Zombie"
new const zombieclass1_model[] = "zombie_swarm"
const zombieclass1_health = 300
const Float:speed = 245.0
const Float:gravity = 1.0
const Float:knockback = 0.8
const iShowOnStage = STAGE_2;
const iHideOnStage = STAGE_3;
const iMaxCount = 99;
new g_iZombieClassId;

new const szPainSound[] = "zombie_plague/zombie_pain2.wav"
new const szPainSound_2[] = "zombie_plague/zombie_pain1.wav"
new const szDeathSound[] = "aslave/slv_die1.wav"

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Classic", VERSION, "ZP Dev Team")
	g_iZombieClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity , knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iZombieClassId, szDeathSound , szPainSound, szPainSound_2);
	// g_ZombieClassID = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	
	/*
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)

	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
	*/
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iZombieClassId && is_user_alive(id))
	{
		cs_set_user_armor(id, 5 , CS_ARMOR_VESTHELM);
	}
}
