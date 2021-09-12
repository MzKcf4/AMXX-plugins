#define m_iKevlar 112

#define COOLDOWN_HAWKEYE 10
#define COOLDOWN_GUT 90
#define DURATION_GODMODE 5.0
#define TASKID_REMOVE_GODMODE 6666

#define DURATION_STUMBLING_BLOCK 1.5
#define TASKID_REMOVE_STUMBLING_BLOCK 7777

#define EXPLOSIVE_SHOT_HIT_COUNT 5
#define EXPLOSIVE_SHOT_RADIUS 100.0
#define EXPLOSIVE_SHOT_BASE_DMG 30.0

#define VAMPIRE_HEAL_AMT 10
#define VAMPIRE_HEAL_RADIUS 120.0

#define TRAIT_TOKEN_COST 2

new const SOUND_LEARN_TRAIT[] = "sound/zombie_plague/levelup_trait.wav"

// === Recoil === //
new const g_CSW_WPN_ENT_NAME[][] = {"weapon_p228", "weapon_scout", "weapon_xm1014",
"weapon_mac10", "weapon_aug", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp",
"weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_deagle",
"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90"};

new Float:g_fPushAngle[MAX_PLAYERS + 1][3];	// The current recoil angle of the weapon that player is holding
// ============= //

// Determination		Each enemy within 12 yards increases your damage by 4%, up to a maximum of 20%.
// Rampage              Increase Strength by 1% for 8 seconds after killing or assisting in killing an enemy. This effect stacks up to 25 times.

enum _:TOTAL_TRAITS{
	ID_ADRENALINE = 0,
	ID_BOXER,
	ID_DEMOLITION,
	ID_FROZEN_SKIN,
	ID_GLASS_CANNON,
	ID_GUNNER,
	ID_HEADHUNTER,
	ID_HAWKEYE,
	ID_OVERLOAD,
	ID_PIERCING,
	ID_SAFEGUARD,
	ID_STEADY_AIM,
	ID_STUMBLING_BLOCK,
	ID_TOUGHNESS,
	ID_VAMPIRE
}

new g_msgScreenFade;
new g_szTraitName[TOTAL_TRAITS][32]
new g_szTraitDesc[TOTAL_TRAITS][96]


new bool:g_hasTrait[33][TOTAL_TRAITS];
new bool:g_bTraitUsed[TOTAL_TRAITS];
new g_hudmessage_id_trait;

// The cooldown of each trait per player;
new g_iTraitCooldown[33][TOTAL_TRAITS];

// For resetting in TakeDamage_Post
new bool:g_bPierced[33];

new bool:g_bFrozen[33];
// For ExplosiveShot
new g_iHitBeforeExplosive[33];


new g_iExplodeSpriteIndex;

plugin_init_human_trait()
{
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_TraceLine,"fw_traceline",1);

	for(new i = 0 ; i < sizeof(g_CSW_WPN_ENT_NAME) ; i++)
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, g_CSW_WPN_ENT_NAME[i], "fw_Weapon_PrimaryAttack_Post", .Post = true)
	}

	initTraits();
	set_task(1.0, "show_trait_message", _,_,_,"b");
	set_task(1.0, "trait_cooldown_tick", _,_,_,"b");
	g_hudmessage_id_trait = hudmessage_queue_register_left(); 
	g_msgScreenFade = get_user_msgid( "ScreenFade" );
}

plugin_precache_human_trait()
{
	precache_generic(SOUND_LEARN_TRAIT);
	g_iExplodeSpriteIndex = precache_model("sprites/zerogxplode.spr"); 
}

initTraits()
{
	// === Name === //
	g_szTraitName[ID_ADRENALINE] = "Adrenaline"
	g_szTraitName[ID_BOXER] = "Boxer"
	g_szTraitName[ID_DEMOLITION] = "Demolition"
	g_szTraitName[ID_FROZEN_SKIN] = "Frozen Skin"
	g_szTraitName[ID_GLASS_CANNON] = "Glass Cannon"
	g_szTraitName[ID_GUNNER] = "Gunner"
	g_szTraitName[ID_HAWKEYE] = "Hawk Eye"
	g_szTraitName[ID_HEADHUNTER] = "Head Hunter"
	g_szTraitName[ID_OVERLOAD] = "Overload"
	g_szTraitName[ID_PIERCING] = "Piercing"
	g_szTraitName[ID_STEADY_AIM] = "Steady Aim"
	g_szTraitName[ID_SAFEGUARD] = "Safeguard"
	g_szTraitName[ID_STUMBLING_BLOCK] = "Stumbling Block"
	g_szTraitName[ID_TOUGHNESS] =	"Toughness"
	g_szTraitName[ID_VAMPIRE] = "Vampire"
	// === Desc === //
	g_szTraitDesc[ID_ADRENALINE] = "+1.5% damage per 2% lost health"
	g_szTraitDesc[ID_BOXER] = "+10%*[Tier] melee damage"
	g_szTraitDesc[ID_DEMOLITION] = "Every 5 hits , next hit deals 30*[Tier] explosive damage"
	g_szTraitDesc[ID_FROZEN_SKIN] = "50% to freeze the attacker for 1.5 seconds upon taking damage"
	g_szTraitDesc[ID_GLASS_CANNON] = "+25% damage , +50% incoming damage"
	g_szTraitDesc[ID_GUNNER] = "+5%*[Tier] gun damage , -5%*[Tier] recoil"
	g_szTraitDesc[ID_OVERLOAD] = "When overflow damage > 300 , 50% is converted to explosive damage"
	g_szTraitDesc[ID_PIERCING] = "Your attack penetrates armor ; + 15% damage to enemy without armor"
	g_szTraitDesc[ID_STEADY_AIM] = "You shoot accurately when jumping / moving"
	g_szTraitDesc[ID_HAWKEYE] = "[BS only] Next shot must headshot (10s CD); -2s CD per hit"
	g_szTraitDesc[ID_HEADHUNTER] = "+20% headshot damage"
	g_szTraitDesc[ID_SAFEGUARD] = "Gain 5 seconds invincibility upon taking fatal damage"		// Maybe +atk ?
	g_szTraitDesc[ID_STUMBLING_BLOCK] = "Shots have 10% (33% for leg hits) chance to immobilize enemy for 1.5 seconds"
	g_szTraitDesc[ID_TOUGHNESS] =	"-6%*[Tier] incoming damage, 3%*[Tier] chance blocks attack"
	g_szTraitDesc[ID_VAMPIRE] = "Heals 10 hp on kills ; or 5 hp when enemies killed nearby"
}

round_start_post_human_trait()
{
	for(new i = 1 ; i < 33 ; i ++)
	{
		for(new j = 0 ; j < TOTAL_TRAITS ; j++)
		{
			g_hasTrait[i][j] = false;
			g_iTraitCooldown[i][j] = -1;
		}
		g_iTraitTakenCount[i] = 0;
	}
	for(new i = 0 ; i < TOTAL_TRAITS ; i++)
	{
		g_bTraitUsed[i] = false;
	}
}

public trait_cooldown_tick()
{
	static id , traitId;
	for(id = 1 ; id < 33 ; id++)
	{
		for(traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
		{
			if(g_hasTrait[id][traitId] && g_iTraitCooldown[id][traitId] > 0)
			{
				g_iTraitCooldown[id][traitId]--;
			}
		}
	}
}

public show_trait_message()
{
	static players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount , GetPlayers_ExcludeBots)
	for( i = 0 ; i < iCount ; i++)
	{
		static szMsg[128]; 
		static id; id = players[i];
		szMsg = "Traits : ";
		for(new traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
		{
			if(g_hasTrait[id][traitId])
			{
				static szTraitName[20];
				if(g_iTraitCooldown[id][traitId] > 0)
					formatex(szTraitName , charsmax(szTraitName), "%s (%i) | ", g_szTraitName[traitId] , g_iTraitCooldown[id][traitId])
				else
					formatex(szTraitName , charsmax(szTraitName), "%s | ", g_szTraitName[traitId])	
				
				strcat(szMsg, szTraitName, charsmax(szMsg))
			}
		}
		hudmessage_queue_set_player_message_left(g_hudmessage_id_trait, id, szMsg)
	}	
	return PLUGIN_HANDLED;
}

Float:Ham_TraceAttack_Pre_Human_Trait(Victim, Attacker, Float:Damage, Float:Direction[3], Traceresult, DamageBits)
{
	if(!is_user_alive(Attacker))
		return Damage;

	new iVictimTeam = _:cs_get_user_team(Victim);
	new iAttackerTeam = _:cs_get_user_team(Attacker);
	if(iVictimTeam == iAttackerTeam)
		return Damage;
	
	static cswId; cswId = get_user_weapon(Attacker);
	static Float:dmg; dmg = Damage;

	// ==HwakEye== //
	if(g_hasTrait[Attacker][ID_HAWKEYE] && ((1 << cswId) & WPN_SEMI_SNIPER))
	{
		if(g_iTraitCooldown[Attacker][ID_HAWKEYE] <= 0 )
		{
			set_tr2(Traceresult, TR_iHitgroup, HIT_HEAD);
			g_iTraitCooldown[Attacker][ID_HAWKEYE] = COOLDOWN_HAWKEYE			
		}
		else
		{
			g_iTraitCooldown[Attacker][ID_HAWKEYE]-= 2;
		}
	}
	if(g_hasTrait[Attacker][ID_GLASS_CANNON])
		dmg *= 1.25;
	// ==Boxer== //
	if(cswId == CSW_KNIFE)
	{
		if(g_hasTrait[Attacker][ID_BOXER])
			dmg *= (1.0 + float(g_iCurrStage)/10)
		
	}
	// ==Gunner== //
	if(g_hasTrait[Attacker][ID_GUNNER] && ((1 << cswId) & GUN_TYPE))
	{
		dmg *= (1.0 + 0.05 * g_iCurrStage)
	}
	// ==Adrenaline== //
	if(g_hasTrait[Attacker][ID_ADRENALINE])
	{
		new Float:multi = 1.0 + (1.0 - float(get_user_health(Attacker))/ 100.0) / 1.5
		dmg *= multi;
	}
	 // ==HeadHunter==//
	if(g_hasTrait[Attacker][ID_HEADHUNTER] && get_tr2(Traceresult, TR_iHitgroup) == HIT_HEAD)
	{
			dmg *= 1.2
	}
	// ==ExplosiveBullet== //
	if(g_hasTrait[Attacker][ID_DEMOLITION])
	{
		if(g_iHitBeforeExplosive[Attacker] <= 0)
		{
			static Float:fOrigin[3] , iPlayerTier;
			entity_get_vector(Victim, EV_VEC_origin, fOrigin)
			iPlayerTier = g_iCurrStage + 1;
			makeExplosion(fOrigin, g_iExplodeSpriteIndex)
			doRadiusDamage(Attacker, fOrigin, true, EXPLOSIVE_SHOT_RADIUS , EXPLOSIVE_SHOT_BASE_DMG*iPlayerTier)
			g_iHitBeforeExplosive[Attacker] = EXPLOSIVE_SHOT_HIT_COUNT;
		}
		else
		{
			g_iHitBeforeExplosive[Attacker]--;
		}
	}
	// ==Stumbling Block==//
	if(g_hasTrait[Attacker][ID_STUMBLING_BLOCK])
	{
		static hitResult; hitResult = get_tr2(Traceresult, TR_iHitgroup);
		if(random_num(1, 100) < 11 || ((hitResult == HIT_LEFTLEG || hitResult == HIT_RIGHTLEG) && random_num(1, 100) < 33))	
		{
			g_bFrozen[Victim] = true;
			fm_set_rendering(Victim,kRenderFxGlowShell,255,255,255,kRenderNormal,8);
			remove_task(Victim + TASKID_REMOVE_STUMBLING_BLOCK);
			set_task(DURATION_STUMBLING_BLOCK, "remove_stumbling_block", Victim + TASKID_REMOVE_STUMBLING_BLOCK);
		}
	}
	return dmg;
}

Float:Ham_TakeDamage_Pre_Human_Trait(Victim, iInflictor, Attacker, Float:fDamage, m_Damagebits )
{
	static Float:dmg; dmg = fDamage;
	if(is_user_connected(Attacker))
	{
		new iVictimTeam = _:cs_get_user_team(Victim);
		new iAttackerTeam = _:cs_get_user_team(Attacker);
		if(iVictimTeam == iAttackerTeam)
			return fDamage;
	}
	if(g_hasTrait[Victim][ID_GLASS_CANNON])
		dmg *= 1.5;
	// ==Toughness== //
	if(g_hasTrait[Victim][ID_TOUGHNESS])
	{
		static iTier; iTier =  g_iCurrStage;
		if(random_num(1, 100) < 4*iTier)
			dmg = 0.0;
		else
			dmg *= 1.0 - float(iTier) * 0.06;
	}
	// ==Gut== //
	if(dmg >= get_user_health(Victim) && g_hasTrait[Victim][ID_SAFEGUARD] && g_iTraitCooldown[Victim][ID_SAFEGUARD] <= 0)
	{	
		fm_set_user_godmode(Victim,1);
		set_task(DURATION_GODMODE, "remove_godmode", Victim + TASKID_REMOVE_GODMODE);
		fm_set_rendering(Victim,kRenderFxGlowShell,255,255,255,kRenderNormal,8);
		set_user_health(Victim, 1);
		g_iTraitCooldown[Victim][ID_SAFEGUARD] = COOLDOWN_GUT
		fade_white(Victim);
		return 0.0;
	}
	// ==Piercing ==//
	if(g_hasTrait[Attacker][ID_PIERCING])
	{
		if(get_user_armor(Victim) > 0)
		{
			set_pdata_int(Victim, m_iKevlar, 0)
			g_bPierced[Victim] = true;			
		}
		else
		{
			dmg *= 1.15;
		}
	}
	// ==Overload== //
	if(g_hasTrait[Attacker][ID_OVERLOAD])
	{
		static iHealth; iHealth = get_user_health(Victim);
		static Float:fDiff; 
		fDiff = dmg - float(iHealth);
		if(fDiff > 300.0)
		{
			static Float:fOrigin[3];
			entity_get_vector(Victim, EV_VEC_origin, fOrigin)	
			makeExplosion(fOrigin, g_iExplodeSpriteIndex)
			fDiff *= 0.5;
			doRadiusDamage(Attacker, fOrigin, true, EXPLOSIVE_SHOT_RADIUS*1.5 , fDiff)
		}
	}
	// ==Frozen Skin== //
	if(g_hasTrait[Victim][ID_FROZEN_SKIN] && random_num(1, 100) < 50)
	{
		g_bFrozen[Victim] = true;
		fm_set_rendering(Victim,kRenderFxGlowShell,255,255,255,kRenderNormal,8);
		remove_task(Victim + TASKID_REMOVE_STUMBLING_BLOCK);
		set_task(DURATION_STUMBLING_BLOCK, "remove_stumbling_block", Victim + TASKID_REMOVE_STUMBLING_BLOCK);
	}
	return dmg;
}

Float:Ham_TakeDamage_Post_Human_Trait(Victim, iInflictor, Attacker, Float:fDamage, m_Damagebits )
{
	if(g_bPierced[Victim])
	{
		set_pdata_int(Victim, m_iKevlar, 2)
		g_bPierced[Victim] = false;
	}
	/*
	if(is_user_connected(Attacker))
	{
		new iVictimTeam = _:cs_get_user_team(Victim);
		new iAttackerTeam = _:cs_get_user_team(Attacker);
		if(iVictimTeam == iAttackerTeam)
			return fDamage;
	}
	if(g_hasTrait[Attacker][ID_PIERCING])
	{
		health = get_user_health(victim);
		health = health < 0 ? 0 : health;		
	}
	*/
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED

	if(g_bFrozen[id])
	{
		static Float:fFrozenVec[3];
		fFrozenVec[0] = 0.0
		fFrozenVec[1] = 0.0
		fFrozenVec[2] = -800.0
		entity_set_vector(id, EV_VEC_velocity, fFrozenVec)
	}
	return FMRES_IGNORED
}


public remove_godmode(taskid)
{
	new id = taskid - TASKID_REMOVE_GODMODE;
	fm_set_user_godmode(id, 0);
	fm_set_rendering(id); // reset back to normal

}

public remove_stumbling_block(taskid)
{
	new id = taskid - TASKID_REMOVE_STUMBLING_BLOCK;
	g_bFrozen[id] = false;
	fm_set_rendering(id); // reset back to normal
}

Ham_Killed_Pre_Human_Trait(victim, attacker, shouldgib)
{
	if(!g_bTraitUsed[ID_VAMPIRE] || !is_zombie(victim))
		return HAM_IGNORED;

	if(is_user_alive(attacker) && g_hasTrait[attacker][ID_VAMPIRE])
	{
		new hp = get_user_health(attacker);
		if(hp < (100 - VAMPIRE_HEAL_AMT))
			set_user_health(attacker, hp + VAMPIRE_HEAL_AMT)
		else
			set_user_health(attacker, 100)
	}
	// Heals other players in radius with Vamprie
	static Float:fOrigin[3];
	entity_get_vector( victim, EV_VEC_origin, fOrigin)	
	new iOtherEnt = -1;
	while((iOtherEnt = engfunc(EngFunc_FindEntityInSphere, iOtherEnt, fOrigin, VAMPIRE_HEAL_RADIUS)))
	{
		if(!is_user_alive(iOtherEnt) || !g_hasTrait[iOtherEnt][ID_VAMPIRE] || iOtherEnt == attacker)
			continue;

		new hp = get_user_health(iOtherEnt);
		if(hp < (100 - VAMPIRE_HEAL_AMT/2))
			set_user_health(iOtherEnt, hp + VAMPIRE_HEAL_AMT/2)
		else
			set_user_health(iOtherEnt, 100)

	}
	return HAM_IGNORED;
}

// someone is shooting, or something...
public fw_traceline(Float:v1[3],Float:v2[3],noMonsters,id,ptr)
{
	if(!is_user_connected(id) || (!g_hasTrait[id][ID_STEADY_AIM]) || is_user_bot(id) || !is_user_alive(id))
		return FMRES_IGNORED;

	static weapon; weapon = get_user_weapon(id);

	if(weapon == CSW_KNIFE || weapon == CSW_M3 || weapon == CSW_XM1014 || weapon == CSW_HEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_SMOKEGRENADE || weapon == CSW_C4)
		return FMRES_IGNORED;

	// get crosshair aim
	static Float:aim[3];
	get_aim(id,v1,aim);
	
	// do another trace to this spot
	new trace = create_tr2();
	engfunc(EngFunc_TraceLine,v1,aim,noMonsters,id,trace);
	
	// copy ints
	set_tr2(ptr,TR_AllSolid,get_tr2(trace,TR_AllSolid));
	set_tr2(ptr,TR_StartSolid,get_tr2(trace,TR_StartSolid));
	set_tr2(ptr,TR_InOpen,get_tr2(trace,TR_InOpen));
	set_tr2(ptr,TR_InWater,get_tr2(trace,TR_InWater));
	set_tr2(ptr,TR_pHit,get_tr2(trace,TR_pHit));
	set_tr2(ptr,TR_iHitgroup,get_tr2(trace,TR_iHitgroup));

	// copy floats
	get_tr2(trace,TR_flFraction,aim[0]);
	set_tr2(ptr,TR_flFraction,aim[0]);
	get_tr2(trace,TR_flPlaneDist,aim[0]);
	set_tr2(ptr,TR_flPlaneDist,aim[0]);
	
	// copy vecs
	get_tr2(trace,TR_vecEndPos,aim);
	set_tr2(ptr,TR_vecEndPos,aim);
	get_tr2(trace,TR_vecPlaneNormal,aim);
	set_tr2(ptr,TR_vecPlaneNormal,aim);

	// get rid of new trace
	free_tr2(trace);

	return FMRES_IGNORED;
}

// gets the end point of an imaginary 2048.0 line from the player's aim
get_aim(id,Float:source[3],Float:ret[3])
{
	static Float:vAngle[3], Float:pAngle[3], Float:dir[3], Float:temp[3];

	// get aiming direction from forward global based on view angle and punch angle
	pev(id,pev_v_angle,vAngle);
	pev(id,pev_punchangle,pAngle);
	xs_vec_add(vAngle,pAngle,temp);
	engfunc(EngFunc_MakeVectors,temp);
	global_get(glb_v_forward,dir);
	
	/* vecEnd = vecSrc + vecDir * flDistance; */
	xs_vec_mul_scalar(dir,8192.0,temp);
	xs_vec_add(source,temp,ret);
}

// ================ Recoil ======================== //
public fw_Weapon_PrimaryAttack_Post(ent)
{
	static ownerId; ownerId = pev(ent, pev_owner)
	if(!g_hasTrait[ownerId][ID_GUNNER])
		return HAM_IGNORED;

	static Float:fRecoil; fRecoil = 1.0;
	if(g_hasTrait[ownerId][ID_GUNNER])
		fRecoil *= 1.0 - g_iCurrStage * 0.05

	new Float:push[3]
	pev(ownerId,pev_punchangle,push)
	xs_vec_sub(push,g_fPushAngle[ownerId],push)
	
	xs_vec_mul_scalar(push, fRecoil ,push)
	xs_vec_add(push,g_fPushAngle[ownerId],push)
	set_pev(ownerId,pev_punchangle,push)
	return HAM_IGNORED
}

// === TraitMenu === //
show_menu_human_trait(id)
{
	static szTitle[32];
	formatex(szTitle, charsmax(szTitle), "\r Tokens : [%i]" , g_iToken[id])
	new menu = menu_create(szTitle, "menu_human_trait_handler" );

	static szDisplay[512];
	static szTraitId[3];
	static traitId;
	new Array:upgradable = get_upgradable_traitId(id);
	for(new i = 0 ; i < ArraySize(upgradable) ; i++)
	{
		traitId = ArrayGetCell(upgradable, i);
		formatex(szDisplay , charsmax(szDisplay) , "%s - %s" ,g_szTraitName[traitId], g_szTraitDesc[traitId])
		formatex(szTraitId , charsmax(szTraitId) , "%i" , traitId);
		menu_additem( menu, szDisplay, szTraitId);	
	}

	ArrayDestroy(upgradable);
	menu_display(id, menu, 0 );
}

public menu_human_trait_handler( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	if(is_user_alive(id) && g_iToken[id] >= TRAIT_TOKEN_COST && g_iTraitTakenCount[id] < g_iPlayerMaxTrait[id]){
		//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
		new szData[16], szName[64];
		new _access, item_callback;
		//heres the function that will give us that information ( since it doesnt magicaly appear )
		menu_item_getinfo( menu, item, _access, szData, charsmax( szData ), szName, charsmax( szName ), item_callback );

		new iTraitId = str_to_num(szData);

		choose_trait(id , iTraitId);
		g_iToken[id] -= TRAIT_TOKEN_COST;
	}
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}


Array:get_upgradable_traitId(id)
{
	new Array:array = ArrayCreate();
	for(new traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
	{
		if(!g_hasTrait[id][traitId])
			ArrayPushCell(array, traitId);
	}
	return array;
}

choose_trait(id, traitId)
{
	g_iTraitTakenCount[id]++;
	g_hasTrait[id][traitId] = true;
	g_bTraitUsed[traitId] = true;
	client_cmd(id, "spk %s", SOUND_LEARN_TRAIT);
}

// ============= Stocks ======================== //
public fade_white(id)
{
    message_begin( MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id );
    write_short( 1 << 10);
    write_short( 1 << 3 );
    write_short( 0 );
    write_byte( 255 );
    write_byte( 255 );
    write_byte( 255 );
    write_byte( 255 );
    message_end();
}

stock makeExplosion(Float:fOrigin[3] , iExplosionSpr)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc( EngFunc_WriteCoord,fOrigin[0]);
	engfunc( EngFunc_WriteCoord,fOrigin[1]);
	engfunc( EngFunc_WriteCoord,fOrigin[2]);
	write_short(iExplosionSpr);
	write_byte(5); // scale
	write_byte(30); // framerate
	write_byte(0); // flags
	message_end();
}

stock doRadiusDamage(iAttacker, Float:vecOrigin[3] , bCheckTeam , Float:fRadius, Float:fDamage)
{
	new iVictim = -1;
	new attackerTeam = _:cs_get_user_team(iAttacker);
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, fRadius)))
	{
		if(!is_user_alive(iVictim) || iVictim == iAttacker)
			continue;


		if(bCheckTeam && (_:cs_get_user_team(iVictim) == attackerTeam))
			continue;
		/*
		static Float: vecVictimOrigin[3]; pev(iVictim, pev_origin, vecVictimOrigin);
		pev(iVictim, pev_origin, vecVictimOrigin);

		static Float: flDistance; flDistance = get_distance_f(vecOrigin, vecVictimOrigin);
		static Float: vecVelocity[3];

		UTIL_GetSpeedVector(vecOrigin, vecVictimOrigin, EXP_KNOCKBACK * (1.0 - flDistance / EXP_RADIUS), vecVelocity);
		set_pev(iVictim, pev_velocity, vecVelocity);

		// Apply dmg to non teamates
		new Float:damage = radius_calc(flDistance,EXP_RADIUS,EXP_DMG,EXP_DMG/3.0);
		*/
		console_print(0 , "[] dealing %f dmg" , fDamage)
		ExecuteHamB(Ham_TakeDamage,iVictim,iAttacker,iAttacker,fDamage,DMG_GRENADE);			
	}
}