public kniferound_init() {
	g_ModFuncs[MODE_KNIFE][MODEFUNC_START]		= CreateOneForward(g_PluginId, "kniferound_start");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_END]		= CreateOneForward(g_PluginId, "kniferound_stop");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_ROUNDSTART]	= CreateOneForward(g_PluginId, "kniferound_roundstart");
	g_ModFuncs[MODE_KNIFE][MODEFUNC_ROUNDEND]	= CreateOneForward(g_PluginId, "kniferound_roundend", FP_CELL);
	g_ModFuncs[MODE_KNIFE][MODEFUNC_PLAYER_JOIN]= CreateOneForward(g_PluginId, "kniferound_player_join", FP_CELL);
}

public kniferound_start() {
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
			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "%L", LANG_PLAYER, "HUD_START_CAPKF");
			chat_print(0, "%L", LANG_PLAYER, "START_KNIFE");
			ChangeGameplay(GAMEPLAY_KNIFE);
		}
		case MATCH_TEAMKNIFE: {
			setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "%L", LANG_PLAYER, "HUD_STARTKNIFE");
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

			set_task(1.0, "WaitPick");
		}
		case MATCH_TEAMKNIFE: {
			if (win_ct) {
				setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "%L", LANG_SERVER, "HUD_KF_WIN_CT");
			} else {
				setTaskHud(0, 2.0, 1, 255, 255, 255, 3.0, "%L", LANG_SERVER, "HUD_KF_WIN_TT");
			}

			savePlayers(win_ct ? TEAM_CT : TEAM_TERRORIST);
			training_start();
			g_iMatchStatus = MATCH_MAPPICK;
			StartVoteRules();
		}
	}
	ChangeGameplay(GAMEPLAY_TRAINING);
}

public kniferound_player_join(id) {
	transferUserToSpec(id);
}