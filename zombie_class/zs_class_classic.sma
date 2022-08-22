/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Normal Zombie"
new const zombieclass1_model[] = "zombie_swarm"
const zombieclass1_health = 170
const Float:speed = 240.0
const Float:gravity = 1.0
const Float:knockback = 1.0
const iShowOnStage = STAGE_1;
const iHideOnStage = STAGE_4;
const iMaxCount = 99;


new const szPainSound[] = "zombie_plague/zombie_pain2.wav"
new const szPainSound_2[] = "zombie_plague/zombie_pain1.wav"
new const szDeathSound[] = "aslave/slv_die1.wav"

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Classic", VERSION, "ZP Dev Team")
	new iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(iClassId, szDeathSound , szPainSound, szPainSound_2);

}
