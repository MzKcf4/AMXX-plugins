/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
// #include <amxmisc>
// #include <cstrike>
#include <engine>
// #include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <vector>
#include <zombie_stage_const>
#include <zombie_stage>
#include <zombie_scenario_utils>
// #include <sqlx>

#define PLUGIN  "[ZS] Class : Ranged"
#define VERSION "1.0"
#define AUTHOR  "Author"

#define TASK_COOLDOWN 98214
#define TASK_SHOOT 97214
#define SKILL_RANGE 1500

// Zombie Attributes
new const zclass_name[] = "Ranged"
new const zclass_model[] = "zombie_swarm"

const zclass_health = 400
const Float:zclass_speed = 230.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 1.0
const iShowOnStage = STAGE_2;
const iHideOnStage = STAGE_4;
const iMaxCount = 1;

new const BALL_MODEL[] = "models/w_grenade_infect2.mdl"
new const ENT_CLASS[] = "CLASSBALL";
new g_iClassId;

new bool:g_bIsRanged[33];
new bool:g_bSkillReady[33];

new g_iShotsLeft[33];
new g_iShotTarget[33];	// Record for tasks.

new const szPainSound[] = "zombie_plague/zombie_pain2.wav"
new const szPainSound_2[] = "zombie_plague/zombie_pain1.wav"
new const szDeathSound[] = "aslave/slv_die1.wav"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	// register_clcmd("ff", "ff")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink") 

	register_touch(ENT_CLASS, "*", "Fw_Ball_Touch")
	// Add your code here...
}

public plugin_precache()
{
	g_iClassId = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity, zclass_knockback, iShowOnStage , iHideOnStage,  iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);
	precache_model(BALL_MODEL)
}

public zs_fw_core_turn_to_zombie_post(id)
{
	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		g_bSkillReady[id] = false;
		g_bIsRanged[id] = true;
		set_task(8.0, "remove_cooldown", id+TASK_COOLDOWN)
	}
	else
	{
		g_bIsRanged[id] = false;
	}
}

public zs_fw_core_zombie_killed_post(id)
{
	g_bSkillReady[id] = false;
	g_bIsRanged[id] = false;
	g_iShotTarget[id] = -1;
	remove_task(id + TASK_SHOOT);
}

public fw_PlayerPreThink(id)
{
	if(!g_bIsRanged[id] || !g_bSkillReady[id])
		return;

	static iTargetId; iTargetId = Get_Random_Visible_Alive_PlayerId_Within_Range(id , SKILL_RANGE);
	if(iTargetId > 0)
	{
		g_iShotTarget[id] = iTargetId;
		g_iShotsLeft[id] = random_num(2, 4);
		g_bSkillReady[id] = false;
		set_task(5.0, "remove_cooldown", id+TASK_COOLDOWN)
		set_task(0.5, "task_fire_balls" , id+TASK_SHOOT);
	}
}

public task_fire_balls(taskid)
{
	new id = taskid - TASK_SHOOT;
	if(g_iShotsLeft[id] > 0)
	{
		g_iShotsLeft[id]--;
		fire_ball(id , g_iShotTarget[id]);
		set_task(0.3, "task_fire_balls", id + TASK_SHOOT);
	}

	if(g_iShotsLeft[id] <= 0)
	{
		g_iShotTarget[id] = -1;
	}
}

public remove_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN;

	if(is_user_alive(id))
		g_bSkillReady[id] = true;
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