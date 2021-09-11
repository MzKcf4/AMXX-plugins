#if defined _customwpn_const_included
  #endinput
#endif
#define _customwpn_const_included

#pragma library wpn_const

#define GLOBAL_MAX_WPN 64


#define PISTOL_TYPE ((1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))
#define SHOTGUN_TYPE ((1<<CSW_M3) | (1<<CSW_XM1014))
#define SMG_TYPE ((1<<CSW_TMP) | (1<<CSW_MP5NAVY) | (1<<CSW_MAC10) | (1<<CSW_UMP45) | (1<<CSW_P90))
#define RIFLE_TYPE ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG552)) 
#define SNIPER_TYPE ((1<<CSW_SG550)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_SCOUT))
#define MG_TYPE (1<<CSW_M249)

// For Zombie mode
#define AUTO_SNIPER_TYPE ((1<<CSW_SG550)|(1<<CSW_G3SG1))
#define BOLT_SNIPER_TYPE ((1<<CSW_AWP)|(1<<CSW_SCOUT))
#define GENERAL_TYPE ((1<<CSW_TMP) | (1<<CSW_MP5NAVY) | (1<<CSW_MAC10) | (1<<CSW_UMP45) | (1<<CSW_P90) | (1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG552) | (1<<CSW_M249))

#define GUN_TYPE ((1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_GALI)|(1<<CSW_FAMAS)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_P90)|(1<<CSW_SCOUT)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_M249)| (1<<CSW_P228) | (1<<CSW_ELITE) | (1<<CSW_FIVESEVEN) | (1<<CSW_USP) | (1<<CSW_GLOCK18) | (1<<CSW_DEAGLE))

#define CSW_MASK 1000000			// iImpulse minus this value for real CSWID