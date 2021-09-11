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
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_STARCHASERSR)
		return Item_PostFrame_StarchaserSR(iPlayerId , iEnt);

	return HAM_IGNORED;
}

// ================================== Knife =====================================
HamF_Knife_PostFrame_Special(iWpnId , iPlayerId , iEnt)
{	
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_CROW9){
		return ItemPostFrame_Crow9(iPlayerId , iEnt);
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_RUNEBLADE){
		return ItemPostFrame_Runeblade(iPlayerId , iEnt);
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALROG9){
		return ItemPostFrame_Balrog9(iPlayerId , iEnt);
	}
	
	return HAM_IGNORED;
}


HamF_Knife_PrimaryAttack_Pre_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_DRAGONSWORD){
		PrimaryAttack_Pre_DragonSword(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_SKULL9){
		PrimaryAttack_Pre_Skull9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_CROW9){
		PrimaryAttack_Pre_Crow9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_RUNEBLADE){
		PrimaryAttack_Pre_Runeblade(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALROG9){
		PrimaryAttack_Pre_Balrog9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}

	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALISONG){
		PrimaryAttack_Pre_Balisong(iPlayerId , iEnt);
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

HamF_Knife_SecondaryAttack_Pre_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_DRAGONSWORD){
		SecondaryAttack_Pre_DragonSword(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_SKULL9){
		SecondaryAttack_Pre_Skull9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_CROW9){
		SecondaryAttack_Pre_Crow9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_RUNEBLADE){
		SecondaryAttack_Pre_Runeblade(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALROG9){
		SecondaryAttack_Pre_Balrog9(iPlayerId , iEnt);
		return HAM_SUPERCEDE;
	}
	
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Pre_Balisong(iPlayerId , iEnt);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

HamF_Knife_SecondaryAttack_Post_Special(iWpnId , iPlayerId , iEnt)
{
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALISONG){
		SecondaryAttack_Post_Balisong(iPlayerId , iEnt);
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
	
}

HamF_Knife_Holster_Post_Special(iWpnId , iPlayerId , iEnt)
{
	
	if(g_iWpnSpecialId[iWpnId] == SPECIAL_DRAGONSWORD){
		Holster_Post_DragonSword(iPlayerId , iEnt);
	} 
	else if(g_iWpnSpecialId[iWpnId] == SPECIAL_SKULL9){
		Holster_Post_Skull9(iPlayerId , iEnt);
	}
	else if(g_iWpnSpecialId[iWpnId] == SPECIAL_CROW9){
		Holster_Post_Crow9(iPlayerId , iEnt);	
	}
	else if(g_iWpnSpecialId[iWpnId] == SPECIAL_RUNEBLADE){
		Holster_Post_Runeblade(iPlayerId , iEnt);
	}
	else if(g_iWpnSpecialId[iWpnId] == SPECIAL_BALROG9){
		Holster_Post_Balrog9(iPlayerId , iEnt);
	}
	
	return HAM_IGNORED;
}