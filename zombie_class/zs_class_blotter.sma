/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <amxmisc>
#include <zombie_stage_const>
#include <zombie_stage>
#include <fun>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <fakemeta>
#include <xs>
#include <engine>

#define PLUGIN  "New Plug-In"
#define VERSION "1.0"
#define AUTHOR  "Author"

// Classic Zombie Attributes
new const zombieclass1_name[] = "Blotter Zombie"
new const zombieclass1_model[] = "zombie_blotter"
const zombieclass1_health = 280
const Float:speed = 240.0
const Float:gravity = 1.0
const Float:knockback = 1.0
const iShowOnStage = STAGE_3;
// const iShowOnStage = STAGE_1;
const iHideOnStage = DO_NOT_HIDE;
const iMaxCount = 1;

new g_iClassId;

new const szPainSound[] = "zombie_plague/passzombie_hurt1.wav"
new const szPainSound_2[] = "zombie_plague/passzombie_hurt2.wav"
new const szDeathSound[] = "zombie_plague/passzombie_death1.wav"

new const szExpSound[] = "zombie_plague/zombiegrenade_exp.wav"
new const szExpSprite[] = "sprites/zombie_plague/zombiebomb_exp.spr"

new g_iExpSpr;
new const szHeModel[] = "models/zombie_plague/w_zombibomb.mdl"

new g_iSkillCooldown[33];
#define TASK_HE_CHECK 10050

// --------- Force throw ------------ //
#define MAX_ITEM_TYPES 6
new const m_rgpPlayerItems_CBasePlayer[MAX_ITEM_TYPES] = {367, 368, ...}

const m_pNext = 42
const m_iId   = 43
const XoCBasePlayerItem = 4
// ---------------------------------- //

// pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_BLOTTER = 681856
new const AFFECTED_MODEL[] = "w_he"

#define EXPLOSION_RADIUS 300.0
#define EXPLOSION_POWER 250.0
#define SKILL_COOLDOWN 8
// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373

// CS Weapon PData Offsets (win32)
const OFFSET_WEAPONID = 43
const OFFSET_LINUX = 5 // offsets +5 in Linux builds

public plugin_init()
{
    register_forward(FM_SetModel, "fw_SetModel")
    RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade");

    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", 1)
    RegisterHamBots(Ham_Killed, "Ham_Player_Killed_Post", 1);
}

public plugin_precache()
{
	register_plugin("[ZS] Class: Blotter", VERSION, "ZP Dev Team")
	g_iClassId = zs_class_zombie_register(zombieclass1_name, zombieclass1_model, zombieclass1_health, speed, gravity,knockback, iShowOnStage ,iHideOnStage, iMaxCount)
	zs_class_zombie_register_sound(g_iClassId, szDeathSound , szPainSound, szPainSound_2);

    precache_sound(szExpSound)
    g_iExpSpr = precache_model(szExpSprite)
    precache_model(szHeModel)
}

public Ham_Player_Killed_Post(victim, attacker, shouldgib) 
{
    if(zs_core_get_player_zombie_class(victim) == g_iClassId)
    {
        remove_task(victim+TASK_HE_CHECK)
    }
}

public zs_fw_core_turn_to_zombie_post(id)
{
    remove_task(id+TASK_HE_CHECK)
	if(zs_core_get_player_zombie_class(id) == g_iClassId)
	{
		set_task(1.0, "he_check", id+TASK_HE_CHECK, _, _, "b")
	}
}

public he_check(taskId)
{
	new id = taskId - TASK_HE_CHECK;
    g_iSkillCooldown[id]--;

    if(g_iSkillCooldown[id] > 0)    return;

    new iTarget = get_random_visible_player(id);   
    if(iTarget != -1)
    {
        strip_user_weapons(id)  
        give_item(id, "weapon_hegrenade");
        engclient_cmd(id, "weapon_hegrenade")
        force_throw_he(id);
        g_iSkillCooldown[id] = SKILL_COOLDOWN
    }
}

force_throw_he(id)
{

    new WeaponEnt = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer[4])    
    while(pev_valid(WeaponEnt))
    {
        if(get_pdata_int(WeaponEnt, m_iId, XoCBasePlayerItem) == CSW_HEGRENADE)
        {
            break
        }    
        WeaponEnt = get_pdata_cbase(WeaponEnt, m_pNext, XoCBasePlayerItem)
    }
    
    if(pev_valid(WeaponEnt))
    {
        
        ExecuteHamB(Ham_Weapon_PrimaryAttack, WeaponEnt)
    }
}

public fw_SetModel(entity, const model[])
{    
    // Get damage time of grenade
    static Float:dmgtime
    pev(entity, pev_dmgtime, dmgtime)
    
    // Grenade not yet thrown
    if (dmgtime == 0.0)
        return FMRES_IGNORED;
    
    // Not an affected grenade
    if (!equal(model[7], AFFECTED_MODEL, 4))
        return FMRES_IGNORED;
    
    // Get owner of grenade and napalm weapon entity
    static owner;
    owner = pev(entity, pev_owner)
    
    // Get owner's team
    static owner_class; owner_class = zs_core_get_player_zombie_class(owner)
    if(owner_class != g_iClassId)
        return FMRES_IGNORED;

    // Give it a glow
    // fm_set_rendering(entity, kRenderFxGlowShell, NAPALM_R, NAPALM_G, NAPALM_B, kRenderNormal, 16)
    
    /*
    // And a colored trail
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW) // TE id
    write_short(entity) // entity
    write_short(g_trailSpr) // sprite
    write_byte(10) // life
    write_byte(10) // width
    write_byte(NAPALM_R) // r
    write_byte(NAPALM_G) // g
    write_byte(NAPALM_B) // b
    write_byte(200) // brightness
    message_end()
    */

    // Set grenade type on the thrown grenade entity
    set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_BLOTTER)
    engfunc(EngFunc_SetModel, entity, szHeModel)

    give_item(owner, "weapon_knife")
    return FMRES_IGNORED;
}

// Grenade Think Forward
public fw_ThinkGrenade(entity)
{
    // Invalid entity
    if (!pev_valid(entity)) return HAM_IGNORED;
    
    // Get damage time of grenade
    static Float:dmgtime
    pev(entity, pev_dmgtime, dmgtime)
    // Check if it's time to go off
    if (dmgtime > get_gametime())
        return HAM_IGNORED;
    // Not a napalm grenade
    if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_BLOTTER)
        return HAM_IGNORED;
    // Explode event
    napalm_explode(entity)
    
    // Keep the original explosion
    // set_pev(entity, PEV_NADE_TYPE, 0)
    // return HAM_IGNORED;
    
    
    // Get rid of the grenade
    engfunc(EngFunc_RemoveEntity, entity)
    return HAM_SUPERCEDE;
    
}

// Napalm Grenade Explosion
napalm_explode(ent)
{    
    // Get origin
    static Float:originF[3] , Float:fDirVelocity[3];
    pev(ent, pev_origin, originF)
    
    // Custom explosion effect
    create_explosion(originF)
    
    // Collisions
    static victim
    victim = -1
    
    while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, EXPLOSION_RADIUS)) != 0)
    {
        // Only effect alive players
        if (!is_user_alive(victim))
            continue;

        static Float: vecVictimOrigin[3]; pev(victim, pev_origin, vecVictimOrigin);
        pev(victim, pev_origin, vecVictimOrigin);

        xs_vec_sub(vecVictimOrigin , originF, fDirVelocity);
        xs_vec_normalize(fDirVelocity , fDirVelocity);
        xs_vec_mul_scalar(fDirVelocity , 600.0 , fDirVelocity);

        entity_set_vector(victim, EV_VEC_velocity, fDirVelocity)
    }
}

create_explosion(Float:Origin[3])
{
    EmitSound(0, CHAN_BODY, szExpSound)
    
    // create effect
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
    write_byte(TE_EXPLOSION) // TE_EXPLOSION
    write_coord_f(Origin[0]) // origin x
    write_coord_f(Origin[1]) // origin y
    write_coord_f(Origin[2]); // origin z
    write_short(g_iExpSpr) // sprites
    write_byte(20) // scale in 0.1's
    write_byte(30) // framerate
    write_byte(14) // flags 
    message_end() // message end
}

public EmitSound(id, chan, const file_sound[])
{
    emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// ----------------------------------------------------------------------------------------------------

stock get_random_visible_player(iVisor)
{
    new iTarget = get_random_player();
    if(iTarget == -1)
        return -1;

    if(Is_Visible(iVisor, iTarget))
            return iTarget;
    return -1;
}

stock bool:Is_Visible(iVisor, iTarget)
{
    new Float:fTargetOrigin[3] , Float:fVisorOrigin[3];
    pev(iTarget, pev_origin, fTargetOrigin);
    pev(iVisor, pev_origin, fVisorOrigin);
    new tr = create_tr2();
    engfunc(EngFunc_TraceLine, fVisorOrigin, fTargetOrigin, DONT_IGNORE_MONSTERS, iVisor, tr);

    new Float:fraction;
    get_tr2(tr, TR_flFraction, fraction)

    new hit = get_tr2(tr, TR_pHit)

    if(fraction < 0.7)
    {
        free_tr2(tr);
        return false;
    }

    
    if(hit == iTarget)
    {
        free_tr2(tr);
        return true;
    }

    free_tr2(tr);
    
    return false;
}


stock get_random_player()
{
    new players[MAX_PLAYERS] , iCount;
    get_players_ex(players, iCount ,GetPlayers_ExcludeDead | GetPlayers_ExcludeBots)
    if(iCount == 0)
        return -1;

    return players[random_num(0 , iCount - 1)];
}

// Get User Current Weapon Entity
stock fm_get_user_current_weapon_ent(id)
{
    return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}