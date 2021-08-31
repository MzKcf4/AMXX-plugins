#include <amxmodx>
#include <amxmisc>
#include <json>

// Load order : 
// 1. api
// 2. loader
// 3.1 core-precacher
// 3.2 core

// Picker (picks & remove json) -> Loader ( main )
// This json object is shared across all plugins.
new JSON:loadedWpnJsonObj;

#define PLUGIN "Wpn Loader Api"
#define VERSION "1.0"
#define AUTHOR "MzKc"

public plugin_natives()
{
	register_library("customwpn_loader_api");
	register_native("api_load_all_wpn", "api_load_all_wpn");
	register_native("api_get_loaded_wpn", "api_get_loaded_wpn");
	register_native("check_count", "check_count");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public api_load_all_wpn(iPlugin , iParams)
{
	// get path from amxx config dir
	new path[64]
	get_configsdir(path, charsmax(path)) // now config dir in path stored
	
	// store file dir in path
	format(path, charsmax(path), "%s/customwpn_list.json", path) // store complete path to file
	loadedWpnJsonObj = json_parse(path, true);
}

public JSON:api_get_loaded_wpn(iPlugin , iParams)
{
	return loadedWpnJsonObj;
}

public api_update_loaded_wpn(iPlugin , iParams)
{
	new JSON:jUpdatedWpnObj = get_param_byref(1);
	loadedWpnJsonObj = json_deep_copy(jUpdatedWpnObj);
	json_free(jUpdatedWpnObj);
}

public check_count(iPlugin , iParams)
{
	new iEntryCount = json_array_get_count(loadedWpnJsonObj);
	console_print(0 , "[API] Entries : %i" , iEntryCount);
}

public plugin_end()
{
	json_free(loadedWpnJsonObj);
}