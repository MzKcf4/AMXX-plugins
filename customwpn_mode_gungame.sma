#include <amxmodx>
#include <amxmisc>
#include <customwpn_mode_api>

#define PLUGIN "Wpn Mode Setter - GunGame"
#define VERSION "1.0"
#define AUTHOR "MzKc"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	wpn_mode_set(WPN_MODE_GUNGAME);
}