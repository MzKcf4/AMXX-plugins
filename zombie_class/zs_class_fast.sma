/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Fast"
new const zombieclass1_model[] = "zombie_skeleton_white"
const zombieclass1_health = 300
const Float:zombieclass1_speed = 310.0
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.3
const iShowOnStage = STAGE_2;
const iHideOnStage = STAGE_3;
const iMaxCount = 2;

new const szPainSound[] = "zombie_plague/resident_hurt1.wav"
new const szPainSound_2[] = "zombie_plague/resident_hurt2.wav"
new const szDeathSound[] = "zombie_plague/resident_death.wav"

public plugin_precache()
{
	register_plugin("[ZS] Class: Fast", VERSION, "ZP Dev Team")
	new iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(iClassId, szDeathSound , szPainSound, szPainSound_2);
	// g_ZombieClassID = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	
	/*
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)

	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
	*/
}
