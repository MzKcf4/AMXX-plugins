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

#define TASK_HEAL 4160
#define ID_HEAL (taskid - TASK_HEAL)
#define HEAL_PERCENT 0.2

#define HEAL_RADIUS		300.0

// Classic Zombie Attributes
new const zombieclass1_name[] = "Voodoo"
new const zombieclass1_model[] = "zombie_heal_host"
const zombieclass1_health = 500
const Float:speed = 230.0
const Float:gravity = 0.7
const Float:knockback = 0.7
const iShowOnStage = STAGE_3;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new g_iClassId;

new const SPR_EXP1[] = "sprites/zombie_plague/zb_restore_health.spr"

new	g_iModelIndex_Effect;

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Voodoo", VERSION, "ZP Dev Team")

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)

	// cvar_dmg_radius = register_cvar("zs_venom_radiation_radius", "180")
	// cvar_dmg = register_cvar("zs_venom_radiation_dmg", "10")

	g_iModelIndex_Effect = precache_model(SPR_EXP1)

}

public zs_fw_core_spawn_post(id)
{
	if(zs_core_get_player_zombie_class(id) != g_iClassId)
	{
		remove_task(id+TASK_HEAL)
	}
}

public zs_fw_core_turn_to_zombie_post(id)
{
	remove_task(id+TASK_HEAL)

	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		set_task(4.0, "do_heal", id+TASK_HEAL, _, _, "b")
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (zs_core_get_player_zombie_class(victim) != g_iClassId)
		return HAM_IGNORED;

	remove_task(victim+TASK_HEAL)
	return HAM_IGNORED;
}

public do_heal(taskid)
{
	new id = taskid - TASK_HEAL;
	static Float: vecOrigin[3];  pev(id, pev_origin, vecOrigin);
	new selfTeam = _:cs_get_user_team(id);
	new iTarget, ta;
	while((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vecOrigin, HEAL_RADIUS)))
	{
		if(!is_user_alive(iTarget))
			continue;

		// this is a team attack, excluding self attack
		ta = (_:cs_get_user_team(iTarget) == selfTeam);
		if(!ta) 
			continue;

		static Float: vecTarget[3];
		pev(iTarget, pev_origin, vecTarget);

		new iMaxHealth = zs_core_get_zombie_max_health(iTarget);
		new iCurrHealth = get_user_health(iTarget);
		new iMaxHealthToRecover = floatround(iMaxHealth * HEAL_PERCENT);
		new iNewHealth = iCurrHealth + iMaxHealthToRecover < iMaxHealth ? iCurrHealth + iMaxHealthToRecover : iMaxHealth
		console_print(0 , "health to recover %i , result %i" , iMaxHealthToRecover , iNewHealth);
		set_user_health(iTarget , iNewHealth);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecTarget[0]);
		engfunc(EngFunc_WriteCoord, vecTarget[1]);
		engfunc(EngFunc_WriteCoord, vecTarget[2]);
		write_short(g_iModelIndex_Effect);
		write_byte(6);
		write_byte(255);
		message_end();
	}
}

public client_disconnected(id)
{
	remove_task(id+TASK_HEAL)
}