#define TASK_HEALTH 60789

Ham_TakeDamage_Post_Health_Regen(pevVictim /*, pevInflictor, pevAttacker, Float:flDamage, BitDamageType */)
{
	if(task_exists(pevVictim))
		return HAM_IGNORED;

	if(!is_user_alive(pevVictim) || is_user_bot(pevVictim))
	{
		return HAM_IGNORED;
	}
	set_task( 1.0, "task_RegenerationHealth", pevVictim, _, _, .flags = "b" );
	return HAM_IGNORED;
}

public task_RegenerationHealth( pPlayer )
{
    if( !is_user_alive( pPlayer ) || get_user_health( pPlayer ) >= 100)
    {
        remove_task( pPlayer );
    } 
    else
    {
    	set_user_health( pPlayer, min( 100, get_user_health( pPlayer ) + 1 ) );
	}
} 