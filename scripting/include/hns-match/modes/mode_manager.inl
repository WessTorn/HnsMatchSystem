public mode_init()
{
	//set_task(30.0, "Task_CheckTime", 120, .flags = "b");

	set_task(0.5, "delayed_mode");
}

public delayed_mode() {
	PDS_GetCell("match_mode", g_iCurrentMode);
	PDS_GetCell("match_gameplay", g_iCurrentGameplay);
	PDS_GetCell("match_status", g_iMatchStatus);

	if (equali(g_iSettings[KNIFEMAP], g_szMapName)) {
		g_iMatchStatus = MATCH_NONE;
		training_start();
	} else if (g_iMatchStatus == MATCH_MAPPICK || g_iMatchStatus == MATCH_WAITCONNECT) {
		g_iMatchStatus = MATCH_WAITCONNECT;
		training_start();
	} else if (g_iCurrentGameplay == GAMEPLAY_HNS && g_iCurrentMode == MODE_PUB) {
		pub_start();
	} else if (g_iCurrentGameplay == GAMEPLAY_HNS && g_iCurrentMode == MODE_DM) {
		dm_start();
	} else  {
		g_iMatchStatus = MATCH_NONE;
		training_start();
	}
}

public Task_CheckTime()
{
	if(g_iCurrentMode == MODE_MIX)
	{
		return PLUGIN_HANDLED;
	}

	if((g_iCurrentMode == MODE_PUB || g_iCurrentMode == MODE_DM) && g_iCurrentGameplay == GAMEPLAY_HNS)
	{
		return PLUGIN_HANDLED;
	}

	new iPlayers[MAX_PLAYERS], iNum
	get_players(iPlayers, iNum, "ch");

	if (iNum == 0) 
	{
		if (equali(g_szMapName, g_iSettings[KNIFEMAP]))
		{
			server_cmd("changelevel rayish_brick-world");
		}
		ChangeGameplay(GAMEPLAY_HNS);
		//ChangeMatchstatus(MATCH_NONE);
		g_iCurrentMode = MODE_DM;
		//dm_cfg();
		restartRound(0.5);
	}
	
	return PLUGIN_CONTINUE;
}