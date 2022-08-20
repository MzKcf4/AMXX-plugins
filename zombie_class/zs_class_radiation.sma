/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zombie_stage_const>
#include <zombie_stage>

#define VERSION "1.0"
#define AUTHOR  "Author"

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define TASK_DMG 200
#define ID_DMG (taskid - TASK_DMG)

#define DMG_TYPE DMG_ACID

// Classic Zombie Attributes
new const zombieclass1_name[] = "Radiation Zombie"
new const zombieclass1_model[] = "zombie_resident"
const zombieclass1_health = 550
const Float:speed = 230.0
const Float:gravity = 0.8
const Float:knockback = 1.1
const iShowOnStage = STAGE_1;
const iHideOnStage = STAGE_3;
const iMaxCount = 2;

new cvar_dmg, cvar_dmg_radius , cvar_aura_color_R, cvar_aura_color_G, cvar_aura_color_B
new g_iClassId;
new g_iMaxPlayers;

new const szPainSound[] = "zombie_plague/resident_hurt1.wav"
new const szPainSound_2[] = "zombie_plague/resident_hurt2.wav"
new const szDeathSound[] = "zombie_plague/resident_death.wav"


public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Radiation", VERSION, "ZP Dev Team")

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post" , true)

	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);

	g_iMaxPlayers = get_maxplayers();
	cvar_dmg_radius = register_cvar("zs_radiation_radius", "180")
	cvar_dmg = register_cvar("zs_radiation_dmg", "5")
	cvar_aura_color_R = register_cvar("zs_radiation_aura_color_R", "0")
	cvar_aura_color_G = register_cvar("zs_radiation_aura_color_G", "30")
	cvar_aura_color_B = register_cvar("zs_radiation_aura_color_B", "0")

}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (zs_core_get_player_zombie_class(victim) == g_iClassId)
	{		
		// Remove nemesis aura
		remove_task(victim+TASK_AURA)
		remove_task(victim+TASK_DMG)
	}
}

public zs_fw_core_spawn_post(id)
{
	if(zs_core_get_player_zombie_class(id) != g_iClassId)
	{
		remove_task(id+TASK_AURA)
		remove_task(id+TASK_DMG)
	}
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		set_task(0.1, "set_aura", id+TASK_AURA, _, _, "b")
		set_task(1.0, "do_radius_damage", id+TASK_DMG, _, _, "b")
	}
	else
	{
		remove_task(id+TASK_AURA)
		remove_task(id+TASK_DMG)
	}
}

public do_radius_damage(taskid)
{
	// Get player's origin
	// new origin[3]
	// get_user_origin(ID_DMG, origin)

	new id = taskid - TASK_DMG;
	new Float:damage = get_pcvar_float(cvar_dmg);
	new radius = get_pcvar_num(cvar_dmg_radius);
	new selfTeam = _:cs_get_user_team(id);
	new Float:origin[3];

	pev(id,pev_origin,origin);

	new ta, Float:targetOrigin[3], Float:distance;

	for(new target=1;target<=g_iMaxPlayers;target++)
	{
		// dead, invincible, or self attack that is not allowed
		if(!is_user_alive(target) || pev(target,pev_takedamage) == DAMAGE_NO
		|| (pev(target,pev_flags) & FL_GODMODE) ||(target == id))
			continue;
		
		// this is a team attack, excluding self attack
		ta = (_:cs_get_user_team(target) == selfTeam);
		if(ta && target != id) 
			continue;
		
		pev(target,pev_origin,targetOrigin);
		distance = vector_distance(origin,targetOrigin);
		
		// too far
		if(distance > radius) 
			continue;

		// ExecuteHamB(Ham_TakeDamage,target,ent,owner,damage,DMG_GRENADE);
		ExecuteHamB(Ham_TakeDamage,target,0,id,damage,DMG_TYPE);
	}
}


public fw_TakeDamage_Post(victim, inflictor, attacker, Float:dmg, dmgbits) 
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;

	if(dmgbits == DMG_TYPE)
	{
		set_pdata_float(victim, 108, 1.0, 5); 
	}

	return HAM_HANDLED;
} 


public set_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

public client_disconnected(id)
{
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_DMG)
}

