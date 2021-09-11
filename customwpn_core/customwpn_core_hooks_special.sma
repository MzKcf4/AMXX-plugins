/*
#include "special_wpn/starchasersr.sma"
#include "special_wpn/dragonsword.sma"
#include "special_wpn/skull9.sma"
#include "special_wpn/crow9.sma"
#include "special_wpn/runeblade.sma"
#include "special_wpn/balrog9.sma"
*/
#include "special_wpn/balisong.sma"


precache_special()
{	
	/*
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		if(g_iWpnSpecialId[i] < 0 )
			continue;
		else if (g_iWpnSpecialId[i] == SPECIAL_STARCHASERSR)
			precache_StarchaserSR();
		else if (g_iWpnSpecialId[i] == SPECIAL_BALROG9)
			precache_Balrog9();
	}
	*/
}



// ============ Weapon Attack =================== //
// 1st step : This blocks client from sending their weapon ATTACK info
public fw_UpdateClientData_Post(playerId, sendweapons, cd_handle)
{
	if(!is_alive(playerId)){
	 	return FMRES_IGNORED
	}
		
	static userCswId ; userCswId = get_user_weapon(playerId);
	static ownedWpnId ; ownedWpnId = Get_Owned_Wpn_By_CSW(userCswId, playerId);
	
	if(ownedWpnId == NO_WPN_OWNED || !g_bOverride[ownedWpnId])
		return FMRES_IGNORED;
	
	// This fires as long as player is holding the weapon
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_HANDLED
}

//  2nd step : Fire Sounds
//  2.1 Sound will be attempted to play when client tries to attack , we hook this event ,
//  2.2 then send a custom attack signal to server 
//  2.3 then play the weapon animation for client
//  2.4 then emit the custom sound
public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED;
		
	static cswId; cswId = get_player_weapon(invoker);
	
	new ownWpnId = Get_Owned_Wpn_By_CSW(cswId , invoker);
	if( ownWpnId == NO_WPN_OWNED )
		return FMRES_IGNORED;
		
	if(!g_bOverride[ownWpnId])
		return FMRES_IGNORED;
	
	// Very cheap fix for elite
	if(cswId != CSW_ELITE && eventid != g_iWpnEventScId[ownWpnId])
		return FMRES_IGNORED;
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	
	// 2nd state attack animation and sound
	if((WPN_WITH_STATE & ( 1 << cswId)) && g_WpnState[invoker][ownWpnId] > 0)
	{
		Set_WeaponAnim(invoker, g_iWpnShootSecondaySeqId[ownWpnId])
		emit_sound(invoker, CHAN_WEAPON, g_szWpnShootSoundSilenced[ownWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} 
	else if (cswId == CSW_ELITE)
	{
		static bLeft; bLeft = random_num(0, 1);
		if(bLeft)
			Set_WeaponAnim(invoker, g_iWpnShootSeqId[ownWpnId])	
		else
			Set_WeaponAnim(invoker, g_iWpnShootSecondaySeqId[ownWpnId])	
		emit_sound(invoker, CHAN_WEAPON, g_szWpnShootSound[ownWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
	}
	else 
	{
		Set_WeaponAnim(invoker, g_iWpnShootSeqId[ownWpnId])
		emit_sound(invoker, CHAN_WEAPON, g_szWpnShootSound[ownWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
		
	return FMRES_SUPERCEDE
}

// 3rd step :
// This event fires when ammo updates in HUD , so it can be used to track when player firing weapons
public Event_CurWeapon(playerId)
{
	/*
	static cswId; cswId = read_data(2)
	
	static ownedWpnId; ownedWpnId = Get_Owned_Wpn_By_CSW(cswId , playerId);
	if(ownedWpnId == -1)	
		return PLUGIN_CONTINUE;
	
	if(g_fWpnShootDelay[ownedWpnId] <= 0)
		return PLUGIN_CONTINUE;
	
	static Ent; Ent = fm_get_user_weapon_entity(playerId, cswId)
	if(!pev_valid(Ent)) 
		return PLUGIN_CONTINUE;

	set_pdata_float(Ent, m_flNextPrimaryAttack, g_fWpnShootDelay[ownedWpnId], LINUX_OFFSET)
	*/
	return PLUGIN_CONTINUE;
}

// =================== 4th step , what did the player hit? ================

// 4.1 : Hit the world
// 4.1.1 : Make the bulletHole & BulletSmoke
public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED
		
	static cswId; cswId = get_user_weapon(Attacker)
	if(cswId == CSW_KNIFE)
		return HAM_IGNORED
	
	static ownedWpnId; ownedWpnId = Get_Owned_Wpn_By_CSW(cswId , Attacker);
	if(ownedWpnId == -1)	
		return HAM_IGNORED
			
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	// SetHamParamFloat(3, float(TEMP_DMG))
	return HAM_HANDLED
}


// 4.2 Hit the player
public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{

	static name[32];
	get_user_name(Victim, name, charsmax(name));
	// console_print(0 , "[TraceAttack_Player] V:%s , A:%i , Damage %f" , name , Attacker , Damage);
	if(!is_connected(Attacker))
		return HAM_IGNORED
		
	static cswId; cswId = get_user_weapon(Attacker)
	static ownedWpnId; ownedWpnId = Get_Owned_Wpn_By_CSW(cswId , Attacker);
	if(ownedWpnId == -1)	
		return HAM_IGNORED
	
	static Float:dmg; dmg = Damage;
	// Note for Zombie mode : can override the fWpnDmgMultiplier in loader so that it will use Z mode multipler
	/*
	if(g_bIsZombieMode && g_fWpnDmgMultiplierZ[ownedWpnId] > 0)
	{
		dmg = Damage * g_fWpnDmgMultiplierZ[ownedWpnId];
		SetHamParamFloat(3, dmg)
		return HAM_HANDLED
	}
	*/
	
	if(g_fWpnDmgMultiplier[ownedWpnId] <= -1.0)
		return HAM_IGNORED

	dmg = Damage * g_fWpnDmgMultiplier[ownedWpnId];

	SetHamParamFloat(3, dmg)
	return HAM_HANDLED
}




/// ========================================================================================



// Called when player switchs (deploys) to that weapon
public HamF_Item_Deploy_Post(ent)
{
	static entOwnerId , cswId, wpnId;
	// https://wiki.alliedmods.net/CBasePlayerItem_(CS)  for  what "41" & "43" means
	entOwnerId = get_pdata_cbase(ent, 41, 4);
	// 43's type is "int" , not CBaseXXXX , so use pdata_int
	cswId = get_pdata_int(ent, 43, 4);
	
	wpnId = Get_Owned_Wpn_By_CSW(cswId , entOwnerId);
	if(wpnId == NO_WPN_OWNED)
		return HAM_IGNORED;
	
	set_pev(entOwnerId, pev_viewmodel2, g_szModel_V[wpnId])
	set_pev(entOwnerId, pev_weaponmodel2, g_szModel_P[wpnId])
	
	static iWpnState; iWpnState = get_pdata_int(ent , m_fWeaponState , 4);

	// When pick up or switch to wpn with state , re-record the state of that weapon
	g_WpnState[entOwnerId][wpnId] = iWpnState;
	// 	console_print(0 , "Wpn %i is deployed , name %s , ammoid %i , itemInSlot %i , cswId %i" , wpnId , g_szWpnId[wpnId], g_PAMMO_ID[cswId], g_ITEM_IN_SLOT[cswId], g_iWpnCswId[wpnId]);
	if(g_iWpnDrawSeqId[wpnId] >= 0)
	{
		Set_WeaponAnim(entOwnerId, g_iWpnDrawSeqId[wpnId]);
	}
	
	if(g_iWpnMoveSpeed[wpnId] != -1)
	{
		set_pev(entOwnerId, pev_maxspeed, g_iWpnMoveSpeed[wpnId])
	}
	
	// ToDo: If there is extra draw time
	// Set_PlayerNextAttack(Id, TIME_DRAW)
	// Set_WeaponIdleTime(Id, CSW_LM, TIME_DRAW + 0.25)
	
	return HAM_HANDLED
}

public HamF_Item_AddToPlayer_Post(const item, const player)
{
	if(!pev_valid(item))
		return HAM_IGNORED;
	
	// Does the player pickup this gun?
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		if(pev(item, pev_impulse) == g_iImpulse[i])
		{
			Set_BitVar(g_HadWpn[i], player)
			set_pev(item, pev_impulse, 0)
			return HAM_IGNORED;
		}
	}
	
	
	// The gun is Not pick up by player., so it is purchased.
	static  cswId, wpnId;
	// 43's type is "int" , not CBaseXXXX , so use pdata_int
	cswId = get_pdata_int(item, 43, 4);
	
	wpnId = Get_Owned_Wpn_By_CSW(cswId , player);
	if(wpnId == NO_WPN_OWNED)
		return HAM_IGNORED;
		
	message_begin( MSG_ONE, g_MsgWeaponList, _, player );
	write_string(g_szWpnId[wpnId]);   	 // WeaponName
	write_byte( g_PAMMO_ID[cswId]);        	// PrimaryAmmoID
	write_byte( 20 );                   	// PrimaryAmmoMaxAmount
	write_byte( -1 );                  	 // SecondaryAmmoID
	write_byte( -1 );                  	 // SecondaryAmmoMaxAmount
	write_byte( g_SLOT[cswId] );                    	// SlotID (0...N)
	write_byte( g_ITEM_IN_SLOT[cswId] );   // NumberInSlot (1...N)
	write_byte( g_iWpnCswId[wpnId]);  	// WeaponID
	write_byte( 0 );                    	// Flags
	message_end();

	// console_print(0 , "Wpn %i is deployed , name %s , ammoid %i , itemInSlot %i , cswId %i" , wpnId , g_szWpnId[wpnId], g_PAMMO_ID[cswId], g_ITEM_IN_SLOT[cswId], g_iWpnCswId[wpnId]);
	return HAM_HANDLED;
}

// Checks if allowed to reload
public HamF_Weapon_Reload_Pre(ent)
{
	static ownerId; ownerId = pev(ent, pev_owner)
	
	if(!is_user_alive(ownerId))
		return HAM_IGNORED

	static cswId; cswId = get_player_weapon(ownerId);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , ownerId);
	if( ownWpnId == NO_WPN_OWNED || g_iWpnClip[ownWpnId] == -1)
		return HAM_IGNORED;

	g_iPlayerWpnClip[ownerId] = -1;
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(ownerId, cswId)
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE

	static iClip; iClip = get_pdata_int(ent, m_iClip, 4)
	if(iClip >= g_iWpnClip[ownWpnId])
		return HAM_SUPERCEDE		
			
	g_iPlayerWpnClip[ownerId] = iClip

	return HAM_HANDLED
}

// Handles reloading time and animation of overriden weapons
public HamF_Weapon_Reload_Post(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	if(!is_user_alive(playerId))
		return HAM_IGNORED
		
	static cswId; cswId = get_player_weapon(playerId);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , playerId);
	if( ownWpnId == NO_WPN_OWNED )
		return HAM_IGNORED;
	
	// Need to fake the reload pdata for Clip shotgun
	if(SHOTGUN_TYPE & (1 << cswId) && g_bClipReload[ownWpnId] && g_iPlayerWpnClip[playerId] >= 0)
	{
		set_pdata_int(ent, m_fInSpecialReload, 0, 4)
		set_pdata_float(playerId, m_flNextAttack,  g_fWpnReloadTime[ownWpnId], 5)
		set_pdata_float(ent, m_flTimeWeaponIdle,  g_fWpnReloadTime[ownWpnId] + 0.5, 4)
		set_pdata_float(ent, m_flNextPrimaryAttack,  g_fWpnReloadTime[ownWpnId] + 0.25, 4)
		set_pdata_float(ent, m_flNextSecondaryAttack,  g_fWpnReloadTime[ownWpnId] + 0.25, 4)
		set_pdata_int(ent, m_fInReload, 1, 4)

		if(g_iWpnReloadSeqId[ownWpnId] >= 0)
			Set_WeaponAnim(playerId, g_iWpnReloadSeqId[ownWpnId])

		return HAM_HANDLED;
	}

	if(SHOTGUN_TYPE & (1 << cswId) && !g_bClipReload[ownWpnId])
	{
		if(g_iWpnReloadSeqId[ownWpnId] <= 0)
			return HAM_HANDLED
		
		static iSpReload; iSpReload = get_pdata_int(ent, m_fInSpecialReload, LINUX_OFFSET)
		if(iSpReload == 0)		// NOT in special (shotgun) reload
		{
			// Set_WeaponAnim(playerId, g_iWpnReloadSeqId[ownWpnId])
		}
		else if(iSpReload == 1)		// Start of special reload
		{
			if(g_iWpnClip[ownWpnId] > 0)
			{
				if(cs_get_weapon_ammo(ent) >= g_iWpnClip[ownWpnId] || cs_get_user_bpammo(playerId, g_iWpnCswId[ownWpnId]) <= 0)
				{
					set_pdata_int(ent, m_fInSpecialReload, 4, 4)
					return HAM_IGNORED;
				} 
			}

			if( get_pdata_float(ent, m_flTimeWeaponIdle, LINUX_OFFSET) > 0.0 )
			{
				return HAM_IGNORED;
			}
			Set_WeaponAnim(playerId, g_iWpnReloadSeqId[ownWpnId])
		}
		else if (iSpReload == 2) 	// Insertion
		{
			// This shotgun has custom clip size
			if(g_iWpnClip[ownWpnId] > 0)
			{
				// Full clip / no more bpammo , stop reloading.
				if(cs_get_weapon_ammo(ent) >= g_iWpnClip[ownWpnId] || cs_get_user_bpammo(playerId, g_iWpnCswId[ownWpnId]) <= 0)
				{
					set_pdata_int(ent, m_fInSpecialReload, 4, 4)
					return HAM_IGNORED;
				} 
				else 	// Do next reload
				{
					set_pdata_int(ent, m_fInSpecialReload, 3, 4)
					set_pdata_float(ent, m_flTimeWeaponIdle, 0.25, 4)
					set_pdata_float(ent, m_flNextPrimaryAttack, 0.25, 4)
					set_pdata_float(ent, m_flNextSecondaryAttack, 0.25, 4)
					set_pdata_float(playerId, m_flNextAttack, 0.25, 5)
				}
					
			}
		}
		else if(iSpReload == 4)
		{
			set_pdata_int(ent, m_fInSpecialReload, 0, 4)
			set_pdata_float(ent, m_flTimeWeaponIdle, 1.0, 4)
			set_pdata_float(ent, m_flNextPrimaryAttack, 1.0, 4)
			set_pdata_float(ent, m_flNextSecondaryAttack, 1.0, 4)
			set_pdata_float(playerId, m_flNextAttack, 1.0, 5)
			Set_WeaponAnim(playerId, 4)
			return HAM_IGNORED;

		}
		else
		{

		} 
		// == 3   				   // Done Insert
		// == 4 				   // Stop reload
	}
	else	// ======== Non shotgun reload ============
	{
		if((get_pdata_int(ent, m_fInReload, 4) == 1))	// reloading
		{ 
			// This wpn tracks ammo
			if(g_iWpnClip[ownWpnId] > 0)
			{
				if(g_iPlayerWpnClip[playerId] == -1)
					return HAM_IGNORED;
				// Has bpammo left ( see fw_Weapon_Reload_Pre )
				set_pdata_int(ent, m_iClip, g_iPlayerWpnClip[playerId], 4)
			}

			if(g_iWpnReloadSeqId[ownWpnId] >= 0)
				Set_WeaponAnim(playerId, g_iWpnReloadSeqId[ownWpnId])
				
			if(g_fWpnReloadTime[ownWpnId] > 0)
				set_pdata_float(playerId, m_flNextAttack ,  g_fWpnReloadTime[ownWpnId], 5)
				// Set_PlayerNextAttack(playerId, g_fWpnReloadTime[ownWpnId])
		
		} 
	}
	
	return HAM_HANDLED
}

// Currently used for auto-pistol only
public HamF_Weapon_PrimaryAttack(ent)
{
	static ownerId; ownerId = pev(ent, pev_owner)
	static cswId; cswId = get_player_weapon(ownerId);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , ownerId);

	if( ownWpnId == NO_WPN_OWNED || !g_bAutoMode[ownWpnId])
		return HAM_IGNORED;

	set_pdata_int( ent, m_iShotsFired, -1 );		
	return HAM_IGNORED
}

// =============== Recoil control ===================== //
public HamF_Weapon_PrimaryAttack_Post(ent)
{
	static ownerId; ownerId = pev(ent, pev_owner)
	static cswId; cswId = get_player_weapon(ownerId);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , ownerId);
	if( ownWpnId == NO_WPN_OWNED )
		return HAM_IGNORED;

	// ============= Recoil ======================= //
	if(g_fWpnRecoil[ownWpnId] > 0.0)
	{
		static Float:push[3]
		pev(ownerId,pev_punchangle,push)
		xs_vec_sub(push,g_fPushAngle[ownerId],push)
		
		xs_vec_mul_scalar(push, g_fWpnRecoil[ownWpnId] ,push)
		xs_vec_add(push,g_fPushAngle[ownerId],push)
		set_pev(ownerId,pev_punchangle,push)
	}
	// ============ Next Attack interval ============ //
	if(g_fWpnShootDelay[ownWpnId] > 0 && pev_valid(ent))
	{
		// ======= ToDo from BTE_Ham =========== //
		// iWeaponState = get_pdata_int(iEnt, m_iWeaponState);
		// if (!(iWeaponState & (WPNSTATE_FAMAS_BURST_MODE | WPNSTATE_GLOCK18_BURST_MODE)))
		// ======================== //
		set_pdata_float(ent, m_flNextPrimaryAttack, g_fWpnShootDelay[ownWpnId]);
		// Also note GetWeaponModePrimaryAttack in BTE_Ham for special weapon mode handling
	}
	// ============================================== //

	return HAM_IGNORED
}

// Tracks reload animtaion & correctly set the clip after reload
public HamF_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if( !is_user_alive(id))
		return HAM_IGNORED

	static cswId; cswId = get_player_weapon(id);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , id);

	// g_iWpnClip = if clip is managed by Wpn system, seems may block special wpn handling ...
	if( ownWpnId == NO_WPN_OWNED || g_iWpnClip[ownWpnId] <= 0)
		return HAM_IGNORED;

	static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, 5)
	static fInReload; fInReload = get_pdata_int(ent, m_fInReload, 4)
	
	// Checks if JUST finished reloading
	if(fInReload && flNextAttack <= 0.0)
	{
		static bpammo; bpammo = cs_get_user_bpammo(id, cswId)
		static iClip; iClip = get_pdata_int(ent, m_iClip, 4)

		static temp1
		temp1 = min(g_iWpnClip[ownWpnId] - iClip, bpammo)

		set_pdata_int(ent, m_iClip, iClip + temp1, 4)
		cs_set_user_bpammo(id, cswId, bpammo - temp1)		
		
		set_pdata_int(ent, m_fInReload, 0, 4)
		// For shotgun (clip reload)
		set_pdata_int(ent, m_fInSpecialReload, 0, 4);
		// fInReload = 0
	}

	/*
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_STARCHASERSR)
		Item_PostFrame_StarchaserSR(id , ent);
	*/

	return HAM_IGNORED
}


// ================================== Knife =====================================
public HamF_Knife_PostFrame(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);
	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	/*
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		return ItemPostFrame_Crow9(playerId , ent);
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		return ItemPostFrame_Runeblade(playerId , ent);
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		return ItemPostFrame_Balrog9(playerId , ent);
	}
	*/

	return HAM_IGNORED;
	/*
	static id; id = pev(ent, pev_owner)
	if( !is_user_alive(id))
		return HAM_IGNORED

	static cswId; cswId = get_player_weapon(id);
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(cswId , id);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_STARCHASERSR)
		Item_PostFrame_StarchaserSR(id , ent);

	return HAM_IGNORED
	*/
}


public HamF_Knife_PrimaryAttack_Pre(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED

	/*
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		PrimaryAttack_Pre_DragonSword(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		PrimaryAttack_Pre_Skull9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		PrimaryAttack_Pre_Crow9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		PrimaryAttack_Pre_Runeblade(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		PrimaryAttack_Pre_Balrog9(playerId , ent);
		return HAM_SUPERCEDE;
	}

	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		PrimaryAttack_Pre_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	*/
	return HAM_IGNORED;
}

public HamF_Knife_SecondaryAttack_Pre(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED
	
	/*
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		SecondaryAttack_Pre_DragonSword(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		SecondaryAttack_Pre_Skull9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		SecondaryAttack_Pre_Crow9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		SecondaryAttack_Pre_Runeblade(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		SecondaryAttack_Pre_Balrog9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	*/

	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Pre_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

public HamF_Knife_SecondaryAttack_Post(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED
	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Post_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
	
}

public HamF_Knife_Holster_Post(ent)
{
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	/*
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		Holster_Post_DragonSword(playerId , ent);
	} 
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		Holster_Post_Skull9(playerId , ent);
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		Holster_Post_Crow9(playerId , ent);	
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		Holster_Post_Runeblade(playerId , ent);
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		Holster_Post_Balrog9(playerId , ent);
	}
	*/
	return HAM_IGNORED;
}