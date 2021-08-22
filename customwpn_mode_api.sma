#include <amxmodx>
#include <amxmisc>
#include <customwpn_mode_api>

#define PLUGIN "Wpn Mode Api"
#define VERSION "1.0"
#define AUTHOR "MzKc"

new g_wpnMode = WPN_MODE_NORMAL;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_natives()
{	
	register_library("wpn_mode_api")
	register_native("wpn_mode_set", "native_mode_set_mode")
	register_native("wpn_mode_get", "native_mode_get_mode")
}

public native_mode_set_mode(plugin_id, num_params)
{
	g_wpnMode = get_param(1);
}

public native_mode_get_mode(plugin_id, num_params)
{
	return g_wpnMode;
}