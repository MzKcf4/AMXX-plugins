#define CROW9_NOT_CHARGED 0
#define CROW9_WAIT_FOR_MOUSE_RELEASE 1
#define CROW9_CHARGING 2
#define CROW9_CHARGE_READY 3
#define CROW9_CHARGE_MISSED 4

#define CROW9_SLASH_DIST 64.0
#define CROW9_SLASH_DMG 30.0

#define CROW9_STAB_DIST 64.0
#define CROW9_STAB_DMG 70.0

#define CROW9_STAB_CHARGED_DIST 96.0
#define CROW9_STAB_CHARGED_DMG 110.0
#define CROW9_STAB_CHARGED_ANGLE 45.0

public PrimaryAttack_Pre_Crow9(id, iEnt)
{
	static iPrevAni; iPrevAni = pev(iEnt, pev_iuser2)
	iPrevAni = iPrevAni == 1 ? 2 : 1;
	Stock_SetWeaponAnimation(id , iPrevAni == 1 ? 2 : 1);
	set_pev(iEnt, pev_iuser2, iPrevAni);
	
	/*
	new iHitResult, Float:flDamage = (!IS_ZBMODE) ? c_flDamage[iBteWpn][0] : c_flDamageZB[iBteWpn][0];	
	if (!c_flAngle[iBteWpn][0])
		iHitResult = KnifeAttack(id, TRUE, c_flDistance[iBteWpn][0], flDamage, _);
	else
		iHitResult = KnifeAttack2(id, TRUE, c_flDistance[iBteWpn][0], c_flAngle[iBteWpn][0], flDamage, _);
	*/
	new iHitResult = Stock_KnifeAttack(id ,g_bIsZombieMode , CROW9_SLASH_DIST, CROW9_SLASH_DMG, _,_,_,1)
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
	Stock_SetWeaponNextAttacks(iEnt , 0.3 , 0.3, 0.3 + 3.0);
	rg_set_animation(id, PLAYER_ATTACK1)
	/*	
	if(iHitResult == RESULT_HIT_WORLD)
	{
		if (iSwing)
			PunchAxis(id, 0.8, 0.8);
		else
			PunchAxis(id, -0.8, -0.8);
	}
	
	if(iHitResult)
		UTIL_WeaponDelay(iEnt, c_flAttackInterval[iBteWpn][0], c_flAttackInterval[iBteWpn][0], c_flAttackInterval[iBteWpn][0] + 1.0);
	else
		UTIL_WeaponDelay(iEnt, c_flAttackInterval[iBteWpn][0] + 0.1, c_flAttackInterval[iBteWpn][0] + 0.1, c_flAttackInterval[iBteWpn][0] + 0.1 + 1.0);
	*/
	
}

public SecondaryAttack_Pre_Crow9(id, iEnt)
{
	Stock_SetWeaponAnimation(id , 4);
	rg_set_animation(id, PLAYER_ATTACK1)

	new iHitResult = Stock_KnifeAttack(id , g_bIsZombieMode, CROW9_STAB_DIST, CROW9_STAB_DMG, _,_,_,1)
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);
	
	// Charge flag
	set_pev(iEnt, pev_iuser1, CROW9_WAIT_FOR_MOUSE_RELEASE);

	set_pev(iEnt, pev_nextthink, get_gametime() + 0.8);
	SetThink(iEnt , "Crow9_ChargeReady");
}

public ItemPostFrame_Crow9(id, iEnt)
{
	static iChargeState; iChargeState = pev(iEnt, pev_iuser1);
	if(iChargeState == CROW9_WAIT_FOR_MOUSE_RELEASE)
	{
		// Even release right click immediately , it still has 3 calls into PostFrame. So need to wait for release.
		if(!(pev(id, pev_button) & IN_ATTACK2))
			set_pev(iEnt, pev_iuser1, CROW9_CHARGING);
	} 
	else if(iChargeState == CROW9_CHARGING) 
	{
		if((pev(id, pev_button) & IN_ATTACK2))
			set_pev(iEnt, pev_iuser1, CROW9_CHARGE_MISSED);
	}
	else if(iChargeState == CROW9_CHARGE_READY)
	{
		if((pev(id, pev_button) & IN_ATTACK2))
			Crow9_ChargeAttack(id, iEnt)
	}
	return HAM_IGNORED
}

public Crow9_ChargeReady(iEnt)
{
	SetThink(iEnt , "");
	new iChargeState = pev(iEnt, pev_iuser1);
	if(iChargeState != CROW9_CHARGE_MISSED)
		set_pev(iEnt, pev_iuser1, CROW9_CHARGE_READY);

	set_pev(iEnt, pev_nextthink, get_gametime() + 0.2);
	SetThink(iEnt , "Crow9_ChargeFail");
}

public Crow9_ChargeFail(iEnt)
{
	// new iBteWpn = WeaponIndex(iEnt);
	new id = get_pdata_cbase(iEnt, m_pPlayer, 4);

	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, CROW9_NOT_CHARGED);
	Stock_SetWeaponAnimation(id , 6);
	// UTIL_WeaponDelay(iEnt, c_flAttackInterval[iBteWpn][2], c_flAttackInterval[iBteWpn][2], c_flAttackInterval[iBteWpn][2] + 0.5);
}

public Crow9_ChargeAttack(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, CROW9_NOT_CHARGED);
	Stock_SetWeaponAnimation(id , 5);
	rg_set_animation(id, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(id, g_bIsZombieMode, CROW9_STAB_CHARGED_DIST, CROW9_STAB_CHARGED_ANGLE,CROW9_STAB_CHARGED_DMG, 0.0);
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
}


Holster_Post_Crow9(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, 0);
	set_pev(iEnt, pev_iuser2, 0);
}
