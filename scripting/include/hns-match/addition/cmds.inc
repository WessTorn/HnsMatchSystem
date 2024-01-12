#if defined _cmds_included
  #endinput
#endif

#define _cmds_included

stock cmds_init() {
	register_clcmd("say", "sayHandle");

	register_clcmd("nightvision", "mainMatchMenu");

	register_clcmd("chooseteam", 	"blockCmd");
	register_clcmd("jointeam", 		"blockCmd");
	register_clcmd("joinclass", 	"blockCmd");

	RegisterSayCmd("mix", 		"mix", 		"mainMatchMenu", 	access, "Main menu admin");

	RegisterSayCmd("pub", 		"public", 		"cmdPubMode", 		access, "Public mode");
	RegisterSayCmd("dm", 		"deathmatch", 	"cmdDMMode", 		access, "DeathMatch mode");
	RegisterSayCmd("zm", 		"zombie", 		"cmdZMMode", 		access, "DeathMatch mode");
	RegisterSayCmd("bld", 		"blend", 		"cmdBlend", 		access, "Blend teams");
	RegisterSayCmd("specall", 	"specall", 		"cmdTransferSpec", 	access, "Spec Transfer");
	RegisterSayCmd("ttall", 	"ttall", 		"cmdTransferTT", 	access, "TT Transfer");
	RegisterSayCmd("ctall", 	"ctall", 		"cmdTransferCT", 	access, "CT Transfer");
	RegisterSayCmd("startmix", 	"start", 		"cmdStartMatch", 	access, "Starts Round");
	RegisterSayCmd("kniferound", "kf", 			"cmdKnifeRound", 	access, "Knife Round");
	RegisterSayCmd("captain", 	"cap", 			"cmdCaptain", 		access, "Captain Mode");
	RegisterSayCmd("stop", 		"cancel", 		"cmdStopMode", 		access, "Stop Current Mode");
	RegisterSayCmd("skill", 	"skill", 		"cmdSkillMode", 	access, "Skill mode");
	RegisterSayCmd("boost", 	"boost", 		"cmdBoostMode", 	access, "Boost mode");
	RegisterSayCmd("rr", 		"restart", 		"cmdRestartRound", 	access, "Restart round");
	RegisterSayCmd("swap", 		"swap", 		"cmdSwapTeams", 	access, "Swap Teams");
	RegisterSayCmd("pause", 	"ps", 			"cmdStartPause", 	access, "Start pause");
	RegisterSayCmd("live", 		"unpause", 		"cmdStopPause",		access, "Unpause");
	RegisterSayCmd("surrender", "sur", 			"cmdSurrender", 	0, "Surrender vote");
	RegisterSayCmd("score", 	"s", 			"cmdShowTimers", 	0, "Score");
	RegisterSayCmd("pick", 		"pick", 		"pickMenu", 		0, "Pick player");
	RegisterSayCmd("np", 		"noplay", 		"cmdNoplay", 		0, "No play");
	RegisterSayCmd("ip", 		"play", 		"cmdPlay", 			0, "Play");
	//RegisterSayCmd("top", 		"tops", 		"ShowTop", 			0, "Show top");
	RegisterSayCmd("tes", 		"tes", 		"TEstCmd", 			0, "Show top");
}

public TEstCmd(id) {
	chat_print(id, "(%d)", g_iMatchStatus);
}

public sayHandle(id) {
	new szArgs[64];

	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if (!szArgs[0])
		return PLUGIN_HANDLED;

	if (szArgs[0] != '/')
		return PLUGIN_CONTINUE;

	new szTarget[32];

	parse(szArgs, \
		  szArgs, charsmax(szArgs), \
		  szTarget, charsmax(szTarget));

	if (equali(szArgs, "/roundtime", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_round_time(szTarget);
			chat_print(0, "%L", LANG_PLAYER, "SET_ROUNDTIME", id, str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/mr", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;
			
		if (!is_str_num(szTarget))
			return PLUGIN_HANDLED;

		if (str_to_num(szTarget) > 0) {
			g_iSettings[MAXROUNDS] = str_to_num(szTarget);
			chat_print(0, "%L", LANG_PLAYER, "SET_MAXROUNDS", id, str_to_num(szTarget), str_to_num(szTarget) * 2);
		}
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public blockCmd(id) {
	if (g_iCurrentMode != MODE_TRAINING)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public cmdPubMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_PUB) {
		chat_print(id, "%L", id, "PUB_ALREADY");
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_TRAINING) {
		chat_print(id, "%L", id, "PUB_CANC");
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "PUB_ACTIVATED", id);

	pub_start();

	return PLUGIN_HANDLED;
}

public cmdDMMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_DM) {
		chat_print(id, "%L", id, "DM_ALREADY");
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_TRAINING) {
		chat_print(id, "%L", id, "DM_CANC");
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "DM_ACTIVATED", id);

	dm_start();

	return PLUGIN_HANDLED;
}

public cmdZMMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_ZM) {
		chat_print(id, "Zombie mode is already running.");
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_TRAINING) {
		chat_print(id, "Please disable other mode before zombie.");
		return PLUGIN_HANDLED;
	}

	chat_print(0, "^3%n^1 has activated ^3zombie^1 mode.", id);

	zm_start();

	return PLUGIN_HANDLED;
}

public cmdBlend(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_PUB && g_iCurrentMode != MODE_DM) 
		return PLUGIN_HANDLED; 

	chat_print(0, "%L", LANG_PLAYER, "BLEND_TEAMS", id);

	new Players[MAX_PLAYERS], Num;
	get_players(Players, Num, "ch");

	for (new i; i < Num; i++) {
		if (!getUserTeam(Players[i])) {
			Players[i--] = Players[--Num];
		}
	}

	new Player, Team = random(2) ? 1 : 2;
	new Random;

	while (Num) {
		Random = random(Num);
		Player = Players[Random];
		rg_set_user_team(Player, TeamName:Team);
		Players[Random] = Players[--Num];
		Team = (Team % 2 + 1);
	}

	restartRound();
	return PLUGIN_HANDLED;
}

public cmdTransferSpec(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}
	
	if (g_iCurrentMode == MODE_MIX) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "TRANSF_SPEC", id);

	transferUsers(TEAM_SPECTATOR);
	
	return PLUGIN_HANDLED;
}

public cmdTransferTT(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_MIX) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "TRANSF_TT", id);

	transferUsers(TEAM_TERRORIST);

	return PLUGIN_HANDLED;
}

public cmdTransferCT(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_MIX) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "TRANSF_CT", id);

	transferUsers(TEAM_CT);

	return PLUGIN_HANDLED;
}

public cmdStartMatch(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_TRAINING) {
		chat_print(id, "%L", id, "NOT_START_MIX");
		return PLUGIN_HANDLED;
	} 
	
	if (equali(g_szMapName, g_iSettings[KNIFEMAP])) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "START_MIX", id);

	mix_start();

	return PLUGIN_HANDLED;
}

public cmdKnifeRound(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_TRAINING) {
		chat_print(id, "%L", id, "NOT_START_KNIFE");
		return PLUGIN_HANDLED;
	}

	if (g_iMatchStatus == MATCH_CAPTAINKNIFE || g_iMatchStatus == MATCH_TEAMKNIFE) {
		chat_print(id, "Ножевой раунд уже запущен.");
		return PLUGIN_HANDLED;
	}

	g_iMatchStatus = MATCH_TEAMKNIFE;
	kniferound_start();

	return PLUGIN_HANDLED;
}

public cmdCaptain(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (!equali(g_szMapName, g_iSettings[KNIFEMAP])) {
		chat_print(id, "Доступно только на ножевой карте.");
		return PLUGIN_HANDLED;
	}

	// if (g_iCurrentMode != MODE_TRAINING) {
	// 	chat_print(id, "Отключите другой режим.");
	// }

	captain_start(id);

	return PLUGIN_HANDLED;
}

public cmdStopMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_MIX) {
		verifMenu(id);
	} else {
		cmdStop(id);
	}

	return PLUGIN_HANDLED;
}

public cmdStop(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode == MODE_TRAINING && g_iMatchStatus == MATCH_NONE) {
		return PLUGIN_HANDLED;
	}


	switch (g_iCurrentMode) {
		case MODE_MIX: {
			mix_stop();
			chat_print(0, "%L", LANG_PLAYER, "STOP_MIX", id);
		}
		case MODE_KNIFE: {
			if (g_iMatchStatus == MATCH_CAPTAINKNIFE) {
				resetCaptainData();
				chat_print(0, "%L", LANG_PLAYER, "STOP_CAP", id);
			} else {
				chat_print(0, "%L", LANG_PLAYER, "STOP_KNIFE", id);
			}
			kniferound_stop();
		}
		case MODE_TRAINING: {
			if (g_iMatchStatus == MATCH_CAPTAINPICK || g_iMatchStatus == MATCH_TEAMPICK) {
				resetCaptainData();
				g_iMatchStatus = MATCH_NONE;
				training_start();
				chat_print(0, "%L", LANG_PLAYER, "STOP_CAP", id);
			} else if (g_iMatchStatus) {
				g_iMatchStatus = MATCH_NONE;
			}
		}
		case MODE_PUB: {
			training_start();
			chat_print(0, "%L", LANG_PLAYER, "STOP_PUB", id);
		}
		case MODE_DM: {
			training_start();
			chat_print(0, "%L", LANG_PLAYER, "STOP_DM", id);
		}
		case MODE_ZM: {
			training_start();
			chat_print(0, "Player %n stopped zombie mode", id);
		}
	}

	rg_send_audio(0, "fvox/fuzz.wav");

	return PLUGIN_HANDLED;
}

public cmdSkillMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "TYPE_SKILL", id);

	if (g_iCurrentMode == MODE_MIX) {
		set_cvar_num("mp_freezetime", 5);
		g_iSettings[FLASH] = 1;
		g_iSettings[SMOKE] = 1;
	}

	g_iSettings[HNSBOOST] = 0;

	if (g_iCurrentMode == MODE_TRAINING)
		set_semiclip(SEMICLIP_ON);
	else
		set_semiclip(SEMICLIP_ON, true);

	return PLUGIN_HANDLED;
}

public cmdBoostMode(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "TYPE_BOOST", id);

	if (g_iCurrentMode == MODE_MIX) {
		set_cvar_num("mp_freezetime", 15);
		g_iSettings[FLASH] = 3;
		g_iSettings[SMOKE] = 1;
	}

	g_iSettings[HNSBOOST] = 1;

	set_semiclip(SEMICLIP_OFF);

	return PLUGIN_HANDLED;
}

public cmdRestartRound(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "GAME_RESTART", id);

	if (g_iCurrentMode == MODE_MIX) {
		mix_restartround()
	} else {
		restartRound();	
	}

	return PLUGIN_HANDLED;
}

public cmdSwapTeams(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	chat_print(0, "%L", LANG_PLAYER, "GAME_SWAP", id);

	if (g_iCurrentMode == MODE_MIX) {
		mix_reverttimer();
		mix_swap();
	} else {
		rg_swap_all_players();
	}

	restartRound(0.5);

	return PLUGIN_HANDLED;
}

public cmdStartPause(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iCurrentMode != MODE_MIX || g_eMatchState == STATE_PAUSED) {
		return PLUGIN_HANDLED;
	}

	mix_pause();

	chat_print(0, "%L", LANG_PLAYER, "GAME_PAUSED", id);

	return PLUGIN_HANDLED;
}

public cmdStopPause(id) {
	if (!getUserInAccess(id)) {
		return PLUGIN_HANDLED;
	}
	
	if (g_iCurrentMode != MODE_MIX || g_eMatchState != STATE_PAUSED) {
		return PLUGIN_HANDLED;
	}

	mix_unpause();

	chat_print(0, "%L", LANG_PLAYER, "GAME_UNPAUSED", id);

	return PLUGIN_HANDLED;
}

public cmdSurrender(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != MODE_MIX)
		return PLUGIN_HANDLED;

	if (!getUserInMatch(id))
		return PLUGIN_HANDLED;

	if (g_eSurrenderData[e_sStarted])
		return PLUGIN_HANDLED;

	if (g_eSurrenderData[e_sFlDelay] > get_gametime()) {
		new szTime[24];
		fnConvertTime(g_eSurrenderData[e_sFlDelay] - get_gametime(), szTime, 23, false);
		chat_print(id, "%L", id, "SUR_WAIT", szTime);
		return PLUGIN_HANDLED;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", getUserTeam(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (iNum != g_eMatchInfo[e_mTeamSizeTT])
		return PLUGIN_HANDLED;

	g_eSurrenderData[e_sStarted] = true;
	g_eSurrenderData[e_sInitiator] = id;
	g_eSurrenderData[e_sFlDelay] = get_gametime() + g_iSettings[SURTIMEDELAY];
	chat_print(0, "%L", LANG_PLAYER, "SUR_PLAYER", id, getUserTeam(id) == TEAM_TERRORIST ? "TERRORISTS" : "CTS");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		surrenderMenu(iPlayer);
	}
	set_task(1.0, "taskSurrender", .flags = "b");

	return PLUGIN_HANDLED;
}

public cmdShowTimers(id) {
	if (g_iCurrentMode != MODE_MIX) {
		return PLUGIN_HANDLED;
	}

	new timeToWin[HNS_TEAM][24], diffTime[24];
	fnConvertTime(Float:g_eMatchInfo[e_flSidesTime][HNS_TEAM_B], timeToWin[HNS_TEAM_B], 23);
	fnConvertTime(Float:g_eMatchInfo[e_flSidesTime][HNS_TEAM_A], timeToWin[HNS_TEAM_A], 23);

	new Float:TimeDiff = floatabs(g_eMatchInfo[e_flSidesTime][g_isTeamTT] - g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT]);
	fnConvertTime(TimeDiff, diffTime, 23, false);


	new iPlayers[MAX_PLAYERS], TTsize, CTSize;
	get_players(iPlayers, TTsize, "ce", "TERRORIST");
	get_players(iPlayers, CTSize, "ce", "CT");
	if (g_isTeamTT == HNS_TEAM_A) {
		chat_print(id, "%L", id, "SCORE_TIME",
			timeToWin[HNS_TEAM_A], TTsize, CTSize, timeToWin[HNS_TEAM_B],
			(g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_A] + g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_B]) + 1, g_iSettings[MAXROUNDS] * 2,
			diffTime);
	} else {
		chat_print(id, "%L", id, "SCORE_TIME",
			timeToWin[HNS_TEAM_B], TTsize, CTSize, timeToWin[HNS_TEAM_A],
			(g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_B] + g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_A]) + 1, g_iSettings[MAXROUNDS] * 2,
			diffTime);
	}

	return PLUGIN_HANDLED;
}

public cmdNoplay(id) {
	if (!g_bNoplay[id]) {
		g_bNoplay[id] = true;
		chat_print(0, "%L", LANG_PLAYER, "STATUS_NOPLAY", id);
	}
}

public cmdPlay(id) {
	if (g_bNoplay[id]) {
		g_bNoplay[id] = false;
		chat_print(0, "%L", LANG_PLAYER, "STATUS_PLAY", id);
	}
}

stock RegisterSayCmd(const szCmd[], const szShort[], const szFunc[], flags = -1, szInfo[] = "") {
	new szTemp[65], szInfoLang[65];
	format(szInfoLang, 64, "%L", LANG_SERVER, szInfo);

	format(szTemp, 64, "say /%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say /%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	return 1;
}