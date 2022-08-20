#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>
#include <zombie_stage_const>
#include <zombie_stage>
#include <cs_ham_bots_api>

#define PLUGIN "[ZP] Zombie Class: Light Zombie"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define TASK_INVISIBLE 124798
#define TASK_COOLDOWN 574825
#define TASK_INVISIBLE_SOUND 111111

new g_zclass_light // ID cua class
new bool:can_invisible[33] // Co the su dung Skill neu = True
new bool:is_invisible[33] // Dang tang Hinh neu = True

new const zclass_name[] = "Light Zombie" // Ten
new const zclass_model[] = "speed_zombi_host"// Player Model
new const invisible_sound[] = "zombie_plague/zombi_pressure_female.wav"
const zclass_health = 650 // Mau
const Float:zclass_speed = 300.0 // Toc Do
const Float:zclass_gravity = 0.7 // Trong Luc
const Float:zclass_knockback = 1.2 // Do Day Lui
const iShowOnStage = STAGE_4;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 2;

new cvar_inv_time
new cvar_cooldown
new cvar_invisible_amount

new const szPainSound[] = "zombie_plague/zombi_hurt_female_1.wav"
new const szPainSound_2[] = "zombie_plague/zombi_hurt_female_2.wav"
new const szDeathSound[] = "zombie_plague/zombi_death_female_2.wav"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop", "use_skill")
	
	register_event("HLTV", "Event_NewRound", "1=0", "2=0")

	RegisterHamBots(Ham_TakeDamage, "Ham_TakeDamage_Post" , true);
	RegisterHamBots(Ham_Killed, "Ham_Player_Killed", 1);
	// RegisterHamBots(Ham_Spawn, "Ham_Player_Spawn", 1 );

	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink") 

	cvar_inv_time = register_cvar("zs_light_invisible_time", "5.0")
	cvar_cooldown = register_cvar("zs_light_cooldown", "15.0")
	cvar_invisible_amount = register_cvar("zs_light_invisible_amount", "50")
}

public plugin_precache()
{
	g_zclass_light = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity,zclass_knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_zclass_light, szDeathSound , szPainSound, szPainSound_2);
	precache_sound(invisible_sound)
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(is_user_alive(id) && zs_core_get_player_zombie_class(id) == g_zclass_light)
	{
		can_invisible[id] = true
		is_invisible[id] = false
		remove_task(id+TASK_INVISIBLE)
		remove_task(id+TASK_COOLDOWN)
		remove_task(id+TASK_INVISIBLE_SOUND)
	}
}

public Ham_Player_Killed(victim, attacker, shouldgib)
{
	if(zs_core_get_player_zombie_class(victim) == g_zclass_light)
	{
		remove_task(victim+TASK_INVISIBLE_SOUND)
		//can_invisible[victim] = true
		//is_invisible[victim] = false
	}
}

public Event_NewRound(id) {

	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)

	if(task_exists(id+TASK_INVISIBLE_SOUND)) {
		remove_task(id+TASK_INVISIBLE_SOUND)
	}
	if(task_exists(id+TASK_COOLDOWN)) {
		remove_task(id+TASK_COOLDOWN)
	}
	if(task_exists(id+TASK_INVISIBLE)) {
		remove_task(id+TASK_INVISIBLE)
	}
}

public FW_PlayerPreThink(id)
{
	if(is_user_alive(id) && zs_core_get_player_zombie_class(id) == g_zclass_light && can_invisible[id] && !is_invisible[id])
	{
		if(Get_Random_Visible_Alive_PlayerId_Within_Range(id) != -1)
			do_skill(id);
	}
}

public Ham_TakeDamage_Post(victim, inflictor, attacker, Float:damage, dmgbits)
{
	if(is_user_alive(attacker) && zs_core_get_player_zombie_class(victim) == g_zclass_light)
	{
		use_skill(victim)
	}
}


public use_skill(id)
{
	if(is_user_alive(id) && zs_core_get_player_zombie_class(id) == g_zclass_light)
	{
		if(can_invisible[id] && !is_invisible[id])
		{
			do_skill(id)		
		}

	}
}

Get_Random_Visible_Alive_PlayerId_Within_Range(visor)
{
	static iVisibleCount; iVisibleCount = 0;
	static iVisiblePlayers[33];
	static i;

	for(i = 1 ; i < 33 ; i++)
	{
		if(!is_user_bot(i) && is_user_alive(i) && is_visible(visor, i))
		{
			static visorOrigin[3];
			static targetOrigin[3];
			get_user_origin(visor, visorOrigin)
			get_user_origin(i, targetOrigin)
			static distance; distance = get_distance(visorOrigin, targetOrigin)
			if(distance < 2500){
				iVisiblePlayers[iVisibleCount] = i;
				iVisibleCount++;
			}
		}
	}

	if(iVisibleCount == 0)
		return -1;

	return iVisiblePlayers[random_num(0 , iVisibleCount - 1)];
}

public do_skill(id)
{
	is_invisible[id] = true
	can_invisible[id] = false

	set_user_maxspeed(id, get_user_maxspeed(id) + 50)
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, get_pcvar_num(cvar_invisible_amount))

	emit_sound(id, CHAN_VOICE, invisible_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(get_pcvar_float(cvar_inv_time), "visible", id+TASK_INVISIBLE)
	set_task(2.5, "emit_invisible_sound", id+TASK_INVISIBLE_SOUND, _, _, "b")
}

public emit_invisible_sound(taskid)
{
	static id; id = taskid - TASK_INVISIBLE_SOUND;
	emit_sound(id, CHAN_VOICE, invisible_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public visible(taskid)
{
	new id = taskid - TASK_INVISIBLE
	
	is_invisible[id] = false
	
	set_user_maxspeed(id, get_user_maxspeed(id) - 50)
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)

	remove_task(id+TASK_INVISIBLE_SOUND)
	set_task(get_pcvar_float(cvar_cooldown), "reset_cooldown", id+TASK_COOLDOWN)
}

public reset_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	if(zs_core_get_player_zombie_class(id) == g_zclass_light)
	{		
		can_invisible[id] = true
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
