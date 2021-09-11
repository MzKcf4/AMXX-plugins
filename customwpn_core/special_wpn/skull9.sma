#define SKULL9_DMG 100.0

#define SKULL9_SLASH_DIST 96.0
#define SKULL9_SLASH_ANGLE 30.0

#define SKULL9_STAB_DIST 90.0
#define SKULL9_STAB_ANGLE 150.0

PrimaryAttack_Pre_Skull9(id , iEnt)
{
	Stock_SetWeaponAnimation(id , 2);
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);

	set_pev(iEnt, pev_nextthink, get_gametime() + 1.0);
	SetThink(iEnt, "slash_skull9")
}

SecondaryAttack_Pre_Skull9(id, iEnt)
{
	Stock_SetWeaponAnimation(id , 5);
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.16);
	SetThink(iEnt, "stab_skull9")
}

public slash_skull9(iEnt)
{
	SetThink(iEnt , "");
	new iPlyId = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static cswId; cswId = get_player_weapon(iPlyId);
	if(cswId != CSW_KNIFE)	
		return;

	rg_set_animation(iPlyId, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(iPlyId, TRUE, SKULL9_SLASH_DIST, SKULL9_SLASH_ANGLE, SKULL9_DMG, 0.0);
	if(iHitResult == RESULT_HIT_NONE)
		Stock_SetWeaponAnimation(iPlyId , 4);
	else
		Stock_SetWeaponAnimation(iPlyId , 3);

	Util_PlayKnifeSoundByHitResult(iPlyId, iEnt, iHitResult , false)

	// new Float:flDamage = (!IS_ZBMODE) ? c_flDamage[iBteWpn][0] : c_flDamageZB[iBteWpn][0];
	/*
	new iHitResult = KnifeAttack(id, FALSE, c_flDistance[iBteWpn][0], flDamage, _);
	*/
}

public stab_skull9(iEnt)
{
	SetThink(iEnt , "");
	new iPlyId = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static cswId; cswId = get_player_weapon(iPlyId);
	if(cswId != CSW_KNIFE)	
		return;
		
	rg_set_animation(iPlyId, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(iPlyId, TRUE, SKULL9_STAB_DIST, SKULL9_STAB_ANGLE, SKULL9_DMG, 0.0);

	Util_PlayKnifeSoundByHitResult(iPlyId, iEnt, iHitResult , false)
}

Holster_Post_Skull9(id , iEnt)
{
	SetThink(iEnt , "");
}