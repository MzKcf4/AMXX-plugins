/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Fast Zombie +"
new const zombieclass1_model[] = "skeleton_bloody"
const zombieclass1_health = 450
const Float:zombieclass1_speed = 360.0
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.5
const iShowOnStage = STAGE_3;
const iHideOnStage = STAGE_4;
const iMaxCount = 2;
// new g_ZombieClassID;

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Classic", VERSION, "ZP Dev Team")
	zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage,iHideOnStage, iMaxCount)
}
