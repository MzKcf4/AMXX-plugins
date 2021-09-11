#include "customwpn_core/special_wpn/starchasersr.sma"
#include "customwpn_core/special_wpn/dragonsword.sma"
#include "customwpn_core/special_wpn/skull9.sma"
#include "customwpn_core/special_wpn/crow9.sma"
#include "customwpn_core/special_wpn/runeblade.sma"
#include "customwpn_core/special_wpn/balrog9.sma"
#include "customwpn_core/special_wpn/balisong.sma"

// Tracks reload animtaion & correctly set the clip after reload
HamF_Item_PostFrame_Special(iWpnId , iPlayerId , iEnt)
{
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_STARCHASERSR)
		return Item_PostFrame_StarchaserSR(id , ent);

	return HAM_IGNORED;
}

// ================================== Knife =====================================
HamF_Knife_PostFrame_Special(iWpnId , iPlayerId , iEnt)
{	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		return ItemPostFrame_Crow9(playerId , ent);
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		return ItemPostFrame_Runeblade(playerId , ent);
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		return ItemPostFrame_Balrog9(playerId , ent);
	}
	
	return HAM_IGNORED;
}


HamF_Knife_PrimaryAttack_Pre_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		PrimaryAttack_Pre_DragonSword(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		PrimaryAttack_Pre_Skull9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		PrimaryAttack_Pre_Crow9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		PrimaryAttack_Pre_Runeblade(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		PrimaryAttack_Pre_Balrog9(playerId , ent);
		return HAM_SUPERCEDE;
	}

	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		PrimaryAttack_Pre_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

HamF_Knife_SecondaryAttack_Pre_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		SecondaryAttack_Pre_DragonSword(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		SecondaryAttack_Pre_Skull9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		SecondaryAttack_Pre_Crow9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		SecondaryAttack_Pre_Runeblade(playerId , ent);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		SecondaryAttack_Pre_Balrog9(playerId , ent);
		return HAM_SUPERCEDE;
	}
	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Pre_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

HamF_Knife_SecondaryAttack_Post_Special(iWpnId , iPlayerId , iEnt)
{
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Post_Balisong(playerId , ent);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
	
}

HamF_Knife_Holster_Post_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[ownWpnId] == SPECIAL_DRAGONSWORD){
		Holster_Post_DragonSword(playerId , ent);
	} 
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_SKULL9){
		Holster_Post_Skull9(playerId , ent);
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_CROW9){
		Holster_Post_Crow9(playerId , ent);	
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_RUNEBLADE){
		Holster_Post_Runeblade(playerId , ent);
	}
	else if(g_iWpnSpecialId[ownWpnId] == SPECIAL_BALROG9){
		Holster_Post_Balrog9(playerId , ent);
	}
	
	return HAM_IGNORED;
}