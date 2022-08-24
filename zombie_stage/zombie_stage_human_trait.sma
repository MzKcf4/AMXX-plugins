#define m_iKevlar 112
#define m_iClip	51

#define COOLDOWN_HAWKEYE 10
#define COOLDOWN_SAFEGUARD 90
#define COOLDOWN_OVERCHARGE 35

#define DURATION_GODMODE 5.0
#define TASKID_REMOVE_GODMODE 6666

#define DURATION_STUMBLING_BLOCK 1.5
#define TASKID_REMOVE_STUMBLING_BLOCK 7777
#define TASKID_FREE_SHOT_RESET 6766

#define EXPLOSIVE_SHOT_HIT_COUNT 3
#define EXPLOSIVE_SHOT_RADIUS 100.0
#define EXPLOSIVE_SHOT_BASE_DMG 30.0

#define OVERLOAD_RADIUS 150.0

#define VAMPIRE_HEAL_AMT 10
#define VAMPIRE_HEAL_RADIUS 120.0

#define TRAIT_TOKEN_COST 2
#define TRAIT_AMMOPACK_COST 10

new const SOUND_LEARN_TRAIT[] = "sound/zombie_plague/levelup_trait.wav"
new const SOUND_BUFF[] = "sound/zombie_plague/td_buff_2.wav"
new const SOUND_DEBUFF[] = "sound/zombie_plague/td_debuff.wav"
new const SOUND_SHOCKWAVE_BLAST[] = "zombie_plague/shockwave_blast.wav"

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
	ID_FREE_SHOT,
	ID_FROZEN_SKIN,
	ID_GLASS_CANNON,
	ID_GRAVITY,
	ID_GUNNER,
	ID_HEADHUNTER,
	ID_HAWKEYE,
	ID_NO_HEAD_NO_DMG,
	ID_OVERCHARGE,
	ID_OVERLOAD,
	ID_PIERCING,
	ID_SAFEGUARD,
	ID_SHOCKWAVE,
	ID_STEADY_AIM,
	ID_STUMBLING_BLOCK,
	ID_TOUGHNESS,
	ID_VAMPIRE
}

enum _:TRAIT_SOURCE {
	SRC_TOKEN = 0,
	SRC_AMMOPACK
}

enum _:TRAIT_TYPE {
	TYPE_PASSIVE = 0,
	TYPE_SKILL
}

new g_msgScreenFade;
new g_iBarTime;
new g_iSprBeamLine;
new g_iSprShockwave;

new g_szTraitName[TOTAL_TRAITS][32]
new g_szTraitDesc[TOTAL_TRAITS][96]
new g_iTraitSource[TOTAL_TRAITS]
new g_iTraitType[TOTAL_TRAITS]
new	bool:g_bIsTraitActive[33][TOTAL_TRAITS]
new g_iTraitStack[33][TOTAL_TRAITS]

new g_iPlayerTraitLevel[33][TOTAL_TRAITS]

new bool:g_hasTrait[33][TOTAL_TRAITS];
new g_hudmessage_id_trait;
new g_hudmessage_id_skill;

// The cooldown of each trait per player;
new g_iTraitCooldown[33][TOTAL_TRAITS];
// Holds the Trait ID
new g_iPlayerSkillSlot[33][3]

// For resetting in TakeDamage_Post
new bool:g_bPierced[33];

new bool:g_bFrozen[33];
// For ExplosiveShot
new g_iHitBeforeExplosive[33];
new g_iExplodeSpriteIndex;

// For resetting free-shot refund
new bool:g_bFreeShotInCooldown[33];

// --- Overcharge --- //
// Weak period after using overcharge
#define TASKID_OVERCHARGE_TO_WEAK 6800
#define DURATION_OVERCHARGE_ACTIVE 5.0
#define TASKID_OVERCHARGE_WEAK_END 6850
#define DURATION_OVERCHARGE_WEAK 15.0
new bool:g_bIsOverchargeWeak[33];

// --- Gravity --- //
#define GRAVITY_RADIUS 300.0

#define TASKID_GRAVITY_PULL 6900
#define INTERVAL_GRAVITY_PULL 0.3
#define REPEAT_TIME_GRAVITY_PULL 16
#define DURATION_GRAVITY_PULL 5.2
#define TASKID_GRAVITY_PULL_END 6950
new g_iGravityPullCount[33];


// --- ShockWave --- //
#define SHOCKWAVE_RADIUS 300.0
#define SHOCKWAVE_COOLDOWN 30
#define SHOCKWAVE_MAX_CHARGE 3
#define SHOCKWAVE_FREEZE_DURATION 2.0


// --- CounterStrike --- //
// #define TASKID_COUNTERSTRIKE_END
// new g_iCounterStrikeCharge[33];

plugin_init_human_trait()
{
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_TraceLine,"fw_traceline",1);

	register_clcmd("ZsSkill1","UseSkill1");
	register_clcmd("ZsSkill2","UseSkill2");
	register_clcmd("ZsSkill3","UseSkill3");

	for(new i = 0 ; i < sizeof(g_CSW_WPN_ENT_NAME) ; i++)
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, g_CSW_WPN_ENT_NAME[i], "fw_Weapon_PrimaryAttack_Post", .Post = true)
	}

	initTraits();
	set_task(1.0, "show_trait_message", _,_,_,"b");
	set_task(1.0, "trait_cooldown_tick", _,_,_,"b");
	g_hudmessage_id_trait = hudmessage_queue_register_left(); 

	g_msgScreenFade = get_user_msgid( "ScreenFade" );
	g_iBarTime = get_user_msgid("BarTime")
}


plugin_precache_human_trait()
{
	precache_generic(SOUND_LEARN_TRAIT);
	precache_generic(SOUND_BUFF);
	precache_generic(SOUND_DEBUFF);

	precache_sound(SOUND_SHOCKWAVE_BLAST);
	g_iSprBeamLine = precache_model("sprites/zbeam4.spr")
	g_iExplodeSpriteIndex = precache_model("sprites/zerogxplode.spr"); 
	g_iSprShockwave = precache_model("sprites/shockwave.spr");  
}

initTraits()
{
	// === Name === //
	g_szTraitName[ID_ADRENALINE] = "Adrenaline"
	g_szTraitName[ID_BOXER] = "Boxer"
	g_szTraitName[ID_DEMOLITION] = "Demolition"
	g_szTraitName[ID_FROZEN_SKIN] = "Frozen Skin"
	g_szTraitName[ID_FREE_SHOT] = "Free shot"
	g_szTraitName[ID_GLASS_CANNON] = "Glass Cannon"
	g_szTraitName[ID_GRAVITY] = "Gravity"
	g_szTraitName[ID_GUNNER] = "Gunner"
	g_szTraitName[ID_HAWKEYE] = "Hawk Eye"
	g_szTraitName[ID_HEADHUNTER] = "Head Hunter"
	g_szTraitName[ID_NO_HEAD_NO_DMG] = "No Head No Dmg"
	g_szTraitName[ID_OVERCHARGE] = "Overcharge"
	g_szTraitName[ID_OVERLOAD] = "Overload"
	g_szTraitName[ID_PIERCING] = "Piercing"
	g_szTraitName[ID_STEADY_AIM] = "Steady Aim"
	g_szTraitName[ID_SAFEGUARD] = "Safeguard"
	g_szTraitName[ID_SHOCKWAVE] = "Shockwave"
	g_szTraitName[ID_STUMBLING_BLOCK] = "Stumbling Block"
	g_szTraitName[ID_TOUGHNESS] =	"Toughness"
	g_szTraitName[ID_VAMPIRE] = "Vampire"
	// === Desc === //
	g_szTraitDesc[ID_ADRENALINE] = "+1.5% damage per 2% lost health"
	g_szTraitDesc[ID_BOXER] = "+10%*[Lv] melee damage"
	g_szTraitDesc[ID_DEMOLITION] = "Every 3 hits , next hit deals 30*[Tier] explosive damage"
	g_szTraitDesc[ID_FREE_SHOT] = "33% chance to refund the ammo on hit"
	g_szTraitDesc[ID_FROZEN_SKIN] = "50% to freeze the attacker for 1.5 seconds upon taking damage"
	g_szTraitDesc[ID_GLASS_CANNON] = "+25% damage , +50% incoming damage"
	g_szTraitDesc[ID_GRAVITY] = "[Skill] Pull enemies to you for 5s, take 30% less damage per pulled (35s CD)"
	g_szTraitDesc[ID_GUNNER] = "+10%*[Tier] gun damage , -10%*[Tier] recoil"
	g_szTraitDesc[ID_NO_HEAD_NO_DMG] = "+50% headshot damage ; - 50% non-headshot damage"
	g_szTraitDesc[ID_OVERCHARGE] = "[Skill] +100% damage for 5s , then -50% damage for 15s (35s CD)"
	g_szTraitDesc[ID_OVERLOAD] = "When overflow damage > 300 , 50% is converted to explosive damage"
	g_szTraitDesc[ID_PIERCING] = "Your attack penetrates armor ; + 15% damage to enemy without armor"
	g_szTraitDesc[ID_STEADY_AIM] = "You shoot accurately when jumping / moving"
	g_szTraitDesc[ID_HAWKEYE] = "[BS only] Next non-headshot must headshot (10s CD); -2s CD per hit"
	g_szTraitDesc[ID_HEADHUNTER] = "+20% headshot damage"
	g_szTraitDesc[ID_SAFEGUARD] = "Gain 5s invincibility upon taking fatal damage, heals 70 hp"		// Maybe +atk ?
	g_szTraitDesc[ID_SHOCKWAVE] = "[Skill] Emit a shockwave that stuns enemies (3 charges , 30s CD)"
	g_szTraitDesc[ID_STUMBLING_BLOCK] = "Shots have 10% (33% for leg hits) chance to immobilize enemy for 1.5 seconds"
	g_szTraitDesc[ID_TOUGHNESS] =	"-10%*[Lv] incoming damage, 5%*[Lv] chance blocks attack"
	g_szTraitDesc[ID_VAMPIRE] = "Heals 10[+1*Tier] hp on kills ; or 5 hp when enemies killed nearby"
	// === SRC === //
	g_iTraitSource[ID_ADRENALINE] = SRC_TOKEN
	g_iTraitSource[ID_BOXER] = SRC_AMMOPACK
	g_iTraitSource[ID_DEMOLITION] = SRC_TOKEN
	g_iTraitSource[ID_FREE_SHOT] = SRC_TOKEN
	g_iTraitSource[ID_FROZEN_SKIN] = SRC_TOKEN
	g_iTraitSource[ID_GLASS_CANNON] = SRC_TOKEN
	g_iTraitSource[ID_GRAVITY] = SRC_TOKEN
	g_iTraitSource[ID_GUNNER] = SRC_AMMOPACK
	g_iTraitSource[ID_NO_HEAD_NO_DMG] = SRC_TOKEN
	g_iTraitSource[ID_OVERCHARGE] = SRC_TOKEN
	g_iTraitSource[ID_OVERLOAD] = SRC_TOKEN
	g_iTraitSource[ID_PIERCING] = SRC_TOKEN
	g_iTraitSource[ID_STEADY_AIM] = SRC_TOKEN
	g_iTraitSource[ID_HAWKEYE] = SRC_TOKEN
	g_iTraitSource[ID_HEADHUNTER] = SRC_TOKEN
	g_iTraitSource[ID_SAFEGUARD] = SRC_TOKEN
	g_iTraitSource[ID_SHOCKWAVE] = SRC_TOKEN
	g_iTraitSource[ID_STUMBLING_BLOCK] = SRC_TOKEN
	g_iTraitSource[ID_TOUGHNESS] =	SRC_AMMOPACK
	g_iTraitSource[ID_VAMPIRE] = SRC_TOKEN
	// === TYPE === //
	g_iTraitType[ID_ADRENALINE] = TYPE_PASSIVE
	g_iTraitType[ID_BOXER] = TYPE_PASSIVE
	g_iTraitType[ID_DEMOLITION] = TYPE_PASSIVE
	g_iTraitType[ID_FREE_SHOT] = TYPE_PASSIVE
	g_iTraitType[ID_FROZEN_SKIN] = TYPE_PASSIVE
	g_iTraitType[ID_GLASS_CANNON] = TYPE_PASSIVE
	g_iTraitType[ID_GRAVITY] = TYPE_SKILL
	g_iTraitType[ID_GUNNER] = TYPE_PASSIVE
	g_iTraitType[ID_NO_HEAD_NO_DMG] = TYPE_PASSIVE
	g_iTraitType[ID_OVERCHARGE] = TYPE_SKILL
	g_iTraitType[ID_OVERLOAD] = TYPE_PASSIVE
	g_iTraitType[ID_PIERCING] = TYPE_PASSIVE
	g_iTraitType[ID_STEADY_AIM] = TYPE_PASSIVE
	g_iTraitType[ID_HAWKEYE] = TYPE_PASSIVE
	g_iTraitType[ID_HEADHUNTER] = TYPE_PASSIVE
	g_iTraitType[ID_SAFEGUARD] = TYPE_PASSIVE
	g_iTraitType[ID_SHOCKWAVE] = TYPE_SKILL
	g_iTraitType[ID_STUMBLING_BLOCK] = TYPE_PASSIVE
	g_iTraitType[ID_TOUGHNESS] = TYPE_PASSIVE
	g_iTraitType[ID_VAMPIRE] = TYPE_PASSIVE
}

round_start_post_human_trait()
{
	for(new i = 1 ; i < 33 ; i ++)
	{
		for(new j = 0 ; j < TOTAL_TRAITS ; j++)
		{
			g_hasTrait[i][j] = false;
			g_iTraitCooldown[i][j] = -1;
			g_iTraitStack[i][j] = 0;
			g_iPlayerTraitLevel[i][j] = 0;
			g_bIsTraitActive[i][j] = false;
		}

		for(new j = 0 ; j < sizeof(g_iPlayerSkillSlot[])  ; j++)
		{
			g_iPlayerSkillSlot[i][j] = -1;
		}
		g_iTraitTakenCount[i] = 0;
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

		// Shockwave charges
		if(g_hasTrait[id][ID_SHOCKWAVE] && g_iTraitCooldown[id][ID_SHOCKWAVE] <= 0 && g_iTraitStack[id][ID_SHOCKWAVE] < SHOCKWAVE_MAX_CHARGE)
		{
			g_iTraitStack[id][ID_SHOCKWAVE]++;
			g_iTraitCooldown[id][ID_SHOCKWAVE] = SHOCKWAVE_COOLDOWN;
		}
	}
}

public show_trait_message()
{
	static players[MAX_PLAYERS] , iCount , i;
	get_players_ex(players, iCount , GetPlayers_ExcludeBots)
	for( i = 0 ; i < iCount ; i++)
	{
		static szMsg[374]; 
		static id; id = players[i];

		static szMsgToken[128]
		static szMsgUpgrade[128]
		static szMsgSkill[128]

		new iOwnSkillCount = 0;

		szMsg = "";
		szMsgToken = "Traits : ";
		szMsgUpgrade = "Upgrades : ";
		szMsgSkill = "Skills : ";

		for(new traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
		{
			if(!g_hasTrait[id][traitId])	continue;
			static szTraitStack[5];

			if(g_iTraitStack[id][traitId] <= 0)
				szTraitStack = "";
			else
				formatex(szTraitStack , charsmax(szTraitStack), " {%i}",g_iTraitStack[id][traitId]);


			if(g_iTraitType[traitId] == TYPE_SKILL)
			{
				static szTraitName[25];

				iOwnSkillCount++;
				
				if(g_iTraitCooldown[id][traitId] > 0)
					formatex(szTraitName , charsmax(szTraitName), "[%i] %s%s (%i) | ",iOwnSkillCount, g_szTraitName[traitId] ,szTraitStack, g_iTraitCooldown[id][traitId])
				else
					formatex(szTraitName , charsmax(szTraitName), "[%i] %s%s | ",iOwnSkillCount, g_szTraitName[traitId],szTraitStack)
				
				strcat(szMsgSkill, szTraitName, charsmax(szMsgSkill))				
			} 
			else if(g_iTraitSource[traitId] == SRC_TOKEN)
			{
				static szTraitName[25];
				if(g_iTraitCooldown[id][traitId] > 0)
					formatex(szTraitName , charsmax(szTraitName), "%s (%i) | ", g_szTraitName[traitId] , g_iTraitCooldown[id][traitId])
				else
					formatex(szTraitName , charsmax(szTraitName), "%s | ", g_szTraitName[traitId])	
				
				strcat(szMsgToken, szTraitName, charsmax(szMsgToken))
			}
			else if (g_iTraitSource[traitId] == SRC_AMMOPACK)
			{
				static szTraitName[20];
				formatex(szTraitName , charsmax(szTraitName), "%s L%i | ", g_szTraitName[traitId] , g_iPlayerTraitLevel[id][traitId])
				
				strcat(szMsgUpgrade, szTraitName, charsmax(szMsgUpgrade))
			}
		}

		
		strcat(szMsg , szMsgSkill, charsmax(szMsg))
		strcat(szMsg , "^n", charsmax(szMsg))
		strcat(szMsg , szMsgToken, charsmax(szMsg))
		strcat(szMsg , "^n", charsmax(szMsg))
		strcat(szMsg , szMsgUpgrade, charsmax(szMsg))
		
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
	
	new cswId; cswId = get_user_weapon(Attacker);
	new Float:dmg; dmg = Damage;
	
	// ==FreeShot== //
	if(g_hasTrait[Attacker][ID_FREE_SHOT] && cswId != CSW_KNIFE)
	{
		if(!g_bFreeShotInCooldown[Attacker])
		{
			if(random_num(1, 100) < 33)
			{
				new iAttackerWpnEnt = cs_get_user_weapon_entity(Attacker);
				new ammo = get_pdata_int(iAttackerWpnEnt, m_iClip, 4);
				cs_set_weapon_ammo(iAttackerWpnEnt, ammo + 1);
			}
			set_task(0.05, "reset_freeshot", Attacker + TASKID_FREE_SHOT_RESET);
			g_bFreeShotInCooldown[Attacker] = true;
		}
	}

	// ==Overcharge== //
	if(g_hasTrait[Attacker][ID_OVERCHARGE])
	{
		if(g_bIsTraitActive[Attacker][ID_OVERCHARGE])
			dmg *= 2.0;
		else if (g_bIsOverchargeWeak[Attacker])
			dmg *= 0.5;
	}

	// ==HwakEye== //
	if(g_hasTrait[Attacker][ID_HAWKEYE] && ((1 << cswId) & WPN_SEMI_SNIPER))
	{
		if(g_iTraitCooldown[Attacker][ID_HAWKEYE] <= 0 && get_tr2(Traceresult, TR_iHitgroup) != HIT_HEAD)
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
			dmg *= 1.0 + g_iPlayerTraitLevel[Attacker][ID_BOXER] * 0.1;
	}

	// ==Gunner== //
	if(g_hasTrait[Attacker][ID_GUNNER] && ((1 << cswId) & GUN_TYPE))
	{
		dmg *= 1.0 + g_iPlayerTraitLevel[Attacker][ID_GUNNER] * 0.1;
	}
	// ==Adrenaline== //
	if(g_hasTrait[Attacker][ID_ADRENALINE])
	{
		new Float:multi = 1.0 + (1.0 - float(get_user_health(Attacker))/ 100.0) / 1.5
		dmg *= multi;
	}

	if(get_tr2(Traceresult, TR_iHitgroup) == HIT_HEAD)
	{
		// ==HeadHunter==//
		if(g_hasTrait[Attacker][ID_HEADHUNTER])
			dmg *= 1.2;
		if(g_hasTrait[Attacker][ID_NO_HEAD_NO_DMG])
			dmg *= 1.5;
	}
	else
	{
		if(g_hasTrait[Attacker][ID_NO_HEAD_NO_DMG])
			dmg *= 0.5;

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
			stumble_entity(Victim , DURATION_STUMBLING_BLOCK)
		}
	}
	return dmg;
}

Float:Ham_TakeDamage_Pre_Human_Trait(Victim, iInflictor, Attacker, Float:fDamage, m_Damagebits )
{
	new Float:dmg; dmg = fDamage;

	if(is_user_connected(Attacker))
	{
		new iVictimTeam = _:cs_get_user_team(Victim);
		new iAttackerTeam = _:cs_get_user_team(Attacker);
		if(iVictimTeam == iAttackerTeam)
			return fDamage;
	}

	if(g_hasTrait[Victim][ID_GRAVITY] && g_bIsTraitActive[Victim][ID_GRAVITY])
	{
		if(g_iGravityPullCount[Victim] > 3)
			return 0.0;

		dmg *= 1.0 - g_iGravityPullCount[Victim] * 0.3;
	}

	if(g_hasTrait[Victim][ID_GLASS_CANNON])
		dmg *= 1.5;
	// ==Toughness== //
	if(g_hasTrait[Victim][ID_TOUGHNESS])
	{
		static iTier; iTier = g_iPlayerTraitLevel[Victim][ID_TOUGHNESS];
		if(random_num(1, 100) < 5*iTier)
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
		g_iTraitCooldown[Victim][ID_SAFEGUARD] = COOLDOWN_SAFEGUARD
		fade_white(Victim);
		set_user_health(Victim, 100)
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
			doRadiusDamage(Attacker, fOrigin, true, OVERLOAD_RADIUS , fDiff)
			create_shockwave(fOrigin , 255 ,0 , 0);
		}
	}
	// ==Frozen Skin== //
	if(g_hasTrait[Victim][ID_FROZEN_SKIN] && random_num(1, 100) < 50)
	{
		g_bFrozen[Attacker] = true;
		fm_set_rendering(Attacker,kRenderFxGlowShell,255,255,255,kRenderNormal,8);
		remove_task(Attacker + TASKID_REMOVE_STUMBLING_BLOCK);
		set_task(DURATION_STUMBLING_BLOCK, "remove_stumbling_block", Attacker + TASKID_REMOVE_STUMBLING_BLOCK);
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

// ========================== Skills =========================== //
public UseSkill1(id)
{
	use_skill(id, 0);
}

public UseSkill2(id)
{
	use_skill(id, 1);
}

public UseSkill3(id)
{
	use_skill(id, 2);
}

use_skill(id, iSlot)
{
	new iTraitId = g_iPlayerSkillSlot[id][iSlot];
	if(iTraitId == -1 || (g_iTraitCooldown[id][iTraitId] > 0 && g_iTraitStack[id][iTraitId] <= 0))		return;

	if(iTraitId == ID_OVERCHARGE)
	{
		g_iTraitCooldown[id][iTraitId] = COOLDOWN_OVERCHARGE;
		g_bIsTraitActive[id][iTraitId] = true;
		set_task(DURATION_OVERCHARGE_ACTIVE, "task_overcharge_to_weak", id + TASKID_OVERCHARGE_TO_WEAK);
		Make_ProgressBar(id , DURATION_OVERCHARGE_ACTIVE);
		client_cmd(id, "spk %s", SOUND_BUFF);
	}
	else if (iTraitId == ID_GRAVITY)
	{
		g_iTraitCooldown[id][iTraitId] = COOLDOWN_OVERCHARGE;
		g_bIsTraitActive[id][iTraitId] = true;
		set_task_ex(INTERVAL_GRAVITY_PULL, "task_gravity_pull" , id + TASKID_GRAVITY_PULL , "" ,0 , SetTask_RepeatTimes , REPEAT_TIME_GRAVITY_PULL)
		set_task(DURATION_GRAVITY_PULL , "task_gravity_pull_end", id + TASKID_GRAVITY_PULL_END)
		Make_ProgressBar(id , DURATION_GRAVITY_PULL);
		client_cmd(id, "spk %s", SOUND_BUFF);
	}
	else if (iTraitId == ID_SHOCKWAVE)
	{
		console_print(0, "Stacks %i" , g_iTraitStack[id][iTraitId]);
		if(g_iTraitStack[id][iTraitId] <= 0)	return;
		g_iTraitStack[id][iTraitId]--;
		g_iTraitCooldown[id][iTraitId] = SHOCKWAVE_COOLDOWN;

		new Float:fOrigin[3]
		pev(id, pev_origin, fOrigin);

		create_shockwave(fOrigin , 0 ,0 , 255);
		freezeEntitiesAroundTarget(id, SHOCKWAVE_RADIUS)
		emit_sound(id, CHAN_AUTO, SOUND_SHOCKWAVE_BLAST, VOL_NORM, ATTN_NORM, 0, PITCH_NORM) 
	}
}

public task_overcharge_to_weak(taskId)
{
	new id = taskId - TASKID_OVERCHARGE_TO_WEAK
	set_task(DURATION_OVERCHARGE_WEAK, "task_overcharge_weak_end", id + TASKID_OVERCHARGE_WEAK_END);
	g_bIsTraitActive[id][ID_OVERCHARGE] = false;
	g_bIsOverchargeWeak[id] = true;
	client_cmd(id, "spk %s", SOUND_DEBUFF);
}

public task_overcharge_weak_end(taskId)
{
	new id = taskId - TASKID_OVERCHARGE_WEAK_END
	g_bIsOverchargeWeak[id] = false;
}

// ------

public task_gravity_pull(taskId)
{
	new id = taskId - TASKID_GRAVITY_PULL
	new iPullCount = pullEntitiesTowardsTarget(id , GRAVITY_RADIUS);
	g_iGravityPullCount[id] = iPullCount;
}

public task_gravity_pull_end(taskId)
{
	new id = taskId - TASKID_GRAVITY_PULL_END
	g_bIsTraitActive[id][ID_GRAVITY] = false;
}

// ========================================================== //

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED

	if(g_bFrozen[id])
	{
		static Float:fFrozenVec[3];
		fFrozenVec[0] = 0.0
		fFrozenVec[1] = 0.0
		fFrozenVec[2] = -500.0
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

public reset_freeshot(taskid)
{
	new id = taskid - TASKID_FREE_SHOT_RESET;
	g_bFreeShotInCooldown[id] = false;
}

Ham_Killed_Pre_Human_Trait(victim, attacker, shouldgib)
{
	if(!is_zombie(victim) || !is_user_alive(attacker))
		return HAM_IGNORED;

	if(is_user_alive(attacker) && g_hasTrait[attacker][ID_VAMPIRE])
	{
		new toHeal = VAMPIRE_HEAL_AMT + g_iCurrStage;
		new hp = get_user_health(attacker);
		if(hp < (100 - toHeal))
			set_user_health(attacker, hp + toHeal)
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
		fRecoil *= 1.0 - g_iPlayerTraitLevel[ownerId][ID_GUNNER] * 0.1

	new Float:push[3]
	pev(ownerId,pev_punchangle,push)
	xs_vec_sub(push,g_fPushAngle[ownerId],push)
	
	xs_vec_mul_scalar(push, fRecoil ,push)
	xs_vec_add(push,g_fPushAngle[ownerId],push)
	set_pev(ownerId,pev_punchangle,push)
	return HAM_IGNORED
}

// === TraitMenu ( Token ) === //
show_menu_human_trait(id)
{
	static szTitle[32];
	formatex(szTitle, charsmax(szTitle), "\r Tokens : [%i]" , g_iToken[id])
	new menu = menu_create(szTitle, "menu_human_trait_handler" );

	static szDisplay[128];
	static szTraitId[3];
	static traitId;
	new Array:upgradable = get_upgradable_traitId_token(id);
	for(new i = 0 ; i < ArraySize(upgradable) ; i++)
	{
		traitId = ArrayGetCell(upgradable, i);
		// formatex(szTraitName , charsmax(szTraitName) , "%s" , g_szTraitName[traitId])
		formatex(szDisplay , charsmax(szDisplay) , "%s - %s" ,g_szTraitName[traitId], g_szTraitDesc[traitId])
		// formatex(szTraitDesc , charsmax(szTraitDesc) , "------- %s", g_szTraitDesc[traitId])
		formatex(szTraitId , charsmax(szTraitId) , "%i" , traitId);
		menu_additem( menu, szDisplay, szTraitId);
		if((i+1) % 5 == 0 )
		{
			menu_addblank2(menu)
			menu_addblank2(menu)
		}
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

		choose_trait_token(id , iTraitId);
		g_iToken[id] -= TRAIT_TOKEN_COST;
	}
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

// ========= Menu ( Ammopack ) =========== //
show_menu_human_trait_ammopack(id)
{
	static szTitle[32];
	formatex(szTitle, charsmax(szTitle), "\r Ammopacks : [%i]" , g_iAmmoPack[id])
	new menu = menu_create(szTitle, "menu_human_trait_handler_ammopack" );

	static szDisplay[128];
	static szTraitId[3];
	static traitId;
	new Array:upgradable = get_upgradable_traitId_ammopack(id);
	for(new i = 0 ; i < ArraySize(upgradable) ; i++)
	{
		traitId = ArrayGetCell(upgradable, i);
		// formatex(szTraitName , charsmax(szTraitName) , "%s" , g_szTraitName[traitId])
		formatex(szDisplay , charsmax(szDisplay) , "%s - %s" ,g_szTraitName[traitId], g_szTraitDesc[traitId])
		// formatex(szTraitDesc , charsmax(szTraitDesc) , "------- %s", g_szTraitDesc[traitId])
		formatex(szTraitId , charsmax(szTraitId) , "%i" , traitId);
		menu_additem( menu, szDisplay, szTraitId);
		if((i+1) % 5 == 0 )
		{
			menu_addblank2(menu)
			menu_addblank2(menu)
		}
	}

	ArrayDestroy(upgradable);
	menu_display(id, menu, 0 );
}

public menu_human_trait_handler_ammopack( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	if(is_user_alive(id) && g_iAmmoPack[id] >= TRAIT_AMMOPACK_COST){
	// if(is_user_alive(id)){
		//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
		new szData[16], szName[64];
		new _access, item_callback;
		//heres the function that will give us that information ( since it doesnt magicaly appear )
		menu_item_getinfo( menu, item, _access, szData, charsmax( szData ), szName, charsmax( szName ), item_callback );

		new iTraitId = str_to_num(szData);

		choose_trait_ammopack(id , iTraitId);
		g_iAmmoPack[id] -= TRAIT_AMMOPACK_COST;
	}
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}


Array:get_upgradable_traitId_token(id)
{
	new Array:array = ArrayCreate();
	for(new traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
	{
		if(!g_hasTrait[id][traitId] && g_iTraitSource[traitId] == SRC_TOKEN)
			ArrayPushCell(array, traitId);
	}
	return array;
}

Array:get_upgradable_traitId_ammopack(id)
{
	new Array:array = ArrayCreate();
	for(new traitId = 0 ; traitId < TOTAL_TRAITS ; traitId++)
	{
		if(g_iTraitSource[traitId] == SRC_AMMOPACK)
			ArrayPushCell(array, traitId);
	}
	return array;
}

choose_trait_token(id, traitId)
{
	g_iTraitTakenCount[id]++;
	g_hasTrait[id][traitId] = true;
	client_cmd(id, "spk %s", SOUND_LEARN_TRAIT);

	if(g_iTraitType[traitId] == TYPE_SKILL)
	{
		for(new i = 0 ; i < sizeof(g_iPlayerSkillSlot[])  ; i++)
		{
			if(g_iPlayerSkillSlot[id][i] == -1)
			{
				g_iPlayerSkillSlot[id][i] = traitId;
				return;
			}
		}
	}
}

choose_trait_ammopack(id, traitId)
{
	g_hasTrait[id][traitId] = true;
	g_iPlayerTraitLevel[id][traitId]++;
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

public draw_beam_to_target(iFromEnt , iToEnt) // set beam (ex. tongue:) if target is player
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)	// TE_BEAMENTS
	write_short(iFromEnt)
	write_short(iToEnt)
	write_short(g_iSprBeamLine)	// sprite index
	write_byte(0)	// start frame
	write_byte(0)	// framerate
	write_byte(2)	// life
	write_byte(8)	// width
	write_byte(1)	// noise
	write_byte(0)	// r, g, b
	write_byte(181)	// r, g, b
	write_byte(226)	// r, g, b
	write_byte(128)	// brightness
	write_byte(10)	// speed
	message_end()
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

		ExecuteHamB(Ham_TakeDamage,iVictim,iAttacker,iAttacker,fDamage,DMG_GRENADE);			
	}
}

stock pullEntitiesTowardsTarget(iTarget, Float:fRadius)
{
	new Float:fSrcVec[3] , Float:fDestVec[3] , Float:fDirVelocity[3];
	pev(iTarget, pev_origin, fSrcVec);

	new targetTeam = _:cs_get_user_team(iTarget);
	new iInRange = -1;
	new iPullCount = 0;
	while((iInRange = engfunc(EngFunc_FindEntityInSphere, iInRange, fSrcVec, fRadius)))
	{
		if(!is_user_alive(iInRange) || iInRange == iTarget)
			continue;

		if((_:cs_get_user_team(iInRange) == targetTeam))
			continue;

		pev(iInRange, pev_origin, fDestVec);

		xs_vec_sub(fSrcVec , fDestVec, fDirVelocity);
		xs_vec_normalize(fDirVelocity , fDirVelocity);
		xs_vec_mul_scalar(fDirVelocity , 600.0 , fDirVelocity);

		entity_set_vector(iInRange, EV_VEC_velocity, fDirVelocity)
		
		draw_beam_to_target(iTarget , iInRange);

		iPullCount++;
	}
	return iPullCount;
}

freezeEntitiesAroundTarget(iTarget, Float:fRadius)
{
	new Float:fSrcVec[3]
	pev(iTarget, pev_origin, fSrcVec);

	new targetTeam = _:cs_get_user_team(iTarget);
	new iInRange = -1;
	while((iInRange = engfunc(EngFunc_FindEntityInSphere, iInRange, fSrcVec, fRadius)))
	{
		if(!is_user_alive(iInRange) || iInRange == iTarget)
			continue;

		if((_:cs_get_user_team(iInRange) == targetTeam))
			continue;

		stumble_entity(iInRange , SHOCKWAVE_FREEZE_DURATION);
	}
}

stumble_entity(iEnt, Float:fDuration)
{
	g_bFrozen[iEnt] = true;
	fm_set_rendering(iEnt,kRenderFxGlowShell,255,255,255,kRenderNormal,8);
	remove_task(iEnt + TASKID_REMOVE_STUMBLING_BLOCK);
	set_task(fDuration, "remove_stumbling_block", iEnt + TASKID_REMOVE_STUMBLING_BLOCK);
}

create_shockwave(const Float:originF[3] , iRed , iGreen , iBlue)
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_iSprShockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(iRed) // red
	write_byte(iGreen) // green
	write_byte(iBlue) // blue
	write_byte(100) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_iSprShockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(iRed) // red
	write_byte(iGreen) // green
	write_byte(iBlue) // blue
	write_byte(150) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_iSprShockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(iRed) // red
	write_byte(iGreen) // green
	write_byte(iBlue) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

Make_ProgressBar(id , Float:fTime)
{
	new iTime = floatround(fTime, floatround_ceil)
	message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id)
	write_short(iTime)
	message_end()
}