/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <wpn_const>
#include <wpn_core>
#include <customwpn_mode_api>

#define PLUGIN "Wpn-GunGame"
#define VERSION "1.0"
#define AUTHOR "shanaO12"

#define RIFLE_COUNT 4		// 5
#define BOLT_SNIPER_COUNT 2
#define AUTO_SNIPER_COUNT 2
#define MG_COUNT 2
#define SMG_COUNT 4		// 10
#define SHOTGUN_COUNT 3		// 12
#define PISTOL_COUNT 4		// 16


#define KILL_PER_LEVEL 2

#define TASK_RESPAWN	300
#define TASK_STRIP_GIVE 400
#define TASK_REMOVE_PROTECTION	700

#define TEAM_T 0
#define TEAM_CT 1

#define KNIFE_SPEED 350
#define BOT_KNIFE_KILL_COUNT 1

new g_bModActive = true;
new g_iWinTeam = -1;

new g_HamBot;


new const wpnOrder[] = { RIFLE_TYPE , BOLT_SNIPER_TYPE, AUTO_SNIPER_TYPE, MG_TYPE,  SMG_TYPE , SHOTGUN_TYPE  , PISTOL_TYPE };
new const wpnMax[] = {RIFLE_COUNT ,BOLT_SNIPER_COUNT,AUTO_SNIPER_COUNT, MG_COUNT, SMG_COUNT ,SHOTGUN_COUNT , PISTOL_COUNT };

new Array:g_AryLevelWpnId;
// new g_iWpnlevel[MAX_PLAYERS + 1];		// Player's wpn level

new g_iTeamWpnLevel[2];				// Team wpn level;
new g_iTeamKillUntilNextLevel[2]	

new const Float:g_fDelay = 5.0;
new g_bPlayerLastKill[MAX_PLAYERS + 1]		// Knife

new g_botTeam = TEAM_CT;

new cvar_sp_time;
new cvar_lv_per_kill_t;
new cvar_lv_per_kill_ct;
// new g_bSpawnProtected[MAX_PLAYERS + 1]

new g_szGameEndSound[] = "sound/events/task_complete.wav";
new g_szLevelUpSound[] = "sound/events/enemy_died.wav";
new const CT_WIN_SOUND[] = "sound/radio/ctwin.wav";
new const T_WIN_SOUND[] = "sound/radio/terwin.wav";
new const ARMOURY_ENTITY[] = "armoury_entity";

new const CSW_MAXAMMO[33]=
{
    -2,
    52,
    0,
    90,
    1,
    32,
    1,
    100,
    90,
    1,
    120,
    100,
    100,
    90,
    90,
    90,
    100,
    120,
    30,
    120,
    200,
    32,
    90,
    120,
    90,
    2,
    35,
    90,
    90,
    0,
    100,
    -1,
    -1
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	// g_iLevelPerKill = 2;
	g_AryLevelWpnId = ArrayCreate();

	cvar_sp_time = register_cvar("gg_sp_time","5.0");
	cvar_lv_per_kill_t = register_cvar("gg_lv_per_kill_t" , "2");
	cvar_lv_per_kill_ct = register_cvar("gg_lv_per_kill_ct" , "2");
	
	RegisterHam(Ham_Killed,"player","ham_player_killed_post",1);
	RegisterHam(Ham_Spawn, "player", "ham_Player_Spawn_Post", 1)
	// Handle the Corpse
	register_message(get_user_msgid("ClCorpse"),"message_clcorpse");
	register_logevent("Event_RoundStart", 2, "1=Round_Start") 
	
	register_concmd("gg_set_wpn_lv_t" , "set_wpn_level_t")
	register_concmd("gg_set_wpn_lv_ct" , "set_wpn_level_ct")
	register_concmd("gg_restart" , "game_restart")
	register_concmd("gg_bot_team_ct" , "init_bot_ct")
	register_concmd("gg_bot_team_t" , "init_bot_t")
	
	register_clcmd( "joinclass", "cmdJoinClass" );
	register_clcmd( "drop", "cmd_Drop" );

	init();
}

public plugin_precache() 
{    	
	wpn_mode_set(WPN_MODE_GUNGAME)
	precache_generic(g_szGameEndSound)
	precache_generic(g_szLevelUpSound)
	register_forward(FM_Spawn,"fw_Spawn_Pre")
}

public fw_Spawn_Pre(ent)
{
    static szClassName[32]
    
    if(pev_valid(ent))
    {    
        pev(ent,pev_classname,szClassName,charsmax(szClassName))
        console_print(0 , "Spawned : %s" , szClassName);
        if(equali(szClassName,ARMOURY_ENTITY))
        {
            server_print("REMOVE:%s",szClassName)
            engfunc(EngFunc_RemoveEntity, ent)
            return FMRES_SUPERCEDE
        }        
    }
    
    return FMRES_IGNORED
}

public cmdJoinClass( id )
{
    update_kill_per_level();
    return PLUGIN_CONTINUE;
} 

public cmd_Drop(id)
{
    return PLUGIN_HANDLED;
}

update_kill_per_level()
{
	static players[MAX_PLAYERS] , iCount;
	if(g_botTeam == TEAM_T)
	{
		get_players_ex(players, iCount, GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "CT")

		set_pcvar_num(cvar_lv_per_kill_ct , iCount+1)
		set_pcvar_num(cvar_lv_per_kill_t , iCount)
	}
	else 
	{
		get_players_ex(players, iCount, GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "TERRORIST")
		set_pcvar_num(cvar_lv_per_kill_ct , iCount)
		set_pcvar_num(cvar_lv_per_kill_t , iCount+1)
	}
	set_level_message();
	return PLUGIN_HANDLED;
}


public init_bot_ct()
{
	g_botTeam = TEAM_CT;
}

public init_bot_t()
{
	g_botTeam = TEAM_T;
}

public Event_RoundStart(id)
{
	if(!g_bModActive)	return PLUGIN_CONTINUE;
	
	static players[MAX_PLAYERS] , iCount , i;
	
	get_players_ex(players, iCount, GetPlayers_ExcludeDead)
	for( i = 0 ; i < iCount ; i++)
	{
		static iPlayerId; iPlayerId = players[i];
		cs_set_user_money(iPlayerId , 0);
		
	}
	set_level_message();
	return PLUGIN_CONTINUE;
	
}

public game_restart()
{
	update_kill_per_level();
	
	g_iTeamKillUntilNextLevel[TEAM_T] = get_pcvar_num(cvar_lv_per_kill_t);
	g_iTeamKillUntilNextLevel[TEAM_CT] = get_pcvar_num(cvar_lv_per_kill_ct);
	g_iTeamWpnLevel[TEAM_T] = 0;
	g_iTeamWpnLevel[TEAM_CT] = 0;

	g_iWinTeam = -1

	server_cmd("bot_all_weapons")
	server_cmd("sv_restart 1")
	server_cmd("mp_autoteambalance 0")
	server_cmd("mp_limitteams 20");
	set_level_message();
}

public init()
{
	g_iTeamKillUntilNextLevel[TEAM_T] = get_pcvar_num(cvar_lv_per_kill_t);
	g_iTeamKillUntilNextLevel[TEAM_CT] = get_pcvar_num(cvar_lv_per_kill_ct);
	g_iTeamWpnLevel[TEAM_T] = 0;
	g_iTeamWpnLevel[TEAM_CT] = 0;

	initWpnLevel();
	set_level_message();
	
	console_cmd(0 , "bot_all_weapons");
	console_cmd(0 , "mp_roundtime 9");
	console_cmd(0 , "mp_startmoney 800");
	console_cmd(0 , "mp_freezetime 0");
	console_cmd(0 , "sv_maxspeed 600");
	console_cmd(0 , "mp_friendlyfire 0");
	console_cmd(0 , "mp_round_infinite 1");
	console_cmd(0 , "sypb_lockzbot 0");

	g_bModActive = true;
	return PLUGIN_HANDLED;
}

initWpnLevel()
{
	for(new i = 0 ; i < sizeof(wpnOrder) ; i++)
	{
		new Array:aryWpn = wpn_core_get_wpn_of_type(wpnOrder[i]);
		new iArySize = ArraySize(aryWpn);
		new iCount;
		
		new iRemaining = wpnMax[i];
		if(iArySize < wpnMax[i])
		{
			for(iCount = 0 ;iCount < iArySize ; iCount++)
				ArrayPushCell(g_AryLevelWpnId , ArrayGetCell(aryWpn, iCount));
				
		}
		else
		{
			while(iRemaining > 0)
			{
				new idx = random_num(0 , iArySize-1);
				ArrayPushCell(g_AryLevelWpnId , ArrayGetCell(aryWpn, idx));
				ArrayDeleteItem(aryWpn , idx);
				iRemaining--;
				iArySize = ArraySize(aryWpn);
			}
		}
	}
}

public set_level_message()
{
	if(!g_bModActive)	return PLUGIN_HANDLED;
	set_hudmessage(255, 0, 0, 0.05, -1.0, 0, 0.0, 540.0, 0.1, 0.2, 2)
	
	static players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount)
	static szMsg[256];
	if(g_iWinTeam == -1)
		formatex(szMsg, charsmax(szMsg) , "%s^n^n%s", get_team_wpn_msg(TEAM_T) , get_team_wpn_msg(TEAM_CT))
	else
	{
		if(g_iWinTeam == TEAM_T)
			szMsg = "Terrorist Win";
		else
			szMsg = "Counter-Terrorist Win";

	}
	for( i = 0 ; i < iCount ; i++)
	{
		static iPlayerId; iPlayerId = players[i];
		show_hudmessage(iPlayerId, "%s", szMsg);
		
	}
	return PLUGIN_HANDLED;
}

public get_team_wpn_msg(iTeam)
{

	static szMsg[128];
	/*
	T (1/14) ||--
	Current : M4A1
	Next : Ak47
	*/

	static szTeam[3];
	if(iTeam == TEAM_T)
		szTeam = "T"
	else
		szTeam = "CT"
	
	static iWpnLvIdx; 
	static szWpnName[32];	
	if(g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId))
	{
		szWpnName = "Knife"
	}
	else
	{
		iWpnLvIdx =  ArrayGetCell(g_AryLevelWpnId, g_iTeamWpnLevel[iTeam]);
		wpn_core_get_wpn_display_name_2(iWpnLvIdx, szWpnName);
	}
	

	static szNextWpnName[32];
	
	if(g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId) - 1)	
	{
		szNextWpnName = "--";
	}
	else
	{
		new iNextWpnLvIdx = ArrayGetCell(g_AryLevelWpnId, g_iTeamWpnLevel[iTeam] + 1);
		wpn_core_get_wpn_display_name_2(iNextWpnLvIdx, szNextWpnName);
	}
	formatex(szMsg, charsmax(szMsg) , "%s (%i/%i) %s^nCurrent: %s^nNext: %s",szTeam,  g_iTeamWpnLevel[iTeam], ArraySize(g_AryLevelWpnId) ,get_team_wpn_level_progress(iTeam), szWpnName, szNextWpnName);
	
	return szMsg;
}

public get_team_wpn_level_progress(iTeam)
{
	static iCurrKill , i;
	if(iTeam == TEAM_T)	
		iCurrKill = get_pcvar_num(cvar_lv_per_kill_t)
	else 			
		iCurrKill = get_pcvar_num(cvar_lv_per_kill_ct)
	
	new szBuffer[8];
	static iRemain; iRemain = iCurrKill - g_iTeamKillUntilNextLevel[iTeam];
	
	for(i = 0 ; i < iRemain; i++)
	{
		strcat(szBuffer , "|" , charsmax(szBuffer));
	}
	
	for(i = 0 ; i < g_iTeamKillUntilNextLevel[iTeam]; i++)
	{
		strcat(szBuffer , "-" , charsmax(szBuffer));
	}

	return szBuffer;
}

public client_putinserver(id)
{
	// Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
	
}

public client_disconnected(id)
{
	remove_task(TASK_RESPAWN+id);
	remove_task(TASK_REMOVE_PROTECTION+id);
	remove_task(TASK_STRIP_GIVE+id);
}


// delay for private data to initialize --
// here is the problem: registering a ham hook for "player" won't
// register it for CZ bots, for some reason. so we have to register
// it by entity. so we do this ridiculous thing in order to do so.
public Do_Register_HamBot(id)
{

	RegisterHamFromEntity(Ham_Spawn,id,"ham_Player_Spawn_Post",1);
	// RegisterHamFromEntity(Ham_Killed,id,"ham_player_killed_pre",0);
	RegisterHamFromEntity(Ham_Killed,id,"ham_player_killed_post",1);
	
	
	// bug fix for mid-round spawning, thanks to MeRcyLeZZ
	// if(is_user_alive(id)) ham_player_spawn(id);
	
}

public ham_player_killed_post(victim,killer,gib)
{
	if(!g_bModActive)		return HAM_IGNORED;

	if(!is_user_connected(victim))  return HAM_IGNORED;

	
	if(!(victim == killer) && is_user_connected(killer) && (cs_get_user_team(killer) != cs_get_user_team(victim)))
	{	
		cs_set_user_money(killer , 0);
		static iTeam; iTeam = _:cs_get_user_team(killer);
		
		// T is 1 in CsTeam , so -1 to match the array.
		iTeam--;
		
		g_iTeamKillUntilNextLevel[iTeam]--;
		
		if(g_iTeamKillUntilNextLevel[iTeam] <= 0)
		{			
			// Knife kill fullfilled , game end
			if(is_last_wpn_level(iTeam))
			{
				g_iWinTeam = iTeam;
				game_end();
			}
			else
			{	
				set_wpn_level(iTeam , g_iTeamWpnLevel[iTeam] + 1)
			}
		}
		set_level_message();
	}
	
	begin_respawn(victim);
	return HAM_HANDLED;
}

game_end()
{
	new players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount)
	for( i = 0 ; i < iCount ; i++)
	{
		new iPlayerId; iPlayerId = players[i];
		strip_user_weapons(iPlayerId);
		client_cmd(iPlayerId , "spk %s" , g_szGameEndSound);

		if(g_iWinTeam == TEAM_T)
			client_cmd(iPlayerId , "spk radio/%s" , T_WIN_SOUND);
		else
			client_cmd(iPlayerId , "spk radio/%s" , CT_WIN_SOUND);
	}
	
}

set_wpn_level(iTeam, iLevel)
{
	g_iTeamWpnLevel[iTeam] = iLevel;	

	static iKillPerLv;
	if(iTeam == TEAM_T)	
		iKillPerLv = get_pcvar_num(cvar_lv_per_kill_t)
	else 			
		iKillPerLv = get_pcvar_num(cvar_lv_per_kill_ct)

	g_iTeamKillUntilNextLevel[iTeam] = iKillPerLv	
	
	level_up_team(iTeam);
	
	/*
	// Post check to for kills setting for knife wpn (Bot only)
	if(is_last_wpn_level(iTeam) && g_botTeam == iTeam)
	{
		if(g_botTeam == iTeam)
			g_iTeamKillUntilNextLevel[iTeam] = BOT_KNIFE_KILL_COUNT
		else
			g_iTeamKillUntilNextLevel[iTeam] = iKillPerLv/2;
	}
	*/
	set_level_message();
}

public set_wpn_level_t(id, level, cid)
{
	new iLevel = read_argv_int(1);
	if(iLevel < 0 && iLevel > ArraySize(g_AryLevelWpnId))
		return PLUGIN_HANDLED;

	set_wpn_level(TEAM_T, iLevel)
	return PLUGIN_HANDLED
}

public set_wpn_level_ct(id, level, cid)
{
	new iLevel = read_argv_int(1);
	if(iLevel < 0 && iLevel > ArraySize(g_AryLevelWpnId))
		return PLUGIN_HANDLED;

	set_wpn_level(TEAM_CT, iLevel)
	return PLUGIN_HANDLED
}

level_up_team(iTeam)
{
	static players[MAX_PLAYERS] , iCount , i;
	
	if(iTeam == TEAM_T)
		get_players_ex(players, iCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "TERRORIST")
	else 
		get_players_ex(players, iCount, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT")
	
	for( i = 0 ; i < iCount ; i++)
	{
		static iPlayerId; iPlayerId = players[i];
		set_task(0.1 , "Strip_and_Give_Wpn" , TASK_STRIP_GIVE + iPlayerId);
		client_cmd(iPlayerId , "spk %s" , g_szLevelUpSound);
		
	}
	return PLUGIN_HANDLED;
}

is_last_wpn_level(iTeam)
{
	return (g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId))
}

// bring someone back to life
public begin_respawn(id)
{
	if(!g_bModActive || !is_user_connected(id))
		return;

	// now on spectator
	// if(!on_valid_team(id)) return;
	
	// alive, and not in the broken sort of way
	if(is_user_alive(id) && !pev(id,pev_iuser1))
		return;

	// round is over, or bomb is planted
	// if(roundEnded || (bombStatus[3] == BOMB_PLANTED && !get_pcvar_num(gg_dm_spawn_afterplant)))
	// 	return;

	// new Float:delay = get_pcvar_float(gg_dm_spawn_delay);
	// if(delay < 0.1) delay = 0.1;

	// new dm_countdown = get_pcvar_num(gg_dm_countdown);
	
	/*
	if((dm_countdown & 1) || (dm_countdown & 2))
	{
		respawn_timeleft[id] = floatround(delay);
		respawn_countdown(id);
	}
	*/

	remove_task(TASK_RESPAWN+id);
	set_task(g_fDelay,"respawn",TASK_RESPAWN+id);
	// set_task(g_fDelay+0.1 , "Strip_and_Give_Wpn" , TASK_STRIP_GIVE+id);
}

// REALLY bring someone back to life
public respawn(taskid)
{
	new id = taskid-TASK_RESPAWN;
	if(!is_user_connected(id) || !g_bModActive) return;

	// alive, and not in the broken sort of way
	if(is_user_alive(id)) return;
	
	ExecuteHamB(Ham_CS_RoundRespawn,id); // note the B
	
	new Float:time = get_pcvar_float(cvar_sp_time);
	// spawn protection
	if(time > 0.0)
	{
		// spawnProtected[id] = 1;
		
		fm_set_user_godmode(id,1);
		fm_set_rendering(id,kRenderFxGlowShell,200,200,100,kRenderNormal,8); // goldenish
		// fm_set_rendering(id,kRenderFxGlowShell,100,100,100,kRenderNormal,8); // gray/white
		set_task(time,"remove_spawn_protection",TASK_REMOVE_PROTECTION+id);
	}
}

public ham_Player_Spawn_Post(iPlayer) 
{
	if(!is_user_alive(iPlayer)) 	return HAM_IGNORED;
	
	set_task(0.1 , "Strip_and_Give_Wpn" , TASK_STRIP_GIVE+iPlayer);
	cs_set_user_money(iPlayer , 0);
	cs_set_user_nvg(iPlayer, 1)
	
	return HAM_IGNORED;
} 

// get rid of the spawn protection effects
public remove_spawn_protection(taskid)
{
	new id = taskid-TASK_REMOVE_PROTECTION;
	// spawnProtected[id] = 0;

	if(!is_user_connected(id)) return;
	
	fm_set_user_godmode(id,0);
	fm_set_rendering(id); // reset back to normal
}


public Strip_and_Give_Wpn(taskid)
{
	static playerId; playerId = taskid-TASK_STRIP_GIVE;
	static iTeam; iTeam = _:cs_get_user_team(playerId);
	// -1 to match team arrayIdx;
	iTeam--;
	cs_set_user_armor(playerId , 100 , CS_ARMOR_VESTHELM);
	wpn_core_remove_all_player_wpn(playerId);
	strip_user_weapons(playerId);
	
	if(g_iWinTeam != -1)
		return;

	// Simple and Trash temp fix
	if(g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId))
	{
		g_bPlayerLastKill[playerId] = true;
		give_item(playerId, "weapon_knife")
		for(new cswId = 0 ; cswId < sizeof(CSW_MAXAMMO) ; cswId++)
		{
			if(CSW_MAXAMMO[cswId] > 0)
				cs_set_user_bpammo(playerId, cswId, CSW_MAXAMMO[cswId])
		}
		set_user_maxspeed(playerId, float(KNIFE_SPEED));
	}
	else
	{
		static wpnid; wpnid = ArrayGetCell(g_AryLevelWpnId,  g_iTeamWpnLevel[iTeam]);
		console_print(0 , "Team is now level %i , giving wpnId %i to %i" , g_iTeamWpnLevel[iTeam], wpnid , playerId);
		wpn_core_give_wpn(playerId , wpnid);
		give_item(playerId, "weapon_knife")
		
		static cswId; cswId = wpn_core_get_wpn_cswId(wpnid);
		if(GUN_TYPE & (1 << cswId))
		{
			cs_set_user_bpammo(playerId, cswId, CSW_MAXAMMO[cswId])
		}
	}
}

// a corpse is to be set, stop player shells bug (thanks sawce)
public message_clcorpse(msg_id,msg_dest,msg_entity)
{
	if(!g_bModActive || get_msg_args() < 12)
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

/*
// SMART way to check 
// an entity is given a model, check for silenced/burst status
public fw_setmodel(ent,model[])
{
	if(!ggActive) return FMRES_IGNORED;

	new owner = pev(ent,pev_owner);

	// no owner
	if(!is_user_connected(owner)) return FMRES_IGNORED;

	static classname[24]; // the extra space is used later
	pev(ent,pev_classname,classname,10);

	// not a weapon
	// checks for weaponbox, weapon_shield
	if(classname[8] != 'x' && !(classname[6] == '_' && classname[7] == 's' && classname[8] == 'h'))
		return FMRES_IGNORED;

	// makes sure we don't get memory access error,
	// but also helpful to narrow down matches
	new len = strlen(model);

	// ignore weaponboxes whose models haven't been set to correspond with their weapon types yet
	// checks for models/w_weaponbox.mdl
	if(len == 22 && model[17] == 'x') return FMRES_IGNORED;

	// ignore C4
	// checks for models/w_backpack.mdl
	if(len == 21 && model[9] == 'b') return FMRES_IGNORED;

	// checks for models/w_usp.mdl, usp, models/w_m4a1.mdl, m4a1
	if((len == 16 && model[10] == 's' && lvlWeapon[owner][1] == 's')
	|| (len == 17 && model[10] == '4' && lvlWeapon[owner][1] == '4') )
	{
		copyc(model,len-1,model[contain_char(model,'_')+1],'.'); // strips off models/w_ and .mdl
		formatex(classname,23,"weapon_%s",model);

		// remember silenced status
		new wEnt = fm_find_ent_by_owner(maxPlayers,classname,ent);
		if(pev_valid(wEnt)) silenced[owner] = cs_get_weapon_silen(wEnt);
	}

	// checks for models/w_glock18.mdl, glock18, models/w_famas.mdl, famas
	else if((len == 20 && model[15] == '8' && lvlWeapon[owner][6] == '8')
	|| (len == 18 && model[9] == 'f' && model[10] == 'a' && lvlWeapon[owner][0] == 'f' && lvlWeapon[owner][1] == 'a') )
	{
		copyc(model,len-1,model[contain_char(model,'_')+1],'.'); // strips off models/w_ and .mdl
		formatex(classname,23,"weapon_%s",model);

		// remember burst status
		new wEnt = fm_find_ent_by_owner(maxPlayers,classname,ent);
		if(pev_valid(wEnt)) silenced[owner] = cs_get_weapon_burst(wEnt);
	}
		
	// if owner is dead, remove it if we need to
	if(get_user_health(owner) <= 0 && get_pcvar_num(gg_dm) && !get_pcvar_num(gg_pickup_others))
	{
		dllfunc(DLLFunc_Think,ent);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}
*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1041\\ f0\\ fs16 \n\\ par }
*/