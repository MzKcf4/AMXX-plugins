#include <customwpn_loader_api>
#include <json>

const WPN_MELEE = (1<<CSW_KNIFE)
const WPN_SHOTGUN = ((1<<CSW_M3)|(1<<CSW_XM1014))
const WPN_SMG = ((1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_M249))
const WPN_AR = ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG552))
const WPN_SEMI_SNIPER = ((1<<CSW_SCOUT) | (1 << CSW_AWP))
const WPN_AUTO_SNIPER = ((1<<CSW_SG550)|(1<<CSW_G3SG1))
const WPN_PISTOL = ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

new bool:g_bModActive = false;

// =============== //
// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_SPAWN_POST = 0,
	FW_USER_TURN_TO_ZB_POST,
	FW_ROUND_START_POST,
	FW_ROUND_END_POST,
	FW_ZOMBIE_KILLED_POST,
	FW_STAGE_CHANGED_POST,
	FW_PROGRESSION_END
}
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]

// == Time vars == //
// #define STAGE_1_PROGRESS 15

#define STAGE_2_PROGRESS 20
#define STAGE_3_PROGRESS 40
#define STAGE_4_PROGRESS 60
#define STAGE_5_PROGRESS 75

#define STAGE_MULTIPLIER 1.2
#define PROGRESS_TICK_INTERVAL 2

enum _:GAME_STATE
{
	STATE_STOP = 0,
	STATE_REST,
	STATE_BATTLE,
	STATE_MIDNIGHT
}

new g_iCurrStage = -1;
new g_iStageTime = 150;				// Length of a stage , in seconds
new g_iStageTimeRemain = 150;
new g_iPointsRequired = 1000;
new g_iPointsCurr = 0;
new g_iRestTime = 5;
new g_iRestTimeRemain = 5;
new g_iGameState = STATE_STOP;
new g_iTickInterval = 3;

new g_iToken[33];
new Float:g_fCurrProgress = 0.0;			
new Float:g_fTickInterval = 10.0;	// updates every 10 seconds

new g_iTraitTakenCount[33];
new g_iPlayerMaxTrait[33];
new g_iKillsInStage;

// === zombie related === //
#define NO_CLASS -1

new g_iZombieClassCount
new Array:g_ZombieClassName
new Array:g_ZombieClassBaseHealth			// Base health from configuration ( 1 player only )
new Array:g_ZombieClassSpeed
new Array:g_ZombieClassGravity
new Array:g_ZombieClassKnockback   			
new Array:g_ZombieClassModelName
new Array:g_ZombieClassShowOnStage;			// This class of zombie starts appearing after stage#x
new Array:g_ZombieClassMaxSpawned;			// Max zombie of that type allowed on the stage
new Array:g_ZombieClassHideOnStage;			// Hides this class after specified stage.
// Sounds
new Array:g_ZombieClassDeathSound;
new Array:g_ZombieClassPainSound;
new Array:g_ZombieClassPainSound_2;

new Array:g_ZombieClassUsable;				// Stores the list of zombie class that is CURRENTLY usable.
new g_iPlayerZombieClass[MAX_PLAYERS + 1]	// zombie class of player , should set to -1 when dead.
new g_iPlayerZombieClassPreKill[MAX_PLAYERS + 1] // For showing dmg , since it clears before TakeDmg_Post.
new Float:g_fPlayerZombieKnockback[MAX_PLAYERS + 1]	// Individual knockback multiplier of zombie

// ========================
new bool:g_bProgressEnd;

// ============ Weapon param override for Zombie mode ================== //
new Float:g_fWpnKnockback[GLOBAL_MAX_WPN] = {-1.0 , ...}		// ZombieMod: Knockback for zombie mode
new Float:g_fWpnDmgMultiplierZ[GLOBAL_MAX_WPN] = {-1.0 , ...}	// ZombieMod: Dmg multiplier when zombie mode is active
new g_iWpnZTier[GLOBAL_MAX_WPN] = {-1 , ...}					// ZombieMod: "Tier" for Zombie mode's weapon system
new g_iWpnZSubType[GLOBAL_MAX_WPN] = {-1 , ...}					// ZombieMod: SubType of Secondary weapon 

new const HUMAN_WIN_SOUND[] = "sound/zombie_plague/win_human.wav"
new const ZOMBIE_WIN_SOUND[] = "sound/zombie_plague/win_zombie.wav"
new const ZOMBIE_EVOLVE_SOUND[] = "sound/zombie_plague/the_horror2.wav"

new g_hudmessage_queue_id;

enum _:WINNER {
	WINNER_HUMAN = 0,
	WINNER_ZOMBIE
}

/*
enum _:ZSubType
{
	ZSubType_NONE = -1,
	ZSubType_SUP,
	ZSubType_DMG
}
*/

var_func_load_z_params()
{

	new JSON:jLoadedWpnObj = api_get_loaded_wpn();
	new JSON:jWpnEntry;	

	new iEntryCount = json_array_get_count(jLoadedWpnObj);

	for(new i = 0 ; i < iEntryCount ; i++)
	{
		jWpnEntry = json_array_get_value(jLoadedWpnObj , i)

		g_fWpnDmgMultiplierZ[i] = json_object_get_real(jWpnEntry, JSON_Z_DMG_MULTIPLIER);
		g_fWpnKnockback[i] = json_object_get_real(jWpnEntry, JSON_Z_KNOCKBACK);
		g_iWpnZTier[i] = json_object_get_number(jWpnEntry, JSON_Z_TIER);
		g_iWpnZSubType[i] = json_object_get_number(jWpnEntry, JSON_Z_SUBTYPE);
	}

	json_free(jWpnEntry);
}

Array:get_wpn_of_ztier(iZTier)
{
	new iWpnId;
	new Array:array = ArrayCreate();
	
	for(iWpnId = 0 ; iWpnId < GLOBAL_MAX_WPN ; iWpnId++)
	{
		if(g_iWpnZTier[iWpnId] == iZTier)
			ArrayPushCell(array, iWpnId);
	}
	return array;
}


public bool:is_zombie(id)
{
	return (is_user_bot(id) == true) && g_bModActive;
}

add_token_to_all(iCount)
{
	for(new i = 0 ; i < 33 ; i++)
	{
		g_iToken[i] += iCount;
	}
}

stock set_user_frozen( id, bool:bFrozen ) {

    if( bFrozen ) 
    	set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FROZEN ) ;
	else
    	set_pev( id, pev_flags, pev( id, pev_flags ) & ~ FL_FROZEN ) ;
}

stock Stock_is_between(in , lower , upper)
{
	return in > lower && in <= upper
}