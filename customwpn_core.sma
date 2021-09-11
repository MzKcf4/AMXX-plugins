// Uncomment to enable special wpn logic
#define _ENABLE_SPECIAL_WPN
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
#include <cs_ham_bots_api>
#include <json>
#if defined _ENABLE_SPECIAL_WPN
#include <reapi>
#endif
#include <customwpn_json_const>
#include <customwpn_const>
#include "customwpn_core/customwpn_core_var_func.sma"
#include "customwpn_core/customwpn_core_precacher.sma"
#include "customwpn_core/customwpn_core_hooks.sma"

#pragma dynamic 10240

#define PLUGIN "Custom Wpn - Core"
#define VERSION "1.0"
#define AUTHOR "MzKc"

// ToDo: 
// read pcvar from config

public plugin_precache()
{
	// Forward to Loader to handle SC events
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr");

	precacher_load_weapons();
	precache_special();
}

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

	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		register_clcmd( g_szWpnId[i] , "CmdSelectWpn" );

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
	
	// This blocks client from sending their weapon ATTACK info
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	// Knife
	register_forward(FM_EmitSound, "fw_EmitSound");
	register_clcmd( "WpnMenu","WpnMenu" );
	
	pcvar_wpnFree = register_cvar("wpn_free" , "0")
	pcvar_wpnCanBuy = register_cvar("wpn_can_buy" , "1")
	pcvar_wpnExtendKnifeDist = register_cvar("wpn_ext_knife" , "0");
}

//======

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
	if(get_pcvar_num(pcvar_wpnCanBuy) == 0)
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
	{
		reset_player_knife(playerId)
		ham_strip_user_weapon(playerId , CSW_KNIFE)
	}
	
	console_print(0, "[WpnCore] giving player wpnId %i" , wpnid);
	// Sets which player (bit) owns the modified gun
	Set_BitVar(g_HadWpn[wpnid], playerId)

	give_item(playerId, g_szWpnIdOld[wpnid])

	// Sets custom clip if any
	if(g_iWpnClip[wpnid] > 0)
	{
		static ent; ent = fm_get_user_weapon_entity(playerId, g_iWpnCswId[wpnid])
		if(!pev_valid(ent)) 
			return PLUGIN_HANDLED;

		cs_set_weapon_ammo(ent, g_iWpnClip[wpnid]);
	}
	

	return PLUGIN_HANDLED
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

reset_player_knife(id)
{
	for(new i = 0 ; i < GLOBAL_MAX_WPN ; i++)
	{
		if(g_iWpnCswId[i] == CSW_KNIFE)
		{
			UnSet_BitVar(g_HadWpn[i], id);
		}
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


// =============================================================
public plugin_natives()
{	
	register_library("customwpn_core_api")
	register_native("api_core_get_wpn_count", "native_core_get_wpn_count")
	register_native("api_core_give_wpn", "native_core_give_wpn")
	register_native("api_core_get_random_wpnid", "native_core_get_random_wpnid")
	register_native("api_core_get_wpn_of_type", "native_core_get_wpn_of_type")
	register_native("api_core_get_wpn_display_name", "native_core_get_wpn_display_name")
	register_native("api_core_get_wpn_cswId", "native_core_get_wpn_cswId")
	register_native("api_core_remove_all_player_wpn", "native_core_remove_all_player_wpn")
	register_native("api_core_reset_player_knife", "native_core_reset_player_knife")
	register_native("api_core_get_owned_wpnId", "native_core_get_owned_wpnId")
	register_native("api_core_is_weapon_wpn", "native_core_is_weapon_wpn")
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
	new Array:array = ArrayCreate(1 , GLOBAL_MAX_WPN);
	
	for(iWpnId = 0 ; iWpnId < GLOBAL_MAX_WPN ; iWpnId++)
	{
		if(iWpnType & ( 1 << g_iWpnCswId[iWpnId]))
		{
			ArrayPushCell(array, iWpnId);
		}
	}
	return array;
}

public native_core_remove_all_player_wpn(plugin_id, num_params)
{
	new iPlayerId = get_param(1);
	for(new i = 0 ; i < GLOBAL_MAX_WPN ; i++)
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
	reset_player_knife(iPlayerId);
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