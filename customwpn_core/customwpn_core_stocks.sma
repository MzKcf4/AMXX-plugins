#define TRUE 1
#define FALSE 0



// cbase.h
#define CLASS_NONE 0
#define CLASS_MACHINE 1
#define CLASS_PLAYER 2
#define CLASS_HUMAN_PASSIVE 3
#define CLASS_HUMAN_MILITARY 4
#define CLASS_ALIEN_MILITARY 5
#define CLASS_ALIEN_PASSIVE 6
#define CLASS_ALIEN_MONSTER 7
#define CLASS_ALIEN_PREY 8
#define CLASS_ALIEN_PREDATOR 9
#define CLASS_INSECT 10
#define CLASS_PLAYER_ALLY 11
#define CLASS_PLAYER_BIOWEAPON 12
#define CLASS_ALIEN_BIOWEAPON 13
#define CLASS_VEHICLE 14
#define CLASS_BARNACLE 99

#define DONT_IGNORE_MONSTERS 0
#define HEAD_HULL 3

#define KNIFE_MIN_DIST_ZOMBIE_MOD 100.0

stock Stock_Get_Aiming(id, Float:out[3])
{
	new Float:start[3], Float:view_ofs[3]
	pev(id, pev_origin, start)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)

	pev(id, pev_v_angle, out)
	engfunc(EngFunc_MakeVectors, out)
	global_get(glb_v_forward, out)
	xs_vec_mul_scalar(out, 8120.0, out)
	xs_vec_add(start, out, out)
	new ptr = create_tr2();
	engfunc(EngFunc_TraceLine, start, out, DONT_IGNORE_MONSTERS, id, ptr)
	get_tr2(ptr, TR_vecEndPos, out)
	free_tr2(ptr)
}

// stock Stock_CreateEntity3(id, iBteWpn, model[], Float:StartOrigin[3], Float:EndOrigin[3], Float:speed, Float:gravity, movetype, Classname)
stock Stock_CreateSpriteEntity(id, model[], Float:StartOrigin[3], Float:EndOrigin[3], Float:speed, Float:gravity, movetype, Classname)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, g_iAllocString_envSprite);

	// Set info for ent
	set_pev(pEntity, pev_movetype, movetype);
	set_pev(pEntity, pev_owner, id);

	engfunc(EngFunc_SetModel, pEntity, model);

	// set_pev(pEntity, pev_classname, "BALL");
	set_pev(pEntity, pev_scale, 0.1);
	set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
	set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
	set_pev(pEntity, pev_origin, StartOrigin);
	set_pev(pEntity, pev_gravity, gravity);
	set_pev(pEntity, pev_solid, SOLID_BBOX);
	set_pev(pEntity, pev_frame, 0.0);

	static Float:Velocity[3];
	Stock_Get_Speed_Vector(StartOrigin, EndOrigin, speed, Velocity);
	set_pev(pEntity, pev_velocity, Velocity);

	new Float:vecVAngle[3]

	pev(id, pev_v_angle, vecVAngle);
	vector_to_angle(Velocity, vecVAngle)
	if(vecVAngle[0] > 90.0) vecVAngle[0] = -(360.0 - vecVAngle[0]);
	set_pev(pEntity, pev_angles, vecVAngle);

	// Set_Ent_Data(pEntity, DEF_ENTCLASS, Classname);
	// Set_Ent_Data(pEntity, DEF_ENTID, iBteWpn);

	return pEntity;
}

stock Stock_Get_Speed_Vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}

stock Stock_DoRadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:flKnockBack=0.0, bitsDamageType, bSkipAttacker, bCheckTeam, bDistanceCheck = TRUE)
{
	new pEntity = -1;
	new tr = create_tr2();
	new Float:flAdjustedDamage, Float:falloff;
	new iHitResult = RESULT_HIT_NONE;

	if (bDistanceCheck)
		falloff = flDamage / flRadius;
	else
		falloff = 0.0;

	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER);

	vecSrc[2] += 1.0;

	if (!pevAttacker)
		pevAttacker = pevInflictor;

	bCheckTeam = get_cvar_num("mp_freeforall") == 0;
	// bCheckTeam = (g_modruning == BTE_MOD_DM) ? FALSE : bCheckTeam;

	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if (pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue;
		
		if (bInWater && !pev(pEntity, pev_waterlevel))
			continue;
		
		if (!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue;
		
		if (bCheckTeam && Stock_IsPlayer(pEntity) && pEntity != pevAttacker)
			if(cs_get_user_team(pEntity) == cs_get_user_team(pevAttacker))
				continue;
		
		if (bSkipAttacker && pEntity == pevAttacker)
			continue;
		
		new Float:vecEnd[3];
		Stock_GetEntOrigin(pEntity, vecEnd);

/*
#if 0
		new Float:vecDirection[3], Float:vecForward[3];
		xs_vec_sub(vecEnd, vecSrc, vecDirection);
		xs_vec_normalize(vecDirection, vecDirection);
		xs_vec_mul_scalar(vecDirection, 8196.0, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);
#endif
*/
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, 0, tr);

		new Float:flFraction;
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0)
			engfunc(EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, HEAD_HULL, 0, tr);

		if (pev_valid(pEntity)/* && get_tr2(tr, TR_pHit) == pEntity*/)
		{
			Stock_GetEntOrigin(pEntity, vecEnd);
			xs_vec_sub(vecEnd, vecSrc, vecEnd);

			new Float:flDistance = xs_vec_len(vecEnd);
			if (flDistance < 1.0)
				flDistance = 0.0;

			flAdjustedDamage = flDistance * falloff;
			flAdjustedDamage = flDamage - flAdjustedDamage;
			/*
			if (get_tr2(tr, TR_pHit) != pEntity)
				flAdjustedDamage *= 0.3;
			*/
			console_print(0 , "%f" , flAdjustedDamage);
			if (flAdjustedDamage <= 0)
				continue;

			xs_vec_normalize(vecEnd, vecEnd);

			/* Knockback
			new Float:vecVelocity[3], Float:vecOldVelocity[3];
			xs_vec_mul_scalar(vecEnd, flKnockBack * ((flRadius - flDistance) / flRadius), vecVelocity);
			pev(pEntity, pev_velocity, vecOldVelocity);
			xs_vec_add(vecVelocity, vecOldVelocity, vecVelocity);

			if (IsPlayer(pEntity) && bte_get_user_zombie(pEntity) == 1)
				set_pev(pEntity, pev_velocity, vecVelocity);
			*/
			set_tr2(tr, TR_iHitgroup, HITGROUP_CHEST);

			rg_multidmg_clear();
			ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker, flAdjustedDamage, vecEnd, tr, bitsDamageType);
			rg_multidmg_apply(pevInflictor, pevAttacker);

			iHitResult = RESULT_HIT_PLAYER;
		}
	}

	free_tr2(tr);

	return iHitResult;
}


stock Stock_KnifeAttack(id, bool:bIsZombieMode, Float:flRange, Float:flDamage, Float:flKnockBack=0.0, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_BULLET, iMaxHits = 99)
{
	flRange = Stock_Get_KnifeDist(flRange , bIsZombieMode)

	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3], Float:vecTemp[3];
	new Float:vecSource[3];
	Stock_GetGunPosition(id, vecSrc);
	xs_vec_copy(vecSrc, vecSource);
	// Get the view angle of player
	pev(id, pev_v_angle, v_angle);

	// Turn the angle into vector
	angle_vector(v_angle , ANGLEVECTOR_FORWARD , vecForward)
	// Extend the forward vector by input range
	xs_vec_mul_scalar(vecForward, flRange, vecTemp);
	// Add the range vector to view vector , to get the end position of attack
	xs_vec_add(vecSrc, vecTemp, vecEnd);
	// Create a traceLine between start(vecSrc) and end(vecEnd)
	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, FALSE, id, tr);
	// -- Check obstacles between start and end --
	new Float:flFraction;
	get_tr2(tr, TR_flFraction, flFraction);
	// flFraction means how much fraction of player can see this point?
	if (flFraction >= 1.0)
	{
		// fully visible , nothing is inbetween (usually implies hit nothing)
		engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	}
	// -------------------------------------------

	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	// new Float:flVol = 1.0;
	new bCanCross = TRUE;
	new pIgnoreEntity = id
	new Float:fCurDistance = 0.0;
	new Float:vecTempOrigin[3];
	new Float:flCurDamage = flDamage;
	new iHit = 0;
	
	while (bCanCross != FALSE)
	{
		flCurDamage = flDamage;
		// Completely visible
		if (flFraction >= 1.0)
		{
			engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, pIgnoreEntity, tr);
			get_tr2(tr, TR_flFraction, flFraction);
			
			if (flFraction >= 1.0)
			{
				bCanCross = FALSE;
				break;
			}
		} 
		else
		{
			
			// Not totally visible
			new pEntity = get_tr2(tr, TR_pHit);
			// If hit self
			if (pEntity == id)
			{
				pIgnoreEntity = pEntity;
				Stock_GetEntOrigin(pEntity, vecTempOrigin);
				// What's the remaining distance between self & end ?
				fCurDistance = get_distance_f(vecSource, vecTempOrigin);
				if (fCurDistance >= flRange)
				{
					bCanCross = FALSE;
					break;
				}
				// Set the traceEnd pos to start pos
				get_tr2(tr, TR_vecEndPos, vecSrc);
				// Get a vector of current pos to remaing distance's pos
				xs_vec_mul_scalar(vecForward, flRange - fCurDistance, vecTemp);
				xs_vec_add(vecSrc, vecTemp, vecEnd);
				// create another traceLine from curr to end
				engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, pIgnoreEntity, tr);

				get_tr2(tr, TR_flFraction, flFraction);

				if (flFraction >= 1.0)
				{
					engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, pIgnoreEntity, tr);
				}

				get_tr2(tr, TR_flFraction, flFraction);
				continue;
			}

			if (!iHitResult) iHitResult = RESULT_HIT_WORLD;

			if (pev_valid(pEntity) && (Stock_IsPlayer(pEntity)))
			{
				if (iHitgroup == -1)
					flCurDamage = flDamage;
					// flCurDamage = KnifeSettings(id, bStab, pEntity, tr, flDamage);

				iHitResult = RESULT_HIT_PLAYER;
			}

			if (pev_valid(pEntity))
			{
				// Turn the angle into vector
				angle_vector(v_angle , ANGLEVECTOR_FORWARD , vecForward)

				if (iHitgroup != -1)
					set_tr2(tr, TR_iHitgroup, iHitgroup);

				if (flDamage)
				{
					rg_multidmg_clear();
					ExecuteHamB(Ham_TraceAttack, pEntity, id, flCurDamage, vecForward, tr, bitsDamageType);
					rg_multidmg_apply(id , id);
				}
				iHit++;

				if(iHit >= iMaxHits)
					break;
				/*
				FakeKnockBack(pEntity, vecSrc, vecEnd, flKnockBack);
				if (!IsAlive(pEntity))
					flVol = 0.1;
				*/
			}
			else if (!is_user_connected(pEntity))
			{
				// Stop immediately if we hit invalid entities
				bCanCross = FALSE;
				break;
			}
			// ---------- Start another trace , starting from the entity hit until the end --------------- //
			pIgnoreEntity = pEntity;
			Stock_GetEntOrigin(pEntity, vecTempOrigin);
			fCurDistance = get_distance_f(vecSource, vecTempOrigin);
			if (fCurDistance >= flRange)
			{
				bCanCross = FALSE;
				break;
			}
			get_tr2(tr, TR_vecEndPos, vecSrc);
			xs_vec_mul_scalar(vecForward, flRange - fCurDistance, vecTemp);
			xs_vec_add(vecSrc, vecTemp, vecEnd);
			engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, pIgnoreEntity, tr);

			get_tr2(tr, TR_flFraction, flFraction);

			if (flFraction >= 1.0)
			{
				engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, pIgnoreEntity, tr);
			}

			get_tr2(tr, TR_flFraction, flFraction);
			continue;
			// ------------------------------------------------------------------------------------------- //
		}
	}
	// set_pdata_int(id, m_iWeaponVolume, floatround(flVol * KNIFE_WALLHIT_VOLUME));
	free_tr2(tr);
	return iHitResult;
}

stock Stock_KnifeAttackWithAngle(id, bool:bIsZombieMode, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack=0.0, iHitgroup = -1, bNoTraceCheck = FALSE, bitsDamageType = DMG_NEVERGIB | DMG_BULLET, bDamageFallByDistance = FALSE, Float:vecReturnHitEnd[3] = {0.0,0.0,0.0})
{
	flRange = Stock_Get_KnifeDist(flRange , bIsZombieMode)

	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	new iHitResult = RESULT_HIT_NONE;
	pev(id, pev_origin, vecOrigin);
	Stock_GetGunPosition(id, vecSrc);
	// Get the view angle of player
	pev(id, pev_v_angle, v_angle);
	// Turn the view angle into vector
	angle_vector(v_angle , ANGLEVECTOR_FORWARD , vecForward)
	// Extend the forward vector by input range
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	// Add the range vector to view vector , to get the end position of attack
	xs_vec_add(vecSrc, vecForward, vecEnd);
	// Create a traceLine between start(vecSrc) and end(vecEnd)
	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, id, tr);
	// -- Check obstacles between start and end --
	new Float:flFraction;
	get_tr2(tr, TR_flFraction, flFraction);
	// No entities detected between start and end
	if (flFraction < 1.0)
	{
		iHitResult = RESULT_HIT_WORLD;
		get_tr2(tr, TR_vecEndPos, vecReturnHitEnd);
	}

	new Float:vecEndZ = vecEnd[2];

	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;

		if (id == pEntity)
			continue;

		//if (!IsAlive(pEntity))
		//	continue;

		if (!CheckAngle(id, pEntity, fAngle))
			continue;

		static Float:fCurDamage;
		fCurDamage = flDamage;

		Stock_GetGunPosition(id, vecSrc);
		Stock_GetEntOrigin(pEntity, vecEnd);
		
		new Float:falloff = (get_distance_f(vecSrc, vecEnd) / flRange);

		vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * falloff;

		xs_vec_sub(vecEnd, vecSrc, vecForward);
		xs_vec_normalize(vecForward, vecForward);
		xs_vec_mul_scalar(vecForward, flRange, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, id, tr);

		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0){
			iHitResult = RESULT_HIT_WORLD;
			engfunc(EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, 3, id, tr);
		}

		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction < 1.0)
		{
			if ((Stock_IsPlayer(pEntity)))
			{
				if (!bNoTraceCheck)
				{
					new iVictim = get_tr2(tr, TR_pHit);
					if (!pev_valid(iVictim))
						continue;
					//if (!IsAlive(iVictim))
					//	continue;
					if (!CheckAngle(id, iVictim, fAngle) && fAngle != 360.0)
						continue;
					if (!pev(iVictim, pev_takedamage))
						continue;
				}
				
				iHitResult = RESULT_HIT_PLAYER;

				if (Stock_IsPlayer(pEntity))
				{
					fCurDamage = flDamage;
				}
			}

			if (pev_valid(pEntity))
			{
				if (!bNoTraceCheck)
				{
					new iVictim = get_tr2(tr, TR_pHit);
					if (!pev_valid(iVictim))
						continue;
					if (!CheckAngle(id, iVictim, fAngle) && fAngle != 360.0)
						continue;
					if (!pev(iVictim, pev_takedamage))
						continue;
				}
				angle_vector(v_angle , ANGLEVECTOR_FORWARD , vecForward)

				if (iHitgroup != -1)
					set_tr2(tr, TR_iHitgroup, iHitgroup);

				if (bDamageFallByDistance)
					fCurDamage *= (1.0-falloff);

				rg_multidmg_clear();
				ExecuteHamB(Ham_TraceAttack, pEntity, id, fCurDamage, vecForward, tr, bitsDamageType);
				rg_multidmg_apply(id , id);
			}
		}
		get_tr2(tr, TR_vecEndPos, vecReturnHitEnd);
		free_tr2(tr);

	}

	return iHitResult;
}


stock Stock_GetGunPosition(id, Float:vecSrc[3])
{
	new Float:vecViewOfs[3];
	pev(id, pev_origin, vecSrc);
	pev(id, pev_view_ofs, vecViewOfs);
	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
}

stock Stock_GetEntOrigin(pEntity, Float:vecOrigin[3])
{
	new Float:maxs[3], Float:mins[3];
	if (pev(pEntity, pev_solid) == SOLID_BSP)
	{
		pev(pEntity, pev_maxs, maxs);
		pev(pEntity, pev_mins, mins);
		vecOrigin[0] = (maxs[0] - mins[0]) / 2 + mins[0];
		vecOrigin[1] = (maxs[1] - mins[1]) / 2 + mins[1];
		vecOrigin[2] = (maxs[2] - mins[2]) / 2 + mins[2];
	}
	else pev (pEntity, pev_origin, vecOrigin);
}

stock Stock_IsPlayer(pEntity)
{
	if (pEntity <= 0)
		return FALSE;

	return ExecuteHam(Ham_Classify, pEntity) == CLASS_PLAYER;
}

stock Stock_SetWeaponNextAttacks(iEnt, Float:flNextPrimaryAttack = -1.0, Float:flNextSecondaryAttack = -1.0, Float:flTimeWeaponIdle = -1.0)
{
	if(flNextPrimaryAttack > 0.0)
		set_pdata_float(iEnt, m_flNextPrimaryAttack, flNextPrimaryAttack);

	if(flNextSecondaryAttack > 0.0)
		set_pdata_float(iEnt, m_flNextSecondaryAttack, flNextSecondaryAttack);

	if(flTimeWeaponIdle > 0.0)
		set_pdata_float(iEnt, m_flTimeWeaponIdle, flTimeWeaponIdle);
}

stock Stock_SetWeaponAnimation(iPlyId , iAniSeq)
{
	if (!is_user_alive(iPlyId) || iAniSeq < 0) return;
	if (pev(iPlyId, pev_weaponanim) == iAniSeq) return;

	set_pev(iPlyId, pev_weaponanim, iAniSeq)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlyId)
	write_byte(iAniSeq)
	write_byte(pev(iPlyId, pev_body))
	message_end()
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)
{
	return (fAngle >= 360.0 || Stock_BTE_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))
}

stock Float:Stock_BTE_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]

	Stock_GetEntOrigin(id, vId_ori)
	Stock_GetEntOrigin(iTarget, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++)
	{
		vOricross[i] = vTar_ori[i] - vId_ori[i]
	}

	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])

	if(fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	}
	else
	{
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}

	angle_vector(vId_ang , ANGLEVECTOR_FORWARD , vForward)

	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]

	return fRad   //->   RAD 90' = 0.5rad
	
}

stock Float:Stock_Get_KnifeDist(Float:fDist , bool:isZombieMode)
{
	if(!isZombieMode)
		return fDist;

	if(KNIFE_MIN_DIST_ZOMBIE_MOD > fDist)
		return KNIFE_MIN_DIST_ZOMBIE_MOD;

	return fDist;
}