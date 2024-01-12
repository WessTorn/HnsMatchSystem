public kniferound_init()
{
	g_ModFuncs[MODE_KNIFE][MODEFUNC_START]			= CreateOneForward(g_PluginId, "kniferound_start");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_END]              = CreateOneForward(g_PluginId, "kniferound_stop");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_ROUNDSTART]	   = CreateOneForward(g_PluginId, "kniferound_roundstart");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_ROUNDEND]		 = CreateOneForward(g_PluginId, "kniferound_roundend", FP_CELL);
	g_ModFuncs[MODE_KNIFE][MODEFUNC_PLAYER_JOIN]      = CreateOneForward(g_PluginId, "kniferound_player_join", FP_CELL);
}

public kniferound_start()
{
	g_iCurrentMode = MODE_KNIFE;
	ChangeGameplay(GAMEPLAY_KNIFE);
	set_cvars_mode(MODE_KNIFE);
	restartRound(1.0);
}

public kniferound_stop() {
	g_iMatchStatus = MATCH_NONE;
	training_start();
}
 
public kniferound_roundstart() {
	switch (g_iMatchStatus) {
		case MATCH_CAPTAINKNIFE: {
			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "Captain knife round started.");
			chat_print(0, "%L", LANG_PLAYER, "START_KNIFE");
			ChangeGameplay(GAMEPLAY_KNIFE);
		}
		case MATCH_TEAMKNIFE: {
			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "Team knife round started.");
			chat_print(0, "%L", LANG_PLAYER, "START_KNIFE");
			ChangeGameplay(GAMEPLAY_KNIFE);
		}
		default: {
			ChangeGameplay(GAMEPLAY_TRAINING);
		}
	}
}

public kniferound_roundend(bool:win_ct) {
	switch(g_iMatchStatus) {
		case MATCH_CAPTAINKNIFE: {
			g_iCaptainPick = win_ct ? g_eCaptain[e_cCT] : g_eCaptain[e_cTT];

			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, fmt("%L", LANG_SERVER, "HUD_CAPWIN", g_iCaptainPick));

			training_start();

			g_iMatchStatus = MATCH_TEAMPICK;

			pickMenu(g_iCaptainPick);
		}
		case MATCH_TEAMKNIFE: {
			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "Team %s Win", win_ct ? "CTS" : "Terrorists");

			savePlayers(win_ct ? TEAM_CT : TEAM_TERRORIST);
			training_start();
			g_iMatchStatus = MATCH_MAPPICK;
			//client_print_color(0, print_team_blue, "%L", 0, "KNIFE_WIN", hns_tag, win_ct ? "CT" : "TT", win_ct ? "CT" : "TT");
		}
	}
	ChangeGameplay(GAMEPLAY_TRAINING);
}

public kniferound_player_join(id) {
	transferUserToSpec(id);
}