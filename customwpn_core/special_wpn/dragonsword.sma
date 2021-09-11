#define DRAGONSWORD_SLASH_DIST 64.0
#define DRAGONSWORD_SLASH_DMG 114.0
#define DRAGONSWORD_SLASH_ANGLE 40.0

#define DRAGONSWORD_STAB_DIST 96.0
#define DRAGONSWORD_STAB_DMG 119.0
#define DRAGONSWORD_STAB_ANGLE 40.0


PrimaryAttack_Pre_DragonSword(id , iEnt)
{
	Stock_SetWeaponAnimation(id , 1);
	Stock_SetWeaponNextAttacks(iEnt , 1.5 , 1.5, 1.5 + 3.0);

	set_pev(iEnt, pev_nextthink, get_gametime() + 0.7);
	SetThink(iEnt, "slash_dragonsword")
}

SecondaryAttack_Pre_DragonSword(id, iEnt)
{
	Stock_SetWeaponAnimation(id , 4);
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.71);
	SetThink(iEnt, "stab_dragonsword")
}


public slash_dragonsword(iEnt)
{
	// new iBteWpn = WeaponIndex(iEnt);
	SetThink(iEnt , "");
	new iPlyId = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static cswId; cswId = get_player_weapon(iPlyId);
	if(cswId != CSW_KNIFE)	
		return;

	rg_set_animation(iPlyId, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(iPlyId, is_extend_knife_dist(), DRAGONSWORD_SLASH_DIST, DRAGONSWORD_SLASH_ANGLE, DRAGONSWORD_SLASH_DMG, 0.0);
	Util_PlayKnifeSoundByHitResult(iPlyId, iEnt, iHitResult , false)
}

public stab_dragonsword(iEnt)
{
	SetThink(iEnt , "");
	new iPlyId = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static cswId; cswId = get_player_weapon(iPlyId);
	if(cswId != CSW_KNIFE)	
		return;
		
	rg_set_animation(iPlyId, PLAYER_ATTACK1)
	Stock_SetWeaponAnimation(iPlyId , 5);
	new iHitResult = Stock_KnifeAttackWithAngle(iPlyId, is_extend_knife_dist(), DRAGONSWORD_STAB_DIST, DRAGONSWORD_STAB_ANGLE, DRAGONSWORD_STAB_DMG, 0.0);

	Util_PlayKnifeSoundByHitResult(iPlyId, iEnt, iHitResult , false)
}

Holster_Post_DragonSword(id , iEnt)
{
	SetThink(iEnt , "");
}