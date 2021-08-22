#define TASK_RESPAWN 534
#define TASK_REMOVE_PROTECTION 568

#define DISTANCE_THRESHOLD 500

new const szSpawnSounds[][] = {
	"zombie_plague/zombie_infect1.wav",
	"zombie_plague/zombie_infect2.wav",
	"zombie_plague/zombie_infect3.wav"
}

new cvar_spawn_delay , cvar_spawn_freeze , cvar_random_spawn

plugin_init_zombie_random_respawn()
{
	cvar_spawn_delay = register_cvar("zs_zombie_respawn_delay" , "5")
	cvar_spawn_freeze = register_cvar("zs_zombie_respawn_freeze" , "5")
	cvar_random_spawn = register_cvar("zs_zombie_random_spawn" , "1")
}

plugin_precache_zombie_random_respawn()
{
	precache_sound(szSpawnSounds[0]);
	precache_sound(szSpawnSounds[1]);
	precache_sound(szSpawnSounds[2]);
}

client_disconnected_zombie_random_spawn(id)
{
	remove_task(TASK_RESPAWN+id);
	remove_task(TASK_REMOVE_PROTECTION+id);
}

Ham_Killed_Post_Zombie_Random_Spawn(id)
{
	if(g_iGameState == STATE_REST)
		return;
	begin_respawn(id)
}


// bring someone back to life
public begin_respawn(id)
{
	if(!is_user_connected(id))
		return;
	
	// alive, and not in the broken sort of way
	if(is_user_alive(id) && !pev(id,pev_iuser1))
		return;

	remove_task(TASK_RESPAWN+id);
	set_task(get_pcvar_float(cvar_spawn_delay),"respawn",TASK_RESPAWN+id);
}

// REALLY bring someone back to life
public respawn(taskid)
{
	if(g_iGameState == STATE_REST)
		return;
	console_print(0 , "current game state %i" , g_iGameState);
	new id = taskid-TASK_RESPAWN;
	if(!is_user_connected(id)) return;

	// alive, and not in the broken sort of way
	if(is_user_alive(id)) return;

	ExecuteHamB(Ham_CS_RoundRespawn,id); // note the B

	if(get_pcvar_bool(cvar_random_spawn) && g_SpawnCountCSDM > 0)
		do_random_spawn(id);

	// play sound & freeze & glow respawned for a specific time	
	emit_sound(id, CHAN_WEAPON, szSpawnSounds[random_num(0, 2)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// engfunc(EngFunc_EmitSound,id,CHAN_ITEM, szSpawnSound ,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	fm_set_user_godmode(id,1);
	fm_set_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,8);
	set_user_frozen(id, true)
	set_task(get_pcvar_float(cvar_spawn_freeze),"remove_spawn_protection",TASK_REMOVE_PROTECTION+id);
	
}

// get rid of the spawn protection effects
public remove_spawn_protection(taskid)
{
	new id = taskid-TASK_REMOVE_PROTECTION;

	if(!is_user_connected(id)) return;
	
	fm_set_user_godmode(id,0);
	fm_set_rendering(id); // reset back to normal
	set_user_frozen(id, false)
}

// place a user at a random spawn
do_random_spawn(id)
{
	// not even alive, don't bother
	if(!is_user_alive(id)) return;

	static Float:vecHolder[3];
	new sp_index = random_num(0,g_SpawnCountCSDM-1);

	// get origin for comparisons
	vecHolder[0] = g_spawns_csdm[sp_index][0];
	vecHolder[1] = g_spawns_csdm[sp_index][1];
	vecHolder[2] = g_spawns_csdm[sp_index][2];

	// this one is taken or very near player
	if( (!is_hull_vacant(vecHolder,HULL_HUMAN) || is_near_player(vecHolder , DISTANCE_THRESHOLD)) && g_SpawnCountCSDM > 1)
	{
		// attempt to pick another random one up to three times
		new i;
		for(i=0;i<3;i++)
		{
			sp_index = random_num(0,g_SpawnCountCSDM-1);

			vecHolder[0] = g_spawns_csdm[sp_index][0];
			vecHolder[1] = g_spawns_csdm[sp_index][1];
			vecHolder[2] = g_spawns_csdm[sp_index][2];
			
			if(is_hull_vacant(vecHolder,HULL_HUMAN) && !is_near_player(vecHolder , DISTANCE_THRESHOLD)) break;
		}

		// we made it through the entire loop, no free spaces
		if(i == 3)
		{
			// just find the first available
			for(i=sp_index+1;i!=sp_index;i++)
			{
				// start over when we reach the end
				if(i >= g_SpawnCountCSDM) i = 0;

				vecHolder[0] = g_spawns_csdm[i][0];
				vecHolder[1] = g_spawns_csdm[i][1];
				vecHolder[2] = g_spawns_csdm[i][2];

				// free space! office space!
				if(is_hull_vacant(vecHolder,HULL_HUMAN))
				{
					sp_index = i;
					break;
				}
			}
		}
	}

	// origin
	vecHolder[0] = g_spawns_csdm[sp_index][0];
	vecHolder[1] = g_spawns_csdm[sp_index][1];
	vecHolder[2] = g_spawns_csdm[sp_index][2];
	engfunc(EngFunc_SetOrigin,id,vecHolder);

	// angles
	vecHolder[0] = g_spawns_csdm[sp_index][3];
	vecHolder[1] = g_spawns_csdm[sp_index][4];
	vecHolder[2] = g_spawns_csdm[sp_index][5];
	set_pev(id,pev_angles,vecHolder);

	// vangles
	vecHolder[0] = g_spawns_csdm[sp_index][6];
	vecHolder[1] = g_spawns_csdm[sp_index][7];
	vecHolder[2] = g_spawns_csdm[sp_index][8];
	set_pev(id,pev_v_angle,vecHolder);

	set_pev(id,pev_fixangle,1);
}

stock is_near_player(Float:inputOrigin[3] , distanceThreshold)
{
	static players[MAX_PLAYERS] , iCount , playerOrigin[3] , Float:playerOrigin_f[3], Float:distance;
	get_players_ex(players, iCount , GetPlayers_ExcludeBots | GetPlayers_ExcludeDead)
	for(new x = 0 ; x < iCount ; x++)
	{
		get_user_origin(players[x], playerOrigin)
		playerOrigin_f[0] = float(playerOrigin[0])
		playerOrigin_f[1] = float(playerOrigin[1])
		playerOrigin_f[2] = float(playerOrigin[2])
		distance = get_distance_f(inputOrigin , playerOrigin_f);
		console_print(0 , "distance : %f" , distance);
		if(distance < distanceThreshold)
			return true;

	}

	return false;

}