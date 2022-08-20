/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "[ZS] Boomer"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Boomer"
new const zombieclass1_model[] = "zboomer"
const zombieclass1_health = 120
const Float:zombieclass1_speed = 230.0
const Float:zombieclass1_gravity = 0.7
const Float:zombieclass1_knockback = 1.3
const iShowOnStage = STAGE_1;
const iMaxCount = 2;
const iHideOnStage = STAGE_3;
new g_iClassId;

new cvar_exp_radius , cvar_exp_dmg , cvar_knockback
new g_iExplodeSpriteIndex;
new g_iMaxPlayers;

new g_MsgScreenShake;

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Boomer", VERSION, "ZP Dev Team")

	g_iExplodeSpriteIndex = precache_model("sprites/zerogxplode.spr"); 

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")

	g_iMaxPlayers = get_maxplayers();
	cvar_exp_radius = register_cvar("zs_boomer_exp_radius", "140")
	cvar_exp_dmg = register_cvar("zs_boomer_exp_dmg", "30")
	cvar_knockback = register_cvar("zs_boomer_exp_knockback", "500")

  	g_MsgScreenShake = get_user_msgid("ScreenShake");

	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage , iHideOnStage, iMaxCount)


	// g_ZombieClassID = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (zs_core_get_player_zombie_class(victim) != g_iClassId)
		return HAM_IGNORED;

	
	// ======= Explosion effect ============= //
	new Float:fOrigin[3];
	entity_get_vector( victim, EV_VEC_origin, fOrigin)	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc( EngFunc_WriteCoord,fOrigin[0]);
	engfunc( EngFunc_WriteCoord,fOrigin[1]);
	engfunc( EngFunc_WriteCoord,fOrigin[2]);
	write_short(g_iExplodeSpriteIndex);
	write_byte(40); // scale
	write_byte(30); // framerate
	write_byte(0); // flags
	message_end();

	// ======= Damage effect ============= //
	new Float:damage = get_pcvar_float(cvar_exp_dmg);
	new Float:radius = get_pcvar_float(cvar_exp_radius);
	new selfTeam = _:cs_get_user_team(victim);

	new ta, Float:fTargetOrigin[3], Float:distance;

	static Float:fKnockback;
	fKnockback = get_pcvar_float ( cvar_knockback )

	new iVictim = -1;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, radius)))
	{
		if(!is_user_alive(iVictim))
			continue;

		static Float: vecVictimOrigin[3]; pev(iVictim, pev_origin, vecVictimOrigin);
		pev(iVictim, pev_origin, vecVictimOrigin);

		static Float: flDistance; flDistance = get_distance_f(fOrigin, vecVictimOrigin);
		static Float: vecVelocity[3];

		UTIL_GetSpeedVector(fOrigin, vecVictimOrigin, fKnockback * (1.0 - flDistance / radius), vecVelocity);
		set_pev(iVictim, pev_velocity, vecVelocity);

		// Apply dmg to non teamates
		new Float:finalDamage = radius_calc(flDistance,radius,damage,damage/3.0);
		ExecuteHamB(Ham_TakeDamage,iVictim,0,victim,finalDamage,DMG_GRENADE);			

		// If you wanna tweak : https://forums.alliedmods.net/showthread.php?t=99026
		// ======== Shake screen =========== // 
		message_begin(MSG_ONE , g_MsgScreenShake , {0,0,0} ,iVictim)
		write_short( 1<<14 );
		write_short( 1<<14 );
		write_short( 1<<14 );
		message_end();
	}

	SetHamParamInteger(3, GIB_ALWAYS)
	return HAM_HANDLED;
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

stock set_knockback_velocity(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
    new_velocity[0] = origin2[0] - origin1[0]
    new_velocity[1] = origin2[1] - origin1[1]
    new_velocity[2] = origin2[2] - origin1[2]
    new Float:num = floatsqroot(speed*speed /  (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] +  new_velocity[2]*new_velocity[2]))
    new_velocity[0] *= num
    new_velocity[1] *= num
    new_velocity[2] *= num
    
    return 1;
}


