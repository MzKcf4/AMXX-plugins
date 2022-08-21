#include <amxmodx>

#define PLUGIN  "HudMessage Queue"
#define VERSION "1.0"
#define AUTHOR  "MzKc"

#define MAX_MSG_QUEUE 8

new const szLinebreak[3] = "^n";
new iRegisteredMsgLeft = 0;
new iRegisteredMsgBottom = 0;
new szPlayerMsgLeft[MAX_MSG_QUEUE][33][128];
new szPlayerMsgBottom[MAX_MSG_QUEUE][33][128];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	set_task(1.0, "show_message_left", _,_,_,"b");
	set_task(1.0, "show_message_bottom", _,_,_,"b");
}

public show_message_left()
{
	set_hudmessage(200, 100, 0, 0.01, 0.32, 0, 0.0, 1.0, 0.1, 0.2, 0)
	
	static i , id, szOutput[512];
	
	for(id = 1 ; id < 33 ; id++)
	{
		if(!is_user_connected(id) || is_user_bot(id))
			continue;

		szOutput = "";
		for(i = 0 ; i < iRegisteredMsgLeft ; i++)
		{
			if(strlen(szPlayerMsgLeft[i][id]) == 0)
				continue;

			// console_print(0 , "length : %i" , strlen(szPlayerMsgLeft[i][id]) );
			strcat(szOutput, szPlayerMsgLeft[i][id], charsmax(szOutput));
			strcat(szOutput, szLinebreak, charsmax(szOutput));
			
			// console_print(0 , "showing %s" , szOutput);
			show_hudmessage(id, szOutput)
		}		
	}
}

public show_message_bottom()
{
	set_hudmessage(0, 200, 0, -1.0, 0.8, 0, 0.0, 1.0, 0.1, 0.2, 1)
	
	static i , id, szOutput[512];
	
	for(id = 1 ; id < 33 ; id++)
	{
		if(!is_user_connected(id) || is_user_bot(id))
			continue;

		szOutput = "";
		for(i = 0 ; i < iRegisteredMsgBottom ; i++)
		{
			if(strlen(szPlayerMsgBottom[i][id]) == 0)
				continue;

			// console_print(0 , "length : %i" , strlen(szPlayerMsgLeft[i][id]) );
			strcat(szOutput, szPlayerMsgBottom[i][id], charsmax(szOutput));
			strcat(szOutput, szLinebreak, charsmax(szOutput));
			
			// console_print(0 , "showing %s" , szOutput);
			show_hudmessage(id, szOutput)
		}		
	}
}



public plugin_natives()
{
	register_library("hudmessage_queue")
	register_native("hudmessage_queue_register_left", "native_register_left")
	register_native("hudmessage_queue_set_player_message_left", "native_set_player_message_left")
	register_native("hudmessage_queue_clear_player_message_left", "native_clear_player_message_left")
	
	register_native("hudmessage_queue_register_bottom", "native_register_bottom")
	register_native("hudmessage_queue_set_player_message_bottom", "native_set_player_message_bottom")
	register_native("hudmessage_queue_clear_player_message_bottom", "native_clear_player_message_bottom")
}

public native_register_left(plugin_id, num_params)
{
	return iRegisteredMsgLeft++;
}

public native_set_player_message_left(plugin_id, num_params)
{
	new idxLeft = get_param(1);
	new iPlayerId = get_param(2)
	static szMsg[128];
	get_string(3, szMsg, charsmax(szMsg))

	// Global msg
	if(iPlayerId == 0)
	{
		for(new i = 1 ; i < 33 ; i++)
		{
			if(is_user_bot(i))
				continue;
			szPlayerMsgLeft[idxLeft][i] = szMsg;
		}
	}
	else
	{
		szPlayerMsgLeft[idxLeft][iPlayerId] = szMsg;
	}
}

public native_clear_player_message_left(plugin_id, num_params)
{
	new idxLeft = get_param(1);
	new iPlayerId = get_param(2)

	// Global msg
	if(iPlayerId == 0)
	{
		for(new i = 1 ; i < 33 ; i++)
		{
			if(is_user_bot(i))
				continue;
			szPlayerMsgLeft[idxLeft][i] = "";
		}
	}
	else
	{
		szPlayerMsgLeft[idxLeft][iPlayerId] = "";
	}
}

// ------------- Bottom

public native_register_bottom(plugin_id, num_params)
{
	return iRegisteredMsgBottom++;
}

public native_set_player_message_bottom(plugin_id, num_params)
{
	new idx = get_param(1);
	new iPlayerId = get_param(2)
	static szMsg[128];
	get_string(3, szMsg, charsmax(szMsg))

	// Global msg
	if(iPlayerId == 0)
	{
		for(new i = 1 ; i < 33 ; i++)
		{
			if(is_user_bot(i))
				continue;
			szPlayerMsgBottom[idx][i] = szMsg;
		}
	}
	else
	{
		szPlayerMsgBottom[idx][iPlayerId] = szMsg;
	}
}

public native_clear_player_message_bottom(plugin_id, num_params)
{
	new idx = get_param(1);
	new iPlayerId = get_param(2)

	// Global msg
	if(iPlayerId == 0)
	{
		for(new i = 1 ; i < 33 ; i++)
		{
			if(is_user_bot(i))
				continue;
			szPlayerMsgLeft[idx][i] = "";
		}
	}
	else
	{
		szPlayerMsgLeft[idx][iPlayerId] = "";
	}
}