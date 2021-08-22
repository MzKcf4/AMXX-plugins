// A 33 bit of Primary weapons
const PRIMARY = ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_M249))
const SECONDARY = ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

#define SPAWN_DATA_ORIGIN_X 0
#define SPAWN_DATA_ORIGIN_Y 1
#define SPAWN_DATA_ORIGIN_Z 2

#define NOT_TAKEN -1

new const CLASSNAME[] = "grave";
new const MODEL[] = "models/grave.mdl";
new const ICON_SPR[] = "sprites/zombie_plague/icon_supplybox.spr"

new const REVIVE_PICKUP_SOUND[] = "zombie_plague/revive.wav";

#define TASK_RESPAWN_HUMAN	300
#define TASK_STRIP_GIVE 400
#define TASK_REMOVE_PROTECTION_HUMAN	700
#define TASK_SHOW_RADAR 734

new cvar_sp_time , cvar_respawn_time;
new g_iPlayerPrimaryWpn[33], g_iPlayerSecondaryWpn[33];	
new g_iGraveEntId[33] = {NOT_TAKEN , ...}				// [TombID] = an Entity ID ( or ptr )
new Float:g_fGraveCoord[33][SPAWN_DATA_ORIGIN_Z+1]

// new g_iMaxPlayer;
// new m_fakeHostage , m_fakeHostageDie;

#define ICON_DISPLAY_DELAY 0.03
new g_iGraveIconId , Float:g_fGraveIconDelay[33];

plugin_init_human_revive()
{
	// register_forward(FM_Touch, "fw_touch" , 0)
	// register_event("HLTV", "Event_NewRound", "1=0", "2=0")

	cvar_sp_time = register_cvar("zs_revive_sp_time","5.0");
	cvar_respawn_time = register_cvar("zs_revive_time", "15.0");

	// m_fakeHostage = get_user_msgid("HostagePos");
	// m_fakeHostageDie = get_user_msgid("HostageK");
}

/*


public plugin_precache()
{
	precache_model(MODEL);
	precache_sound(REVIVE_PICKUP_SOUND);
	g_iGraveIconId = engfunc(EngFunc_PrecacheModel, ICON_SPR)
}
*/



round_start_post_human_revive()
{
	//remove_task(TASK_SHOW_RADAR)
	//destroy_all_grave();
	for(new i = 0 ; i < 33 ; i++)
	{
		g_iPlayerPrimaryWpn[i] = NOT_TAKEN;
		g_iPlayerSecondaryWpn[i] = NOT_TAKEN;
		if(task_exists(i+TASK_RESPAWN_HUMAN)) 
			remove_task(i+TASK_RESPAWN_HUMAN)
	}
	// set_task(1.0, "show_grave", TASK_SHOW_RADAR, _, _, "b")
}

rest_start_human_revive()
{
	for(new i = 0 ; i < 33 ; i++)
	{
		if(task_exists(i+TASK_RESPAWN_HUMAN)) 
			remove_task(i+TASK_RESPAWN_HUMAN)

		if(is_user_connected(i) && !is_user_alive(i) && !is_zombie(i))
			revive_player(i);
	}
}

/*
public show_grave()
{
	for (new i = 1 ; i < g_iMaxPlayer ; i++){
		if(g_iGraveEntId[i] == NOT_TAKEN)
			continue;

		for(new j = 1 ; j < g_iMaxPlayer ; j++){
			if(is_user_alive(j) && !is_user_bot(j) && is_user_connected(j) )
			ShowEntOnRadar(j , i , i)
		}
	}
}
*/
/*
public client_PostThink(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return
	if(g_fGraveIconDelay[id] + ICON_DISPLAY_DELAY > get_gametime())
		return;
	g_fGraveIconDelay[id] = get_gametime();

	static i
	for(i = 1 ; i < 33 ; i++)
	{
		if(g_iGraveEntId[i] != NOT_TAKEN)
		{
			create_icon_origin(id, g_iGraveEntId[i], g_iGraveIconId)
		}
	}
}
*/

/*
ShowEntOnRadar(id, iSpawnPointId, cnt) 
{
	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostage, {0,0,0}, .player=id);
	write_byte(id);		// who can see this?
	write_byte(cnt);	// Just a "Display id" on the radar
	write_coord(floatround(g_fGraveCoord[iSpawnPointId][SPAWN_DATA_ORIGIN_X]));
	write_coord(floatround(g_fGraveCoord[iSpawnPointId][SPAWN_DATA_ORIGIN_Y]));
	write_coord(floatround(g_fGraveCoord[iSpawnPointId][SPAWN_DATA_ORIGIN_Z]));
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, m_fakeHostageDie, {0,0,0}, .player=id);
	write_byte(cnt);
	message_end();
	
}
*/
Ham_Killed_Pre_Human_Revive(victim, attacker, shouldgib)
{
	if(!is_user_bot(victim) && !is_zombie(victim))
	{
		new weapons[32], num
		get_user_weapons(victim, weapons, num)
		for (new i = 0; i < num; i++) 
		{
			new iWpnId = wpn_core_get_owned_wpnId(victim, weapons[i])
			if (PRIMARY & (1 << weapons[i])) 
				g_iPlayerPrimaryWpn[victim] = iWpnId;

			if (SECONDARY & (1 << weapons[i]))
				g_iPlayerSecondaryWpn[victim] = iWpnId;
		}

		// new Float:fOrigin[3]
		// entity_get_vector( victim, EV_VEC_origin, fOrigin)
		// create_grave_ent(victim , fOrigin)
	}
}

public create_grave_ent(iPlayerId , Float:fOrigin[3])
{
	new ent = create_entity("info_target")
	
	g_iGraveEntId[iPlayerId] = ent;
	
	g_fGraveCoord[iPlayerId][SPAWN_DATA_ORIGIN_X] = fOrigin[0]
	g_fGraveCoord[iPlayerId][SPAWN_DATA_ORIGIN_Y] = fOrigin[1]
	g_fGraveCoord[iPlayerId][SPAWN_DATA_ORIGIN_Z] = fOrigin[2]
	entity_set_origin(ent,fOrigin);
	
	entity_set_string(ent,EV_SZ_classname,CLASSNAME);     // set classname for it
	entity_set_model(ent,MODEL);			 			  // set model for it
	entity_set_int(ent,EV_INT_solid, SOLID_TRIGGER)					  // make it touchable + passable
	
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {16.0,16.0,36.0}
	new Float:mins[3] = {-16.0,-16.0,-36.0}
	entity_set_size(ent,mins,maxs)
	fm_set_rendering(ent,kRenderFxGlowShell,255,255,255,kRenderNormal,8); // white
	drop_to_floor(ent);
}

/*
public fw_touch(ptr, ptd)
{	
	new classname[32]
	if(!pev_valid(ptr))
		return FMRES_IGNORED;

	pev(ptr, pev_classname, classname, 31)
	if(classname[0] == 'g' && classname[4] == 'e' && !is_user_bot(ptd) && is_user_alive(ptd))	//   equali(classname,"grave")
	{
		revive_player(ptr)
		emit_sound(ptd, CHAN_WEAPON, REVIVE_PICKUP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_RemoveEntity, ptr)

	}
	return FMRES_HANDLED
}
*/

/*
// ToDo: Another method for respawning during Rest Phrase?
public revive_player(entptr)
{
	new iPlayerId = GetPlayerIdByEntId(entptr);
	g_iGraveEntId[iPlayerId] = NOT_TAKEN;

	remove_task(TASK_RESPAWN_HUMAN+iPlayerId);

	set_task(get_pcvar_float(cvar_respawn_time),"respawn_player",TASK_RESPAWN_HUMAN+iPlayerId);
}
*/
public revive_player(iPlayerId)
{
	remove_task(TASK_RESPAWN_HUMAN+iPlayerId);
	set_task(get_pcvar_float(cvar_respawn_time),"respawn_player",TASK_RESPAWN_HUMAN+iPlayerId);
}

GetPlayerIdByEntId(iEntId)
{
	for(new i = 0 ; i<g_iMaxPlayer; i++){
		if(g_iGraveEntId[i] == iEntId)
			return i;
	}
	
	return -1
}

public respawn_player(taskid)
{
	new id = taskid-TASK_RESPAWN_HUMAN;
	if(!is_user_connected(id) || is_user_alive(id)) return;
	// if(!is_user_connected(id)) return;

	ExecuteHamB(Ham_CS_RoundRespawn,id); // note the B
	
	new Float:time = get_pcvar_float(cvar_sp_time);

	set_task(0.3 , "strip_and_give_wpn" , TASK_STRIP_GIVE+id);

	// spawn protection
	if(time > 0.0)
	{
		fm_set_user_godmode(id,1);
		fm_set_rendering(id,kRenderFxGlowShell,200,200,100,kRenderNormal,8); // goldenish
		// fm_set_rendering(id,kRenderFxGlowShell,100,100,100,kRenderNormal,8); // gray/white
		set_task(time,"remove_spawn_protection_human",TASK_REMOVE_PROTECTION_HUMAN+id);
	}
}

public strip_and_give_wpn(taskid)
{
	new iPlayerId = taskid-TASK_STRIP_GIVE;
	new iPrimaryWpnId = g_iPlayerPrimaryWpn[iPlayerId]
	new iSecondaryWpnId = g_iPlayerSecondaryWpn[iPlayerId];
	
	strip_user_weapons(iPlayerId);
	give_item(iPlayerId, "weapon_knife")
	cs_set_user_nvg(iPlayerId , 1);

	if(iPrimaryWpnId > NOT_TAKEN)
		wpn_core_give_wpn(iPlayerId, iPrimaryWpnId)
	if(iSecondaryWpnId > NOT_TAKEN)
		wpn_core_give_wpn(iPlayerId, iSecondaryWpnId)

}

// get rid of the spawn protection effects
public remove_spawn_protection_human(taskid)
{
	new id = taskid-TASK_REMOVE_PROTECTION_HUMAN;

	if(!is_user_connected(id)) return;
	
	fm_set_user_godmode(id,0);
	fm_set_rendering(id); // reset back to normal
}

destroy_all_grave()
{
	for( new i = 0 ; i < 33 ; i++)
	{
		if(g_iGraveEntId[i] != NOT_TAKEN)
		{

			engfunc(EngFunc_RemoveEntity, g_iGraveEntId[i])
			g_iGraveEntId[i] = NOT_TAKEN;
		}
	}
}

stock create_icon_origin(id, ent, sprite) // By sontung0
{
	if (!pev_valid(ent)) return;
	
	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)
	
	new target = ent
	new Float:fTargetOrigin[3]
	entity_get_vector(target, EV_VEC_origin, fTargetOrigin)
	fTargetOrigin[2] += 40.0
	
	if (!is_in_viewcone(id, fTargetOrigin)) return;

	new Float:fMiddle[3], Float:fHitPoint[3]
	xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
	trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
							
	new Float:fWallOffset[3], Float:fDistanceToWall
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
	normalize(fMiddle, fWallOffset, fDistanceToWall)
	
	new Float:fSpriteOffset[3]
	xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
	new Float:fScale
	fScale = 0.01 * fDistanceToWall
	
	new scale = floatround(fScale)
	scale = max(scale, 1)
	// scale = min(scale, get_pcvar_num(cvar_supplybox_icon_size))
	scale = min(scale, 2)
	scale = max(scale, 1)

	// te_sprite(id, fSpriteOffset, sprite, scale, get_pcvar_num(cvar_supplybox_icon_light))
	te_sprite(id, fSpriteOffset, sprite, scale, 200)
}

stock te_sprite(id, Float:origin[3], sprite, scale, brightness) // By sontung0
{	
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite)
	write_byte(scale) 
	write_byte(brightness)
	message_end()
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}