/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <cs_maxspeed_api>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <zombie_stage_const>
#include <zombie_stage>
#include <cstrike>

#define PLUGIN  "[ZS] New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Witch"
new const zombieclass1_model[] = "l4d_witch"
const zombieclass1_health = 2500
const Float:zombieclass1_speed = 260.0
const Float:zombieclass1_gravity = 0.6
const Float:zombieclass1_knockback = 0.3
const iShowOnStage = STAGE_6;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;
new g_iClassId;

new const szPainSound[] = "zombie_plague/witch_pain_1.wav"
new const szPainSound_2[] = "zombie_plague/witch_pain_2.wav"
new const szDeathSound[] = "zombie_plague/witch_death_1.wav"

public plugin_precache()
{
	register_plugin("[ZS] Class: Zombie: Witch", VERSION, "ZP Dev Team")
	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iClassId && is_user_alive(id))
	{
		cs_set_user_armor(id, 4000 , CS_ARMOR_VESTHELM);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;

	// Attacker is witch
	if(zs_core_get_player_zombie_class(attacker) == g_iClassId)
	{
		SetHamParamFloat(4, 500.0)
		return HAM_IGNORED;
	}

	// Attacker is Human , done to witch
	if(zs_core_get_player_zombie_class(victim) != g_iClassId || !is_user_alive(victim))
		return HAM_IGNORED;

	static iHealth; iHealth = get_user_health(victim);
	// Improve speed & Knockback by 1% per 2% lost health
	static Float:fLostPercent; fLostPercent = 1.0 - floatdiv(float(iHealth), float(zombieclass1_health));
	// console_print(0 , "lost percentage : %f" , fLostPercent);

	if(fLostPercent < 0.01)
		return HAM_IGNORED;

	static Float:fMultiplyBy; fMultiplyBy = 1.0 + (fLostPercent/2);
	cs_set_player_maxspeed(victim, zombieclass1_speed*fMultiplyBy);
	zs_core_set_player_knockback(victim, zombieclass1_knockback - zombieclass1_knockback * (fLostPercent/2) )

	fm_set_rendering(victim,kRenderFxGlowShell,floatround(255*fLostPercent) ,0,0,kRenderNormal,8);
	
	return HAM_IGNORED
}