#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <cs_player_models_api>
#include <cs_ham_bots_api>
#include <cs_maxspeed_api>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <zombie_stage_const>
#include <hudmessage_queue>
#include <customwpn_const>
#include <customwpn_core_api>
#include "zombie_stage/zombie_stage_var_func.sma"
#include "zombie_stage/zombie_stage_random_spawn_points.sma"
#include "zombie_stage/zombie_stage_wpn_manager.sma"
#include "zombie_stage/zombie_stage_ammopack.sma"
#include "zombie_stage/zombie_stage_health_regeneration.sma"
#include "zombie_stage/zombie_stage_zombie_random_respawn.sma"
#include "zombie_stage/zombie_stage_human_revive.sma"
#include "zombie_stage/zombie_stage_human_trait.sma"
#include "zombie_stage/zombie_stage_relic.sma"

#define PLUGIN  "Custom Wpn - Zombie Stage"
#define VERSION "1.0"
#define AUTHOR  "MzKc"

#define TASK_PROGRESS   4001
#define TASK_CHANGE_BOT_MODE 80

#define KNIFE_MIN_DIST_ZOMBIE_MOD 64.0

new cvar_init_bot_count;
new cvar_health_multiplier;
new cvar_rest_time;
new cvar_stage_time;
new cvar_start_token;
new cvar_token_kills_per_stage;

#define m_flNextPrimaryAttack	46
#define m_flNextSecondaryAttack	47


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Spawn, "player", "Ham_Spawn_Post", 1);
	RegisterHam(Ham_Killed,"player","Ham_Killed_Pre");
	RegisterHam(Ham_Killed,"player","Ham_Killed_Post", 1);
	RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_Pre");
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre");
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Post" , 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham_Knife_PrimaryAttack_Post" , 1);
	
	// For setting speed
	RegisterHam(Ham_Item_PreFrame,"player","Ham_Item_PreFrame_Post",1);
	register_logevent("Event_RoundStart", 2, "1=Round_Start") 
	register_message(get_user_msgid("ClCorpse"),"message_clcorpse");
	register_forward(FM_EmitSound, "fw_EmitSound");
	// Extended knife slash distance
	register_forward(FM_TraceHull, "fw_TraceHull")
	// ToDo:
	// https://forums.alliedmods.net/showthread.php?t=89863

	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("zs_fw_core_spawn_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_TURN_TO_ZB_POST] = CreateMultiForward("zs_fw_core_turn_to_zombie_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_ROUND_START_POST] = CreateMultiForward("zs_fw_core_round_start_post", ET_IGNORE)
	g_Forwards[FW_ROUND_END_POST] = CreateMultiForward("zs_fw_core_round_end_post", ET_IGNORE)
	g_Forwards[FW_ZOMBIE_KILLED_POST] = CreateMultiForward("zs_fw_core_zombie_killed_post", ET_IGNORE, FP_CELL)

	cvar_init_bot_count = register_cvar("zs_stage_init_bot_count" , "6")
	cvar_health_multiplier = register_cvar("zs_stage_health_multiplier_per_player" , "1.2")
	cvar_rest_time = register_cvar("zs_stage_rest_time" , "30")
	cvar_stage_time = register_cvar("zs_stage_stage_time", "150");
	cvar_start_token = register_cvar("zs_stage_token_start", "2");
	cvar_token_kills_per_stage = register_cvar("zs_stage_token_kills_per_stage", "30");

	register_concmd("zs_start" , "Start_Game")
	g_hudmessage_queue_id = hudmessage_queue_register_left();
	remove_entity_name( "trigger_camera" );
	set_task(1.0,"RemoveDoors");

	register_clcmd( "zsmenu","show_main_menu" );
	// -------------------------------------------------- // 
	plugin_init_random_spawn_points();
	plugin_init_wpn_mgr();
	plugin_init_ammopack();
	plugin_init_zombie_random_respawn();
	plugin_init_relic();
	plugin_init_human_revive();
	plugin_init_human_trait();
}

public RemoveDoors()
{
    new Door;
    while((Door = find_ent_by_class(Door,"func_door_rotating"))) {
        remove_entity(Door);
    }
    while((Door = find_ent_by_class(Door,"func_door"))) {
        remove_entity(Door);
    }
}

public plugin_precache()
{
	precache_generic(HUMAN_WIN_SOUND)
	precache_generic(ZOMBIE_WIN_SOUND)
	precache_generic(ZOMBIE_EVOLVE_SOUND)

	var_func_load_z_params();
	plugin_precache_ammopack();
	plugin_precache_zombie_random_respawn();
	plugin_precache_human_trait();
	plugin_precache_relic();
}

public Start_Game()
{
	g_bModActive = true;
	g_iCurrStage = -1;
	

	for(new i = 0 ; i < MAX_PLAYERS + 1 ; i++)
	{
		g_iPlayerZombieClassPreKill[i] = NO_CLASS;
		g_iPlayerZombieClass[i] = NO_CLASS;
	}

	server_cmd("sypb kickall")
	server_cmd("sypb_quota 0")
	server_cmd("mp_round_infinite 1");
	server_cmd("mp_friendlyfire 0");
	server_cmd("sv_restart 1");
	server_cmd("sypb_gamemod 2");
	server_cmd("wpn_zombie_mode_on")
	server_cmd("sypb_lockzbot 0")
	server_cmd("mp_buytime 0.15")
	server_cmd("mp_autoteambalance 0")
	server_cmd("mp_limitteams 20");
	server_cmd("sv_maxspeed 10000");
	server_cmd("mp_timelimit 9999");
}

public Event_RoundStart(id)
{
	if(!g_bModActive)	return PLUGIN_HANDLED;

	g_bProgressEnd = false;
	g_iCurrStage = STAGE_1;
	Rest_Start();

	remove_task(TASK_PROGRESS)
	set_lights("f")

	ExecuteForward(g_Forwards[FW_ROUND_START_POST], g_ForwardResult)

	g_iTickInterval = PROGRESS_TICK_INTERVAL;
	set_task(float(PROGRESS_TICK_INTERVAL), "tick_progress", TASK_PROGRESS, _, _, "b")

	static players[MAX_PLAYERS] , iCount;
	get_players_ex(players, iCount , GetPlayers_ExcludeBots)
	for(new x = 0 ; x < iCount ; x++)
	{
		cs_set_user_nvg(players[x], 1)
		g_iToken[players[x]] = get_pcvar_num(cvar_start_token);
		g_iPlayerMaxTrait[players[x]] = 1;
	}

	round_start_post_wpn_mgr();
	round_start_post_ammopack();
	round_start_post_human_revive();
	round_start_post_human_trait();
	round_start_post_relic();

	return PLUGIN_HANDLED;
}

public tick_progress()
{
	if(!g_bModActive)	return;

	if(g_iGameState == STATE_REST)
	{
		if(g_iRestTimeRemain > 0)
		{
			g_iRestTimeRemain -= g_iTickInterval;
		}
		else
		{
			Rest_End();
			Stage_Start();
		}
	}
	else if (g_iGameState == STATE_BATTLE)
	{
		if(g_iStageTimeRemain > 0)
		{
			g_iStageTimeRemain -= g_iTickInterval;
			if(g_iKillsInStage < get_pcvar_num(cvar_token_kills_per_stage))
			{
				if(Stock_is_between(g_iStageTimeRemain , 20 , 30))
					set_lights("e")
				else if(Stock_is_between(g_iStageTimeRemain , 10 , 20))
					set_lights("d")
				else if(Stock_is_between(g_iStageTimeRemain , 0 , 10))
					set_lights("c")
			}
		}
		else
		{
			if(g_iKillsInStage < get_pcvar_num(cvar_token_kills_per_stage))
			{
				stage_midnight_start();
			}
			else
			{
				Stage_End();
				Rest_Start();
			}
		}
	}
	set_info_message();
}

Rest_Start()
{
	if(!g_bModActive)	return;

	set_lights("f")
	g_iGameState = STATE_REST;
	g_iRestTimeRemain = get_pcvar_num(cvar_rest_time)
	new bool:bEnoughKills = g_iKillsInStage >= get_pcvar_num(cvar_token_kills_per_stage);
	for(new i = 0 ; i < 33 ; i++)
	{
		g_iToken[i] += 1;
		if(is_user_alive(i) && is_zombie(i))	// Kill all zombies
			user_kill(i);

		if(bEnoughKills)
			g_iToken[i]++;
	}

	rest_start_wpn_mgr();
	rest_start_human_revive();
	rest_start_relic();
}

Rest_End()
{

}

Stage_Start()
{
	set_lights("f")
	g_iKillsInStage = 0;
	g_iGameState = STATE_BATTLE;
	g_iStageTimeRemain = get_pcvar_num(cvar_stage_time);
	
	Update_Usable_Zombie_Class();
	if(g_iCurrStage == STAGE_1)
	{
		new iBotCount = get_pcvar_num(cvar_init_bot_count)
		for(new i = 0 ; i  < iBotCount ; i++)
		{
			server_cmd("sypb_add_t")
		}
	}
	else
	{
		if(g_iCurrStage == STAGE_3 || g_iCurrStage == STAGE_5)
			server_cmd("sypb_add_ct")	// ct , it will be auto transfer to t
	}

	for(new i = 0 ; i < 33 ; i++)
	{
		if(!is_user_alive(i) && is_zombie(i))
			ExecuteHamB(Ham_CS_RoundRespawn,i); // note the B
	}
	
	stage_start_relic();
}

stage_midnight_start()
{
	g_iGameState = STATE_MIDNIGHT;
	set_lights("b")
	for(new i = 0 ; i < 33 ; i++)
	{
		if(is_user_alive(i) && is_zombie(i))
		{
			cs_set_player_maxspeed(i , 1.5 , true);
		}
	}
	set_dhudmessage(255 , 100 , 0 , -1.0 , 0.70 , 1 , .fxtime = 5.0, .holdtime = 5.0, .fadeintime = 1.0, .fadeouttime = 1.0)
	show_dhudmessage(0, "Zombies are enraged");
}

stage_midnight_end()
{
	set_lights("f")
	Stage_End();
	Rest_Start();
}

Stage_End()
{
	// Only end if it's after the final stage
	if (g_iCurrStage >= MAX_STAGE)
	{
		Game_End();
	}

	if(g_iCurrStage == STAGE_2 || g_iCurrStage == STAGE_4 || g_iCurrStage == STAGE_7)
	{
		for(new i = 0 ; i < 33 ; i++)
		{
			g_iPlayerMaxTrait[i]++;
		}
	}
	g_iCurrStage++;


	// ToDo: Point to token conversion
}

Game_End()
{
	round_end(WINNER_HUMAN);
}

public set_info_message()
{
	set_hudmessage(255, 0, 0, 0.01, 0.4, 0, 0.0, g_fTickInterval, 0.1, 0.2, 2)
	static szMsg[32];
	if(g_iGameState == STATE_REST)
		formatex(szMsg, charsmax(szMsg) , "Stage %i in : %i", g_iCurrStage, g_iRestTimeRemain)
	else if(g_iGameState == STATE_BATTLE)
		formatex(szMsg, charsmax(szMsg) , "Stage %i : %i (Kills %i/%i)" ,g_iCurrStage, g_iStageTimeRemain, g_iKillsInStage, get_pcvar_num(cvar_token_kills_per_stage))
	else if(g_iGameState == STATE_MIDNIGHT)
		formatex(szMsg, charsmax(szMsg) , "Stage %i : Midnight (Kills %i/%i)" ,g_iCurrStage, g_iKillsInStage, get_pcvar_num(cvar_token_kills_per_stage))
	hudmessage_queue_set_player_message_left(g_hudmessage_queue_id, 0, szMsg);	
	return PLUGIN_HANDLED;
}

Update_Usable_Zombie_Class()
{
	ArrayDestroy(g_ZombieClassUsable);
	g_ZombieClassUsable = ArrayCreate();

	for(new zid = 0 ; zid < g_iZombieClassCount ; zid++)
	{
		new iHideOnStage = ArrayGetCell(g_ZombieClassHideOnStage, zid);
		new iShowOnStage = ArrayGetCell(g_ZombieClassShowOnStage, zid);
		if(iShowOnStage <= g_iCurrStage && (iHideOnStage > g_iCurrStage))
		{
			ArrayPushCell(g_ZombieClassUsable, zid)
		}
	}
	set_dhudmessage(255 , 100 , 0 , -1.0 , 0.70 , 1 , .fxtime = 5.0, .holdtime = 5.0, .fadeintime = 1.0, .fadeouttime = 1.0)
	show_dhudmessage(0, "Zombies have evolved");
	for(new i = 1 ; i < 33 ; i++)
	{
		client_cmd(i, "spk %s", ZOMBIE_EVOLVE_SOUND);
	}
}


public Ham_TraceAttack_Pre(Victim, Attacker, Float:Damage, Float:Direction[3], Traceresult, DamageBits)
{
	if(is_zombie(Attacker))
	{
		if(get_tr2(Traceresult, TR_iHitgroup) == HIT_HEAD)
		{
			set_tr2(Traceresult, TR_iHitgroup, HIT_STOMACH);
		}
		
	}

	new Float:newDmg = Ham_TraceAttack_Pre_Relic(Victim, Attacker, Damage, Direction, Traceresult, DamageBits);
	newDmg = Ham_TraceAttack_Pre_Human_Trait(Victim, Attacker, newDmg, Direction, Traceresult, DamageBits)
	SetHamParamFloat(3, newDmg)

	return HAM_IGNORED;
}

public Ham_Knife_PrimaryAttack_Post(ent)
{
	static ownerId; ownerId = pev(ent, pev_owner)
	if(is_zombie(ownerId))
	{
		set_pdata_float(ent, m_flNextPrimaryAttack, 1.5);
		set_pdata_float(ent, m_flNextSecondaryAttack, 1.5);
	}
	return HAM_IGNORED
}

public Ham_TakeDamage_Pre(Victim, iInflictor, Attacker, Float:fDamage, m_Damagebits)
{
	static Float:newDmg;

	newDmg = Ham_TakeDamage_Pre_Human_Trait(Victim, iInflictor, Attacker, fDamage, m_Damagebits);
	newDmg = Ham_TakeDamage_Pre_Relic(Victim, iInflictor, Attacker, newDmg, m_Damagebits);
	SetHamParamFloat(4, newDmg)
}

public Ham_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{	
	if(is_zombie(victim))
	{
		if(!is_user_connected(attacker))
			return;

		static szZombieInfo[128], szZombieName[24] , health;

		ArrayGetString(g_ZombieClassName, g_iPlayerZombieClassPreKill[victim], szZombieName, charsmax(szZombieName))
		health = get_user_health(victim);
		health = health < 0 ? 0 : health;
		// e.g : "Classic Zombie : 500 hp"
		formatex(szZombieInfo, charsmax(szZombieInfo),  "%s : %i hp ( -%i )^n", szZombieName , health , floatround(damage));
		set_hudmessage(255, 255, 0, -1.0, 0.6, 0, 0.1, 0.5, 0.1, 0.1, 1)
		show_hudmessage(attacker, szZombieInfo)
	}

	Ham_TakeDamage_Post_Health_Regen(victim /*, inflictor, attacker, damage, damage_type */)
	Ham_TakeDamage_Post_Human_Trait(victim, inflictor, attacker,damage, damage_type)
}

// This is fired when slashing knife
public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	

	if(get_user_weapon(id) != CSW_KNIFE || is_user_bot(id))
		return FMRES_IGNORED

	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, KNIFE_MIN_DIST_ZOMBIE_MOD , v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

// ================== Spawn related ============================== //

public Ham_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;

	cs_set_user_money(id, 0)
	if(is_zombie(id))
	{
		strip_zombie_weapons(id)
		set_random_zombie_class(id);
		ExecuteForward(g_Forwards[FW_USER_TURN_TO_ZB_POST], g_ForwardResult, id)
	}
	else
	{
		cs_set_user_armor(id, 50, CS_ARMOR_VESTHELM)
	}

	return HAM_HANDLED;
}

public Ham_Killed_Pre(victim, attacker, shouldgib)
{
	if(!g_bModActive)
		return HAM_IGNORED;

	Ham_Killed_Pre_Human_Revive(victim, attacker, shouldgib)
	Ham_Killed_Pre_Human_Trait(victim, attacker, shouldgib)
	return HAM_IGNORED;
}

public Ham_Killed_Post(id, attacker, shouldgib)
{
	if(!g_bModActive)
		return HAM_IGNORED;

	if(is_zombie(id))
	{
		g_iPlayerZombieClass[id] = NO_CLASS;
		Ham_Killed_Post_Zombie_Random_Spawn(id /*, attacker , shouldgib */);
		ExecuteForward(g_Forwards[FW_ZOMBIE_KILLED_POST], g_ForwardResult, id);
		g_iKillsInStage++;
		if(g_iGameState == STATE_MIDNIGHT && g_iKillsInStage >= get_pcvar_num(cvar_token_kills_per_stage))
		{
			stage_midnight_end();
		}
	}

	if(get_alive_human_count() == 0)
	{
		round_end(WINNER_ZOMBIE)
	}

	Ham_Killed_Post_AmmoPack(id /*, attacker , shouldgib */);


	return HAM_IGNORED;
}


public fw_EmitSound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED;

	if(is_zombie(id))
	{
		static szSoundPath[128];

		// Pain
		if (sample[1] == 'l' && sample[2] == 'a' && sample[3] == 'y' && ( (containi(sample, "bhit") != -1) || (containi(sample, "pain") != -1) || (containi(sample, "shot") != -1)))
		{
			if(random_num(1, 100) < 50){
				if(random_num(1, 100) < 50)
					ArrayGetString(g_ZombieClassPainSound, g_iPlayerZombieClass[id], szSoundPath, charsmax(szSoundPath));
				else
					ArrayGetString(g_ZombieClassPainSound_2, g_iPlayerZombieClass[id], szSoundPath, charsmax(szSoundPath));

				if(strlen(szSoundPath) > 0){
					emit_sound(id, CHAN_VOICE, szSoundPath, volume, attn, flag, pitch);
				}
			}
			return FMRES_SUPERCEDE;
		} 
		else if (sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
		{
			// Death
			ArrayGetString(g_ZombieClassDeathSound, g_iPlayerZombieClass[id], szSoundPath, charsmax(szSoundPath));
			if(strlen(szSoundPath) > 0){
				emit_sound(id, CHAN_VOICE, szSoundPath, volume, attn, flag, pitch);
			}
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

// This is currently used for setting speed
public Ham_Item_PreFrame_Post(id)
{
	Ham_Item_PreFrame_Post_Relic(id)

	return HAM_IGNORED;
}

get_alive_human_count()
{
	new players[MAX_PLAYERS] , iCount;
	get_players_ex(players, iCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT")
	return iCount;
}

get_alive_zombie_count()
{
	new players[MAX_PLAYERS] , iCount;
	get_players_ex(players, iCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST")
	return iCount;
}

public round_end(winner)
{
	if(winner == WINNER_HUMAN)
	{
		client_cmd(0 , "spk %s" , HUMAN_WIN_SOUND);
		for(new i = 0 ; i < 33 ; i++)
		{
			g_iToken[i] += 1;
			if(is_user_alive(i) && is_zombie(i))	// Kill all zombies
				user_kill(i);
		}

	}
	else
	{
		client_cmd(0 , "spk %s" , ZOMBIE_WIN_SOUND);
	}
	g_bModActive = false;
	g_iGameState = STATE_STOP;
}

set_random_zombie_class(id)
{
	if(!is_zombie(id) || !g_bModActive)
		return PLUGIN_HANDLED;

	new iClassId;
	new i = 0;
	do{
		static iCellIdx; iCellIdx = random_num(0, ArraySize(g_ZombieClassUsable) - 1);
		iClassId = ArrayGetCell(g_ZombieClassUsable , iCellIdx);
		i++;
		/*
		console_print(0 , "=================");
		console_print(0 , "Spawned Count : %i" , Get_Spawned_Zombie_Class_Of(iClassId))
		console_print(0 , "Max Count : %i" , ArrayGetCell(g_ZombieClassMaxSpawned , iClassId))
		*/

	} while(Get_Spawned_Zombie_Class_Of(iClassId) >= ArrayGetCell(g_ZombieClassMaxSpawned , iClassId) && i < 50)
	new szModel[128];
	ArrayGetString(g_ZombieClassModelName , iClassId , szModel , charsmax(szModel))
	cs_set_player_model(id,szModel);

	new iBaseHealth = ArrayGetCell(g_ZombieClassBaseHealth, iClassId);
	new Float:fHealth = float(iBaseHealth) * get_health_multiplier();
	new iNewHealth = floatround(fHealth);
	g_iZombieMaxHealth[id] = iNewHealth;
	set_user_health(id , iNewHealth);

	if(g_iGameState == STATE_MIDNIGHT)
	{
		new Float:fBaseSpeed = ArrayGetCell(g_ZombieClassSpeed, iClassId);
		new Float:fNewSpeed = fBaseSpeed * 1.5;
		cs_set_player_maxspeed(id, fNewSpeed);
	}
	else
		cs_set_player_maxspeed(id, ArrayGetCell(g_ZombieClassSpeed, iClassId));

	new Float:fGravity = ArrayGetCell(g_ZombieClassGravity, iClassId);
	set_user_gravity(id, fGravity);

	g_iPlayerZombieClassPreKill[id] = iClassId;
	g_iPlayerZombieClass[id] = iClassId;
	g_fPlayerZombieKnockback[id] = ArrayGetCell(g_ZombieClassKnockback , iClassId);

	return PLUGIN_HANDLED;
}

Float:get_health_multiplier()
{
	static players[MAX_PLAYERS] , iCount;
	get_players_ex(players, iCount, GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "CT")

	static Float:fMultiplier;
	static Float:fCountMulti; 

	fCountMulti = floatpower(get_pcvar_float(cvar_health_multiplier), float(iCount) - 1);
	fMultiplier = fCountMulti * floatpower(STAGE_MULTIPLIER, float(g_iCurrStage) - 1);
	return fMultiplier;
}

// ==============================================


public strip_zombie_weapons(id)
{
	strip_user_weapons(id)	
	give_item(id, "weapon_knife")
}

Get_Spawned_Zombie_Class_Of(iClassId)
{
	static iCount; iCount = 0;
	for(new i = 0 ; i < sizeof(g_iPlayerZombieClass) ; i++)
	{
		if(g_iPlayerZombieClass[i] == iClassId)
			iCount++;
	}
	return iCount;
}

// a corpse is to be set, stop player shells bug (thanks sawce)
public message_clcorpse(msg_id,msg_dest,msg_entity)
{
	if(!g_bModActive || get_msg_args() < 12)
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}


public client_disconnected(id)
{
	g_iPlayerZombieClass[id] = NO_CLASS;

	client_disconnected_wpn_mgr(id);
	client_disconnected_zombie_random_spawn(id);
}

// =================== Menu ======================= //

public show_main_menu(id)
{
	static szTitle[32] , szItem[64];
	formatex(szTitle, charsmax(szTitle), "\r Upgrades ( Tokens : [%i] )" , g_iToken[id])
	new menu = menu_create(szTitle, "main_menu_handler" );

	menu_additem( menu, "\wUpgrade Primary Weapon", "", 0);
	menu_additem( menu, "\wUpgrade Secondary Weapon", "", 0);

	formatex(szItem, charsmax(szItem), "\wBuy Traits with Token (%i/%i)" , g_iTraitTakenCount[id] , g_iPlayerMaxTrait[id])
	menu_additem( menu, szItem, "", 0);

	formatex(szItem, charsmax(szItem), "\wBuy Traits with Ammopack")
	menu_additem( menu, szItem, "", 0);
	menu_display( id, menu, 0 );
}

public main_menu_handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			show_menu_wpn_upgrade_primary(id);
		}
		case 1:
		{
			show_menu_wpn_upgrade_secondary(id);
		}
		case 2:
		{
			show_menu_human_trait(id);
		}
		case 3:
		{
			show_menu_human_trait_ammopack(id);
		}
	}
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public plugin_natives()
{
	register_library("zombie_stage")
	register_native("zs_class_zombie_register", "native_class_zombie_register")
	register_native("zs_class_zombie_register_sound", "native_class_zombie_register_sound")
	register_native("zs_core_is_active", "native_core_is_active")
	register_native("zs_core_is_zombie", "native_core_is_zombie")
	register_native("zs_core_get_player_zombie_class", "native_core_get_player_zombie_class")
	register_native("zs_core_get_zombie_max_health", "native_core_get_zombie_max_health")
	register_native("zs_core_get_zombie_class_knockback", "native_core_get_zombie_class_knockback")
	register_native("zs_core_get_player_knockback", "native_core_get_player_knockback")
	register_native("zs_core_set_player_knockback", "native_core_set_player_knockback")


	// Initialize dynamic arrays
	g_ZombieClassName = ArrayCreate(32, 1)
	g_ZombieClassBaseHealth = ArrayCreate(1, 1)
	g_ZombieClassSpeed = ArrayCreate(1, 1)
	g_ZombieClassGravity = ArrayCreate(1, 1)
	g_ZombieClassModelName = ArrayCreate(128)
	g_ZombieClassMaxSpawned = ArrayCreate(1,1)
	g_ZombieClassShowOnStage = ArrayCreate(1,1)
	g_ZombieClassKnockback = ArrayCreate(1,1)
	g_ZombieClassHideOnStage = ArrayCreate(1,1)
	g_ZombieClassDeathSound = ArrayCreate(128)
	g_ZombieClassPainSound = ArrayCreate(128)
	g_ZombieClassPainSound_2 = ArrayCreate(128)
}

// Call this only in plugin_precache()
public native_class_zombie_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))

	// Name
	ArrayPushString(g_ZombieClassName, name)

	// Models
	new model_name[32] , model_path[128]
	get_string(2, model_name, charsmax(model_name))
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model_name, model_name)	
	precache_model(model_path)
	ArrayPushString(g_ZombieClassModelName, model_name)

	// Health
	new health = get_param(3)
	ArrayPushCell(g_ZombieClassBaseHealth, health)
	// Speed
	new Float:speed = get_param_f(4)
	ArrayPushCell(g_ZombieClassSpeed, speed)

	new Float:gravity = get_param_f(5)
	ArrayPushCell(g_ZombieClassGravity, gravity)
	// 
	ArrayPushCell(g_ZombieClassKnockback, get_param_f(6))

	ArrayPushCell(g_ZombieClassShowOnStage , get_param(7))
	ArrayPushCell(g_ZombieClassHideOnStage , get_param(8))
	ArrayPushCell(g_ZombieClassMaxSpawned , get_param(9))

	// Push empty to sounds , will be registered later
	ArrayPushString(g_ZombieClassDeathSound, "")
	ArrayPushString(g_ZombieClassPainSound, "")
	ArrayPushString(g_ZombieClassPainSound_2, "")

	g_iZombieClassCount++

	console_print(0, "Zombie registered : %s" , name)
	
	return g_iZombieClassCount - 1;
}

public native_class_zombie_register_sound(plugin_id, num_params)
{
	new classId = get_param(1);
	new szSoundPath[128];

	// Death
	get_string(2, szSoundPath, charsmax(szSoundPath))
	ArraySetString(g_ZombieClassDeathSound, classId,szSoundPath)
	if(strlen(szSoundPath) > 0)
		precache_sound(szSoundPath)

	// Pain1
	get_string(3, szSoundPath, charsmax(szSoundPath))
	ArraySetString(g_ZombieClassPainSound,classId ,szSoundPath)
	if(strlen(szSoundPath) > 0)
		precache_sound(szSoundPath)


	// Pain2
	get_string(4, szSoundPath, charsmax(szSoundPath))
	ArraySetString(g_ZombieClassPainSound_2,classId ,szSoundPath)
	if(strlen(szSoundPath) > 0)
		precache_sound(szSoundPath)

}

public native_core_is_zombie(plugin_id, num_params)
{
	return is_zombie(get_param(1))
}


public native_core_get_player_zombie_class(plugin_id, num_params)
{
	return g_iPlayerZombieClass[get_param(1)];
}

public Float:native_core_get_zombie_class_knockback(plugin_id, num_params)
{
	return ArrayGetCell(g_ZombieClassKnockback , get_param(1));
}

public Float:native_core_get_player_knockback(plugin_id, num_params)
{
	return g_fPlayerZombieKnockback[get_param(1)]
}

public native_core_set_player_knockback(plugin_id, num_params)
{
	g_fPlayerZombieKnockback[get_param(1)] = get_param_f(2)
}

public native_core_get_zombie_max_health()
{
	return g_iZombieMaxHealth[get_param(1)];
}

public native_core_is_active()
{
	return g_bModActive;
}