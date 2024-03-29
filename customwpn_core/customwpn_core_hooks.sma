#if defined _ENABLE_SPECIAL_WPN
#include "customwpn_core/customwpn_core_hooks_special.sma"
#endif

precache_special()
{	
	#if defined _ENABLE_SPECIAL_WPN
	
	for(new i = 0 ; i < g_iWpnCount ; i++)
	{
		if(g_iWpnSpecialId[i] < 0 )
			continue;
		else if (g_iWpnSpecialId[i] == SPECIAL_STARCHASERSR)
			precache_StarchaserSR();
		else if (g_iWpnSpecialId[i] == SPECIAL_BALROG9)
			precache_Balrog9();
	}
	
	#endif
}


// ============ Weapon Attack =================== //
// 1st step : This blocks client from sending their weapon ATTACK info
public fw_UpdateClientData_Post(playerId, sendweapons, cd_handle)
{
	if(!is_user_alive(playerId)){
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
	if (!is_user_connected(invoker))
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

// =================== 4th step , what did the player hit? ================

// 4.1 : Hit the world
// 4.1.1 : Make the bulletHole & BulletSmoke
public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
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

	return HAM_HANDLED
}


// 4.2 Hit the player
public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	static name[32];
	get_user_name(Victim, name, charsmax(name));
	if(!is_user_connected(Attacker))
		return HAM_IGNORED
		
	static cswId; cswId = get_user_weapon(Attacker)
	static ownedWpnId; ownedWpnId = Get_Owned_Wpn_By_CSW(cswId , Attacker);
	if(ownedWpnId == -1)	
		return HAM_IGNORED
	
	static Float:dmg; dmg = Damage;
	
	if(g_fWpnDmgMultiplier[ownedWpnId] <= -1.0)
		return HAM_IGNORED

	dmg = Damage * g_fWpnDmgMultiplier[ownedWpnId];

	SetHamParamFloat(3, dmg)
	return HAM_HANDLED
}

// Called when player switchs (deploys) to that weapon
public HamF_Item_Deploy_Post(ent)
{
	static entOwnerId , cswId, wpnId;
	entOwnerId = get_pdata_cbase(ent, m_pPlayer, 4);
	// 43's type is "int" , not CBaseXXXX , so use pdata_int
	cswId = get_pdata_int(ent, m_iId, 4);
	
	wpnId = Get_Owned_Wpn_By_CSW(cswId , entOwnerId);
	if(wpnId == NO_WPN_OWNED)
		return HAM_IGNORED;
	
	set_pev(entOwnerId, pev_viewmodel2, g_szModel_V[wpnId])
	set_pev(entOwnerId, pev_weaponmodel2, g_szModel_P[wpnId])
	
	static iWpnState; iWpnState = get_pdata_int(ent , m_fWeaponState , 4);

	// When pick up or switch to wpn with state , re-record the state of that weapon
	g_WpnState[entOwnerId][wpnId] = iWpnState;
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
	cswId = get_pdata_int(item, m_iId, 4);
	
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

// =============== Recoil control and Shoot Speed===================== //
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


// Weapon that has secondary action
// https://forums.alliedmods.net/showthread.php?t=199103
public HamF_Weapon_SecondaryAttack_Post(ent)
{
	static entOwnerId , cswId, wpnId;
	entOwnerId = get_pdata_cbase(ent, m_pPlayer, 4);
	cswId = get_pdata_int(ent, m_iId, 4);
	
	wpnId = Get_Owned_Wpn_By_CSW(cswId , entOwnerId);
	if(wpnId == NO_WPN_OWNED)
		return HAM_IGNORED;
		
	static iWpnState; iWpnState = get_pdata_int(ent , m_fWeaponState , 4);

	g_WpnState[entOwnerId][wpnId] = iWpnState;
	
	return HAM_HANDLED;
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

	#if defined _ENABLE_SPECIAL_WPN
	HamF_Item_PostFrame_Special(ownWpnId , id , ent)
	#endif

	return HAM_IGNORED
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

// ================================== Knife =====================================
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


public HamF_Knife_PostFrame(ent)
{
	#if defined _ENABLE_SPECIAL_WPN
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);
	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	return HamF_Knife_PostFrame_Special(ownWpnId , playerId , ent)
	#endif
	
	return HAM_IGNORED;
}


public HamF_Knife_PrimaryAttack_Pre(ent)
{
	#if defined _ENABLE_SPECIAL_WPN
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED

	return HamF_Knife_PrimaryAttack_Pre_Special(ownWpnId , playerId , ent)
	#endif

	return HAM_IGNORED;
}

public HamF_Knife_SecondaryAttack_Pre(ent)
{
	#if defined _ENABLE_SPECIAL_WPN

	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED

	return HamF_Knife_SecondaryAttack_Pre_Special(ownWpnId , playerId , ent)

	#endif

	return HAM_IGNORED;
}

public HamF_Knife_SecondaryAttack_Post(ent)
{
	#if defined _ENABLE_SPECIAL_WPN
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	if(!is_user_alive(playerId))
		return HAM_IGNORED

	HamF_Knife_SecondaryAttack_Post_Special(ownWpnId , playerId , ent)
	#endif

	return HAM_IGNORED;
	
}

public HamF_Knife_Holster_Post(ent)
{
	#if defined _ENABLE_SPECIAL_WPN
	static playerId; playerId = pev(ent, pev_owner)
	static ownWpnId; ownWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , playerId);

	if( ownWpnId == NO_WPN_OWNED)
		return HAM_IGNORED;

	HamF_Knife_Holster_Post_Special(ownWpnId , playerId , ent);
	#endif
	return HAM_IGNORED;
}