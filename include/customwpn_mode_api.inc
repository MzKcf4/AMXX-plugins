#if defined _customwpn_mode_const_included
  #endinput
#endif
#define _customwpn_mode_const_included

#define WPN_MODE_NORMAL 0
#define WPN_MODE_ZOMBIE 1
#define WPN_MODE_GUNGAME 2
#define WPN_MODE_GUNGAME_SNIPER 3

native wpn_mode_set(modeId)

native wpn_mode_get()