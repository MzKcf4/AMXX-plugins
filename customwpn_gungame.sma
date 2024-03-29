#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <customwpn_const>
#include <customwpn_core_api>
#include <customwpn_loader_api>

#define PLUGIN "Custom Wpn - GunGame Mode"
#define VERSION "1.0"
#define AUTHOR "MzKc"

#define TASK_RESPAWN	300
#define TASK_STRIP_GIVE 400
#define TASK_REMOVE_PROTECTION	700

#define TEAM_T 0
#define TEAM_CT 1

#define KNIFE_SPEED 350

#define WBOX "models/w_weaponbox.mdl"
#define BOMB "models/w_backpack.mdl"
#define SHLD "models/w_shield.mdl"

new const CSW_MAXBPAMMO[33] = {-2,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100,-1,-1}

new g_entid[MAX_PLAYERS + 1]
new g_maxents
new g_iWinTeam = -1;
new g_HamBot;


new const wpnOrder[] = { RIFLE_TYPE , BOLT_SNIPER_TYPE, AUTO_SNIPER_TYPE, MG_TYPE,  SMG_TYPE , SHOTGUN_TYPE  , PISTOL_TYPE };

new Array:g_AryLevelWpnId;

new g_iTeamWpnLevel[2];				// Team wpn level;
new g_iTeamCurrLevelKill[2];

new const Float:g_fDelay = 5.0;
new g_bPlayerLastKill[MAX_PLAYERS + 1]		// Knife

new cvar_sp_time;
new cvar_lv_per_kill_t;
new cvar_lv_per_kill_ct;
new cvar_auto_config;

new const g_szGameEndSound[] = "sound/events/task_complete.wav";
new const g_szLevelUpSound[] = "sound/events/enemy_died.wav";
new const CT_WIN_SOUND[] = "sound/radio/ctwin.wav";
new const T_WIN_SOUND[] = "sound/radio/terwin.wav";
new const ARMOURY_ENTITY[] = "armoury_entity";

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_AryLevelWpnId = ArrayCreate();
	g_maxents = get_global_int(GL_maxEntities)

	cvar_sp_time = register_cvar("gg_sp_time","5.0");
	cvar_lv_per_kill_t = register_cvar("gg_lv_per_kill_t" , "2");
	cvar_lv_per_kill_ct = register_cvar("gg_lv_per_kill_ct" , "2");
	cvar_auto_config = register_cvar("gg_auto_config" , "1");
	
	RegisterHam(Ham_Killed,"player","ham_player_killed_post",1);
	RegisterHam(Ham_Spawn, "player", "ham_Player_Spawn_Post", 1)

	register_forward(FM_SetModel, "fw_set_model")
	register_forward(FM_ClientKill, "fw_client_kill")

	// Handle the Corpse
	register_message(get_user_msgid("ClCorpse"),"message_clcorpse");
	register_logevent("Event_RoundStart", 2, "1=Round_Start") 
	register_logevent("JoinTeam", 3, "1=joined team")

	
	register_concmd("gg_set_wpn_lv_t" , "set_wpn_level_t")
	register_concmd("gg_set_wpn_lv_ct" , "set_wpn_level_ct")
	register_concmd("gg_restart" , "game_restart")
	

	register_clcmd( "joinclass", "cmdJoinClass" );
	register_clcmd( "drop", "cmdDropWeapon" );

	load_config_file();
	initWpnLevel();
	init();
}

public plugin_precache() 
{    	
	precache_generic(g_szGameEndSound)
	precache_generic(g_szLevelUpSound)
	register_forward(FM_Spawn,"fw_Spawn_Pre")
}

public plugin_end()
{
	ArrayDestroy(g_AryLevelWpnId);
}

load_config_file()
{
	// get path from amxx config dir
	new szFilePath[256]
	get_configsdir(szFilePath, charsmax(szFilePath)) // now config dir in path stored
	// store file dir in path
	format(szFilePath, charsmax(szFilePath), "%s/customwpn_gungame.cfg", szFilePath) // store complete path to file

	if(file_exists(szFilePath))
	{
		server_cmd("exec %s", szFilePath);
	}
}

// Removes the guns on the map
public fw_Spawn_Pre(ent)
{
    static szClassName[32]
    
    if(pev_valid(ent))
    {    
        pev(ent,pev_classname,szClassName,charsmax(szClassName))
        if(equali(szClassName,ARMOURY_ENTITY))
        {
            engfunc(EngFunc_RemoveEntity, ent)
            return FMRES_SUPERCEDE
        }        
    }
    
    return FMRES_IGNORED
}

public fw_client_kill(id)
{
	return FMRES_SUPERCEDE
}

public JoinTeam()
{
	auto_config();
}

public cmdJoinClass( id )
{
	auto_config();
	return PLUGIN_CONTINUE;
} 

// Disable weapon dropping
public cmdDropWeapon(id)
{
    return PLUGIN_HANDLED;
}

public Event_RoundStart(id)
{
	auto_config();

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

auto_config()
{
	if(!get_pcvar_num(cvar_auto_config))
		return;

	static players[MAX_PLAYERS];
	new iCount;
	get_players_ex(players, iCount, GetPlayers_MatchTeam, "TERRORIST")
	set_pcvar_num(cvar_lv_per_kill_t , (iCount+1))

	get_players_ex(players, iCount, GetPlayers_MatchTeam, "CT")
	set_pcvar_num(cvar_lv_per_kill_ct , (iCount+1))
	
	set_level_message();
}

public game_restart()
{
	auto_config()
	server_cmd("sv_restart 1")
	init();
	set_level_message();
}

public init()
{
	g_iTeamCurrLevelKill[TEAM_T] = 0;
	g_iTeamCurrLevelKill[TEAM_CT] = 0;
	g_iTeamWpnLevel[TEAM_T] = 0;
	g_iTeamWpnLevel[TEAM_CT] = 0;
	g_iWinTeam = -1
	
	set_level_message();
	
	return PLUGIN_HANDLED;
}

initWpnLevel()
{
	for(new i = 0 ; i < sizeof(wpnOrder) ; i++)
	{
		new Array:aryWpn = api_core_get_wpn_of_type(wpnOrder[i]);

		for(new iCount = 0 ;iCount < ArraySize(aryWpn) ; iCount++)
			ArrayPushCell(g_AryLevelWpnId , ArrayGetCell(aryWpn, iCount));

		ArrayDestroy(aryWpn);
	}
}

public set_level_message()
{
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
		api_core_get_wpn_display_name(iWpnLvIdx, szWpnName);
	}
	

	static szNextWpnName[32];
	
	if(g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId) - 1)	
	{
		szNextWpnName = "--";
	}
	else
	{
		new iNextWpnLvIdx = ArrayGetCell(g_AryLevelWpnId, g_iTeamWpnLevel[iTeam] + 1);
		api_core_get_wpn_display_name(iNextWpnLvIdx, szNextWpnName);
	}
	formatex(szMsg, charsmax(szMsg) , "%s (%i/%i) %s^nCurrent: %s^nNext: %s",szTeam,  g_iTeamWpnLevel[iTeam], ArraySize(g_AryLevelWpnId) ,get_team_wpn_level_progress(iTeam), szWpnName, szNextWpnName);
	
	return szMsg;
}

public get_team_wpn_level_progress(iTeam)
{
	static iKillPerLv , i;
	iKillPerLv = iTeam == TEAM_T ? get_pcvar_num(cvar_lv_per_kill_t) : get_pcvar_num(cvar_lv_per_kill_ct)

	new szBuffer[16];
	static iRemain; iRemain = iKillPerLv - g_iTeamCurrLevelKill[iTeam];
	
	for(i = 0 ; i < g_iTeamCurrLevelKill[iTeam]; i++)
	{
		strcat(szBuffer , "|" , charsmax(szBuffer));
	}
	
	for(i = 0 ; i < iRemain; i++)
	{
		strcat(szBuffer , "-" , charsmax(szBuffer));
	}

	return szBuffer;
}

public client_putinserver(id)
{	
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
	auto_config();
}


// delay for private data to initialize --
// here is the problem: registering a ham hook for "player" won't
// register it for CZ bots, for some reason. so we have to register
// it by entity. so we do this ridiculous thing in order to do so.
public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_Spawn,id,"ham_Player_Spawn_Post",1);
	RegisterHamFromEntity(Ham_Killed,id,"ham_player_killed_post",1);
}

public ham_player_killed_post(victim,killer,gib)
{
	if(!is_user_connected(victim))  return HAM_IGNORED;

	
	if(!(victim == killer) && is_user_connected(killer) && (cs_get_user_team(killer) != cs_get_user_team(victim)))
	{	
		cs_set_user_money(killer , 0);
		static iTeam; iTeam = _:cs_get_user_team(killer);
		
		// T is 1 in CsTeam , so -1 to match the array.
		iTeam--;
		g_iTeamCurrLevelKill[iTeam]++;

		static iLvUpKill; iLvUpKill = iTeam == TEAM_T ? get_pcvar_num(cvar_lv_per_kill_t) : get_pcvar_num(cvar_lv_per_kill_ct)
		if(g_iTeamCurrLevelKill[iTeam] >= iLvUpKill)
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
	g_iTeamCurrLevelKill[iTeam] = 0;
	level_up_team(iTeam);
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
	if(!is_user_connected(id))
		return;

	// now on spectator
	// if(!on_valid_team(id)) return;
	
	// alive, and not in the broken sort of way
	if(is_user_alive(id) && !pev(id,pev_iuser1))
		return;

	remove_task(TASK_RESPAWN+id);
	set_task(g_fDelay,"respawn",TASK_RESPAWN+id);
}

// REALLY bring someone back to life
public respawn(taskid)
{
	new id = taskid-TASK_RESPAWN;
	if(!is_user_connected(id)) return;

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
	api_core_remove_all_player_wpn(playerId);
	strip_user_weapons(playerId);
	
	if(g_iWinTeam != -1)
		return;

	// Last weapon , should be a knife.
	if(g_iTeamWpnLevel[iTeam] >= ArraySize(g_AryLevelWpnId))
	{
		g_bPlayerLastKill[playerId] = true;
		give_item(playerId, "weapon_knife")
		set_user_maxspeed(playerId, float(KNIFE_SPEED));
	}
	else
	{
		static wpnid; wpnid = ArrayGetCell(g_AryLevelWpnId,  g_iTeamWpnLevel[iTeam]);
		api_core_give_wpn(playerId , wpnid);
		give_item(playerId, "weapon_knife")
		
		static cswId; cswId = api_core_get_wpn_cswId(wpnid);
		if(GUN_TYPE & (1 << cswId))
		{
			cs_set_user_bpammo(playerId, cswId, CSW_MAXBPAMMO[cswId])
		}
	}
}

// a corpse is to be set, stop player shells bug (thanks sawce)
public message_clcorpse(msg_id,msg_dest,msg_entity)
{
	if(get_msg_args() < 12)
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}


// From No Weapon Drop on Death by VEN (https://forums.alliedmods.net/showthread.php?p=202171)
public fw_set_model(entid, model[]) {
	if (!is_valid_ent(entid) || !equal(model, WBOX, 9))
		return FMRES_IGNORED

	new id = entity_get_edict(entid, EV_ENT_owner)
	if (!id || !is_user_connected(id) || is_user_alive(id))
		return FMRES_IGNORED

	if (equal(model, SHLD)) {
		kill_entity(entid)
		return FMRES_IGNORED
	}

	if (equal(model, WBOX)) {
		g_entid[id] = entid
		return FMRES_IGNORED
	}

	if (entid != g_entid[id])
		return FMRES_IGNORED

	g_entid[id] = 0

	if (equal(model, BOMB))
		return FMRES_IGNORED

	for (new i = 1; i <= g_maxents; ++i) {
		if (is_valid_ent(i) && entid == entity_get_edict(i, EV_ENT_owner)) {
			kill_entity(entid)
			kill_entity(i)
		}
	}

	return FMRES_IGNORED
}

stock kill_entity(id) {
	entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags)|FL_KILLME)
}