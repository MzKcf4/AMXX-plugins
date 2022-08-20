#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include <zombie_stage_const>
#include <zombie_stage>
#include <cs_ham_bots_api>
#include <amxconst>
#include <xs>
#include <engine>
#include <amxmisc>
#include <reapi>
#include <fakemeta_util>

#define _PLUGIN     "[ZP] Zombie Class: Banshee Zombie"
#define _VERSION                  "1.0"
#define _AUTHOR                "H.RED.ZONE"

enum _Bits {
	HasBats,
	InTrouble,
	Alive,
	Connected,
	Zombie,
	Banshee
}

new const zclass_name[] = "Banshee Zombie"
new const zclass_model[] = "witch_zombi_origin"
const zclass_health = 600
const Float:zclass_speed = 220.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 1.0
const iShowOnStage = STAGE_3;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new const SZ_BAT_MODEL[] = "models/bat_banshee.mdl";
new const SZ_BAT_ENT_CLASS[] = "bat_witch";

#define TIME_REMOVE_BAT_ENT 5.0

enum (+= 110) {
	TASK_REGULAR_TICK,
	TASK_BAT_FLY,
	TASK_HOOK_HUMAN,
	TASK_THROW_BAT,
	TASK_COOLDOWN
}

enum _Cvar {
	_Cooldown,
	_RemoveBet_Time,
	_Hook_speed
} 

new pCvar [_Cvar]

new gClass_BansheeID

new bool:g_bIsBanshee[33];
new Float:g_fSkillCooldown[33];
new g_iBatEntReference[33];

public plugin_init() {
	register_plugin(_PLUGIN, _VERSION, _AUTHOR)

	register_touch(SZ_BAT_ENT_CLASS , "player" , "Fw_Touch_BatEnt");
	register_event("HLTV", "_Event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_Killed, "player", "_FW_Player_Killed", 1)
	RegisterHamBots(Ham_Killed, "_FW_Player_Killed", 1);
	
	pCvar[_Cooldown] = register_cvar("zs_banshee_cooldown","10.0")
}

public plugin_precache() {
	gClass_BansheeID = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity,zclass_knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	// gExplosion_Spr = precache_model("sprites/zerogxplode.spr")
	precache_model(SZ_BAT_MODEL)
}

public zs_fw_core_turn_to_zombie_post(id) {
	if(zs_core_get_player_zombie_class(id) == gClass_BansheeID) {
		g_bIsBanshee[id] = true;
		g_fSkillCooldown[id] = get_pcvar_float(pCvar[_Cooldown]);
	}
	else
	{
		g_bIsBanshee[id] = false;
	}
}

public _FW_Player_Killed(victim, attacker, shouldgib) {
	g_bIsBanshee[victim] = false;
}

public _Event_NewRound(id) {
	for(new i = 0 ; i < 33 ; i++)
	{
		g_bIsBanshee[i] = false;
		if(pev_valid(g_iBatEntReference[i]))
			remove_entity(g_iBatEntReference[i])
		g_iBatEntReference[i] = -1;
	}

	if(!task_exists(TASK_REGULAR_TICK)) {
		set_task_ex(1.0, "Regular_Tick", TASK_REGULAR_TICK, _,_,SetTask_Repeat)
	}
}


public Regular_Tick()
{
	for(new i = 0 ; i < 33 ; i++)
	{
		if(!g_bIsBanshee[i])
			continue;

		if(g_fSkillCooldown[i] > 0)
		{
			g_fSkillCooldown[i] -= 1.0;
			continue;
		}

		new iTarget = Get_Visible_Player(i);
		if(iTarget != -1)
		{
			Throw_Bat_To_Player(i , iTarget);
			g_fSkillCooldown[i] = get_pcvar_float(pCvar[_Cooldown])
		}
	}
}

Throw_Bat_To_Player(iBanshee , iTarget)
{
	static Float:fSrcVec[3] , Float:fDestVec[3] , Float:fDirVelocity[3];
	pev(iBanshee, pev_origin, fSrcVec);
	pev(iTarget, pev_origin, fDestVec);
	new iBatEnt = Create_Bat_Entity(iBanshee);
	// If bat catches any player , this think will be overriden
	SetThink(iBatEnt, "remove_self");
	set_pev(iBatEnt, pev_nextthink, get_gametime() + TIME_REMOVE_BAT_ENT);
	g_iBatEntReference[iBanshee] = iBatEnt;


	xs_vec_sub(fDestVec, fSrcVec, fDirVelocity);
	xs_vec_normalize(fDirVelocity , fDirVelocity);
	xs_vec_mul_scalar(fDirVelocity , 600.0 , fDirVelocity);
	entity_set_vector(iBatEnt, EV_VEC_velocity, fDirVelocity)

	g_fSkillCooldown[iBanshee] = get_pcvar_float(pCvar[_Cooldown]);
}

public remove_self(iBatEnt)
{
	new iBanshee = entity_get_edict(iBatEnt,EV_ENT_owner)
	g_iBatEntReference[iBanshee] = -1;
	remove_entity(iBatEnt);
}

public Fw_Touch_BatEnt(iBatEnt, iPlayerEnt)
{
	if(zs_core_is_zombie(iPlayerEnt) || !is_user_alive(iPlayerEnt))
		return FMRES_IGNORED;

	// So bat ent won't trigger "Touch" event anymore
	entity_set_int(iBatEnt, EV_INT_solid, SOLID_NOT)

	set_pev(iBatEnt, pev_iuser1, iPlayerEnt)
	SetThink(iBatEnt, "BatEnt_DragThink");
	set_pev(iBatEnt, pev_nextthink, get_gametime() + 0.1);
	return FMRES_IGNORED;
}

public BatEnt_DragThink(iBatEnt)
{
	static iPlayerEnt; iPlayerEnt = pev(iBatEnt , pev_iuser1);
	static iBanshee; iBanshee = entity_get_edict(iBatEnt,EV_ENT_owner)
	if(!pev_valid(iPlayerEnt) || !is_user_alive(iPlayerEnt) || !is_user_alive(iBanshee))
	{
		SetThink(iBatEnt , "");
		remove_entity(iBatEnt);
		g_iBatEntReference[iBanshee] = -1;
		return;
	}
	drag_player_to_banshee(iBatEnt, iBanshee , iPlayerEnt);
	// Keep the think drag loop
	set_pev(iBatEnt, pev_nextthink, get_gametime() + 0.1);
}

// Slowly drag player to banshee
drag_player_to_banshee(iBatEnt , iBanshee , iPlayer)
{
	static Float:fPlayerOrigin[3] , Float:fBansheeOrigin[3], Float:fDirVelocity[3];
	pev(iBanshee, pev_origin, fBansheeOrigin);
	pev(iPlayer, pev_origin, fPlayerOrigin);
	
	xs_vec_sub(fBansheeOrigin, fPlayerOrigin, fDirVelocity);
	xs_vec_normalize(fDirVelocity , fDirVelocity);
	xs_vec_mul_scalar(fDirVelocity , 100.0 , fDirVelocity);
	// entity_set_vector(iBatEnt, EV_VEC_velocity, fDirVelocity)
	entity_set_vector(iPlayer, EV_VEC_velocity, fDirVelocity)
	set_pev(iBatEnt, pev_origin, fPlayerOrigin);

	g_fSkillCooldown[iBanshee] = get_pcvar_float(pCvar[_Cooldown])
}

stock Create_Bat_Entity(owner)
{
	new iBatEnt = create_entity("info_target");
	new Float:Origin[3], Float:Angle[3]
	
	entity_get_vector(owner, EV_VEC_v_angle, Angle)
	entity_get_vector(owner, EV_VEC_origin, Origin)
	entity_set_origin(iBatEnt, Origin)
	
	entity_set_string(iBatEnt,EV_SZ_classname, SZ_BAT_ENT_CLASS);
	entity_set_model(iBatEnt, SZ_BAT_MODEL)

	entity_set_int(iBatEnt,EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(iBatEnt, EV_INT_movetype, 5)
	
	entity_set_vector(iBatEnt, EV_VEC_angles, Angle)
	
	entity_set_byte(iBatEnt,EV_BYTE_controller1,125);
	entity_set_byte(iBatEnt,EV_BYTE_controller2,125);
	entity_set_byte(iBatEnt,EV_BYTE_controller3,125);
	entity_set_byte(iBatEnt,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {10.0,10.0,15.0}
	new Float:mins[3] = {-10.0,-10.0,-15.0}
	entity_set_size(iBatEnt,mins,maxs)
	
	entity_set_edict(iBatEnt, EV_ENT_owner, owner)
	
	entity_set_float(iBatEnt,EV_FL_animtime,2.0)
	entity_set_float(iBatEnt,EV_FL_framerate,1.0)
	entity_set_int(iBatEnt,EV_INT_sequence, 0)

	return iBatEnt;
}

stock Get_Visible_Player(iVisor)
{
	static Float:fPlyOrigin[3] , Float:fVisorOrigin;
	for(new i = 0 ; i < 33 ; i++)
	{
		if(zs_core_is_zombie(i) || !is_user_alive(i))
			continue;
		pev(i, pev_origin, fPlyOrigin);
		if(is_in_viewcone(iVisor, fPlyOrigin , true))
		{
			pev(iVisor, pev_origin, fVisorOrigin);
			new tr = create_tr2();
			engfunc(EngFunc_TraceLine, fVisorOrigin, fPlyOrigin, IGNORE_MONSTERS, 0, tr);
			// -- Check obstacles between start and end --
			new Float:fFraction;
			get_tr2(tr, TR_flFraction, fFraction);
			// The point player standing is fully visible
			if(fFraction == 1.0)
			{
				free_tr2(tr);
				return i;
			}
			free_tr2(tr);
		}
	}
	return -1;
}