#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <zombie_stage_const>
#include <zombie_stage>
#include <zombie_scenario_utils>

#define PLUGIN "[ZEVO] Zombie Class: Deimos"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon Leon"

#define ZOMBIE_NAME "Deimos"

// Skill
#define SHOCK_COOLDOWN 5.0
#define SHOCK_DISTANCE 800.0
#define SHOCK_SPEED 1500.0

//Smoker Atributes
new const zclass_name[] = { "Deimos" }
new const zclass_model[] = { "deimos_origin_ev" }
const zclass_health = 2000
const Float:zclass_speed = 250.0
const Float:zclass_gravity = 0.7
const Float:zclass_knockback = 0.3
const iShowOnStage = STAGE_5;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;
new g_iClassId;
new bool:g_bIsDemions[33];

new const ShockModel[] = "models/zombie_plague/deimos_tail.mdl"
// new const DashSound[] = "zombie_plague/zombie/deimos_dash.wav"
new const ShockSound[] = "zombie_plague/deimos_shock.wav"
new const ShockHitSound[] = "zombie_plague/deimos_shock_hit.wav"
new const ShockExpSound[] = "zombie_plague/zombiegrenade_exp.wav"
new const ShockSprite[] = "sprites/zombie_plague/deimos_shock.spr"
new const ShockTrail[] = "sprites/zombie_plague/deimos_trail.spr"

// Task
#define TASK_DASHING 25001
#define TASK_SHOCKING 25002
#define TASK_SHOCK_COOLDOWN 25003

#define SHOCK_CLASSNAME "hiddentail"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new g_ShockSpriteID, g_TrailSprID
new bool:g_bShockReady[33];
new bool:g_bIsHuman[33];

new const szPainSound[] = "zombie_plague/zombi_hurt_heavy_1.wav"
new const szPainSound_2[] = "zombie_plague/zombi_hurt_heavy_2.wav"
new const szDeathSound[] = "zombie_plague/zombi_death_heavy_2.wav"


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
		
	register_think(SHOCK_CLASSNAME, "fw_ShockThink")
	register_touch(SHOCK_CLASSNAME, "*", "fw_ShockTouch")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_logevent("Event_RoundStart", 2, "1=Round_Start") 
}

public plugin_precache()
{
	// Precache
	precache_model(ShockModel)
	precache_sound(ShockSound)
	precache_sound(ShockHitSound)
	precache_sound(ShockExpSound)
	g_ShockSpriteID = precache_model(ShockSprite)
	g_TrailSprID = precache_model(ShockTrail)
	
	g_iClassId = zs_class_zombie_register(zclass_name, zclass_model, zclass_health, zclass_speed, zclass_gravity, zclass_knockback, iShowOnStage , iHideOnStage,  iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);
}

public Event_RoundStart(id)
{
	for(new i = 1 ; i < 33 ; i ++)
	{
		if(zs_core_get_player_zombie_class(i) < 0)
			g_bIsHuman[i] = true;
	}
}

public zs_fw_core_turn_to_zombie_post(id)
{
	remove_task(id+TASK_SHOCK_COOLDOWN)
	g_bShockReady[id] = false;
	g_bIsHuman[id] = false;

	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		g_bIsDemions[id] = true;
		set_task(SHOCK_COOLDOWN * 2, "remove_cooldown", id+TASK_SHOCK_COOLDOWN)
	}
	else
	{
		g_bIsDemions[id] = false;
	}
	
}

public zs_fw_core_zombie_killed_post(id)
{
	g_bIsDemions[id] = false;
	remove_task(id + TASK_SHOCK_COOLDOWN);
}

public remove_cooldown(taskid)
{
	static id; id = taskid - TASK_SHOCK_COOLDOWN;
	g_bShockReady[id] = true;
}

public fw_PlayerPreThink(id)
{
	if(!g_bIsDemions[id])
		return FMRES_IGNORED;

	if(g_bShockReady[id])
	{
		static target; target = Get_Random_Visible_Alive_PlayerId_Within_Range(id , floatround(SHOCK_DISTANCE));
		if(target != -1)
		{
			Skill_Shock(id , target);
		}
	}

	return PLUGIN_CONTINUE
}

public Skill_Shock(id , target)
{
	if(!g_bIsDemions[id])
		return
	
	g_bShockReady[id] = false;
	set_task(SHOCK_COOLDOWN, "remove_cooldown", id + TASK_SHOCK_COOLDOWN);

	// check
	static Float:Origin[3], Float:Angles[3], Float:Vel[3];

	// === Shoot direction === //
	VelocityByAim(id, floatround(SHOCK_SPEED), Vel)
	/*
	new Float:shootDirVelocity[3];
	new targetOrigin[3];
	new visorOrigin[3];

	get_user_origin(id , visorOrigin);
	get_user_origin(target , targetOrigin);

	shootDirVelocity[0] = (targetOrigin[0] - visorOrigin[0]) * SHOCK_SPEED
	shootDirVelocity[1] = (targetOrigin[1] - visorOrigin[1]) * SHOCK_SPEED
	shootDirVelocity[2] = (targetOrigin[2] - visorOrigin[2]) * SHOCK_SPEED
	*/
	// === Others === // 
	pev(id, pev_v_angle, Angles)
	Angles[0] *= -1.0
	get_position(id, 48.0, 0.0, 0.0, Origin)

	// create ent
	static Tail; Tail = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Tail)) return
	
	set_pev(Tail, pev_classname, SHOCK_CLASSNAME)
	engfunc(EngFunc_SetModel, Tail, ShockModel)
	
	set_pev(Tail, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Tail, pev_maxs, Float:{1.0, 1.0, 1.0})
	
	set_pev(Tail, pev_origin, Origin)
	
	set_pev(Tail, pev_movetype, MOVETYPE_FLY)
	set_pev(Tail, pev_gravity, 0.01)
	
	// set_pev(Tail, pev_velocity, shootDirVelocity)
	set_pev(Tail, pev_velocity, Vel)
	set_pev(Tail, pev_owner, id)
	set_pev(Tail, pev_angles, Angles)
	set_pev(Tail, pev_solid, SOLID_TRIGGER)						//store the enitty id
	
	set_pev(Tail, pev_nextthink, get_gametime() + 0.05)
	
	// show trail	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(Tail)				//entity
	write_short(g_TrailSprID)		//model
	write_byte(20)		//10)//life
	write_byte(2)		//5)//width
	write_byte(0)					//r, hegrenade
	write_byte(170)					//g, gas-grenade
	write_byte(255)					//b
	write_byte(250)		//brightness
	message_end()					//move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)
}

public fw_ShockThink(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!g_bIsDemions[id] || entity_range(Ent, id) >= SHOCK_DISTANCE)
	{
		static Float:Origin[3]; pev(Ent, pev_origin, Origin)
		Shock_Explosion(Origin)
		
		set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
		set_pev(Ent, pev_flags, FL_KILLME)
		
		return
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}

public fw_ShockTouch(Ent, id)
{
	if(!pev_valid(Ent))
		return
	
	// Let it go through zombies
	if(id > 0 && !g_bIsHuman[id])
		return;
	// console_print(0, "Hit id : %i , isHuman : %i" , id , g_bIsHuman[id]);

	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
		
	if(id > 0 && id < 33 && g_bIsHuman[id])
	{
		Shock_Explosion(Origin)
				
		static CSW; CSW = get_user_weapon(id)
		static wpnEnt; wpnEnt = cs_get_user_weapon_entity(id)
		if(!(WPN_NOT_DROP & (1<<CSW)))
		{
			cs_set_weapon_ammo(wpnEnt , 0);
		}

		set_pdata_float(id, 108, 0.8)
		
		static MSG; if(!MSG) MSG = get_user_msgid("ScreenShake")
		message_begin(MSG_ONE_UNRELIABLE, MSG, _, id)
		write_short(255<<14)
		write_short(10<<14)
		write_short(255<<14)
		message_end()	
		
		PlaySound(id, ShockHitSound)
	} else {
		Shock_Explosion(Origin)
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	set_pev(Ent, pev_flags, FL_KILLME)
}

public Shock_Explosion(Float:Origin[3])
{
	EmitSound(0, CHAN_BODY, ShockExpSound)
	
	// create effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION) // TE_EXPLOSION
	write_coord_f(Origin[0]) // origin x
	write_coord_f(Origin[1]) // origin y
	write_coord_f(Origin[2]); // origin z
	write_short(g_ShockSpriteID) // sprites
	write_byte(20) // scale in 0.1's
	write_byte(30) // framerate
	write_byte(14) // flags 
	message_end() // message end
}

public EmitSound(id, chan, const file_sound[])
{
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock Get_SpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= (num * 2.0)
	new_velocity[1] *= (num * 2.0)
	new_velocity[2] *= (num / 2.0)
}  

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	//vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}
