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

new const g_CSW_ENT_NAME[][] = {"weapon_thighpack", "weapon_p228", "weapon_shield", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp",
"weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90", "w_backpack"};

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

new const g_MAX_BPAMMO[] = {-1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100};
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

// =============== //
// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_REGISTER_WPN_POST = 0,
	FW_GIVE_WPN,
	FW_DROP_WPN
}
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]
// ============= //

#define MAX_WPN 32

// --- The args  [id][arg] --- //
new g_iImpulse[MAX_WPN]						// 7 digit unique impulse id
new g_szWpnId[MAX_WPN][32]					// weapon_xxxxx
new g_szWpnIdOld[MAX_WPN][32]  				// old weapon to replace
new g_iWpnCswId[MAX_WPN]	  				// The corresponding CSW_ID of the weapon
new g_szWpnDisplayName[MAX_WPN][32]			// display name in buy menu
new g_szModel_V[MAX_WPN][64]
new g_szModel_P[MAX_WPN][64]
new g_szModel_W[MAX_WPN][64]
new g_szSprite[MAX_WPN][64]					// The weapon sprite text 
new g_iWpnCost[MAX_WPN]
new g_bAutoMode[MAX_WPN]					// [Pistol Only] automatic shoot
new g_bClipReload[MAX_WPN]					// [Shotgun Only] Clip reload
new g_bOverride[MAX_WPN]					// Whether to use custom sound handling for the wpn , to use custom sound , you MUST enable override
new g_szWpnShootSound[MAX_WPN][64]			// The sound file for shooting
new g_szWpnShootSoundSilenced[MAX_WPN][64]  // The sound file for slienced shooting ( USP & M4 only )
// new g_szWpnShootEvent[MAX_WPN][32]    		// The event/xxx.sc to hook
// new g_WpnEventSc[MAX_WPN]					// The event object held after hooking the event/xxx.sc
// new g_scToHook;								// The bit of CSW to show which g_CSW_SC to hook.
new g_iWpnEventScId[MAX_WPN]				// The eventid of object held after hooking the event/xxx.sc
new Float:g_fWpnDmgMultiplier[MAX_WPN] = {-1.0 , ...}		// The multiplier base on base damage of that wpn
new Float:g_fWpnShootDelay[MAX_WPN]						// The delay between each shots , in seconds
new g_iWpnMoveSpeed[MAX_WPN]							// The movement speed of this Wpn	
new Float:g_fWpnRecoil[MAX_WPN]							// The recoil multiplier for that wpn
new Float:g_fWpnReloadTime[MAX_WPN]         			// The reload time of weapon , in seconds 
new g_iWpnShootSeqId[MAX_WPN]         					// The 'shoot"(or shoot-unsil) sequence id in the v_model
new g_iWpnShootSecondaySeqId[MAX_WPN]       			// The 'shoot" slience sequence id in the v_model for USP and M4A1 , OR , right shoot sequence for elite
new g_iWpnReloadSeqId[MAX_WPN]        					// The "reload" sequence id in the v_model
new g_iWpnDrawSeqId[MAX_WPN]         					// The "draw" sequence id in the v_model 
new g_iWpnSpecialId[MAX_WPN]				// > -1 , if this wpn has special attack / handling

new g_iWpnClip[MAX_WPN]						// The clip size of the weapon

// ----------------------- Knife sounds --------------------------------- //
new g_szKnifeHitSound[MAX_WPN][64]
new g_szKnifeHitWallSound[MAX_WPN][64]
new g_szKnifeSlashSound[MAX_WPN][64]
new g_szKnifeStabSound[MAX_WPN][64]
// ============ Zombie mode cvar ================== //
new Float:g_fWpnKnockback[MAX_WPN] = {-1.0 , ...}		// ZombieMod: Knockback for zombie mode
new Float:g_fWpnDmgMultiplierZ[MAX_WPN] = {-1.0 , ...}	// ZombieMod: Dmg multiplier when zombie mode is active
new g_iWpnZTier[MAX_WPN] = {-1 , ...}					// ZombieMod: "Tier" for Zombie mode's weapon system
new g_iWpnZSubType[MAX_WPN] = {-1 , ...}				// ZombieMod: SubType of Secondary weapon 
						// Override some of methods if zombie mode is active

enum _:ZSubType
{
	ZSubType_NONE = -1,
	ZSubType_SUP,
	ZSubType_DMG
}

// Rotation related
new g_iWpnCount = 0;	// How many wpn registered?

// ============
new g_HadWpn[MAX_WPN]			// An array of a 32 bit value, each bit correspond to a playerId , 1 = own weapon , 0 = not
new g_WpnState[MAX_PLAYERS + 1][MAX_WPN]		// The weapon state of each player's Wpn : "[1][3] = 1 " means : player id 1's  wpn 4  has usp slicened.
new Float:g_fPushAngle[MAX_PLAYERS + 1][3];	// The current recoil angle of the weapon that player is holding
new g_iPlayerWpnClip[33];						// The clip info used for reloading of each player's wpn

// Safety
new g_IsConnected, g_IsAlive , g_PlayerWeapon[33]	// PlayerId ranges from 1 to 32.

new g_MsgWeaponList;

new g_iAllocString_infoTarget;
new g_iAllocString_envSprite;

// ============ Some constants ================= //
new Float:g_vecZero[3]={0.0,0.0,0.0}

enum _:ENTITY_CLASS (+=100)
{
	ENTCLASS_NADE=2000,
	ENTCLASS_NADE_BOUNCE,
	ENTCLASS_BOLT,
	ENTCLASS_PLASMA,
	ENTCLASS_SMOKE,
	ENTCLASS_TKNIFE,
	ENTCLASS_KILLME,
	ENTCLASS_BOW,
	ENTCLASS_DGUN,
	ENTCLASS_SPEARGUN,
	ENTCLASS_PETROL,
	ENTCLASS_DESTROYER,
	ENTCLASS_BLOCKMISSILE,
	ENTCLASS_BOW,
	ENTCLASS_FADEIN,
	ENTCLASS_FIRE        //灭却星光 SME
}

enum _:SPECIAL_WPN
{
	SPECIAL_NON=-1,
	SPECIAL_STARCHASERSR=0,
	SPECIAL_DRAGONSWORD,
	SPECIAL_BALISONG,
	SPECIAL_SKULL9,
	SPECIAL_CROW9,
	SPECIAL_RUNEBLADE=5,
	SPECIAL_BALROG9
}

enum _:HIT_RESULT
{
	RESULT_HIT_NONE = 0,
	RESULT_HIT_PLAYER,
	RESULT_HIT_WORLD
}

Util_PlayKnifeSoundByHitResult(id,iEnt,iHitResult,bStab)
{
	static iWpnId; iWpnId = Get_Owned_Wpn_By_CSW(CSW_KNIFE , id);
	if(iWpnId == NO_WPN_OWNED)	return;


	if(iHitResult == RESULT_HIT_NONE)
	{
		if(strlen(g_szKnifeSlashSound[iWpnId]) > 0){
			emit_sound(iEnt, CHAN_WEAPON, g_szKnifeSlashSound[iWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		return;
	}

	if(iHitResult == RESULT_HIT_WORLD)
	{
		if(strlen(g_szKnifeHitWallSound[iWpnId]) > 0){
			emit_sound(iEnt, CHAN_WEAPON, g_szKnifeHitWallSound[iWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		return;
	}

	if(iHitResult == RESULT_HIT_PLAYER)
	{
		if(bStab)
		{
			if(strlen(g_szKnifeStabSound[iWpnId]) > 0)
				emit_sound(iEnt, CHAN_WEAPON, g_szKnifeStabSound[iWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		else
		{
			if(strlen(g_szKnifeHitSound[iWpnId]) > 0)
				emit_sound(iEnt, CHAN_WEAPON, g_szKnifeHitSound[iWpnId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		return;
	}
}

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
