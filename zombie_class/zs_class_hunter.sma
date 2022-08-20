/*================================================================================

-----------------------------------
-*- [ZP] Hunter L4D -*-
-----------------------------------

~~~~~~~~~~~~~~~
- Description -
~~~~~~~~~~~~~~~

This zombie has long jumps as well as the popular game L4D2
Well, this time the skill is good and better,
to jump you have to press Ctrl + E and look where you want to jump.

================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zombie_stage_const>
#include <zombie_stage>
#include <zombie_scenario_utils>

/*================================================================================
[Customizations]
=================================================================================*/

// Zombie Attributes
new const zclass_name[] = "Hunter"
new const zclass_model[] = "l4d_hunter"

const zclass_health = 500
const Float:zclass_speed = 230.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 1.0
const iShowOnStage = STAGE_2;
const iHideOnStage = STAGE_4;
const iMaxCount = 1;

new const leap_sound[3][] = { "zombie_plague/hunter_jump.wav", "zombie_plague/hunter_jump1.wav", "zombie_plague/hunter_jump2.wav"}

// Variables
new g_iClassId

// Cvar pointers
new cvar_force, cvar_cooldown , cvar_heigh
new bool:g_bIsHunter[33];
new bool:g_bSkillReady[33];

// Plugin info.
#define PLUG_VERSION "0.2"
#define PLUG_AUTHOR "DJHD!"

#define TASK_COOLDOWN 1034
#define SKILL_RANGE 1500

new const szPainSound[] = "zombie_plague/hunter_painshort_03.wav"
new const szPainSound_2[] = "zombie_plague/hunter_painshort_04.wav"
new const szDeathSound[] = "zombie_plague/hunter_death_07.wav"

/*================================================================================
[Init, CFG and Precache]
=================================================================================*/

public plugin_precache()
{
	// Register the new class and store ID for reference
	g_iClassId = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity, zclass_knockback, iShowOnStage , iHideOnStage,  iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);
	// Sound
	new i
	for(i = 0; i < sizeof leap_sound; i++)
		precache_sound(leap_sound[i])
}

public plugin_init() 
{
	// Plugin Info
	register_plugin("[ZS] Zombie Class: Hunter", PLUG_VERSION, PLUG_AUTHOR)
	
	// Forward
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink") 
	
	// Cvars
	cvar_force = register_cvar("zs_hunter_leap_force", "890") 
	cvar_heigh = register_cvar("zs_hunter_leap_height", "330")
	cvar_cooldown = register_cvar("zs_hunter_leap_cooldown", "4.0")
}

/*================================================================================
[Zombie Plague Forwards]
=================================================================================*/

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		g_bSkillReady[id] = false;
		g_bIsHunter[id] = true;
		set_task(get_pcvar_float(cvar_cooldown)*2, "remove_cooldown", id+TASK_COOLDOWN)
	}
	else
	{
		g_bIsHunter[id] = false;
	}
}

public zs_fw_core_zombie_killed_post(id)
{
	g_bIsHunter[id] = false;
}

/*================================================================================
[Main Forwards]
=================================================================================*/

public fw_PlayerPreThink(id)
{
	if(!g_bIsHunter[id] || !g_bSkillReady[id])
		return;

	if((pev(id, pev_flags) & FL_ONGROUND) && Get_Random_Visible_Alive_PlayerId_Within_Range(id , SKILL_RANGE) != -1)
	{
		static Float:velocity[3]
		velocity_by_aim(id, get_pcvar_num(cvar_force), velocity)
		velocity[2] = get_pcvar_float(cvar_heigh)
		set_pev(id, pev_velocity, velocity)
		
		emit_sound(id, CHAN_STREAM, leap_sound[random_num(0, sizeof leap_sound -1)], 1.0, ATTN_NORM, 0, PITCH_HIGH)
		
		g_bSkillReady[id] = false;
		set_task(get_pcvar_float(cvar_cooldown), "remove_cooldown", id+TASK_COOLDOWN)
	}
}

public remove_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN;

	if(is_user_alive(id))
		g_bSkillReady[id] = true;
}