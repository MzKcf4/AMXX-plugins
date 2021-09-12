// #define NO_WPN_OWNED -1
new const NO_WPN_OWNED = -1

// This sets the Bit of a var  
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define LINUX_OFFSET 		4
#define m_pPlayer		41
#define m_iId			43
#define m_fKnown		44
#define m_flNextPrimaryAttack	46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle	48
#define m_iPrimaryAmmoType	49
#define m_iClip			51
#define m_fInReload	 	54		// Are we in the middle of a reload ?
#define m_fInSpecialReload      55		// Middle of Shotgun reload
#define m_flAccuracy            62		
#define m_iShotsFired 	64
#define m_fWeaponState		74
#define m_flNextAttack		83

// A 33 bit of Primary weapons
const PRIMARY = ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_M249))
const SECONDARY = ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

const WPN_WITH_STATE = ((1<<CSW_M4A1) | (1<<CSW_USP))

// ================================== Models & Resources ============================= //
new const SC_PREFIX[] = "events/";
new const SC_EXT[] = ".sc";
new const g_CSW_SC[][] = {"", "p228", "", "scout", "", "xm1014", "",
"mac10", "aug", "", "elite_left", "fiveseven", "ump45", "sg550", "galil", "famas", "usp",
"glock18", "awp", "mp5n", "m249", "m3", "m4a1", "tmp", "g3sg1", "", "deagle",
"sg552", "ak47", "knife", "p90", ""};

new const SPRITE_PREFIX[] = "sprites/"
new const SPRITE_EXT[] = ".txt";

new const MDL_PREFIX[] = "models/customwpn/"
new const MDL_PREFIX_DEFAULT[] = "models/"
new const MDL_EXT[] = ".mdl";
new const MDL_P_PREFIX[] = "p_";
new const MDL_V_PREFIX[] = "v_";
new const MDL_W_PREFIX[] = "w_";
new const MDL_DEFAULT[][] = {"thighpack", "p228", "shield", "scout", "hegrenade", "xm1014", "c4",
"mac10", "aug", "smokegrenade", "elite", "fiveseven", "ump45", "sg550", "galil", "famas", "usp",
"glock18", "awp", "mp5", "m249", "m3", "m4a1", "tmp", "g3sg1", "flashbang", "deagle",
"sg552", "ak47", "knife", "p90", "backpack"};
// =================================================================================== // 


new const g_ITEM_IN_SLOT[] = {-1, 3, -1, 9,1,12,3,13,14,3,5,6,15,16,17,18,4,2,2,7,4,5,6,11,3,2,1,10,1,1,8}
new const g_SLOT[] = {-1 , 1 , -1 , 0 , 3 , 0 , 4 , 0 , 0 , 3 , 1 , 1 , 0 , 0 , 0 , 0 ,1 , 1 , 0 , 0 ,0 , 0 , 0 , 0 ,0 , 3 , 1 , 0 ,0 , 2 , 0}

#define PAMMO_ID_338 1
#define PAMMO_ID_762 2
#define PAMMO_ID_556_NATO 3
#define PAMMO_ID_556 4
#define PAMMO_ID_BUCK 5
#define PAMMO_ID_45 6
#define PAMMO_ID_57 7
#define PAMMO_ID_357 9
#define PAMMO_ID_9 10

new const g_PAMMO_ID[] = {
	-1 , 9, -1,  2, 12, 5, 14, 6, 4 , 13 , 10 , 7 , 6 , 4 , 4 , 4 ,
	6, 10,1,10,3,5,4,10,2,11,8,4,2,-1,7}

// Offsets
const OFFSET_USE_STOPPED 			= 0;
const OFFSET_PDATA					= 2;
const OFFSET_LINUX_WEAPONS 			= 4;
const OFFSET_LINUX		 			= 5;
const OFFSET_WEAPON_OWNER			= 41;
const OFFSET_ID						= 43;
const OFFSET_NEXT_PRIMARY_ATTACK	= 46;
const OFFSET_NEXT_SECONDARY_ATTACK 	= 47;
const OFFSET_TIME_WEAPON_IDLE 		= 48;
const OFFSET_IN_RELOAD 				= 54;
const OFFSET_IN_SPECIAL_RELOAD 		= 55;
const OFFSET_NEXT_ATTACK			= 83;
const OFFSET_FOV					= 363;
const OFFSET_ACTIVE_ITEM 			= 373;

enum ( <<=1 )
{
    WEAPONSTATE_USP_SILENCED = 1,
    WEAPONSTATE_GLOCK18_BURST_MODE,
    WEAPONSTATE_M4A1_SILENCED,
    WEAPONSTATE_ELITE_LEFT,
    WEAPONSTATE_FAMAS_BURST_MODE,
    WEAPONSTATE_SHIELD_DRAWN
}

new const g_szWbox_model[] = "models/w_weaponbox.mdl"
new const g_szWbox_model_prefix[] = "models/w_"

new g_SmokePuff_SprId;

new pcvar_wpnFree;
new pcvar_wpnCanBuy;
new pcvar_wpnExtendKnifeDist;

// --- The args  [id][arg] --- //
new g_iImpulse[GLOBAL_MAX_WPN]						// 7 digit unique impulse id
new g_szWpnId[GLOBAL_MAX_WPN][32]					// weapon_xxxxx
new g_szWpnIdOld[GLOBAL_MAX_WPN][32]  				// old weapon to replace
new g_iWpnCswId[GLOBAL_MAX_WPN]	  				// The corresponding CSW_ID of the weapon
new g_szWpnDisplayName[GLOBAL_MAX_WPN][32]			// display name in buy menu
new g_szModel_V[GLOBAL_MAX_WPN][64]
new g_szModel_P[GLOBAL_MAX_WPN][64]
new g_szModel_W[GLOBAL_MAX_WPN][64]
new g_szSprite[GLOBAL_MAX_WPN][64]					// The weapon sprite text 
new g_iWpnCost[GLOBAL_MAX_WPN]
new g_bAutoMode[GLOBAL_MAX_WPN]					// [Pistol Only] automatic shoot
new g_bClipReload[GLOBAL_MAX_WPN]					// [Shotgun Only] Clip reload
new g_bOverride[GLOBAL_MAX_WPN]					// Whether to use custom sound handling for the wpn , to use custom sound , you MUST enable override
new g_szWpnShootSound[GLOBAL_MAX_WPN][64]			// The sound file for shooting
new g_szWpnShootSoundSilenced[GLOBAL_MAX_WPN][64]  // The sound file for slienced shooting ( USP & M4 only )
// new g_szWpnShootEvent[GLOBAL_MAX_WPN][32]    		// The event/xxx.sc to hook
// new g_WpnEventSc[GLOBAL_MAX_WPN]					// The event object held after hooking the event/xxx.sc
// new g_scToHook;								// The bit of CSW to show which g_CSW_SC to hook.
new g_iWpnEventScId[GLOBAL_MAX_WPN]				// The eventid of object held after hooking the event/xxx.sc
new Float:g_fWpnDmgMultiplier[GLOBAL_MAX_WPN] = {-1.0 , ...}		// The multiplier base on base damage of that wpn
new Float:g_fWpnShootDelay[GLOBAL_MAX_WPN]						// The delay between each shots , in seconds
new g_iWpnMoveSpeed[GLOBAL_MAX_WPN]							// The movement speed of this Wpn	
new Float:g_fWpnRecoil[GLOBAL_MAX_WPN]							// The recoil multiplier for that wpn
new Float:g_fWpnReloadTime[GLOBAL_MAX_WPN]         			// The reload time of weapon , in seconds 
new g_iWpnShootSeqId[GLOBAL_MAX_WPN]         					// The 'shoot"(or shoot-unsil) sequence id in the v_model
new g_iWpnShootSecondaySeqId[GLOBAL_MAX_WPN]       			// The 'shoot" slience sequence id in the v_model for USP and M4A1 , OR , right shoot sequence for elite
new g_iWpnReloadSeqId[GLOBAL_MAX_WPN]        					// The "reload" sequence id in the v_model
new g_iWpnDrawSeqId[GLOBAL_MAX_WPN]         					// The "draw" sequence id in the v_model 
new g_iWpnSpecialId[GLOBAL_MAX_WPN]				// > -1 , if this wpn has special attack / handling

new g_iWpnClip[GLOBAL_MAX_WPN]						// The clip size of the weapon

// ----------------------- Knife sounds --------------------------------- //
new g_szKnifeHitSound[GLOBAL_MAX_WPN][64]
new g_szKnifeHitWallSound[GLOBAL_MAX_WPN][64]
new g_szKnifeSlashSound[GLOBAL_MAX_WPN][64]
new g_szKnifeStabSound[GLOBAL_MAX_WPN][64]


// Rotation related
new g_iWpnCount = 0;	// How many wpn registered?

// ============
new g_HadWpn[GLOBAL_MAX_WPN]			// An array of a 32 bit value, each bit correspond to a playerId , 1 = own weapon , 0 = not
new g_WpnState[MAX_PLAYERS + 1][GLOBAL_MAX_WPN]		// The weapon state of each player's Wpn : "[1][3] = 1 " means : player id 1's  wpn 4  has usp slicened.
new Float:g_fPushAngle[MAX_PLAYERS + 1][3];	// The current recoil angle of the weapon that player is holding
new g_iPlayerWpnClip[33];						// The clip info used for reloading of each player's wpn

// Safety
new g_PlayerWeapon[33]	// PlayerId ranges from 1 to 32.

new g_MsgWeaponList;

new g_iAllocString_infoTarget;
new g_iAllocString_envSprite;

// ============ Some constants ================= //
new Float:g_vecZero[3]={0.0,0.0,0.0}

public Get_Owned_Wpn_By_CSW(cswId , playerId)
{
	static i;
	for(i = 0 ; i < g_iWpnCount ; i++)
	{
		if(g_iWpnCswId[i] == cswId && Get_BitVar(g_HadWpn[i] , playerId))
		{
			return i;
		}
	}
	return NO_WPN_OWNED;
}



// ============================= STOCKS ========================================== //

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

#if defined _ENABLE_SPECIAL_WPN
#include "customwpn_core/customwpn_core_var_func_special.sma"
#endif