#if defined _cmds_included
  #endinput
#endif

#define _cmds_included

stock cmds_init() {
	register_clcmd("nightvision", "mainMatchMenu");

	register_clcmd("chooseteam", "blockCmd");
	register_clcmd("jointeam", "blockCmd");
	register_clcmd("joinclass", "blockCmd");

	RegisterSayCmd("showknife", "knife", "cmdShowKnife");
	RegisterSayCmd("hideknife", "hknife", "cmdShowKnife");

	RegisterSayCmd("mix", "mix", "mainMatchMenu", access, "Main menu admin");
	RegisterSayCmd("mode", "type", "modeSelectMenu", access, "Mode menu");
	RegisterSayCmd("training", "training", "trainingMenu", 0, "Training menu");

	RegisterSayCmd("pub", "public", "cmdPubMode", access, "Public mode");
	RegisterSayCmd("dm", "deathmatch", "cmdDMMode", access, "DeathMatch mode");
	RegisterSayCmd("specall", "specall", "cmdTransferSpec", access, "Spec Transfer");
	RegisterSayCmd("ttall", "ttall", "cmdTransferTT", access, "TT Transfer");
	RegisterSayCmd("ctall", "ctall", "cmdTransferCT", access, "CT Transfer");
	RegisterSayCmd("startmix", "start", "cmdStartRound", access, "Starts Round");
	RegisterSayCmd("kniferound", "kf", "cmdKnifeRound", access, "Knife Round");
	RegisterSayCmd("captain", "cap", "cmdCaptain", access, "Captain Mode");
	RegisterSayCmd("stop", "cancel", "cmdStopMode", access, "Stop Current Mode");
	RegisterSayCmd("skill", "skill", "cmdSkillMode", access, "Skill mode");
	RegisterSayCmd("boost", "boost", "cmdBoostMode", access, "Boost mode");
	RegisterSayCmd("aa10", "10aa", "cmdAa10", access, "10aa");
	RegisterSayCmd("aa100", "100aa", "cmdAa100", access, "100aa");
	RegisterSayCmd("rr", "restart", "cmdRestartRound", access, "Restart round");
	RegisterSayCmd("swap", "swap", "cmdSwapTeams", access, "Swap Teams");
	RegisterSayCmd("pause", "ps", "cmdStartPause", access, "Start pause");
	RegisterSayCmd("live", "unpause", "cmdStopPause", access, "Unpause");
	RegisterSayCmd("mr", "maxround", "cmdMrMode", access, "Max Rounds mode");
	RegisterSayCmd("timer", "timer", "cmdTimerMode", access, "Timer mode");
	RegisterSayCmd("surrender", "sur", "cmdSurrender", 0, "Surrender vote");
	RegisterSayCmd("score", "s", "cmdShowTimers", 0, "Score");
	RegisterSayCmd("pick", "pick", "cmdPick", 0, "Pick player");
	RegisterSayCmd("back", "spec", "cmdTeamSpec", 0, "Spec/Back player");
	RegisterSayCmd("np", "noplay", "cmdNoplay", 0, "No play");
	RegisterSayCmd("ip", "play", "cmdPlay", 0, "Play");
	RegisterSayCmd("checkpoint", "cp", "cmdCheckpoint", 0, "Сheckpoint");
	RegisterSayCmd("teleport", "tp", "cmdGoCheck", 0, "Teleport to checkpoint");
	RegisterSayCmd("gocheck", "gc", "cmdGoCheck", 0, "Сheckpoint");
	RegisterSayCmd("damage", "showdamade", "cmdShowDamage", 0, "Show damage");
	RegisterSayCmd("noclip", "clip", "cmdClipMode", 0, "No clip mode");
	RegisterSayCmd("respawn", "resp", "cmdRespawn", 0, "Respawn player");
	RegisterSayCmd("top", "tops", "ShowTop", 0, "Show top");
}

public blockCmd(id) {
	if (g_iCurrentMode != e_mTraining)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public cmdShowKnife(id) {
	g_bOnOff[id] = !g_bOnOff[id];

	chat_print(id, "%L", id, "SHOW_KNIFE", g_bOnOff[id] ? "^3in" : "^3");

	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (get_user_weapon(id) == CSW_KNIFE) {
		if (g_bOnOff[id]){
			set_pev(id, pev_viewmodel, 0);
		} else {
			new iWeapon = get_member(id, m_pActiveItem);
			if (iWeapon != -1)
				ExecuteHamB(Ham_Item_Deploy, iWeapon);
		}
	}

	return PLUGIN_CONTINUE;
}

public cmdPubMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mPublic) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mPublic);
			chat_print(0, "%L", id, "PUB_ACTIVATED", getUserName(id));
		}
	} else {
		chat_print(id, "%L", id, "PUB_ALREADY", getUserName(id));
	}

	if (containi(g_eMatchInfo[e_mMapName], "boost") != -1) {
		disableSemiclip();
	} else {
		enableSemiclip(3);
	}

	removeHook(id);

	return PLUGIN_HANDLED;
}

public cmdDMMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mDM) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mDM);
			chat_print(0, "%L", id, "DM_ACTIVATED", getUserName(id));
		}
	} else {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			chat_print(id, "%L", id, "DM_ALREADY", getUserName(id));
		}
	}

	if (containi(g_eMatchInfo[e_mMapName], "boost") != -1) {
		disableSemiclip();
	} else {
		enableSemiclip(3);
	}

	removeHook(id);

	return PLUGIN_HANDLED;
}

public cmdTransferSpec(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "TRANSF_SPEC", getUserName(id));
	transferUsers(TEAM_SPECTATOR);
	return PLUGIN_HANDLED;
}

public cmdTransferTT(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "TRANSF_TT", getUserName(id));
	transferUsers(TEAM_TERRORIST);
	return PLUGIN_HANDLED;
}

public cmdTransferCT(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "TRANSF_CT", getUserName(id));
	transferUsers(TEAM_CT);
	return PLUGIN_HANDLED;
}

public cmdStartRound(id) {
	if (!getUserInAccess(id))
		return;

	if (g_iCurrentMode != e_mTraining) {
		chat_print(id, "%L", id, "NOT_START_MIX");
		return;
	} else {
		if (equali(g_eMatchInfo[e_mMapName], knifemap))
			return;

		chat_print(0, "%L", id, "START_MIX", getUserName(id));
		g_eSurrenderData[e_sFlDelay] = get_gametime() + get_sur_delay();

		#if defined USE_PTS
			g_flMatchDelay = get_gametime() + 600; // Сделать кваром
		#endif
			
		new iPlayers[MAX_PLAYERS], iNum;
		get_players(iPlayers, iNum, "c");
		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			arrayset(g_ePlayerInfo[iPlayer], 0, PlayerInfo_s);
		}

		pfStartMatch();
	}
}

stock pfStartMatch() {
	g_iGameStops = 0;
	rg_send_audio(0, "plats/elevbell1.wav");
	set_task(2.5, "taskPrepareMode", e_mMatch);
	setTaskHud(0, 0.0, 1, 255, 255, 0, 3.0, "Going Live in 3 second!");
	setTaskHud(0, 3.1, 1, 255, 255, 0, 3.0, "Live! Live! Live!^nGood Luck & Have Fun!");
}

public cmdKnifeRound(id) {
	if (!getUserInAccess(id))
		return;
	
	if (g_iCurrentMode != e_mTraining) {
		chat_print(id, "%L", id, "NOT_START_KNIFE");
		return;
	} else {
		pfKnifeRound(id);
		removeHook(id);
	}
}

stock pfKnifeRound(id) {
	taskPrepareMode(e_mKnife);
	setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, "Knife Round Started");

	if (id)
		chat_print(0, "%L", id, "START_KNIFE", getUserName(id));

	return;
}

public cmdCaptain(id) {
	if (!getUserInAccess(id))
		return;

	if (!equali(g_eMatchInfo[e_mMapName], knifemap))
		return;

	if (g_iCurrentMode != e_mTraining)
		return;
	
	captainStart(id);
}

public cmdStopMode(id) {
	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
		verifMenu(id);
	} else {
		cmdStop(id);
	}
}

public cmdStop(id) {
	if (id && !getUserInAccess(id))
		return;

	if (!g_iCurrentMode)
		return;

	if (!id) {
		if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
			g_bGameStarted = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
			g_bLastRound = false;
			taskPrepareMode(e_mTraining);
			return;
		}

		rg_send_audio(0, "fvox/fuzz.wav");
		taskPrepareMode(e_mTraining);
		return;
	}

	switch (g_iCurrentMode) {
		case e_mPaused, e_mMatch: {
			chat_print(0, "%L", id, "STOP_MIX", getUserName(id));
			g_bGameStarted = false;
			g_bLastRound = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
			g_iRoundsPlayed[!g_iCurrentSW] = g_iRoundsPlayed[g_iCurrentSW] = 0;
		}
		case e_mKnife: {
			chat_print(0, "%L", id, "STOP_KNIFE", getUserName(id));
		}
		case e_mCaptain: {
			chat_print(0, "%L", id, "STOP_CAP", getUserName(id));
			resetCaptainData();
			return;
		}
		case e_mPublic: {
			chat_print(0, "%L", id, "STOP_PUB", getUserName(id));
		}
		case e_mDM: {
			chat_print(0, "%L", id, "STOP_DM", getUserName(id));
		}
	}
	rg_send_audio(0, "fvox/fuzz.wav");
	taskPrepareMode(e_mTraining);
}

public cmdSkillMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "TYPE_SKILL", getUserName(id));

	if (equali(knifemap, g_eMatchInfo[e_mMapName])) {
		enableSemiclip(0);
	} else {
		if (g_iCurrentMode == e_mTraining)
			enableSemiclip(0);
		else
			enableSemiclip(3);
	}

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 5);
		set_flash_num(1);
		set_smoke_num(1);
	}

	set_semiclip(true);

	return PLUGIN_HANDLED;
}

public cmdBoostMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "TYPE_BOOST", getUserName(id));

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 15);
		set_flash_num(3);
		set_smoke_num(1);
	}
	set_semiclip(false);
	disableSemiclip();

	return PLUGIN_HANDLED;
}

public cmdAa10(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "AA_10", getUserName(id));

	set_cvar_num("sv_airaccelerate", 10);
	set_aa_mode(10);

	return PLUGIN_HANDLED;
}

public cmdAa100(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "AA_100", getUserName(id));

	set_cvar_num("sv_airaccelerate", 100);
	set_aa_mode(100);

	return PLUGIN_HANDLED;
}

public cmdRestartRound(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "GAME_RESTART", getUserName(id));
	restartRound();
	removeHook(id);

	if (g_iCurrentMode == e_mMatch)
		g_iGameStops++;

	return PLUGIN_HANDLED;
}

public cmdSwapTeams(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	chat_print(0, "%L", id, "GAME_SWAP", getUserName(id));

	restartRound();
	rg_swap_all_players();
	removeHook(id);
	g_iCurrentSW = !g_iCurrentSW;

	if (g_iCurrentMode == e_mMatch)
		g_iGameStops++;

	return PLUGIN_HANDLED;
}

public cmdStartPause(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mMatch) {

		if (id)
			g_iGameStops++;

		new iPlayers[32], iNum;

		g_iCurrentMode = e_mPaused;

		if (g_bGameStarted) {
			g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;
			
			get_players(iPlayers, iNum, "c");
			for (new i; i < iNum; i++) {
				new iPlayer = iPlayers[i];
				ResetPlayerRoundData(iPlayer);
				arrayset(g_eRoundInfo[iPlayer], 0, RoundInfo_s);
			}

			g_bSurvival = false;
			g_bGameStarted = false;
		} else {
			if (id)
				chat_print(id,  "%L", id, "GAME_NOTSTARTED");
		}

		get_players(iPlayers, iNum, "ac");
		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			rg_remove_all_items(iPlayer);
			rg_give_item(iPlayer, "weapon_knife");
			setUserGodmode(iPlayer, true);
			rg_reset_maxspeed(iPlayer);
		}

		set_task(1.0, "taskHudPaused", .flags = "b");

		if (id) {
			chat_print(0, "%L", id, "GAME_PAUSED", getUserName(id));
		}

		rg_send_audio(0, "fvox/deactivated.wav");
		server_cmd("sv_alltalk 1"); //  Переделать!
		disableSemiclip();
	}
	return PLUGIN_HANDLED;
}

public taskHudPaused() {
	if (g_iCurrentMode == e_mPaused) {
		set_dhudmessage(100, 100, 100, -1.0, 0.75, 0, 0.0, 1.01, 0.0, 0.0);
		show_dhudmessage(0, "GAME PAUSE");
	}
}

public cmdStopPause(id) {
	if (id && !getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mPaused) {
		g_iCurrentMode = e_mMatch;

		if (id) {
			chat_print(0, "%L", id, "GAME_UNPAUSED", getUserName(id));
		}

		rg_send_audio(0, "fvox/activated.wav");
		g_bGameStarted = true;

		setTaskHud(0, 1.0, 1, 255, 255, 0, 3.0, "Game Unpause^nLive Live Live");

		restartRound();
		removeHook(id);

		if (is_semiclip() == 1) {
			set_cvar_num("mp_freezetime", 5);
			enableSemiclip(3);
		} else {
			set_cvar_num("mp_freezetime", 15);
			disableSemiclip();
		}
		
		loadMapCFG();

		if (get_flash_num() == 0)
			set_flash_num(0);
	}

	server_cmd("sv_alltalk 3"); //  Переделать!
	return PLUGIN_HANDLED;
}

public cmdMrMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
		if (g_iCurrentRules != e_mMR) {
			chat_print(0, "%L", id, "MR_ACTIVATED", id);
			set_rules_mode(1);
			g_iCurrentRules = e_mMR;
		} else {
			chat_print(id, "%L", id, "MR_ALREADY", id);
		}
	}
	return PLUGIN_HANDLED
}

public cmdTimerMode(id) {
	if (!getUserInAccess(id))
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
		if (g_iCurrentRules != e_mTimer) {
			chat_print(0, "%L", id, "TIMER_ACTIVATED", id);
			set_rules_mode(2);
			g_iCurrentRules = e_mTimer;
		} else {
			chat_print(id, "%L", id, "TIMER_ALREADY", id);
		}
	}
	return PLUGIN_HANDLED
}

public cmdSurrender(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!getUserInMatch(id))
		return;

	if (g_eSurrenderData[e_sStarted])
		return;

	if (g_eSurrenderData[e_sFlDelay] > get_gametime()) {
		new szTime[24];
		fnConvertTime(g_eSurrenderData[e_sFlDelay] - get_gametime(), szTime, 23, false);
		chat_print(id, "%L", id, "SUR_WAIT", szTime);
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", getUserTeam(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (iNum != g_eMatchInfo[e_mTeamSizeTT])
		return;

	g_eSurrenderData[e_sStarted] = true;
	g_eSurrenderData[e_sInitiator] = id;
	g_eSurrenderData[e_sFlDelay] = get_gametime() + get_sur_delay();
	chat_print(0, "%L", id, "SUR_PLAYER", id, getUserTeam(id) == TEAM_TERRORIST ? "TERRORISTS" : "CTS");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		surrenderMenu(iPlayer);
	}
	set_task(1.0, "taskSurrender", .flags = "b");
}

public cmdShowTimers(id) {
	if (g_bGameStarted || g_iCurrentMode == e_mPaused) {
		new timeToWin[2][24];
		fnConvertTime((get_pcvar_float(get_cap_time()) * 60.0) - g_flSidesTime[g_iCurrentSW], timeToWin[0], 23);
		fnConvertTime((get_pcvar_float(get_cap_time()) * 60.0) - g_flSidesTime[!g_iCurrentSW], timeToWin[1], 23);
		
		new iPlayers[MAX_PLAYERS], TTsize, CTSize;
		get_players(iPlayers, TTsize, "ce", "TERRORIST");
		get_players(iPlayers, CTSize, "ce", "CT");

		if (g_iCurrentRules == e_mTimer) {
			new timeDiff[2][24];
			fnConvertTime(g_flSidesTime[g_iCurrentSW] - g_flSidesTime[!g_iCurrentSW], timeDiff[0], 23, false);
			fnConvertTime(g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[g_iCurrentSW], timeDiff[1], 23, false);

			if (g_flSidesTime[!g_iCurrentSW] > g_flSidesTime[g_iCurrentSW]) {
				if (!g_iCurrentSW)
					client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME1", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[1]);
				else
					client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME2", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[1]);
			} else if(g_flSidesTime[!g_iCurrentSW] < g_flSidesTime[g_iCurrentSW]) {
				if (!g_iCurrentSW)
					client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME3", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[0]);
				else
					client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME4", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[0]);
			} else {
				if (!g_iCurrentSW)
					client_print_color(id, print_team_blue, "%L", 0, "SCORE_TIME5", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[0]);
				else
					client_print_color(id, print_team_blue, "%L", 0, "SCORE_TIME6", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[1]);
			}
		} else {
			fnConvertTime(g_flSidesTime[0], timeToWin[0], 23);
			fnConvertTime(g_flSidesTime[1], timeToWin[1], 23);
			if (!g_iCurrentSW) {
				chat_print(id, "%L", 0, "SCORE_TIME_MR1",
					timeToWin[0], TTsize, CTSize, timeToWin[1],
					(g_iRoundsPlayed[!g_iCurrentSW] + g_iRoundsPlayed[g_iCurrentSW]) + 1, get_max_rounds() * 2);
			} else {
				chat_print(id, "%L", 0, "SCORE_TIME_MR2",
					timeToWin[1], TTsize, CTSize, timeToWin[0],
					(g_iRoundsPlayed[!g_iCurrentSW] + g_iRoundsPlayed[g_iCurrentSW]) + 1, get_max_rounds() * 2);
			}
		}
	} else {
		chat_print(id, "%L", id, "SCORE_NOT");
	}
}

public cmdPick(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mCaptain)
		return;

	if (id != g_iCaptainPick)
		return;

	pickMenu(id);
}

public cmdTeamSpec(id) {
	if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) { // Переделать
		g_bSpec[id] = !g_bSpec[id];

		if (g_bSpec[id]) {
			if (getUserTeam(id) == TEAM_SPECTATOR) {
				g_bSpec[id] = false;
				return;
			}
			hTeam[id] = getUserTeam(id);
			transferUserToSpec(id);
		} else {
			if (getUserTeam(id) != TEAM_SPECTATOR) {
				g_bSpec[id] = true;
				return;
			}
			rg_set_user_team(id, hTeam[id]);
		}
	}
}

public cmdNoplay(id) {
	if (!g_bNoplay[id]) {
		g_bNoplay[id] = true;
		chat_print(0, "%L", id, "STATUS_NOPLAY", getUserName(id));
	}
}

public cmdPlay(id) {
	if (g_bNoplay[id]) {
		g_bNoplay[id] = false;
		chat_print(0, "%L", id, "STATUS_PLAY", getUserName(id));
	}
}

public cmdShowDamage(id) {
	if (g_iCurrentMode == e_mTraining) {
		cmdDamade(id);
	}
}

public cmdClipMode(id) {
	if (g_iCurrentMode != e_mTraining) {
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))  {
		chat_print(id, "%L", id, "TRAINING_NOTALIVE")
		return PLUGIN_HANDLED
	} else {
		if(!get_user_noclip(id))
			set_user_noclip(id, 1);
		else
			set_user_noclip(id, 0);
		chat_print(id, "%s No Clip ^3%sabled!", get_user_noclip(id) ? "en" : "dis");
	}
	return PLUGIN_HANDLED;
}

public cmdRespawn(id) {
	if (getUserTeam(id) != TEAM_SPECTATOR) {
		if (g_iCurrentMode == e_mTraining) {
			rg_round_respawn(id);
		}
	}
}

public cmdCheckpoint(id) {
	if (g_iCurrentMode == e_mTraining) {
		checkPoint(id);
	}
}

public cmdGoCheck(id) {
	if (g_iCurrentMode == e_mTraining) {
		goCheck(id);
	}
}

public cmdStuck(id) {
	if (g_iCurrentMode == e_mTraining) {
		stuck(id);
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