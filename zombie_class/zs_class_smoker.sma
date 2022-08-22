#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <engine>
#include <amxmisc>
#include <reapi>
#include <zombie_stage_const>
#include <zombie_stage>
#include <zombie_scenario_utils>

#define PLUGIN "[ZP] Class Smoker"
#define VERSION "1.3"
#define AUTHOR "4eRT"

enum (+= 210) {
	TASK_COOLDOWN
}

//Main Class, modelT & Sprite Beam
new g_iZombieClassId, g_Line
new const generic_models[][] = { "models/player/zombie_smoker/zombie_smokerT.mdl" } 
//Sounds
new g_sndMiss[] = "zombie_plague/Smoker_TongueHit_miss.wav"
new g_sndDrag[] = "zombie_plague/Smoker_TongueHit_drag.wav"

new g_sndWarn[][] = {
						"zombie_plague/smoker_warn_04.wav",
						"zombie_plague/smoker_warn_05.wav",
						"zombie_plague/smoker_warn_06.wav"
					}

//Cvars
new cvar_dragspeed, cvar_cooldown, cvar_dmg2stop;

//Smoker Atributes
new const zclass_name[] = { "Smoker" }
new const zclass_model[] = { "zombie_smoker" }
const zclass_health = 500
const Float:zclass_speed = 230.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 1.0
const iShowOnStage = STAGE_5;
// const iShowOnStage = STAGE_1;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

enum _:DRAG_MODE {
	DRAG_MODE_NONE,
	DRAG_MODE_AIMING,
	DRAG_MODE_DRAGGING
}

//Some vars
new g_iHookingTarget[33]	// [dragger] = victim
new g_ovr_dmg[33]
new bool:g_bIsSmoker[33];
new Float:g_fSkillCooldown[33];
new g_iDragMode[33] = DRAG_MODE_NONE;
new g_iAimTarget[33] = -1;

#define AIM_TIME 2.0
#define TASK_SMOKER_THINK 5500


public plugin_init()
{
	cvar_dragspeed = register_cvar("zs_smoker_dragspeed", "240")
	cvar_cooldown = register_cvar("zs_smoker_cooldown", "10")
	cvar_dmg2stop = register_cvar("zs_smoker_dmg2stop", "50")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	// RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", 1)
	RegisterHamBots(Ham_Killed, "Ham_Player_Killed_Post", 1);

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	register_logevent("Event_RoundStart", 2, "1=Round_Start") 
}

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_iZombieClassId = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity, zclass_knockback, iShowOnStage , iHideOnStage,  iMaxCount)
	precache_sound(g_sndDrag)
	precache_sound(g_sndMiss)
	for(new i = 0 ; i < sizeof(g_sndWarn) ; i++){
		precache_sound(g_sndWarn[i])
	}
	g_Line = precache_model("sprites/zbeam4.spr")
	
	for (new i = 0; i < sizeof generic_models; i++)
		precache_model(generic_models[i])
}

public zs_fw_core_turn_to_zombie_post(id)
{
	remove_task(id+TASK_SMOKER_THINK)
	if(zs_core_get_player_zombie_class(id) == g_iZombieClassId && is_user_alive(id))
	{
		set_task_ex(1.0, "Task_Smoker_Think", id+TASK_SMOKER_THINK, _,_,SetTask_Repeat)
		g_bIsSmoker[id] = true;
		g_fSkillCooldown[id] = get_pcvar_float(cvar_cooldown);
		g_iDragMode[id] = DRAG_MODE_NONE;
	}
	else
	{
		g_bIsSmoker[id] = false;
	}
}


public Task_Smoker_Think(taskId)
{
	new id = taskId - TASK_SMOKER_THINK;
	if(!is_user_alive(id))	return;
	
	console_print(0 , "%i : cooldown : %f , target : %i" , id , g_fSkillCooldown[id], g_iAimTarget[id])
	if(g_fSkillCooldown[id] <= 0.0 && g_iDragMode[id] == DRAG_MODE_NONE)
	{
		new iTarget = Get_Visible_Player(id);	
		if(iTarget != -1)
		{
			g_iDragMode[id] = DRAG_MODE_AIMING;
			g_iAimTarget[id] = iTarget;
			emit_sound(iTarget, CHAN_BODY, g_sndWarn[random_num(0, sizeof(g_sndWarn)-1)] ,  1.0, ATTN_NORM, 0, PITCH_HIGH)
			set_user_frozen(id, true)
		}
	}
	else if(g_iDragMode[id] == DRAG_MODE_AIMING)
	{
		if(Is_Visible(id, g_iAimTarget[id]))
		{
			g_iDragMode[id] = DRAG_MODE_DRAGGING;
			drag_start(id , g_iAimTarget[id]);
		}
		else
		{
			g_iAimTarget[id] = -1;
			g_fSkillCooldown[id] = get_pcvar_float(cvar_cooldown)/2;
			g_iDragMode[id] = DRAG_MODE_NONE;
			set_user_frozen(id, false)
		}
	}

	if(g_fSkillCooldown[id] >= 0)
	{
		g_fSkillCooldown[id] -= 1.0;
	}

}

// Drag player if hit
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{	
	if(!is_user_alive(attacker))
		return HAM_IGNORED;

	// player attacking smoker
	if((zs_core_get_player_zombie_class(victim) == g_iZombieClassId) && g_iHookingTarget[victim] > 0 && !zs_core_is_zombie(attacker) && is_user_alive(attacker))		
	{
		g_ovr_dmg[victim] = g_ovr_dmg[victim] + floatround(damage)
		if (g_ovr_dmg[victim] >= get_pcvar_num(cvar_dmg2stop))
		{
			g_ovr_dmg[victim] = 0
			drag_end(victim)
			return HAM_IGNORED;
		}
	}
	return HAM_IGNORED
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED

	if(g_iHookingTarget[id] != 0)
	{
		set_pev(g_iHookingTarget[id], pev_maxspeed, 1.0)
	}

	return PLUGIN_CONTINUE
}

public drag_start(dragger , victim) // starts drag, checks if player is Smoker, checks cvars
{		
	if(!(zs_core_get_player_zombie_class(dragger) == g_iZombieClassId))
		return PLUGIN_HANDLED;

	g_iHookingTarget[dragger] = victim
	emit_sound(victim, CHAN_BODY, g_sndDrag, 1.0, ATTN_NORM, 0, PITCH_HIGH)

	new parm[2]
	parm[0] = dragger
	parm[1] = victim

	set_task(0.1, "smoker_reelin", dragger, parm, 2, "b")
	harpoon_target(parm)

	set_user_frozen(dragger, true)

	return PLUGIN_CONTINUE
}

public smoker_reelin(parm[]) // dragging player to smoker
{
	new id = parm[0]
	new victim = parm[1]

	if (!g_iHookingTarget[id] || !is_user_alive(victim))
	{
		drag_end(id)
		return
	}

	new Float:fl_Velocity[3]
	new idOrigin[3], vicOrigin[3]

	get_user_origin(victim, vicOrigin)
	get_user_origin(id, idOrigin)
	new distance = get_distance(idOrigin, vicOrigin)

	if (distance > 1) {
		new Float:fl_Time = distance / get_pcvar_float(cvar_dragspeed)

		fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time
		fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time
		fl_Velocity[2] = -200.0 //(idOrigin[2] - vicOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity) //<- rewritten. now uses engine
}

public drag_end(id) // drags end function
{
	set_pev(g_iHookingTarget[id], pev_maxspeed, 250.0)
	g_iHookingTarget[id] = 0
	beam_remove(id)
	remove_task(id)
		
	g_iAimTarget[id] = -1;
	set_user_frozen(id , false);
	g_fSkillCooldown[id] = get_pcvar_float(cvar_cooldown);
	g_iDragMode[id] = DRAG_MODE_NONE;
}

public Ham_Player_Killed_Post(victim, attacker, shouldgib) 
{
	if(zs_core_get_player_zombie_class(victim) == g_iZombieClassId)
	{
		remove_task(victim+TASK_SMOKER_THINK)
		beam_remove(victim)
		if (g_iHookingTarget[victim])
			drag_end(victim)
	}
}

public client_disconnected(id) // if client disconnects drag off
{
	if (id <= 0 || id > 32)
		return
	
	if (g_iHookingTarget[id])
		drag_end(id)
}

public harpoon_target(parm[]) // set beam (ex. tongue:) if target is player
{
	new id = parm[0]
	new hooktarget = parm[1]

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)	// TE_BEAMENTS
	write_short(id)
	write_short(hooktarget)
	write_short(g_Line)	// sprite index
	write_byte(0)	// start frame
	write_byte(0)	// framerate
	write_byte(200)	// life
	write_byte(8)	// width
	write_byte(1)	// noise
	write_byte(155)	// r, g, b
	write_byte(155)	// r, g, b
	write_byte(55)	// r, g, b
	write_byte(90)	// brightness
	write_byte(10)	// speed
	message_end()
}

public beam_remove(id) // remove beam
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)	//TE_KILLBEAM
	write_short(id)	//entity
	message_end()
}

// ============== Tasks ================ 
stock set_user_frozen( id, bool:bFrozen ) {

    if( bFrozen ) 
    	set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FROZEN ) ;
	else
    	set_pev( id, pev_flags, pev( id, pev_flags ) & ~ FL_FROZEN ) ;
}

stock Get_Visible_Player(iVisor)
{
	new iTarget = Get_Random_Player();
	if(iTarget == -1)
		return -1;

	if(Is_Visible(iVisor, iTarget))
			return iTarget;
	return -1;
	/*
	for(new i = 0 ; i < 33 ; i++)
	{
		if(is_user_bot(i) || !is_user_alive(i))
			continue;
		if(Is_Visible(iVisor, i))
			return i;
	}
	return -1;
	*/
}

stock bool:Is_Visible(iVisor, iTarget)
{
	new Float:fTargetOrigin[3] , Float:fVisorOrigin[3];
	pev(iTarget, pev_origin, fTargetOrigin);
	pev(iVisor, pev_origin, fVisorOrigin);
	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, fVisorOrigin, fTargetOrigin, DONT_IGNORE_MONSTERS, iVisor, tr);

	new Float:fraction;
	get_tr2(tr, TR_flFraction, fraction)

	new hit = get_tr2(tr, TR_pHit)
	console_print(0, "%i to %i: fraction %f , pHit %i" , iVisor , iTarget , fraction , hit);

	if(fraction < 0.7)
	{
		free_tr2(tr);
		return false;
	}

	
	if(hit == iTarget)
	{
		free_tr2(tr);
		return true;
	}

	free_tr2(tr);
	
	return false;
}


Get_Random_Player()
{
	new players[MAX_PLAYERS] , iCount;
	get_players_ex(players, iCount ,GetPlayers_ExcludeDead | GetPlayers_ExcludeBots)
	if(iCount == 0)
		return -1;

	return players[random_num(0 , iCount - 1)];
}