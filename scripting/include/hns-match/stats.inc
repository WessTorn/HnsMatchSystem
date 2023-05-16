// in e_mMatch

enum _:STATS_FUNCS
{
	STATSFUNCS_STAB,
	STATSFUNCS_DAMAGE,
	STATSFUNCS_FALSHEDTIME,
	STATSFUNCS_PRETHINK,
	STATSFUNCS_KD
};

new g_StatsFuncs[STATS_FUNCS];

enum _:STATS_PLAYER
{
	Float:e_flSurviveTime,
	Float:e_flDmg,
	Float:e_flRunDistance,
	Float:e_flFlashedTime,
	e_iStabs,
	e_iKills,
	e_iDeaths,
	Float:e_flSaveDiscTime,
	Float:e_flSaveSurviveTime,
	e_iSaveKills,
	e_iSaveDeaths,
	e_iSaveGameStops,
	e_szSaveTeam[16],
	e_bSaveAlive
};

new g_eRoundStats[MAX_PLAYERS + 1][STATS_PLAYER];
new iStats[MAX_PLAYERS + 1][STATS_PLAYER];

new Float:last_position[MAX_PLAYERS+ 1][3];

new Trie:g_tSaveData;

public stats_init()
{
	g_StatsFuncs[STATSFUNCS_STAB]			= CreateOneForward(g_PluginId, "stats_stab", FP_CELL);
	g_StatsFuncs[STATSFUNCS_DAMAGE]			= CreateOneForward(g_PluginId, "stats_dmg", FP_CELL, FP_CELL);
	g_StatsFuncs[STATSFUNCS_FALSHEDTIME]	= CreateOneForward(g_PluginId, "stats_flashedtime", FP_CELL, FP_CELL);
	g_StatsFuncs[STATSFUNCS_PRETHINK]		= CreateOneForward(g_PluginId, "stats_prethink", FP_CELL);
	g_StatsFuncs[STATSFUNCS_KD]				= CreateOneForward(g_PluginId, "stats_kd", FP_CELL, FP_CELL);
}

public stats_stab(attacker) {
	g_eRoundStats[attacker][e_iStabs]++;
	iStats[attacker][e_iStabs]++;
}

public stats_dmg(id, Float:damage) {
	g_eRoundStats[id][e_flDmg] += damage;
	iStats[id][e_flDmg] += damage
}

public stats_flashedtime(attacker, Float:fadeHold) {
	g_eRoundStats[attacker][e_flFlashedTime] += fadeHold;
	iStats[attacker][e_flFlashedTime] += fadeHold;
}

public stats_prethink(id) {
	static Float:origin[3];
	static Float:velocity[3];
	static Float:last_updated[MAX_PLAYERS + 1];
	static Float:frametime;
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_velocity, velocity);

	frametime = get_gametime() - last_updated[id];
	if (frametime > 1.0)
	{
		frametime = 1.0;
	}
	if (!g_bFreezePeriod)
	{

		if (is_user_alive(id))
		{
			if (getUserTeam(id) == TEAM_TERRORIST)
			{
				if (vector_length(velocity) * frametime >= get_distance_f(origin, last_position[id]))
				{
					velocity[2] = 0.0;
					if (vector_length(velocity) > 125.0)
					{
						g_eRoundStats[id][e_flRunDistance] += vector_length(velocity) * frametime;
						iStats[id][e_flRunDistance] += vector_length(velocity) * frametime;
					}
				}

			}
		}
	}
	last_updated[id] = get_gametime();
	xs_vec_copy(origin, last_position[id]);
}

public stats_kd(victim, attacker) {
	iStats[victim][e_iDeaths]++;
	g_eRoundStats[victim][e_iDeaths]++;

	if (attacker != victim) {
		iStats[attacker][e_iKills]++;
		g_eRoundStats[attacker][e_iDeaths]++;
	}
}

stock ResetPlayerRoundStats(id) {
	if (getUserTeam(id) == TEAM_TERRORIST)
		iStats[id][e_flSurviveTime] -= g_eRoundStats[id][e_flSurviveTime];

	if (getUserTeam(id) == TEAM_TERRORIST || getUserTeam(id) == TEAM_CT) {
		iStats[id][e_iStabs] -= g_eRoundStats[id][e_iStabs];
		iStats[id][e_flDmg] -= g_eRoundStats[id][e_flDmg];
		iStats[id][e_flRunDistance] -= g_eRoundStats[id][e_flRunDistance];
		iStats[id][e_flFlashedTime] -= g_eRoundStats[id][e_flFlashedTime];
	}

	if (g_eRoundStats[id][e_iKills] || g_eRoundStats[id][e_iDeaths]) {
		iStats[id][e_iKills] -= g_eRoundStats[id][e_iKills];
		iStats[id][e_iDeaths] -= g_eRoundStats[id][e_iDeaths];
		SetScoreInfo(id);
	}
}

public setPlayerData() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "h");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		arrayset(iStats[iPlayer], 0, STATS_PLAYER);
		SetScoreInfo(iPlayer);
	}
}

public setPlayerStats(id) {
	TrieGetArray(g_tSaveData, getUserKey(id), iStats[id], STATS_PLAYER);
	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
		if (iStats[id][e_iSaveGameStops] < g_iGameStops) {
			if (iStats[id][e_flSaveSurviveTime]) {
				iStats[id][e_flSurviveTime] -= iStats[id][e_flSaveSurviveTime];
				iStats[id][e_flSaveSurviveTime] = 0.0;
			}

			if (iStats[id][e_iSaveKills] || iStats[id][e_iSaveDeaths]) {
				iStats[id][e_iKills] -= iStats[id][e_iSaveKills];
				iStats[id][e_iDeaths] -= iStats[id][e_iSaveDeaths];
				iStats[id][e_iSaveKills] = 0;
				iStats[id][e_iSaveDeaths] = 0;
				SetScoreInfo(id);
			}
		} else {
			if (iStats[id][e_iKills] || iStats[id][e_iDeaths])
				SetScoreInfo(id);
		}

		if (iStats[id][e_flSaveDiscTime] > get_gametime()) {
			new iPlayers[MAX_PLAYERS], iNum;
			get_players(iPlayers, iNum, "he", iStats[id][e_szSaveTeam]);

			if (iNum < g_eMatchInfo[e_mTeamSizeTT])
				set_task(0.3, "task_SetTeam", id + TASK_SET_TEAM);
		}
	} else
		arrayset(iStats[id], 0, STATS_PLAYER);
}

public savePlayerStats(id) {
	if (!is_entity(id))
		return;

	iStats[id][e_flSaveDiscTime] = 0.0;

	if ((getUserTeam(id) == TEAM_TERRORIST || getUserTeam(id) == TEAM_CT) && (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused)) {
		iStats[id][e_flSaveDiscTime] = g_flRetry;
		iStats[id][e_flSaveSurviveTime] = g_eRoundStats[id][e_flSurviveTime];
		iStats[id][e_bSaveAlive] = Float:get_entvar(id, var_health) >= RETRY_HP && g_iCurrentMode != e_mPaused ? true : false;
		copy(iStats[id][e_szSaveTeam], charsmax(iStats[][e_szSaveTeam]), fmt("%s", getUserTeam(id) == TEAM_TERRORIST ? "TERRORIST" : "CT"));

		if (g_eRoundStats[id][e_iKills] || g_eRoundStats[id][e_iDeaths]) {
			iStats[id][e_iSaveKills] = g_eRoundStats[id][e_iKills];
			iStats[id][e_iSaveDeaths] = g_eRoundStats[id][e_iDeaths];
		}

		iStats[id][e_iSaveGameStops] = g_iGameStops;

		console_print(0, "Player %n was disconnected..", id);
		chat_print(0, "Player %n was disconnected..", id);
	}
	TrieSetArray(g_tSaveData, getUserKey(id), iStats[id], STATS_PLAYER);
}

public task_SetTeam(id) {
	id -= TASK_SET_TEAM;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	rg_set_user_team(id, iStats[id][e_szSaveTeam][0] == 'T' ? TEAM_TERRORIST : TEAM_CT);

	if (!iStats[id][e_bSaveAlive] || g_iCurrentMode == e_mPaused) {
		console_print(0, "Player %n joined!", id);
		chat_print(0, "Player %n joined!", id);

		if (g_iCurrentMode == e_mPaused)
			rg_round_respawn(id);

		return;
	}

	new iPlayers[MAX_PLAYERS], iNum, bool:restart_round;
	get_players(iPlayers, iNum, "ahe", iStats[id][e_szSaveTeam]);

	new bid;
	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (Float:get_entvar(iPlayer, var_health) < RETRY_HP) bid++;
	}

	restart_round = iNum == g_eMatchInfo[e_mTeamSizeTT] - 1 && !bid ? true : false;

	if (restart_round)
		restartRound();

	console_print(0, "Player %n joined%s", id, restart_round ? ", restart round!" : "!");
	chat_print(0, "Player %n joined%s", id, restart_round ? ", restart round!" : "!");
}

stock SetScoreInfo(id) {
	set_entvar(id, var_frags, float(iStats[id][e_iKills]));
	set_member(id, m_iDeaths, iStats[id][e_iDeaths]);
	Msg_Update_ScoreInfo(id);
}

stock Msg_Update_ScoreInfo(id) {
	const iMsg_ScoreInfo = 85;

	message_begin(MSG_BROADCAST, iMsg_ScoreInfo);
	write_byte(id);
	write_short(0);
	write_short(0);
	write_short(0);
	write_short(0);
	message_end();
}