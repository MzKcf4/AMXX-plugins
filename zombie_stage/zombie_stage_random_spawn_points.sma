#define MAX_CSDM_SPAWNS 128

#define SPAWN_DATA_ORIGIN_X 0
#define SPAWN_DATA_ORIGIN_Y 1
#define SPAWN_DATA_ORIGIN_Z 2
#define SPAWN_DATA_ANGLES_X 3
#define SPAWN_DATA_ANGLES_Y 4
#define SPAWN_DATA_ANGLES_Z 5
#define SPAWN_DATA_V_ANGLES_X 6
#define SPAWN_DATA_V_ANGLES_Y 7
#define SPAWN_DATA_V_ANGLES_Z 8

new Float:g_spawns_csdm[MAX_CSDM_SPAWNS][SPAWN_DATA_V_ANGLES_Z+1]
new g_SpawnCountCSDM

plugin_init_random_spawn_points()
{
	load_spawns();
}
stock load_spawns()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_X] = floatstr(csdmdata[0])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Y] = floatstr(csdmdata[1])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Z] = floatstr(csdmdata[2])
			
			// angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_X] = floatstr(csdmdata[3])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Y] = floatstr(csdmdata[4])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Z] = floatstr(csdmdata[5])
			
			// view angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_X] = floatstr(csdmdata[7])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Y] = floatstr(csdmdata[8])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Z] = floatstr(csdmdata[9])
			
			// increase spawn count
			g_SpawnCountCSDM++
			if (g_SpawnCountCSDM >= sizeof g_spawns_csdm) break;
		}
		if (file) fclose(file)
	}
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}

// checks if a space is vacant, by VEN
stock bool:is_hull_vacant(const Float:origin[3],hull)
{
	new tr = 0;
	engfunc(EngFunc_TraceHull,origin,origin,0,hull,0,tr);

	if(!get_tr2(tr,TR_StartSolid) && !get_tr2(tr,TR_AllSolid) && get_tr2(tr,TR_InOpen))
		return true;
	
	return false;
}
