public dm_init()
{
	g_ModFuncs[MODE_DM][MODEFUNC_KILL] = CreateOneForward(g_PluginId, "dm_killed", FP_CELL, FP_CELL);	
}

public dm_start()
{	
	ChangeGameplay(GAMEPLAY_HNS);
	g_iCurrentMode = MODE_DM;
	g_iMatchStatus = MATCH_NONE;
	set_cvars_mode(MODE_DM);
	restartRound(0.5);
}

public dm_killed(victim, killer)
{
	if (killer != victim && getUserTeam(killer) == TEAM_CT) {
		rg_set_user_team(killer, TEAM_TERRORIST);
		rg_set_user_team(victim, TEAM_CT);

		if (!g_iSettings[ONEHPMODE])
			set_entvar(killer, var_health, 100.0);
		
		hns_setrole(killer);
	} else {
		if (getUserTeam(victim) == TEAM_TERRORIST) {
			new lucky = GetRandomCT();
			if (lucky) {
				rg_set_user_team(lucky, TEAM_TERRORIST);
				chat_print(0, "%L", LANG_PLAYER, "DM_TRANSF", lucky)
				rg_set_user_team(victim, TEAM_CT);
				hns_setrole(lucky);
			}
		}
	}

	set_task(g_iSettings[DMRESPAWN], "RespawnPlayer", victim);
}

public RespawnPlayer(id)
{
	if (!is_user_connected(id))
		return;

	if (getUserTeam(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

GetRandomCT() {
	static iPlayers[32], iCTNum
	get_players(iPlayers, iCTNum, "ahe", "CT");

	if (!iCTNum)
		return 0

	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
}