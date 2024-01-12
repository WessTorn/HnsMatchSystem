public zm_init()
{
	g_ModFuncs[MODE_ZM][MODEFUNC_START] 		= CreateOneForward(g_PluginId, "zm_start");
	g_ModFuncs[MODE_ZM][MODEFUNC_KILL] 			= CreateOneForward(g_PluginId, "zm_killed", FP_CELL, FP_CELL);
	g_ModFuncs[MODE_ZM][MODEFUNC_ROUNDEND] 		= CreateOneForward(g_PluginId, "zm_roundend", FP_CELL);
	g_ModFuncs[MODE_ZM][MODEFUNC_PLAYER_JOIN]	= CreateOneForward(g_PluginId, "zm_player_join", FP_CELL);
}

public zm_start() {
	g_iCurrentMode = MODE_ZM;
	g_iMatchStatus = MATCH_NONE;

	ChangeGameplay(GAMEPLAY_HNS);
	set_semiclip(SEMICLIP_ON, true);
	set_cvars_mode(MODE_ZM);
	loadMapCFG();
	g_iSettings[FLASH] = 1;

	zm_set_teams();

	restartRound(0.5);
}

public zm_killed(victim, killer) {
	if (killer != victim && getUserTeam(killer) == TEAM_CT) {
		rg_set_user_team(victim, TEAM_CT);
	} else {
		if (getUserTeam(victim) == TEAM_TERRORIST) {
			rg_set_user_team(victim, TEAM_CT);
		}
	}

	set_task(g_iSettings[DMRESPAWN], "RespawnPlayer", victim);
}

public zm_roundend(bool:win_ct) {
	set_task(2.0, "zm_set_teams", 1231);
}

public zm_set_teams() {
	new iPlayers[MAX_PLAYERS], iNum
	get_players(iPlayers, iNum, "ch");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		if (getUserTeam(iPlayer) == TEAM_SPECTATOR)
			continue;

		rg_set_user_team(iPlayer, TEAM_TERRORIST);
	}

	set_task(1.0, "set_zombie", 11223);
}

public set_zombie() {
	new iZombie = GetRandomTT();
	rg_set_user_team(iZombie, TEAM_CT);
	chat_print(0, "^3%n^1 zombie!", iZombie);
	hns_setrole(iZombie);
}

GetRandomTT() {
	static iPlayers[32], iCTNum
	get_players(iPlayers, iCTNum, "che", "TERRORIST");

	if (!iCTNum)
		return 0

	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
}

public zm_player_join(id) {
	rg_set_user_team(id, TEAM_CT);
	rg_round_respawn(id);
}