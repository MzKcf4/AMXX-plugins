/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <cstrike>
#include <fakemeta_util>
#include <zombie_scenario_utils>
#include <zombie_stage_const>
#include <zombie_stage>
#include <cs_maxspeed_api>
#include <hamsandwich>

#define PLUGIN  "Tank Zombie+"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Tank Origin"
new const zombieclass1_model[] = "tank_zombi_origin"
const zombieclass1_health = 750
const Float:zombieclass1_speed = 240.0
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 0.2
const iShowOnStage = STAGE_4;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new const szSkillSound[] = "zombie_plague/zombi_pressure.wav"
new g_iZombieClassId
// new g_ZombieClassID;

#define SKILL_RANGE 800
#define TASK_REMOVE_BERSERK 934
#define TASK_REMOVE_COOLDOWN 970
new bool:g_bSkillReady[33];
new cvar_berserk_time , cvar_cooldown;

new const szPainSound[] = "zombie_plague/tank_pain1.wav"
new const szPainSound_2[] = "zombie_plague/tank_pain2.wav"
new const szDeathSound[] = "zombie_plague/tank_death2.wav"


public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Classic", VERSION, "ZP Dev Team")
	g_iZombieClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iZombieClassId, szDeathSound , szPainSound, szPainSound_2);
	precache_sound(szSkillSound)

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink") 

	cvar_berserk_time = register_cvar("zs_tankp_berserk_time", "6.0")
	cvar_cooldown = register_cvar("zs_tankp_berserk_cooldown", "16.0")

}

public zs_fw_core_turn_to_zombie_post(id)
{
	remove_task(id+TASK_REMOVE_BERSERK)
	remove_task(id+TASK_REMOVE_COOLDOWN)
	if(zs_core_get_player_zombie_class(id) == g_iZombieClassId && is_user_alive(id))
	{
		cs_set_user_armor(id, 2000 , CS_ARMOR_VESTHELM);
		set_task(get_pcvar_float(cvar_cooldown), "remove_cooldown", id+TASK_REMOVE_COOLDOWN)
	}
}

public FW_PlayerPreThink(id)
{
	if(g_bSkillReady[id] && is_user_alive(id) && zs_core_get_player_zombie_class(id) == g_iZombieClassId)
	{
		if(Get_Random_Visible_Alive_PlayerId_Within_Range(id , SKILL_RANGE) != -1)
			do_skill(id);
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(zs_core_get_player_zombie_class(victim) == g_iZombieClassId)
	{
		remove_task(victim+TASK_REMOVE_BERSERK)
		skill_end(victim+TASK_REMOVE_BERSERK)
	}
}

do_skill(id)
{
	if(!is_user_alive(id))
		return;

	emit_sound(id, CHAN_VOICE, szSkillSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	fm_set_rendering(id,kRenderFxGlowShell,255 ,0,0,kRenderNormal,8);
	cs_set_player_maxspeed(id, zombieclass1_speed*1.3);
	zs_core_set_player_knockback(id, 0.1)
	g_bSkillReady[id] = false;

	set_task(get_pcvar_float(cvar_berserk_time), "skill_end", id+TASK_REMOVE_BERSERK)
	set_task(get_pcvar_float(cvar_cooldown), "remove_cooldown", id+TASK_REMOVE_COOLDOWN)

}

public skill_end(taskid)
{
	new id = taskid - TASK_REMOVE_BERSERK;
	fm_set_rendering(id); // reset back to normal
	cs_set_player_maxspeed(id, zombieclass1_speed);
	zs_core_set_player_knockback(id, zombieclass1_knockback)
}

public remove_cooldown(taskid)	
{
	new id = taskid - TASK_REMOVE_COOLDOWN;
	g_bSkillReady[id] = true;

}

	
	