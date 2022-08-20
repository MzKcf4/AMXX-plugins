#include <customwpn_const>

#define TIER_1 0
#define TIER_2 1
#define TIER_3 2
#define TIER_4 3
#define TIER_5 4
#define TIER_6 5
#define TIER_7 6
#define TIER_8 7
#define TIER_9 8
#define TIER_MAX TIER_9

#define NO_WPN -1

// #define CLASS_NOT_SELECTED -1
enum _:PLAYER_WPN_CLASS
{
	CLASS_NOT_SELECTED = 0,
	CLASS_MELEE,
	CLASS_SG ,
	CLASS_SMG,
	CLASS_AR,
	CLASS_BS,
	CLASS_AS
}

enum _:PLAYER_WPN_SUB_CLASS
{
	SUB_CLASS_SUP = CLASS_AS + 1,
	SUB_CLASS_DMG
}

new g_iPlayerWpnClass[MAX_PLAYERS + 1];
new g_iPlayerWpnTierPrimary[MAX_PLAYERS + 1];

new g_iPlayerWpnSubClass[MAX_PLAYERS + 1];
new g_iPlayerWpnTierSecondary[MAX_PLAYERS + 1];

new g_iWpnId_InTier[TIER_MAX+1][SUB_CLASS_DMG + 1];		// +1 for array size

plugin_init_wpn_mgr()
{
	prepareWpn();
}

prepareWpn()
{
	for(new iTier = 0 ; iTier < sizeof(g_iWpnId_InTier) ; iTier++)
	{
		new Array:wpnIds = get_wpn_of_ztier(iTier+1);	// +1 , as there is no T0
		for(new i = 0 ; i < ArraySize(wpnIds); i++)
		{
			new iWpnId = ArrayGetCell(wpnIds , i);
			new iCswId = 1 << api_core_get_wpn_cswId(iWpnId);
			if(iCswId & WPN_MELEE)
				g_iWpnId_InTier[iTier][CLASS_MELEE] = iWpnId;
			else if(iCswId & WPN_SHOTGUN)
				g_iWpnId_InTier[iTier][CLASS_SG] = iWpnId;
			else if(iCswId & WPN_SMG)
				g_iWpnId_InTier[iTier][CLASS_SMG] = iWpnId;
			else if(iCswId & WPN_AR)
				g_iWpnId_InTier[iTier][CLASS_AR] = iWpnId;
			else if(iCswId & WPN_SEMI_SNIPER)
				g_iWpnId_InTier[iTier][CLASS_BS] = iWpnId;
			else if(iCswId & WPN_AUTO_SNIPER)
				g_iWpnId_InTier[iTier][CLASS_AS] = iWpnId;
			else if(iCswId & WPN_PISTOL)
			{
				// Pick depends on SubType of pistol
				new iSubType = g_iWpnZSubType[iWpnId];
				if(iSubType == ZSubType_SUP)
					g_iWpnId_InTier[iTier][SUB_CLASS_SUP] = iWpnId;
				else
					g_iWpnId_InTier[iTier][SUB_CLASS_DMG] = iWpnId;
			}
			/*
			new szTemp[32]
			api_core_get_wpn_display_name(iWpnId , szTemp);
			console_print(0 , "%s added for Tier %i" , szTemp , iTier );
			*/
			
		}
		ArrayDestroy(wpnIds)
	}
}

round_start_post_wpn_mgr()
{
	// SUP is default pistol type
	new iTierOnePistol_WpnId = g_iWpnId_InTier[TIER_1][SUB_CLASS_SUP];

	for(new i = 1 ; i < MAX_PLAYERS + 1 ; i++)
	{
		g_iPlayerWpnClass[i] = CLASS_NOT_SELECTED
		g_iPlayerWpnSubClass[i] = CLASS_NOT_SELECTED
		g_iPlayerWpnTierPrimary[i] = TIER_1;
		// We use 0 here , because stage is 1,2,3,4,5,6 , for calculating diff of 2 , we need to start with 0
		g_iPlayerWpnTierSecondary[i] = 0;
		api_core_remove_all_player_wpn(i);
		if(is_user_alive(i) && !is_zombie(i))
		{
			strip_user_weapons(i)
			api_core_remove_all_player_wpn(i)
			api_core_reset_player_knife(i)

			give_item(i, "weapon_knife")
			api_core_give_wpn(i , iTierOnePistol_WpnId);
		}
	}
}

rest_start_wpn_mgr()
{
	if(g_iCurrStage == STAGE_1)
	{
		for(new i = 1 ; i < MAX_PLAYERS + 1 ; i++)
		{
			if(is_user_alive(i)){
				show_menu_wpn_class(i)
			}
		}
		
	}
}

set_player_wpn_class(id , iWpnClass)
{
	g_iPlayerWpnClass[id] = iWpnClass;
}

// ====================== Menu =========================== //
show_menu_wpn_class(iPlayerId)
{
	new menu = menu_create("\r Select weaponn class : " , "menu_wpn_class_handler" );

	static szClassId[2]
	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_MELEE)
	menu_additem( menu, "Melee", szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_SG)
	menu_additem( menu, "Shotgun",szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_SMG)
	menu_additem( menu, "Machine Gun",szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_AR)
	menu_additem( menu, "Rifle",szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_BS)
	menu_additem( menu, "Bolt-Action Sniper",szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",CLASS_AS)
	menu_additem( menu, "Automatic Sniper",szClassId, 0);

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display( iPlayerId, menu, 0 );
}

public menu_wpn_class_handler(id, menu, item)
{
	//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[8], szName[32];
	new _access, item_callback;
	//heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName, charsmax( szName ), item_callback );

	new iWpnClassEnum = str_to_num(szData);
	set_player_wpn_class(id, iWpnClassEnum)
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public show_menu_wpn_upgrade_primary(id)
{
	if(g_iPlayerWpnClass[id] == CLASS_NOT_SELECTED)
	{
		show_menu_wpn_class(id);
		return;
	}

	if(g_iPlayerWpnTierPrimary[id] >= g_iCurrStage)	return;

	new iPlyWpnClass = g_iPlayerWpnClass[id];
	new iPlyTier = g_iPlayerWpnTierPrimary[id];
	if(iPlyTier >= TIER_MAX)
		return;

	new iPlyNextWpnId = g_iWpnId_InTier[iPlyTier + 1][iPlyWpnClass];
	new szNextWpnName[32];

	api_core_get_wpn_display_name(iPlyNextWpnId , szNextWpnName);

	static szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\r Upgrade weapon to %s", szNextWpnName)

	new menu = menu_create( szTitle, "menu_wpn_upgrade_primary_handler" );
	menu_additem( menu, "\wYes ( Cost 1 Token )", "", 0);
	menu_additem( menu, "\wNo", "", 0);
	menu_display( id, menu, 0 );
}

public menu_wpn_upgrade_primary_handler(id, menu, item)
{
    switch( item )
    {
        case 0:
        {
        	if(g_iToken[id] <= 0)
        	{
        		client_print( id, print_chat, "Not enough token" );
        		return PLUGIN_HANDLED;
    		}	
        	new iPlyWpnClass = g_iPlayerWpnClass[id];
        	new iPlyTier = g_iPlayerWpnTierPrimary[id];
        	new iPlyNextWpnId = g_iWpnId_InTier[iPlyTier + 1][iPlyWpnClass];
        	api_core_give_wpn(id, iPlyNextWpnId);
        	g_iPlayerWpnTierPrimary[id]++;
        	g_iToken[id]--;
        }
        case 1:
        {
        }
    }

    //lets finish up this function by destroying the menu with menu_destroy, and a return
    menu_destroy( menu );
    return PLUGIN_HANDLED;
}

// ===================================== Secondary =======================================================
public show_menu_wpn_sub_class(iPlayerId)
{
	new menu = menu_create("\r Select Secondary Weapon class : " , "menu_wpn_sub_class_handler" );

	static szClassId[2]
	formatex(szClassId, charsmax(szClassId) , "%i",SUB_CLASS_SUP)
	menu_additem( menu, "General", szClassId, 0);

	formatex(szClassId, charsmax(szClassId) , "%i",SUB_CLASS_DMG)
	menu_additem( menu, "Damage",szClassId, 0);

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display( iPlayerId, menu, 0 );
}

public menu_wpn_sub_class_handler(id, menu, item)
{
	//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[8], szName[32];
	new _access, item_callback;
	//heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName, charsmax( szName ), item_callback );

	new iWpnClassEnum = str_to_num(szData);
	g_iPlayerWpnSubClass[id] = iWpnClassEnum;
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public show_menu_wpn_upgrade_secondary(id)
{
	if(g_iPlayerWpnSubClass[id] == CLASS_NOT_SELECTED)
	{
		show_menu_wpn_sub_class(id);
		return;
	}
	if(g_iPlayerWpnTierSecondary[id] >= g_iCurrStage)	return;
	// Keep the difference 2. So even stage 5 can upgrade from 2 to 4.	( 5 - 2 = 3)
	if(g_iCurrStage - g_iPlayerWpnTierSecondary[id] < 1)		return;

	new iPlySubClass = g_iPlayerWpnSubClass[id];
	new iPlyTier = g_iPlayerWpnTierSecondary[id];
	if(iPlyTier == TIER_MAX)
		return;

	// T1 = 0 , but stage 1 = 1 , it's very problematic , please resolve this one day
	new iPlyNextWpnId = g_iWpnId_InTier[iPlyTier + 1][iPlySubClass];
	new szNextWpnName[32];

	api_core_get_wpn_display_name(iPlyNextWpnId , szNextWpnName);
	static szTitle[64];
	formatex(szTitle, charsmax(szTitle), "\r Upgrade weapon to %s", szNextWpnName)

	new menu = menu_create( szTitle, "menu_wpn_upgrade_secondary_handler" );
	menu_additem( menu, "\wYes ( Cost 1 Token )", "", 0);
	menu_additem( menu, "\wNo", "", 0);
	menu_display( id, menu, 0 );
}

public menu_wpn_upgrade_secondary_handler(id, menu, item)
{
    switch( item )
    {
        case 0:
        {
        	if(g_iToken[id] < 1)
        	{
        		client_print( id, print_chat, "Not enough token" );
        		return PLUGIN_HANDLED;
    		}
    		new iPlySubClass = g_iPlayerWpnSubClass[id]	;
        	new iPlyTier = g_iPlayerWpnTierSecondary[id];
        	new iPlyNextWpnId = g_iWpnId_InTier[iPlyTier + 1][iPlySubClass];
        	api_core_give_wpn(id, iPlyNextWpnId);
        	g_iPlayerWpnTierSecondary[id] += 2;
        	g_iToken[id] -= 1;
        }
        case 1:
        {
        }
    }

    //lets finish up this function by destroying the menu with menu_destroy, and a return
    menu_destroy( menu );
    return PLUGIN_HANDLED;
}




Give_Player_Weapon(iPlayerId , iWpnId)
{
	wpn_core_give_wpn(iPlayerId, iWpnId)
	give_item(iPlayerId, "weapon_knife")
}

// === Tier Menu === //
public PreviewMenu_Show(iPlayerId)
{
	new menu = menu_create( "\r Weapon Tier", "PreviewMenu_Handler" );
	static szDisplay[32] , szItem[3];
	for(new i = 0 ; i < TIER_MAX ; i++)
	{
		formatex(szDisplay, charsmax(szDisplay), "Tier %i", i+1);
		formatex(szItem, charsmax(szItem), "%i", i);
		menu_additem(menu, szDisplay, szItem);
	}
	menu_display( iPlayerId, menu, 0 );
}

public PreviewMenu_Handler(id, menu, item )
{
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}

	new szData[16], szName[64];
	new _access, item_callback;
	//heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName, charsmax( szName ), item_callback );
	new iTier = str_to_num(szData);
	TierMenu_Show(id , iTier);
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public TierMenu_Show(iPlayerId , iTier)
{
	static szTitle[32];
	formatex(szTitle, charsmax(szTitle), "\r Tier %i weapon : ", iTier+1)
	new menu = menu_create( szTitle, "TierMenu_Handler" );

	static szWpnid[16];
	static szDisplay[64];
	for(new i = 0 ; i < sizeof(g_iWpnId_InTier[]) ; i++)
	{
		if(g_iWpnId_InTier[iTier][i] == NO_WPN)
			break;
		static szWpnName[48];
		api_core_get_wpn_display_name(g_iWpnId_InTier[iTier][i] , szWpnName)
		formatex(szDisplay, charsmax(szDisplay), "%s %s", get_wpn_type(g_iWpnId_InTier[iTier][i]) , szWpnName)

		// Use ID for both CSW + WpnId compability
		formatex(szWpnid , charsmax(szWpnid) , "%i" , g_iWpnId_InTier[iTier][i])
		menu_additem( menu, szDisplay, szWpnid, 0);
	}

	menu_display( iPlayerId, menu, 0 );
}

public TierMenu_Handler(id, menu, item)
{
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}



get_wpn_type(wpnid)
{
	static cswId; cswId = (1 << api_core_get_wpn_cswId(wpnid));
	static sz[5];
	
	if(cswId & GENERAL_TYPE)
		sz = "[G]"
	if(cswId & AUTO_SNIPER_TYPE)
		sz =  "[AS]"
	if(cswId & BOLT_SNIPER_TYPE)
		sz =  "[BS]"
	if(cswId & SHOTGUN_TYPE)
		sz =  "[SG]"
	if(cswId & PISTOL_TYPE)
		sz =  "[HG]"

	return sz;

}

client_putinserver(id)
{
	g_iPlayerWpnTierPrimary[id] = TIER_1;
}

client_disconnected_wpn_mgr(id)
{
	g_iPlayerWpnTierPrimary[id] = TIER_1;
}