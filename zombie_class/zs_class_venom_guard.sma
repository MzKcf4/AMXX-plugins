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

#define TASK_AURA 1000
#define ID_AURA (taskid - TASK_AURA)

#define TASK_DMG 2000
#define ID_DMG (taskid - TASK_DMG)

#define DMG_TYPE DMG_ACID
#define EXP_RADIUS		250.0
#define EXP_KNOCKBACK	1000.0
#define EXP_DMG			50.0

#define RAD_RADIUS      180.0
#define RAD_DMG         10.0

// Classic Zombie Attributes
new const zombieclass1_name[] = "Venom Guard"
new const zombieclass1_model[] = "zombie_venomguard"
const zombieclass1_health = 400
const Float:speed = 230.0
const Float:gravity = 0.7
const Float:knockback = 0.7
const iShowOnStage = STAGE_3;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new cvar_dmg, cvar_dmg_radius , cvar_aura_color_R, cvar_aura_color_G, cvar_aura_color_B
new g_iClassId;

new const SPR_EXP1[] = "sprites/zombie_plague/ef_boomer_ex.spr"
new const SPR_EXP2[] = "sprites/zombie_plague/spr_boomer.spr"

new	g_iModelIndex_Exp;
new	g_iModelIndex_ExpEffect;

new g_MsgScreenShake;

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Radiation", VERSION, "ZP Dev Team")

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	// RegisterHamBots(Ham_Killed, "fw_PlayerKilled")

	// RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post" , true)
	g_MsgScreenShake = get_user_msgid("ScreenShake");

	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)

	cvar_dmg_radius = register_cvar("zs_venom_radiation_radius", "180")
	cvar_dmg = register_cvar("zs_venom_radiation_dmg", "10")
	cvar_aura_color_R = register_cvar("zs_venom_radiation_aura_color_R", "0")
	cvar_aura_color_G = register_cvar("zs_venom_radiation_aura_color_G", "50")
	cvar_aura_color_B = register_cvar("zs_venom_radiation_aura_color_B", "0")

	g_iModelIndex_Exp = precache_model(SPR_EXP1)
	g_iModelIndex_ExpEffect = precache_model(SPR_EXP2)

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
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_DMG)

	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		set_task(0.1, "set_aura", id+TASK_AURA, _, _, "b")
		set_task(1.0, "do_radius_damage", id+TASK_DMG, _, _, "b")
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (zs_core_get_player_zombie_class(victim) != g_iClassId)
		return HAM_IGNORED;

	remove_task(victim+TASK_AURA)
	remove_task(victim+TASK_DMG)
	do_explosion(victim)
	return HAM_IGNORED;
}



public do_explosion(id)
{
	static Float: vecOrigin[3]; pev(id, pev_origin, vecOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iModelIndex_Exp); // Model Index
	write_byte(2); // Scale
	write_byte(1); // Framerate
	// write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES); // Flags
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iModelIndex_ExpEffect);
	write_byte(6);
	write_byte(255);
	message_end();

	new iVictim = -1;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, EXP_RADIUS)))
	{
		if(!is_user_alive(iVictim))
			continue;

		static Float: vecVictimOrigin[3]; pev(iVictim, pev_origin, vecVictimOrigin);
		pev(iVictim, pev_origin, vecVictimOrigin);

		static Float: flDistance; flDistance = get_distance_f(vecOrigin, vecVictimOrigin);
		static Float: vecVelocity[3];

		UTIL_GetSpeedVector(vecOrigin, vecVictimOrigin, EXP_KNOCKBACK * (1.0 - flDistance / EXP_RADIUS), vecVelocity);
		set_pev(iVictim, pev_velocity, vecVelocity);

		// Apply dmg to non teamates
		new Float:damage = radius_calc(flDistance,EXP_RADIUS,EXP_DMG,EXP_DMG/3.0);
		ExecuteHamB(Ham_TakeDamage,iVictim,0,id,damage,DMG_GRENADE);			

		// If you wanna tweak : https://forums.alliedmods.net/showthread.php?t=99026
		// ======== Shake screen =========== // 
		message_begin(MSG_ONE , g_MsgScreenShake , {0,0,0} ,iVictim)
		write_short( 1<<14 );
		write_short( 1<<14 );
		write_short( 1<<14 );
		message_end();
	}
}

public do_radius_damage(taskid)
{
	// Get player's origin
	// new origin[3]
	// get_user_origin(ID_DMG, origin)

	new id = taskid - TASK_DMG;
	/*
	new Float:damage = get_pcvar_float(cvar_dmg);
	new radius = get_pcvar_num(cvar_dmg_radius);
	*/
	new selfTeam = _:cs_get_user_team(id);
	new Float:origin[3];

	pev(id,pev_origin,origin);

	new ta// , Float:targetOrigin[3], Float:distance;

	new iVictim = -1;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, origin, EXP_RADIUS)))
	{
		// dead, invincible, or self attack that is not allowed
		if(!is_user_alive(iVictim) || pev(iVictim,pev_takedamage) == DAMAGE_NO || (pev(iVictim,pev_flags) & FL_GODMODE) ||(iVictim == id))
			continue;

		// this is a team attack, excluding self attack
		ta = (_:cs_get_user_team(iVictim) == selfTeam);
		if(ta && iVictim != id) 
			continue;

		static Float: vecVictimOrigin[3]; pev(iVictim, pev_origin, vecVictimOrigin);
		pev(iVictim, pev_origin, vecVictimOrigin);

		static Float: flDistance; flDistance = get_distance_f(origin, vecVictimOrigin);
		new Float:damage = radius_calc(flDistance,RAD_RADIUS,RAD_DMG,RAD_DMG/3.0);
		ExecuteHamB(Ham_TakeDamage,iVictim,0,id,damage,DMG_TYPE);
	}
}

/*
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
*/


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
	write_byte(26) // radius
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

stock UTIL_GetSpeedVector(const Float: vecOrigin1[3], const Float: vecOrigin2[3], Float: flSpeed, Float: vecVelocity[3])
{
	vecVelocity[0] = vecOrigin2[0] - vecOrigin1[0];
	vecVelocity[1] = vecOrigin2[1] - vecOrigin1[1];
	vecVelocity[2] = vecOrigin2[2] - vecOrigin1[2];

	new Float: flNum = floatsqroot(flSpeed * flSpeed / (vecVelocity[0] * vecVelocity[0] + vecVelocity[1] * vecVelocity[1] + vecVelocity[2] * vecVelocity[2]));

	vecVelocity[0] *= flNum;
	vecVelocity[1] *= flNum;
	vecVelocity[2] *= flNum;

	return 1;
}

// scale a value equally (inversely?) with the distance that something
// is from the center of another thing. that makes pretty much no sense,
// so basically, the closer we are to the center of a ring, the higher
// our value gets.
//
// EXAMPLE: distance = 60.0, radius = 240.0, maxVal = 100.0, minVal = 20.0
// we are 0.75 (1.0-(60.0/240.0)) of the way to the radius, so scaled with our
// values, it comes out to 80.0 (20.0 + (0.75 * (100.0 - 20.0)))
Float:radius_calc(Float:distance,Float:radius,Float:maxVal,Float:minVal)
{
	if(maxVal <= 0.0) return 0.0;
	if(minVal >= maxVal) return minVal;
	return minVal + ((1.0 - (distance / radius)) * (maxVal - minVal));
}