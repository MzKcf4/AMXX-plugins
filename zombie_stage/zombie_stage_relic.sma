#define TASKID_SPAWN 1811
#define TASKID_SHOW_RADAR 1911

#define MAX_RELIC 2
#define NOT_SPAWN -1
#define NO_MORE_SUPPLY -1

#define NO_BUFF 0
new const CLASSNAME_RELIC[] = "relic";
new const MODEL_RELIC[] = "models/zombie_mod/supplybox2.mdl";
new const UPGRADE_SOUND[] = "zombie_plague/levelup.wav"

new g_iRelicEntId[MAX_RELIC] = {NOT_SPAWN , ...}				// [SupplyID] = an Entity ID ( or ptr )
new g_iRelicEntOnSpawnPoint[MAX_RELIC] = {NOT_SPAWN , ...}	// [SupplyID] = csdm spawn point id		
new g_iRelicTaken = 0;

new m_fakeHostage;
new m_fakeHostageDie;

new cvar_relic_spawn_first , cvar_relic_spawn_second

enum _:TOTAL_RELIC_BUFF {
	RELIC_DAMAGE = 0,
	RELIC_TOUGHNESS,
	RELIC_SPEED
}
new g_iPlayerBuffLevel[33][TOTAL_RELIC_BUFF]
new g_szBuffName[TOTAL_RELIC_BUFF][32]

new g_iRelicBuffLevel[TOTAL_RELIC_BUFF];

new g_hudmessage_id_relic;

plugin_init_relic()
{
	register_touch(CLASSNAME_RELIC , "player" , "Fw_Touch_Relic");

	cvar_relic_spawn_first = register_cvar("zs_relic_spawn_first", "15");
	cvar_relic_spawn_second = register_cvar("zs_relic_spawn_second", "75");

	m_fakeHostage = get_user_msgid("HostagePos");
	m_fakeHostageDie = get_user_msgid("HostageK");

	g_szBuffName[RELIC_DAMAGE] = "Damage"
	g_szBuffName[RELIC_TOUGHNESS] = "Toughness"
	g_szBuffName[RELIC_SPEED] = "Speed"

	g_hudmessage_id_relic = hudmessage_queue_register_left();
	set_task(1.0, "show_relic_message", _,_,_,"b");
}

plugin_precache_relic()
{
	precache_model(MODEL_RELIC);
	precache_generic(UPGRADE_SOUND);
}

init_relic()
{

}

public show_relic_message()
{
	static players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount , GetPlayers_ExcludeBots)
	for( i = 0 ; i < iCount ; i++)
	{
		static szMsg[128];
		static id; id = players[i];
		szMsg = "Relic Buffs : ";
		for(new buffId = 0 ; buffId < TOTAL_RELIC_BUFF ; buffId++)
		{
			if(g_iRelicBuffLevel[buffId] > NO_BUFF)
			{
				static szBuffName[20];
				formatex(szBuffName , charsmax(szBuffName), "%s (L.%i) | ", g_szBuffName[buffId] , g_iRelicBuffLevel[buffId])	
				strcat(szMsg, szBuffName, charsmax(szMsg))
			}
		}
		hudmessage_queue_set_player_message_left(g_hudmessage_id_relic, id, szMsg)
	}	
	return PLUGIN_HANDLED;
}

Float:Ham_TraceAttack_Pre_Relic(Victim, Attacker, Float:Damage, Float:Direction[3], Traceresult, DamageBits)
{
	if(g_iRelicBuffLevel[RELIC_DAMAGE] > NO_BUFF && !is_zombie(Attacker) && is_user_alive(Attacker))
	{
		Damage = Damage * ( 1.0 + g_iRelicBuffLevel[RELIC_DAMAGE] * 0.05 )
	}
	return Damage;
}

Float:Ham_TakeDamage_Pre_Relic(Victim, iInflictor, Attacker, Float:fDamage, m_Damagebits )
{
	if(g_iRelicBuffLevel[RELIC_TOUGHNESS] > NO_BUFF && !is_zombie(Attacker) && is_user_alive(Attacker))
	{
		fDamage = fDamage * ( 1.0 - g_iRelicBuffLevel[RELIC_TOUGHNESS] * 0.1 )
	}
	return fDamage;
}

// This is currently used for setting speed
Ham_Item_PreFrame_Post_Relic(id)
{
	static Float:fMaxSpeed;
	pev(id,pev_maxspeed,fMaxSpeed)
	if(g_iRelicBuffLevel[RELIC_SPEED] > 0 && is_user_alive(id) && !is_zombie(id) && fMaxSpeed != 1.0)
	{
		fMaxSpeed *= ( 1.0 + g_iRelicBuffLevel[RELIC_SPEED] * 0.05 );
		set_pev(id,pev_maxspeed, fMaxSpeed)
	}
}

round_start_post_relic()
{
	for(new i = 0 ; i < TOTAL_RELIC_BUFF ; i++)
		g_iRelicBuffLevel[i] = NO_BUFF;
}

rest_start_relic()
{
	g_iRelicTaken = 0;
	if(g_SpawnCountCSDM <= 0)
		return;

	remove_task(TASKID_SPAWN);
	remove_task(TASKID_SHOW_RADAR)
	DestroyAllBoxes();
	for(new i = 0 ; i < MAX_RELIC ; i++)
	{
		g_iRelicEntId[i] = NOT_SPAWN;
		g_iRelicEntOnSpawnPoint[i] = NOT_SPAWN;
	}
}

stage_start_relic()
{
	set_task(get_pcvar_float(cvar_relic_spawn_first), "spawn_relic", TASKID_SPAWN, _, _)
	set_task(get_pcvar_float(cvar_relic_spawn_second), "spawn_relic", TASKID_SPAWN, _, _)
	set_task(1.0, "show_relic", TASKID_SHOW_RADAR, _, _, "b")
}

public spawn_relic()
{
	if(GetNextSupplyId() == NO_MORE_SUPPLY)
		return;

	client_print(0 , print_center , "A relic is spawned , check your radar")
	create_random_supply_ent();	
	return;
}

public show_relic()
{
	for (new i = 0 ; i < MAX_RELIC ; i++){
		if(g_iRelicEntId[i] == NOT_SPAWN)
			continue;

		for(new j = 1 ; j < 33 ; j++){
			if(is_user_alive(j) && !is_user_bot(j) && is_user_connected(j) )
			ShowEntOnRadar(j , g_iRelicEntOnSpawnPoint[i] , i)
		}
	}
}

public create_random_supply_ent()
{
	new iSupplyId = GetNextSupplyId();
	if(iSupplyId == NO_MORE_SUPPLY)
		return;

	new iSpawnPointId = random_num(0 , g_SpawnCountCSDM);
	
	while(IsSpawnPointTaken(iSpawnPointId))
	{
		iSpawnPointId = random_num(0 , g_SpawnCountCSDM);
	}
	
	new Float:origin[3]
	new ent = create_entity("info_target")
	
	g_iRelicEntId[iSupplyId] = ent;
	g_iRelicEntOnSpawnPoint[iSupplyId] = iSpawnPointId
	
	origin[0] = g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_X]
	origin[1] = g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_Y]
	origin[2] = g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_Z] - 18
	entity_set_origin(ent,origin);
	
	entity_set_string(ent,EV_SZ_classname, CLASSNAME_RELIC);     // set classname for it
	entity_set_model(ent,MODEL_RELIC);			 			  // set model for it
	entity_set_int(ent,EV_INT_solid, SOLID_TRIGGER)					  // make it touchable
	
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {16.0,16.0,36.0}
	new Float:mins[3] = {-16.0,-16.0,-36.0}
	entity_set_size(ent,mins,maxs)
	fm_set_rendering(ent,kRenderFxGlowShell,255,255,255,kRenderNormal,8); // white
}

ShowEntOnRadar(id, iSpawnPointId, cnt) 
{

	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostage, {0,0,0}, .player=id);
	write_byte(id);		// who can see this?
	write_byte(cnt);	// Just a "Display id" on the radar
	write_coord(floatround(g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_X]));
	write_coord(floatround(g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_Y]));
	write_coord(floatround(g_spawns_csdm[iSpawnPointId][SPAWN_DATA_ORIGIN_Z]));
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostageDie, {0,0,0}, .player=id);
	write_byte(cnt);
	message_end();
}

public Fw_Touch_Relic(iRelicEnt, iPlayerEnt)
{
	if(is_user_bot(iPlayerEnt) || !is_user_alive(iPlayerEnt))
		return;

	take_relic(iRelicEnt);
	engfunc(EngFunc_EmitSound,iRelicEnt,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	engfunc(EngFunc_RemoveEntity, iRelicEnt)
}

take_relic(iRelicEnt)
{
	new iSupplyId = GetSupplyIdByEntId(iRelicEnt);
	g_iRelicEntId[iSupplyId] = NOT_SPAWN;
	g_iRelicEntOnSpawnPoint[iSupplyId] = NOT_SPAWN;
	g_iRelicTaken++;

	if(g_iRelicTaken == 2)
	{
		new iBuffId = random_num(0 , TOTAL_RELIC_BUFF - 1)
		g_iRelicBuffLevel[iBuffId]++;
		for(new i = 0 ; i < 33 ; i++)
		{
			if(is_user_connected(i) && !is_user_bot(i))
			{
				client_cmd(i, "spk %s", UPGRADE_SOUND);
			}
		}
		add_token_to_all(1);
	}
}


DestroyAllBoxes()
{
	for( new i = 0 ; i < MAX_RELIC ; i++)
	{
		static iEntId;  iEntId = g_iRelicEntId[i];
		if(iEntId != NOT_SPAWN)
		{
			g_iRelicEntId[i] = NOT_SPAWN;
			g_iRelicEntOnSpawnPoint[i] = NOT_SPAWN;
			engfunc(EngFunc_RemoveEntity, iEntId)
		}
	}
}

GetNextSupplyId()
{
	for(new i = 0 ; i<MAX_RELIC; i++){
		if(g_iRelicEntId[i] == NOT_SPAWN)
			return i;
	}
	
	return NO_MORE_SUPPLY
}

GetSupplyIdByEntId(iEntId)
{
	for(new i = 0 ; i<MAX_RELIC;i++){
		if(g_iRelicEntId[i] == iEntId)
			return i;
	}
	
	return -1
}

bool:IsSpawnPointTaken(iSpawnPointId)
{
	for(new i = 0 ; i<MAX_RELIC;i++)
	{
		if(g_iRelicEntOnSpawnPoint[i] == iSpawnPointId)
			return true;
	}
	
	return false;
}