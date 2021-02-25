#if defined _event_included
  #endinput
#endif

#define _event_included

stock event_init() {
    register_event("DeathMsg", "EventDeathMsg", "a");
}

public EventDeathMsg() {
	if (g_iCurrentMode != e_mDM) {
		return;
	}

	new killer = read_data(1);
	new victim = read_data(2);
	
	if(killer == 0)  {
		if(getUserTeam(victim) == TEAM_TERRORIST) {
			new lucky = GetRandomCT();
			if(lucky) {
				rg_set_user_team(lucky, TEAM_TERRORIST);
				client_print_color(lucky, print_team_blue, "%L", lucky, "DM_TRANSF", prefix)
				rg_set_user_team(victim, TEAM_CT);
				setUserRole(lucky);
			}
		}
	} else if(killer != victim && getUserTeam(killer) == TEAM_CT) {
		rg_set_user_team(killer, TEAM_TERRORIST); 
		rg_set_user_team(victim, TEAM_CT); 
		
		setUserRole(killer);
	}
	
	set_task(get_pcvar_float(g_eCvars[e_cDMRespawn]), "RespawnPlayer", victim);
}

public RespawnPlayer(id) {
	if (!is_user_connected(id))
		return;
	
	if (getUserTeam(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

GetRandomCT() {
	static iPlayers[32], iCTNum
	get_players(iPlayers, iCTNum, "ae", "CT");
		
	if(!iCTNum)
		return 0
		
	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
}
