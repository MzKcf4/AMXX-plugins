#include <amxmodx>
#include <amxmisc>
#include <customwpn_mode_api>

#define PLUGIN "Wpn Mode Setter - Zombie Stage"
#define VERSION "1.0"
#define AUTHOR "shanaO12"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	wpn_mode_set(WPN_MODE_ZOMBIE);
}