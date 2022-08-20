/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <cstrike>
#include <fakemeta_util>
#include <zombie_scenario_utils>
#include <zombie_stage_const>
#include <zombie_stage>
#include <cs_maxspeed_api>
#include <hamsandwich>

#define PLUGIN  "Metatronic Zombie"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Metatronic Zombie"
new const zombieclass1_model[] = "metatronic_zombie"
const zombieclass1_health = 2000
const Float:zombieclass1_speed = 270.0
const Float:zombieclass1_gravity = 0.6
const Float:zombieclass1_knockback = 0.15
const iShowOnStage = STAGE_6;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new const szSkillSound[] = "zombie_plague/metatronic_skill.wav"
new g_iZombieClassId

#define SKILL_RANGE 800
#define TASK_REMOVE_BERSERK 934
#define TASK_REMOVE_COOLDOWN 970
new bool:g_bBerserkReady[33];
new bool:g_bInBerserk[33];
new cvar_berserk_time , cvar_cooldown_berserk;

new const BALL_MODEL[] = "models/w_grenade_infect2.mdl"
new const ENT_CLASS[] = "CLASSBALL_META";

new const szPainSound[] = "zombie_plague/zombi_hurt_heavy_1.wav"
new const szPainSound_2[] = "zombie_plague/zombi_hurt_heavy_2.wav"
new const szDeathSound[] = "zombie_plague/zombi_death_heavy_2.wav"

public plugin_precache()
{
	register_plugin("[ZS] Metatronic Zombie", VERSION, "ZP Dev Team")
	g_iZombieClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity,zombieclass1_knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iZombieClassId, szDeathSound , szPainSound, szPainSound_2);
	precache_sound(szSkillSound)
	precache_model(BALL_MODEL)

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre")
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink") 

	cvar_berserk_time = register_cvar("zs_metatronic_berserk_time", "7.0")
	cvar_cooldown_berserk = register_cvar("zs_metatronic_berserk_cooldown", "15.0")

	register_touch(ENT_CLASS, "*", "Fw_Ball_Touch")

}

public zs_fw_core_turn_to_zombie_post(id)
{
	g_bBerserkReady[id] = false;
	g_bInBerserk[id] = false;
	remove_task(id+TASK_REMOVE_BERSERK)
	remove_task(id+TASK_REMOVE_COOLDOWN)
	if(zs_core_get_player_zombie_class(id) == g_iZombieClassId && is_user_alive(id))
	{
		cs_set_user_armor(id, 2000 , CS_ARMOR_VESTHELM);
		set_task(get_pcvar_float(cvar_cooldown_berserk), "remove_cooldown", id+TASK_REMOVE_COOLDOWN)
	}
}

public fw_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damage_type)
{	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;

	if(zs_core_get_player_zombie_class(victim) != g_iZombieClassId || !is_user_alive(victim))
		return HAM_IGNORED;

	if(g_bInBerserk[victim])
	{
		SetHamParamFloat(4, 1.0)
		fire_ball(victim, attacker)
		return HAM_HANDLED;
	}

	return HAM_IGNORED
}

public FW_PlayerPreThink(id)
{
	if(g_bBerserkReady[id] && is_user_alive(id) && zs_core_get_player_zombie_class(id) == g_iZombieClassId)
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
	zs_core_set_player_knockback(id, 0.02)
	g_bBerserkReady[id] = false;
	g_bInBerserk[id] = true;

	set_task(get_pcvar_float(cvar_berserk_time), "skill_end", id+TASK_REMOVE_BERSERK)
	set_task(get_pcvar_float(cvar_cooldown_berserk), "remove_cooldown", id+TASK_REMOVE_COOLDOWN)

}

public skill_end(taskid)
{
	new id = taskid - TASK_REMOVE_BERSERK;
	fm_set_rendering(id); // reset back to normal
	cs_set_player_maxspeed(id, zombieclass1_speed);
	zs_core_set_player_knockback(id, zombieclass1_knockback)
	g_bInBerserk[id] = false;
}

public remove_cooldown(taskid)	
{
	new id = taskid - TASK_REMOVE_COOLDOWN;
	g_bBerserkReady[id] = true;
}

public fire_ball(fromEnt , toEnt)
{
	if(fromEnt <= 0 || toEnt <= 0)
		return;
	new targetOrigin[3];
	new visorOrigin[3];
	new distance[3];
	new Float:fDistance[3];
	new Float:fAngle[3];
	new Float:fVisorOrigin[3];
	new Float:fNormalized[3];

	get_user_origin(fromEnt , visorOrigin);
	get_user_origin(toEnt , targetOrigin);

	distance[0] = targetOrigin[0] - visorOrigin[0]
	distance[1] = targetOrigin[1] - visorOrigin[1]
	distance[2] = targetOrigin[2] - visorOrigin[2]

	IVecFVec(visorOrigin, fVisorOrigin);
	IVecFVec(distance, fDistance);

	xs_vec_normalize(fDistance, fNormalized)
	new Float:fVelocity[3];
	// xs_vec_mul_scalar(fNormalized, 100.0, fVelocity)
	
	fVelocity[0] = 400.0 * fNormalized[0];
	fVelocity[1] = 400.0 * fNormalized[1];
	fVelocity[2] = 400.0 * fNormalized[2];
	
	new ballEnt = create_ballEnt(fromEnt, fVisorOrigin, fAngle);
	entity_set_vector(ballEnt, EV_VEC_velocity, fVelocity)
	fm_set_rendering(ballEnt,kRenderFxGlowShell,255,255,0,kRenderNormal,8);
}

public create_ballEnt(entOwner , Float:fOrigin[3] , Float:fAngle[3]) {
	new newEntity = create_entity("info_target")

	entity_set_origin(newEntity, fOrigin)
	entity_set_vector(newEntity, EV_VEC_angles, fAngle)
	entity_set_string(newEntity,EV_SZ_classname, ENT_CLASS);
	entity_set_model(newEntity, BALL_MODEL)
	entity_set_int(newEntity,EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(newEntity, EV_INT_movetype, 5)
	
	entity_set_byte(newEntity,EV_BYTE_controller1,125);
	entity_set_byte(newEntity,EV_BYTE_controller2,125);
	entity_set_byte(newEntity,EV_BYTE_controller3,125);
	entity_set_byte(newEntity,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {10.0,10.0,15.0}
	new Float:mins[3] = {-10.0,-10.0,-15.0}
	entity_set_size(newEntity,mins,maxs)
	
	entity_set_edict(newEntity, EV_ENT_owner, entOwner)
	
	entity_set_float(newEntity,EV_FL_animtime,2.0)
	entity_set_float(newEntity,EV_FL_framerate,1.0)
	entity_set_int(newEntity,EV_INT_sequence, 0)

	return newEntity;
}

public Fw_Ball_Touch(ent, touched)
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED;
	
	new owner = entity_get_edict(ent,EV_ENT_owner);
	if(owner == touched)
		return FMRES_IGNORED;
	if(touched > 0 && touched < 33 && !is_user_bot(touched))
	{
		// console_print(0 , "1 remove")
		// fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
		ExecuteHamB(Ham_TakeDamage,touched,owner,owner,15.0,DMG_BULLET);
		remove_entity(ent)
	} else if (touched == 0 || touched >= 33){
		// console_print(0 , "2 remove")
		remove_entity(ent)
	}

	return FMRES_IGNORED;
}
	