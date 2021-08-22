#define TASK_ID 500
#define TASK_SHOW_AMMOPACK 600
const SECONDARY = ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

enum _:PAMMO_ID {
	PAMMO_ID_338 = 1,	// awp
	PAMMO_ID_762,
	PAMMO_ID_556_NATO,
	PAMMO_ID_556,
	PAMMO_ID_BUCK,
	PAMMO_ID_45,	// .45 acp
	PAMMO_ID_57,
	PAMMO_ID_50,	// deagle	
	PAMMO_ID_357,	// p228
	PAMMO_ID_9
}

new const g_PAMMO_ID[] = 
{   
	-1,				// thighpick
	PAMMO_ID_357,
	-1,				// shield
	PAMMO_ID_762,
	12,
	PAMMO_ID_BUCK,
	14,
	PAMMO_ID_45,	// Mac10
	PAMMO_ID_556,
	13,				// smoke
	PAMMO_ID_9,
	PAMMO_ID_57,	// 57
	PAMMO_ID_45,	// ump45
	PAMMO_ID_556,	// sg550
	PAMMO_ID_556,
	PAMMO_ID_556,
	PAMMO_ID_45,
	PAMMO_ID_9,		// 9mm	
	PAMMO_ID_338,	// awp
	PAMMO_ID_9,	
	PAMMO_ID_556_NATO,	// m249
	PAMMO_ID_BUCK,
	PAMMO_ID_556,
	PAMMO_ID_9,
	PAMMO_ID_762,
	11,
	PAMMO_ID_50,	// deagle
	PAMMO_ID_556,
	PAMMO_ID_762,
	-1,
	PAMMO_ID_57,
	-1
}

new g_iWpnAmmoSupply[] = {
	0, 
	39,				// "weapon_p228", 
	0, 				// weapon_shield
	10,				// "weapon_scout", 
	0,				// weapon_hegrenade 
	7,				// "weapon_xm1014", 
	0,				// "weapon_c4"
	50,				// "weapon_mac10", 
	30,				// "weapon_aug", 
	0,				// "weapon_smokegrenade", 
	60,				// "weapon_elite", 
	50,				// "weapon_fiveseven", 
	50,				// "weapon_ump45", 
	20,				// "weapon_sg550", 
	30,				// "weapon_galil", 
	30,				// "weapon_famas", 
	50,				// "weapon_usp",
	60,				// "weapon_glock18", 
	10,				// "weapon_awp", 
	60,				// "weapon_mp5navy", 
	50,				// "weapon_m249", 
	7,				// "weapon_m3", 
	30,				// "weapon_m4a1", 
	60,				// "weapon_tmp", 
	20,				// "weapon_g3sg1", 
	0,				// "weapon_flashbang", 
	21,				// "weapon_deagle",
	30,				// "weapon_sg552", 
	30,				// "weapon_ak47", 
	0,				// "weapon_knife", 
	50,				// "weapon_p90", 
	0
}

new g_iAmmoPack[33];
new g_hudmessage_id_ammopack;
new g_iCurrAmmoBoxDropChance = 10;
new cvar_ammo_box_drop_chance_base = 10;
new cvar_ammo_box_drop_chance_increment = 10;

new const CLASSNAME_AMMOBOX[] = "ammo_box";
new const MODEL_AMMOBOX[] = "models/zombie_mod/ammobox.mdl";

plugin_init_ammopack()
{
	register_clcmd( "buyammo1", "buy_ammo" );
	register_clcmd( "buyammo2", "buy_ammo" );

	register_touch(CLASSNAME_AMMOBOX , "player" , "Fw_Touch_AmmoBox");

	cvar_ammo_box_drop_chance_base = register_cvar("zs_ammo_box_drop_chance_base", "10")
	cvar_ammo_box_drop_chance_increment = register_cvar("zs_ammo_box_drop_chance_increment", "5")

	g_hudmessage_id_ammopack = hudmessage_queue_register_left();
}

plugin_precache_ammopack()
{
	precache_model(MODEL_AMMOBOX);
}

round_start_post_ammopack()
{
	for(new i = 0 ; i < 33 ; i++)
	{
		g_iAmmoPack[i] = 3;
	}
	destroy_all_ammobox();
	g_iCurrAmmoBoxDropChance = get_pcvar_num(cvar_ammo_box_drop_chance_base);

	remove_task(TASK_SHOW_AMMOPACK)
	set_task(1.0, "show_ammo_pack", TASK_SHOW_AMMOPACK, _, _, "b")
}

destroy_all_ammobox()
{
	new ammobox_ent;
	while((ammobox_ent = find_ent_by_class(ammobox_ent, CLASSNAME_AMMOBOX))) {
		remove_entity(ammobox_ent);
	}
}

Ham_Killed_Post_AmmoPack(victim /*, attacker, shouldgib */)
{
	if(!is_zombie(victim) || g_iGameState == STATE_REST)
		return;

	if(random_num(0 , 100) > g_iCurrAmmoBoxDropChance)
	{
		g_iCurrAmmoBoxDropChance += get_pcvar_num(cvar_ammo_box_drop_chance_increment);
	}
	else
	{
		g_iCurrAmmoBoxDropChance = get_pcvar_num(cvar_ammo_box_drop_chance_base);
		static Float:fOrigin[3]
		entity_get_vector(victim, EV_VEC_origin, fOrigin)
		create_ammobox_ent(fOrigin)
	}

}

// iTouched = AmmoBox
public Fw_Touch_AmmoBox(iAmmoBoxEnt, iPlayerEnt)
{
	if(is_user_bot(iPlayerEnt) || !is_user_alive(iPlayerEnt))
		return;

	engfunc(EngFunc_EmitSound,iAmmoBoxEnt,CHAN_ITEM,"items/gunpickup2.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM);
	engfunc(EngFunc_RemoveEntity, iAmmoBoxEnt)

	static players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount)
	for( i = 0 ; i < iCount ; i++)
	{
		static iPlayerId; iPlayerId = players[i];
		g_iAmmoPack[iPlayerId]++;
	}
}

public show_ammo_pack()
{
	static players[MAX_PLAYERS] , iCount , i , szMsg[32];
	get_players_ex(players, iCount)
	for( i = 0 ; i < iCount ; i++)
	{
		static iPlayerId; iPlayerId = players[i];
		formatex(szMsg, charsmax(szMsg), "Ammo Pack : %i" , g_iAmmoPack[iPlayerId]);
		hudmessage_queue_set_player_message_left(g_hudmessage_id_ammopack, iPlayerId, szMsg);
	}
	
	return PLUGIN_HANDLED;
}

public buy_ammo(id)
{
	if(g_iAmmoPack[id] <= 0 || !is_user_alive(id))
	 		return PLUGIN_HANDLED;

	static iBpAmmo;
	static iClip;
	static iCswId; 
	static iGet;
	static iBpAmmoId;
	iCswId = get_user_weapon(id , iClip , iBpAmmo);
	if(g_iWpnAmmoSupply[iCswId] > 0)
	{
		iGet = g_iWpnAmmoSupply[iCswId];
		iBpAmmoId = g_PAMMO_ID[iCswId];
		iBpAmmo += iGet
		cs_set_user_bpammo(id, iCswId, iBpAmmo)

		message_begin(MSG_ONE, get_user_msgid("AmmoPickup"), {0,0,0}, id)
		write_byte(iBpAmmoId)
		write_byte(iGet)
		message_end()
		g_iAmmoPack[id]--;
	}

	// Don't let this event pass
	return PLUGIN_HANDLED;
}

public create_ammobox_ent(Float:fOrigin[3])
{
	new ent = create_entity("info_target")
	entity_set_origin(ent,fOrigin);
	
	entity_set_string(ent,EV_SZ_classname,CLASSNAME_AMMOBOX);     // set classname for it
	entity_set_model(ent,MODEL_AMMOBOX);			 			  // set model for it
	entity_set_int(ent,EV_INT_solid, SOLID_TRIGGER)					  // make it touchable + passable
	entity_set_int( ent, EV_INT_movetype, MOVETYPE_TOSS );
	
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
	
	new Float:maxs[3] = {16.0,16.0,16.0}
	new Float:mins[3] = {-16.0,-16.0,-16.0}
	entity_set_size(ent,mins,maxs)
	fm_set_rendering(ent,kRenderFxGlowShell,255,255,255,kRenderNormal,8); // white
	drop_to_floor(ent);
}



/*
public Ham_Killed_Post(victim, attacker, shouldgib)
{
	if(is_user_alive(attacker) && !is_user_bot(attacker))
	{
		g_iAmmoPack[attacker]++

		static iTeamPack; iTeamPack = get_pcvar_num(cvar_team_pack_per_kill);
		static players[MAX_PLAYERS] , iCount , i;
		get_players_ex(players, iCount , GetPlayers_ExcludeDead | GetPlayers_ExcludeBots)
		for( i = 0 ; i < iCount ; i++)
		{
			static iPlayerId; iPlayerId = players[i];
			if(cs_get_user_team(iPlayerId) == CS_TEAM_CT)
			{
				g_iAmmoPack[iPlayerId] += iTeamPack;
			}
		}
	}
}
*/