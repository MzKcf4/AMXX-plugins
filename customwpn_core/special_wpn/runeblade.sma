#define RUNEBLADE_NOT_CHARGED 0
#define RUNEBLADE_WAIT_FOR_CHARGE_START 1
#define RUNEBLADE_CHARGING 2
#define RUNEBLADE_CHARGED 3

#define RUNEBLADE_CHARGE_TIME 3.0

#define RUNEBLADE_SLASH_DIST 96.0
#define RUNEBLADE_SLASH_DMG 118.0
#define RUNEBLADE_SLASH_ANGLE 180.0

#define RUNEBLADE_STAB_DIST 96.0
#define RUNEBLADE_STAB_DMG 96.0
#define RUNEBLADE_STAB_ANGLE 120.0

#define RUNEBLADE_STAB_CHARGED_DIST 160.0
#define RUNEBLADE_STAB_CHARGED_DMG 163.0


PrimaryAttack_Pre_Runeblade(id, iEnt)
{
	Stock_SetWeaponAnimation(id , 1);
	Stock_SetWeaponNextAttacks(iEnt , 1.4 , 1.4, 2.0 + 3.0);

	set_pev(iEnt, pev_nextthink, get_gametime() + 0.33);
	SetThink(iEnt, "slash_runeblade")
}

public slash_runeblade(iEnt)
{
	SetThink(iEnt , "");
	new iPlyId = get_pdata_cbase(iEnt, m_pPlayer, 4);
	static cswId; cswId = get_player_weapon(iPlyId);
	if(cswId != CSW_KNIFE)	
		return;

	rg_set_animation(iPlyId, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(iPlyId, is_extend_knife_dist(), RUNEBLADE_SLASH_DIST, RUNEBLADE_SLASH_ANGLE, RUNEBLADE_SLASH_DMG, 0.0);
	Util_PlayKnifeSoundByHitResult(iPlyId, iEnt, iHitResult , false)
}

SecondaryAttack_Pre_Runeblade(id, iEnt)
{
	new iCharged = pev(iEnt, pev_iuser1);
	if(iCharged == RUNEBLADE_NOT_CHARGED)
	{
		SetThink(iEnt , "");
		set_pev(iEnt, pev_iuser1, RUNEBLADE_WAIT_FOR_CHARGE_START);
		set_pev(iEnt, pev_nextthink, get_gametime() + 1.0);
		SetThink(iEnt, "check_charge_runeblade")
		Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 3.0);
		Stock_SetWeaponAnimation(id , 9);
	}
}

// First check , if pass , then go to charge check loop
public check_charge_runeblade(iEnt)
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, 4);

	SetThink(iEnt , "");
	
	// Still holding right click?	
	if(pev(id, pev_button) & IN_ATTACK2)
	{
		// Switch to charging mode
		set_pev(iEnt, pev_iuser1, RUNEBLADE_CHARGING);
		Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 3.0);
		Stock_SetWeaponAnimation(id , 3);

		set_pev(iEnt, pev_nextthink, get_gametime() + 0.5);
		set_pev(iEnt, pev_fuser1, RUNEBLADE_CHARGE_TIME)
		// Start the charge animation loop by think
		SetThink(iEnt, "charging_runeblade")
	}
	else
	{
		set_pev(iEnt, pev_iuser1, RUNEBLADE_NOT_CHARGED);
		new iHitResult = Stock_KnifeAttackWithAngle(id, is_extend_knife_dist(), RUNEBLADE_STAB_DIST, RUNEBLADE_STAB_ANGLE, RUNEBLADE_STAB_DMG, 0.0);
		Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
		rg_set_animation(id, PLAYER_ATTACK1)
	}
}

public charging_runeblade(iEnt)
{
	static iChargeState; iChargeState = pev(iEnt, pev_iuser1);
	static id; id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	if(iChargeState == RUNEBLADE_CHARGING)
	{
		static Float:fChargeRemaining; 
		pev(iEnt, pev_fuser1,fChargeRemaining)
		fChargeRemaining -= 1.0;
		if(fChargeRemaining <= 0.0)
		{
			
			Stock_SetWeaponAnimation(id , 4);
			set_pev(iEnt, pev_iuser1, RUNEBLADE_CHARGED);
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.33);
			return;
		}
		else 
		{
			Stock_SetWeaponAnimation(id , 5);
			set_pev(iEnt,pev_fuser1, fChargeRemaining)
		}		
	} 
	else if (iChargeState == RUNEBLADE_CHARGED)
	{
		Stock_SetWeaponAnimation(id , 6);
	}
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.0);
}

public ItemPostFrame_Runeblade(id, iEnt)
{
	static iChargeState; iChargeState = pev(iEnt, pev_iuser1);
	static iButton; iButton = pev(id, pev_button);

	if(iChargeState == RUNEBLADE_WAIT_FOR_CHARGE_START)
	{
		// Released immediately after pressing Attack2
		if(!(iButton & IN_ATTACK2))
		{
			set_pev(iEnt, pev_iuser1, RUNEBLADE_NOT_CHARGED);
		}
	}
	else if(iChargeState == RUNEBLADE_CHARGING)
	{
		if(!(iButton & IN_ATTACK2))
		{
			charge_attack_incomplete_runeblade(id, iEnt);
		}
		else
		{
			// Still charging
			Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 99.0);	
		}
	}
	else if(iChargeState == RUNEBLADE_CHARGED)
	{
		if(!(iButton & IN_ATTACK2))
		{
			charge_attack_complete_runeblade(id , iEnt);
		}
		else
		{
			// Still holding Attack2
			Stock_SetWeaponNextAttacks(iEnt , 2.7 , 2.7, 2.7 + 99.0);	
		}
	}
	return HAM_IGNORED;
}

public charge_attack_incomplete_runeblade(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, RUNEBLADE_NOT_CHARGED);
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);
	Stock_SetWeaponAnimation(id , 7);


	rg_set_animation(id, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(id, is_extend_knife_dist(), RUNEBLADE_STAB_DIST,RUNEBLADE_STAB_ANGLE, RUNEBLADE_STAB_DMG, 0.0);
	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
}

public charge_attack_complete_runeblade(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, RUNEBLADE_NOT_CHARGED);
	Stock_SetWeaponNextAttacks(iEnt , 2.0 , 2.0, 2.0 + 3.0);
	Stock_SetWeaponAnimation(id , 8);

	SetThink(iEnt, "do_charge_attack_complete_runeblade")
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.56);
}

public do_charge_attack_complete_runeblade(iEnt)
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, 4);
	SetThink(iEnt , "");

	rg_set_animation(id, PLAYER_ATTACK1)
	new iHitResult = Stock_KnifeAttackWithAngle(id, is_extend_knife_dist(), RUNEBLADE_STAB_CHARGED_DIST,RUNEBLADE_STAB_ANGLE,RUNEBLADE_STAB_CHARGED_DMG, 0.0);

	Util_PlayKnifeSoundByHitResult(id, iEnt, iHitResult , false)
}


public Holster_Post_Runeblade(id, iEnt)
{
	SetThink(iEnt , "");
	set_pev(iEnt, pev_iuser1, 0);
	set_pev(iEnt, pev_fuser1, 0.0);
	
}
