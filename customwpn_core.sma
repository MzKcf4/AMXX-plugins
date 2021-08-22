#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <string>
#include <stripweapons>
#include <wpn_const>
#include <wpn_core>
#include <gfl_voice>
#include <cs_ham_bots_api>
#include <reapi>
#include <json>
#include <customwpn_mode_api>
#include <customwpn_json_const>
#include "customwpn_variables.sma"
#include "customwpn_stocks.sma"
#include "customwpn_loader.sma"
#include "customwpn_wpn_hooks.sma"

#pragma dynamic 10240

#define PLUGIN "Custom Wpn - Core"
#define VERSION "1.0"
#define AUTHOR "MzKc"

new pcvar_wpnFree;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	// -------- for stock use to create entity ------------ //
	g_iAllocString_infoTarget = engfunc(EngFunc_AllocString, "info_target");
	g_iAllocString_envSprite = engfunc(EngFunc_AllocString, "env_sprite");

	// === Safety ===
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_Safety_Spawn_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_Safety_Killed_Post", 1)
	
	// Shooting speed
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	// Remove weapons
	// register_event("DeathMsg", "Event_Client_Killed", "a"); 
	
	// Bullet holes
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack_World");
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack_World");
	// Custom dmg for players
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack_Player")

	// Extended knife dmg
	// register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")
	
	// So maybe use bits of CSWID to NOT register hooks repeatly?
	new registeredCswId = 0;
	console_print(0 , "[CORE] WpnCount is : %i" , g_iWpnCount)
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		register_clcmd( g_szWpnId[i] , "CmdSelectWpn" );
		// Don't let following func register twice for same CswId
		if(Get_BitVar(registeredCswId , g_iWpnCswId[i]))
			continue;
		Set_BitVar(registeredCswId,g_iWpnCswId[i])

		// HamItemDeploy -- When player switchs (deploys) to that weapon
		RegisterHam(Ham_Item_Deploy, g_szWpnIdOld[i], "HamF_Item_Deploy_Post", .Post = true)
		// When player gets the Item
		RegisterHam(Ham_Item_AddToPlayer, g_szWpnIdOld[i] , "HamF_Item_AddToPlayer_Post", .Post = true );
		if(g_iWpnCswId[i] == CSW_KNIFE)
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HamF_Knife_PrimaryAttack_Pre");
			RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HamF_Knife_SecondaryAttack_Pre");
			RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HamF_Knife_SecondaryAttack_Post" , .Post = true);
			RegisterHam(Ham_Item_PostFrame, "weapon_knife", "HamF_Knife_PostFrame")		// Ammo reduction
			RegisterHam(Ham_Item_Holster, "weapon_knife", "HamF_Knife_Holster_Post", .Post = true)		// When switch away
		}
		else
		{			
			RegisterHam(Ham_Weapon_Reload, g_szWpnIdOld[i], "HamF_Weapon_Reload_Pre")
			// Handles reloading time and animation of overriden weapons
			RegisterHam(Ham_Weapon_Reload, g_szWpnIdOld[i], "HamF_Weapon_Reload_Post", .Post = true)
			
			// Recoil & Auto pistol
			RegisterHam(Ham_Weapon_PrimaryAttack, g_szWpnIdOld[i], "HamF_Weapon_PrimaryAttack")
			RegisterHam(Ham_Weapon_PrimaryAttack, g_szWpnIdOld[i], "HamF_Weapon_PrimaryAttack_Post", .Post = true)
			
			// Tracks reload animtaion & correctly set the clip after reload
			RegisterHam(Ham_Item_PostFrame, g_szWpnIdOld[i], "HamF_Item_PostFrame")		// Ammo reduction

			// for weapons that has 2nd weapon state.
			if(WPN_WITH_STATE &  (1 << g_iWpnCswId[i]))
			{
				RegisterHam(Ham_Weapon_SecondaryAttack, g_szWpnIdOld[i], "OnWeaponSecondaryAttack", .Post = true)
			}
		}

	}
	g_MsgWeaponList = get_user_msgid("WeaponList");
	
	// FM_SetModel calls when any model is deployed to the world. (e.g dropping ) , so also used to catch "Drop" event
	register_forward(FM_SetModel, "fw_SetModel")

	// ToDo: 
	// RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_Weapon_PrimaryAttack_Post", 1)	// For Muzzle
	
	// This blocks client from sending their weapon ATTACK info
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	// Knife
	register_forward(FM_EmitSound, "fw_EmitSound");
	register_clcmd( "WpnMenu","WpnMenu" );
	
	pcvar_wpnFree = register_cvar("wpn_free" , "0")

	register_srvcmd("wpn_zombie_mode_on" , "enable_zombie_mode")
	register_srvcmd("wpn_zombie_mode_off" , "disable_zombie_mode")
}

public plugin_precache()
{
	// Forward to Loader to handle SC events
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	g_Forwards[FW_GIVE_WPN] = CreateMultiForward("wpn_core_give_wpn", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_REGISTER_WPN_POST] = CreateMultiForward("wpn_register_wpn", ET_IGNORE, FP_CELL, FP_CELL)
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr");

	loader_load_weapons();
	precache_special();
}

//======

public enable_zombie_mode()
{
	g_bIsZombieMode = true;
}

public disable_zombie_mode()
{
	g_bIsZombieMode = false;	
}

public client_putinserver(id)
{
	Safety_Connected(id)	
}

public client_disconnected(id)
{
	Safety_Disconnected(id)
	// Muzzleflash_Reset(id)
}

// ================== Wpn Attack related ==================== //

// =========== Knife emit sound ================= //
public fw_EmitSound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED;

	// weapons/knife_ hit1/2/3/4  ;  hitwall1  ; slash1/2 , stab
	if (sample[0] == 'w' && sample[1] == 'e' && sample[8] == 'k' && sample[9] == 'n')
	{
		static iWpnId; iWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , id);
		if(iWpnId == -1)	
			return FMRES_IGNORED;

		switch(sample[17])
		{
			//case 'l':		dep[l]oy1
			//	return FMRES_SUPERCEDE;

			case 's':	// sla[s]h1
			{
				if(strlen(g_szKnifeSlashSound[iWpnId]) > 0){
					emit_sound(id, CHAN_WEAPON, g_szKnifeSlashSound[iWpnId], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;				
				}
			}
			case 'w':	// hit[w]all1
			{
				if(strlen(g_szKnifeHitWallSound[iWpnId]) > 0){
					emit_sound(id, CHAN_WEAPON, g_szKnifeHitWallSound[iWpnId], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;
				}
			}
			case 'b':  // sta[b]
			{
				if(strlen(g_szKnifeStabSound[iWpnId]) > 0){
					emit_sound(id, CHAN_WEAPON, g_szKnifeStabSound[iWpnId], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;
				}
			}
			case '1', '2', '3', '4':	// hit[1]
			{
				if(strlen(g_szKnifeHitSound[iWpnId]) > 0){
					emit_sound(id, CHAN_WEAPON, g_szKnifeHitSound[iWpnId], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;
				}
			}
		}
	}
	return FMRES_IGNORED;
}


// ========================== Knife attack radius related ===================================

// This is fired when slashing knife
public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	// if(get_player_weapon(id) != CSW_HORSEAXE || !Get_BitVar(g_Had_HorseAxe, id))
	if(!g_bIsZombieMode || get_player_weapon(id) != CSW_KNIFE || is_user_bot(id))
		return FMRES_IGNORED
	// console_print(0 , "Tracing hull");
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

// ===============================

public CmdSelectWpn(playerId)
{
	
	static szWpnName[32];
	// 0 arg is the command itself
	read_argv(0 , szWpnName , charsmax(szWpnName));
	// console_print(0 , "Someone selecting : %s" , szWpnName);
	
	static wpnId;
	wpnId = get_wpnId_by_wpnname(szWpnName);
	
	engclient_cmd(playerId, g_szWpnIdOld[wpnId]); 
	return PLUGIN_CONTINUE;
}


// Weapon that has secondary attack
// https://forums.alliedmods.net/showthread.php?t=199103
public OnWeaponSecondaryAttack(ent)
{
	static entOwnerId , cswId, wpnId;
	// https://wiki.alliedmods.net/CBasePlayerItem_(CS)  for  what "41" & "43" means
	entOwnerId = get_pdata_cbase(ent, 41, 4);
	// 43's type is "int" , not CBaseXXXX , so use pdata_int
	cswId = get_pdata_int(ent, 43, 4);
	
	wpnId = Get_Owned_Wpn_By_CSW(cswId , entOwnerId);
	if(wpnId == NO_WPN_OWNED)
		return HAM_IGNORED;
		
	static iWpnState; iWpnState = get_pdata_int(ent , m_fWeaponState , 4);

	g_WpnState[entOwnerId][wpnId] = iWpnState;
	
	return HAM_HANDLED;
}

// =========================== Weapon dropping ============================================ //
public fw_SetModel(ent , const model[])
{    
	if (!pev_valid(ent) || !equali(model, g_szWbox_model_prefix, sizeof g_szWbox_model_prefix - 1) || equali(model, g_szWbox_model))
		return FMRES_IGNORED
	
	// Checks if the ent is a dropped weapon
	// When dropping a weapon, the entity is linked to a weaponbox entity.
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	// Who drop this?
	static playerId; playerId = pev(ent , pev_owner);
	if( playerId < 0  || playerId > 33)
		return FMRES_IGNORED
	
	// So now we know a playerId dropped a WeaponBox entity with model set to "w_xxxxx"
	// Now check all wpn that replace that w_ weapon , see if player drops a wpn weapon or just an original weapon
	
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		static replacedMdl[32]
		// models/w_xxx.mdl
		formatex(replacedMdl , charsmax(replacedMdl) , "%s%s%s%s" , MDL_PREFIX_DEFAULT, MDL_W_PREFIX, MDL_DEFAULT[g_iWpnCswId[i]] , MDL_EXT)
		
		// This is a model replaced by Wpn AND player own this wpnid 
		if( equali(model , replacedMdl)  &&  Get_BitVar(g_HadWpn[i] , playerId))
		{
			static weapon; weapon = find_ent_by_owner(-1, g_szWpnIdOld[i], ent)
			if(!pev_valid(weapon))
				return FMRES_IGNORED;
			
			set_pev(weapon, pev_impulse, g_iImpulse[i])
			engfunc(EngFunc_SetModel, ent, g_szModel_W[i])
			DropWpn(i , playerId)
			//console_print(0, "Model set for : %s ; owner = %i ", model , playerId)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED;
}
// =============================== Commands ============================================


public DropWpn(wpnid, playerId)
{
	UnSet_BitVar(g_HadWpn[wpnid] , playerId);
}


public CmdBuyWpn(playerId)
{
	// Ignore if Cmd without arg
	if(read_argc() == 1) return PLUGIN_HANDLED;
	
	new arg[3] , wpnid
	// Retrieves full client command string., used in clcmd / concmd forawrd only.
	read_argv(1, arg , charsmax(arg));
	wpnid = str_to_num(arg);
	
	if(wpnid < 0 || wpnid >= g_iWpnCount) 
		return PLUGIN_HANDLED;
	
	// console_print(0, "wpnid %i is called by %i , wpnName = %s" , wpnid , playerId , g_szWpnDisplayName[wpnid])
	BuyWpn(wpnid , playerId);
	return PLUGIN_HANDLED
}

public BuyWpn(wpnid , playerId)
{
	if(g_bIsZombieMode && g_iWpnCost[wpnid] > 0 && (get_pcvar_num(pcvar_wpnFree) == 0))
		return PLUGIN_HANDLED;
	if(get_pcvar_num(pcvar_wpnFree) == 0)
	{
		static iPlayerMoney; iPlayerMoney = cs_get_user_money(playerId)
		if(iPlayerMoney < g_iWpnCost[wpnid])
		{
			client_print(playerId , print_chat , "You don't have enough money");
			return PLUGIN_HANDLED
		}
		
		iPlayerMoney -= g_iWpnCost[wpnid];
		cs_set_user_money(playerId , iPlayerMoney)
	}
	CmdGiveWpn(playerId , wpnid)
	return PLUGIN_HANDLED
}

public CmdGiveWpn(playerId, wpnid)
{	
	
	if(PRIMARY & (1<<g_iWpnCswId[wpnid]))
		Drop_Primary_Weapon(playerId);
	else if(SECONDARY & (1<<g_iWpnCswId[wpnid]))
		Drop_Secondary_Weapon(playerId)
	else if(CSW_KNIFE == g_iWpnCswId[wpnid])
		wpn_core_reset_player_knife(playerId)
	
	console_print(0, "[WpnCore] giving player wpnId %i" , wpnid);
	// Sets which player (bit) owns the modified gun
	Set_BitVar(g_HadWpn[wpnid], playerId)

	// If controlled by external plugin , use forwards to give
	if(g_bWpnExternal[wpnid])
		ExecuteForward(g_Forwards[FW_GIVE_WPN], g_ForwardResult , playerId , wpnid)
	else
	{
		give_item(playerId, g_szWpnIdOld[wpnid])

		// Plays the deploy voice
		gfl_voice_play_deploy_voice(playerId, g_szModel_V[wpnid])

		// Sets custom clip if any
		if(g_iWpnClip[wpnid] > 0)
		{
			static ent; ent = fm_get_user_weapon_entity(playerId, g_iWpnCswId[wpnid])
			if(!pev_valid(ent)) 
				return PLUGIN_HANDLED;

			cs_set_weapon_ammo(ent, g_iWpnClip[wpnid]);
		}
	}

	return PLUGIN_HANDLED
	/*
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_AK47)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, 30);
	cs_set_user_bpammo(id, CSW_AK47, 90)
	
	
	message_begin(MSG_ONE_UNRELIABLE, gMsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_AK47)
	write_byte(30)
	message_end()
	*/
	// Set custom MuzzleFlash , if any 
	// MuzzleFlash_Set(id, Muzzleflash, 0.1)
}

// ======================= Menu ================================ //

public WpnMenu(playerId)
{
	//first we need to make a variable that will hold the menu
	new menu = menu_create( "\r Wpn Menu:", "WpnMenu_Handler2" );
	//Now lets add some things to select from the menu
	
	menu_additem( menu, "Pistols" , "1", 0 );
	menu_additem( menu, "Shotguns" , "2", 0 );
	menu_additem( menu, "SMGs" , "3", 0 );
	menu_additem( menu, "Assult Rifles" , "4", 0 );
	menu_additem( menu, "Sniper Rifles" , "5", 0 );
	menu_additem( menu, "Machine Guns" , "6", 0 );
	menu_additem( menu, "Knives" , "7", 0 );
	
	menu_display( playerId, menu, 0 );
}

public WpnMenu_Handler2( id, menu, item )
{
	//Do a check to see if they exited because menu_item_getinfo ( see below ) will give an error if the item is MENU_EXIT
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[2], szName[64];
	new _access, item_callback;
	//heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName,charsmax( szName ), item_callback );
	new wpnType = str_to_num(szData);
	menu_destroy( menu );
		
	switch(wpnType)
	{
		case 1:
			MakeCswTypeMenu(id , SECONDARY);
		case 2:
			MakeCswTypeMenu(id , SHOTGUN_TYPE);
		case 3:
			MakeCswTypeMenu(id , SMG_TYPE);
		case 4:
			MakeCswTypeMenu(id , RIFLE_TYPE);
		case 5:
			MakeCswTypeMenu(id , SNIPER_TYPE);
		case 6:
			MakeCswTypeMenu(id, MG_TYPE)
		case 7:
			MakeCswTypeMenu(id , (1<<CSW_KNIFE));
	}
	
	return PLUGIN_HANDLED;
}

public MakeCswTypeMenu(playerId , cswType)
{
	new menu = menu_create( "\wWpn Menu: \RCost", "WpnMenu_Handler" );
	static szWpnid[5];
	static szDisplay[64];
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		if(cswType & (1 << g_iWpnCswId[i]))
		{
			format(szWpnid , charsmax(szWpnid) , "%i" , i)
			format(szDisplay, charsmax(szDisplay) , "%s\R%i" , g_szWpnDisplayName[i] , g_iWpnCost[i]);
			menu_additem( menu, szDisplay , szWpnid, 0 );
		}
	}
	menu_display( playerId, menu, 0 );
}

//okay, we showed them the menu, now lets handle it ( looking back at menu_create, we are going to use that function )
public WpnMenu_Handler( id, menu, item )
{
	//Do a check to see if they exited because menu_item_getinfo ( see below ) will give an error if the item is MENU_EXIT
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[5], szName[64];
	new _access, item_callback;
	//heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName,charsmax( szName ), item_callback );
	
	new wpnid = str_to_num(szData);
	BuyWpn(wpnid , id)
	
	//lets finish up this function by destroying the menu with menu_destroy, and a return
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

// ========================================================= // 

/* ===============================
------------- SAFETY -------------
=================================*/
public Safety_Connected(id)
{
	reset_player_wpn(id)
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	reset_player_wpn(id)
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_alive(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	if(!Get_BitVar(g_IsAlive, id)) 
		return 0
	
	return 1
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

public reset_player_wpn(id)
{
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		UnSet_BitVar(g_HadWpn[i], id)
	}
}

public get_wpnId_by_wpnname(szWpnName[])
{
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		if(equali(szWpnName , g_szWpnId[i]))
			return i;
	}
	return -1;
}

// ================================
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}


stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}


stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

// =======================================================

stock Drop_Primary_Weapon(playerId) 
{
	new weapons[32], num
	get_user_weapons(playerId, weapons, num)
	for (new i = 0; i < num; i++) 
	{
		if (PRIMARY & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(playerId, "drop", wname)
		}
	}
}

stock Drop_Secondary_Weapon(playerId) 
{
	new weapons[32], num
	get_user_weapons(playerId, weapons, num)
	for (new i = 0; i < num; i++) 
	{
		if (SECONDARY & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(playerId, "drop", wname)
		}
	}
}

stock fm_get_weapon_ent_owner(ent)
{
	if(pev_valid(ent) != OFFSET_PDATA)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, OFFSET_LINUX_WEAPONS);
}

// Convert from weapon_a -> a
stock extract_weapon_name(szWpn[])
{
	new szWpnName[32];
	replace_stringex(szWpnName , sizeof(szWpnName[]) , "weapon_" , szWpn);
	return szWpnName;
}

stock find_str_in_array(szAry[][] , str[] , iArySize)
{
	static i
	for(i = 0 ; i < iArySize ; i++)
	{
		if(equali(szAry[i] , str))
			return i;
	}
	return -1;
}

// =============================================================
public plugin_natives()
{	
	register_library("wpn_core")
	register_native("wpn_core_get_wpn_count", "native_core_get_wpn_count")
	register_native("wpn_core_give_wpn", "native_core_give_wpn")
	register_native("wpn_core_get_random_wpnid", "native_core_get_random_wpnid")
	register_native("wpn_core_get_wpn_of_type", "native_core_get_wpn_of_type")
	register_native("wpn_core_get_wpn_display_name", "native_core_get_wpn_display_name")
	register_native("wpn_core_get_wpn_display_name_2", "native_core_get_wpn_display_name_2")
	register_native("wpn_core_get_wpn_cswId", "native_core_get_wpn_cswId")
	register_native("wpn_core_remove_all_player_wpn", "native_core_remove_all_player_wpn")
	register_native("wpn_core_reset_player_knife", "native_core_reset_player_knife")
	register_native("wpn_core_get_owned_wpnId", "native_core_get_owned_wpnId")
	register_native("wpn_core_is_weapon_wpn", "native_core_is_weapon_wpn")
	register_native("wpn_core_get_wpn_of_tier", "native_core_get_wpn_of_tier")

	register_native("wpn_core_get_wpn_knockback", "native_core_get_wpn_knockback")
	register_native("wpn_core_get_wpn_z_subtype", "native_core_get_wpn_z_subtype")
}


public native_core_get_random_wpnid(plugin_id, num_params)
{
	// -1 to prevent index out of bound
	return random_num(0 , g_iWpnCount-1);
}


public native_core_get_wpn_count(plugin_id, num_params)
{
	return g_iWpnCount;
}

public native_core_get_wpn_display_name(plugin_id, num_params)
{
	static wpnId; wpnId = get_param(1);
	return g_szWpnDisplayName[wpnId];
}

public native_core_get_wpn_display_name_2(plugin_id, num_params)
{
	static wpnId; wpnId = get_param(1);
	return set_string(2 , g_szWpnDisplayName[wpnId] , charsmax(g_szWpnDisplayName[]));
}


public native_core_give_wpn(plugin_id, num_params)
{
	
	new playerId = get_param(1);
	new wpnId = get_param(2);
	
	if (wpnId > g_iWpnCount)
	{
		log_error(AMX_ERR_NATIVE, "Invalid WpnId (%d)", wpnId)
		return false;
	}
	
	CmdGiveWpn(playerId, wpnId)
	return true;
}

public native_core_get_wpn_cswId(plugin_id, num_params)
{
	static wpnId; wpnId = get_param(1);
	if (wpnId > g_iWpnCount)
	{
		log_error(AMX_ERR_NATIVE, "Invalid WpnId (%d)", wpnId)
		return false;
	}
	return g_iWpnCswId[wpnId]
	
}

public Array:native_core_get_wpn_of_type(plugin_id, num_params)
{
	new iWpnType = get_param(1);
	static iWpnId;
	new Array:array = ArrayCreate(1 , MAX_WPN);
	
	for(iWpnId = 0 ; iWpnId < MAX_WPN ; iWpnId++)
	{
		if(iWpnType & ( 1 << g_iWpnCswId[iWpnId]))
		{
			ArrayPushCell(array, iWpnId);
		}
	}
	return array;
}

public Array:native_core_get_wpn_of_tier(plugin_id, num_params)
{
	new iTier = get_param(1);
	new iWpnId;
	new Array:array = ArrayCreate(1 , MAX_WPN);
	
	for(iWpnId = 0 ; iWpnId < MAX_WPN ; iWpnId++)
	{
		if(g_iWpnZTier[iWpnId] == iTier)
			ArrayPushCell(array, iWpnId);
	}
	return array;
}

public native_core_get_wpn_z_subtype(plugin_id, num_params)
{
	new iWpnId = get_param(1);
	return g_iWpnZSubType[iWpnId]
}

public native_core_get_wpn_contains_ammo_pack(plugin_id, num_params)
{
	new iWpnId;
	new Array:array = ArrayCreate(1 , MAX_WPN);
	return array;
}

public native_core_remove_all_player_wpn(plugin_id, num_params)
{
	new iPlayerId = get_param(1);
	for(new i = 0 ; i < MAX_WPN ; i++)
	{
		if( !(g_iWpnCswId[i] == CSW_KNIFE))
		{
			UnSet_BitVar(g_HadWpn[i], iPlayerId);
		}
	}
}

public native_core_reset_player_knife(plugin_id, num_params)
{
	new iPlayerId = get_param(1);
	for(new i = 0 ; i < MAX_WPN ; i++)
	{
		if(g_iWpnCswId[i] == CSW_KNIFE)
		{
			UnSet_BitVar(g_HadWpn[i], iPlayerId);
		}
	}
}

public bool:native_core_is_weapon_wpn(plugin_id, num_params)
{
	new iPlayerId = get_param(1);
	new cswId = get_param(2);

	new ownedWpnId = Get_Owned_Wpn_By_CSW(cswId, iPlayerId);
	
	return ownedWpnId != NO_WPN_OWNED
}

public native_core_get_owned_wpnId(plugin_id, num_params)
{
	new iPlayerId = get_param(1);
	new cswId = get_param(2);

	return Get_Owned_Wpn_By_CSW(cswId, iPlayerId);
}

public Float:native_core_get_wpn_knockback(plugin_id, num_params)
{
	static wpnId; wpnId = get_param(1);
	if (wpnId > g_iWpnCount)
	{
		log_error(AMX_ERR_NATIVE, "Invalid WpnId (%d)", wpnId)
		return -1.0;
	}
	return g_fWpnKnockback[wpnId];
}