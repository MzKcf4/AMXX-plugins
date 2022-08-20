/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <zombie_stage_const>
#include <zombie_stage>

#define PLUGIN  "[ZS] Class : Charger"
#define VERSION "1.0"
#define AUTHOR  "Author"

#define COLLIDE_GRACE_TIME 0.5
#define TASK_COLLIDE_GRACE 7542
#define SKILL_COOLDOWN 8.0
#define TASK_COOLDOWN 7414
#define SKILL_RANGE 1500

new Float:g_fChargeVelocity[33][3];
new Float:g_fLastFrameOrigin[33][3];
new bool:g_bInSkill[33];
new bool:g_bInGrace[33];
new bool:g_bSkillReady[33];
new bool:g_bPlayerHitInSingleCharge[33][33];

new const g_szSoundImpact[][] = {"zombie_plague/charger_impact_04.wav"};
new const g_szSoundCharge[][] = {"zombie_plague/charger_charge_01.wav"};
new const g_szSoundHit[][] = {"zombie_plague/charger_smash_02.wav"};

// Zombie Attributes
new const zclass_name[] = "Charger" // name

new const zclass_model[] = "l4d_charger" // model

const zclass_health = 300

const Float:zclass_speed = 230.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 0.5
const iShowOnStage = STAGE_3;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;
new g_iClassId;

new const szPainSound[] = "zombie_plague/charger_pain_03.wav"
new const szPainSound_2[] = "zombie_plague/charger_pain_06.wav"
new const szDeathSound[] = "zombie_plague/charger_die_01.wav"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink") 
	register_touch("player", "*", "fw_PlayerTouch");
}

public plugin_precache()
{
	g_iClassId = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity, zclass_knockback, iShowOnStage , iHideOnStage,  iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);
	new i;
	
	for(i = 0; i < sizeof(g_szSoundImpact); ++i) {
		precache_sound(g_szSoundImpact[i]);
	}
	for(i = 0; i < sizeof(g_szSoundCharge); ++i) {
		precache_sound(g_szSoundCharge[i]);
	}
	for(i = 0; i < sizeof(g_szSoundHit); ++i) {
		precache_sound(g_szSoundHit[i]);
	}
}

public zs_fw_core_turn_to_zombie_post(id)
{
	remove_task(id + TASK_COOLDOWN);
	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		g_bSkillReady[id] = false;
		g_bInSkill[id] = false;
		set_task(8.0*2, "task_cooldown", id+TASK_COOLDOWN)
	}
	else
	{
		g_bSkillReady[id] = false;
		g_bInSkill[id] = false;
	}
}

public zs_fw_core_zombie_killed_post(id)
{
	g_bSkillReady[id] = false;
	g_bInSkill[id] = false;
	g_bInGrace[id] = false;
	remove_task(id + TASK_COOLDOWN);
}

public doCharge(id)
{
	velocity_by_aim(id, 1000, g_fChargeVelocity[id]);
	g_fChargeVelocity[id][2] = -500.0;
	g_bInSkill[id] = true;
	g_fLastFrameOrigin[id][0] = -1.0;
	g_bInGrace[id] = false;
	set_task(SKILL_COOLDOWN, "task_cooldown" , id + TASK_COOLDOWN)
	emit_sound(id, CHAN_STREAM, g_szSoundCharge[random_num(0, charsmax(g_szSoundCharge))], 1.0, ATTN_NORM, 0, PITCH_NORM);
	strip_user_weapons(id);
	for(new i = 0 ; i < 33 ; i++)
	{
		g_bPlayerHitInSingleCharge[id][i] = false;
	}
}

public fw_PlayerPreThink(id)
{
	if(g_bSkillReady[id])
	{
		static iTarget , body;
		get_user_aiming(id, iTarget,body, 1000);
		if(iTarget != 0 && !is_user_bot(iTarget))
		{
			doCharge(id);
			g_bSkillReady[id] = false;
		}

	}
	else if(g_bInSkill[id])
	{

		entity_set_vector(id, EV_VEC_velocity, g_fChargeVelocity[id])

		static newOrigin[3] , Float:fNewOrigin[3] , Float:fDistance;
		get_user_origin(id, newOrigin, 0);
		IVecFVec(newOrigin, fNewOrigin)
		if(g_fLastFrameOrigin[id][0] == -1.0)
		{
			g_fLastFrameOrigin[id] = fNewOrigin	
		}
		else
		{
			// Checks if hit the wall.
			fDistance = vector_distance(fNewOrigin, g_fLastFrameOrigin[id]);
			g_fLastFrameOrigin[id] = fNewOrigin	
			if(fDistance < 3.0 && !g_bInGrace[id])
			{
				g_bInSkill[id] = false;
				emit_sound(id, CHAN_BODY, g_szSoundImpact[random_num(0, charsmax(g_szSoundImpact))], 1.0, ATTN_NORM, 0, PITCH_NORM);
				give_item(id, "weapon_knife");
			}
		}
	}

}

public fw_PlayerTouch(id , touched)
{
	// Hitting someone will cause short pause , make a grace period so it prethink won't count it as "Stopped".
	if(g_bInSkill[id] && is_user_alive(touched))
	{
		static Float:fVelocity[3];
		fVelocity[0] = 0.0;
		fVelocity[1] = 0.0;
		fVelocity[2] = 300.0;
		entity_set_vector(touched, EV_VEC_velocity, fVelocity)
		g_bInGrace[id] = true;
		set_task(COLLIDE_GRACE_TIME, "task_reset_collide_grace" , id + TASK_COLLIDE_GRACE)
		if(!is_user_bot(touched) && !g_bPlayerHitInSingleCharge[id][touched])
		{
			ExecuteHamB(Ham_TakeDamage,touched,id,id,25.0,DMG_BULLET);
			g_bPlayerHitInSingleCharge[id][touched] = true;
		}
	}
}

public task_reset_collide_grace(taskid)
{
	new id = taskid - TASK_COLLIDE_GRACE;
	g_bInGrace[id] = false;
}

public task_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN;
	g_bSkillReady[id] = true;
}