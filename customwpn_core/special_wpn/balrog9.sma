#define BALROG9_SLASH_SEQ_1 1
#define BALROG9_SLASH_SEQ_2 2
#define BALROG9_SLASH_SEQ_3 3
#define BALROG9_SLASH_SEQ_4 4
#define BALROG9_SLASH_SEQ_5 5

#define BALROG9_CHARGE_TIME 1.0

#define BALROG9_NOT_CHARGED 0
#define BALROG9_WAIT_FOR_CHARGE_START 1
#define BALROG9_CHARGING 2
#define BALROG9_CHARGED 3

#define BALROG9_SLASH_DIST 48.0
#define BALROG9_SLASH_DMG 35.0

#define BALROG9_STAB_DIST 48.0
#define BALROG9_STAB_DMG 58.0

#define BALROG9_EXPLODE_DMG 50.0
#define BALROG9_EXPLODE_RADIUS 128.0

new balrog9_explode_spr_index;

public precache_Balrog9()
{
	balrog9_explode_spr_index = precache_model("sprites/ef_balrog1.spr");
}

PrimaryAttack_Pre_Balrog9(id , iEnt)
{
	static iPrevSlashSeq, iNextSlashSeq;
	iPrevSlashSeq = pev(iEnt, pev_iuser2);
	if(iPrevSlashSeq <= 0 || iPrevSlashSeq == BALROG9_SLASH_SEQ_5)
		iNextSlashSeq = BALROG9_SLASH_SEQ_1;
	else
		iNextSlashSeq++;

	Stock_SetWeaponNextAttacks(iEnt , 0.3 , 0.3, 0.3 + 3.0);
	Stock_SetWeaponAnimation(id , iNextSlashSeq);
	set_pev(iEnt, pev_iuser2 , iNextSlashSeq)	

	new iHitResult = Stock_KnifeAttack(id, g_bIsZombieMode, BALROG9_SLASH_DIST, BALROG9_SLASH_DMG, _, _,_,1);
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
	rg_set_animation(id, PLAYER_ATTACK1)
}


SecondaryAttack_Pre_Balrog9(id, iEnt)
{
	new iCharged = pev(iEnt, pev_iuser1);
	if(iCharged == RUNEBLADE_NOT_CHARGED)
	{
		SetThink(iEnt , "");
		set_pev(iEnt, pev_iuser1, BALROG9_WAIT_FOR_CHARGE_START);
		set_pev(iEnt, pev_nextthink, get_gametime() + 1.0);
		SetThink(iEnt, "check_charge_balrog9")
		Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 3.0);
		Stock_SetWeaponAnimation(id , 7);
	}
}

// First check , if pass , then go to charge check loop
public check_charge_balrog9(iEnt)
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, 4);

	SetThink(iEnt , "");
	
	// Still holding right click?	
	if(pev(id, pev_button) & IN_ATTACK2)
	{
		// Switch to charging mode
		set_pev(iEnt, pev_iuser1, BALROG9_CHARGING);
		Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 3.0);
		Stock_SetWeaponAnimation(id , 9);

		set_pev(iEnt, pev_nextthink, get_gametime() + 0.5);
		set_pev(iEnt, pev_fuser1, BALROG9_CHARGE_TIME)
		// Start the charge animation loop by think
		SetThink(iEnt, "charging_balrog9")
	}
	else
	{
		// Released
		charge_attack_balrog9(id , iEnt , false);
		/*
		set_pev(iEnt, pev_iuser1, BALROG9_NOT_CHARGED);
		new iHitResult = Stock_KnifeAttack(id, FALSE, BLAROG9_STAB_DIST, BLAROG9_STAB_DMG, _, _,_,_,1);
		Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
		rg_set_animation(id, PLAYER_ATTACK1)
		*/
	}
}

public charging_balrog9(iEnt)
{
	static iChargeState; iChargeState = pev(iEnt, pev_iuser1);
	static id; id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	if(iChargeState == BALROG9_CHARGING)
	{
		static Float:fChargeRemaining; 
		pev(iEnt, pev_fuser1,fChargeRemaining)
		fChargeRemaining -= 1.0;
		if(fChargeRemaining <= 0.0)
		{
			Stock_SetWeaponAnimation(id , 8);
			set_pev(iEnt, pev_iuser1, BALROG9_CHARGED);
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.33);
			return;
		}
		else 
		{
			Stock_SetWeaponAnimation(id , 9);
			set_pev(iEnt,pev_fuser1, fChargeRemaining)
		}		
	} 
	else if (iChargeState == BALROG9_CHARGED)
	{
		Stock_SetWeaponAnimation(id , 10);
	}
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.0);
}


public ItemPostFrame_Balrog9(id, iEnt)
{
	static iChargeState; iChargeState = pev(iEnt, pev_iuser1);
	static iButton; iButton = pev(id, pev_button);

	if(iChargeState == BALROG9_WAIT_FOR_CHARGE_START)
	{
		// Released immediately after pressing Attack2
		if(!(iButton & IN_ATTACK2))
		{
			set_pev(iEnt, pev_iuser1, BALROG9_NOT_CHARGED);
		}
	}
	else if(iChargeState == BALROG9_CHARGING)
	{
		if(!(iButton & IN_ATTACK2))
		{
			charge_attack_balrog9(id, iEnt, false);
		}
		else
		{
			// Still charging
			Stock_SetWeaponNextAttacks(iEnt , 1.5 , 1.5, 1.5 + 99.0);
		}
	}
	else if(iChargeState == BALROG9_CHARGED)
	{
		if(!(iButton & IN_ATTACK2))
		{
			charge_attack_balrog9(id , iEnt, true);
		}
		else
		{
			// Still holding Attack2
			Stock_SetWeaponNextAttacks(iEnt , 1.5 , 1.5, 1.5 + 99.0);	
		}
	}
	return HAM_IGNORED;
}

public charge_attack_balrog9(id , iEnt, bCharged)
{
	SetThink(iEnt, "");
	set_pev(iEnt, pev_iuser1, RUNEBLADE_NOT_CHARGED);
	Stock_SetWeaponNextAttacks(iEnt , 1.5 , 1.5, 1.5 + 3.0);

	if(bCharged)
		Stock_SetWeaponAnimation(id , 12);
	else
		Stock_SetWeaponAnimation(id , 11);

	new iHitResult = Stock_KnifeAttack(id, g_bIsZombieMode, BALROG9_STAB_DIST, BALROG9_STAB_DMG, _, _,_,1);
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
	rg_set_animation(id, PLAYER_ATTACK1)

	if(bCharged)
	{
		new Float:vecOrigin[3], Float:vecForward[3], Float:vecResult[3];
		pev(id, pev_origin, vecOrigin);
		// Get the view angle of player
		// pev(id, pev_v_angle, v_angle);
		// Turn the view angle into vector
		// angle_vector(v_angle , ANGLEVECTOR_FORWARD , vecForward)
		// Add the range vector to view vector , to get the end position of attack
		velocity_by_aim(id , 10, vecForward);
		xs_vec_add(vecOrigin, vecForward, vecResult);

		// static Float:fPos[3];
		// pev(id , pev_origin, fPos);
		Stock_DoRadiusDamage(vecResult, iEnt , id , BALROG9_EXPLODE_DMG , BALROG9_EXPLODE_RADIUS , _ , DMG_BULLET, true , false , false);
		// stock Stock_DoRadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:flKnockBack=0.0, bitsDamageType, bSkipAttacker = TRUE, bCheckTeam, bDistanceCheck = TRUE)
		// rg_dmg_radius(fPos , iEnt , id, BALROG9_EXPLODE_DMG , BALROG9_EXPLODE_RADIUS,DONT_IGNORE_MONSTERS, DMG_BULLET)
		make_explosion(id, vecResult);
	}
}

public Holster_Post_Balrog9(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, 0);
	set_pev(iEnt, pev_fuser1, 0.0);	
}


stock make_explosion(id, Float:fOrigin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc( EngFunc_WriteCoord,fOrigin[0]);
	engfunc( EngFunc_WriteCoord,fOrigin[1] + 1.0);
	engfunc( EngFunc_WriteCoord,fOrigin[2]);
	write_short(balrog9_explode_spr_index);
	write_byte(10); // scale
	write_byte(30); // framerate
	write_byte(0); // flags
	message_end();
}