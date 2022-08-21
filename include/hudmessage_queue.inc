/* Sublime AMXX Editor v2.2 */

#if defined _hudmessage_queue_included
	#endinput
#endif
#define _hudmessage_queue_included

/* Load custom module ?

#pragma reqlib LIBRARY_NAME
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib LIBRARY_NAME
#endif

*/



// Add your code here...
native hudmessage_queue_register_left()

native hudmessage_queue_set_player_message_left(idx, iPlayerId, const szMsg[])

native hudmessage_queue_clear_player_message_left(idx , iPlayerId);

native hudmessage_queue_register_bottom()

native hudmessage_queue_set_player_message_bottom(idx, iPlayerId, const szMsg[])

native hudmessage_queue_clear_player_message_bottom(idx , iPlayerId);
