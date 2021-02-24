/*
	1.0.9.n - Рефакторинг кода
*/

#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
	precache_sound(sndUseSound);
}

public plugin_init() {
	register_plugin("Hide'n'Seek Match System", "1.0.9.1", "??"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor

	get_mapname(g_eMatchInfo[e_mMapName], charsmax(g_eMatchInfo[e_mMapName]));

	g_eCvars[e_cRoundTime] = get_cvar_pointer("mp_roundtime");
	
	g_eCvars[e_cCapTime]	= register_cvar("hns_wintime", "15");
	g_eCvars[e_cFlashNum]	= register_cvar("hns_flash", "2", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSmokeNum]	= register_cvar("hns_smoke", "1", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cLastMode]	= register_cvar("hns_lastmode", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cAA]			= register_cvar("hns_aa", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSemiclip]	= register_cvar("hns_semiclip", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cHpMode]		= register_cvar("hns_hpmode", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cDMRespawn] 	= register_cvar("hns_dmrespawn", "3", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cGameName]	= register_cvar("hns_gamename", "Hide'n'Seek");

	register_clcmd("say", "sayHandle");

	hookOnOff_init();

	RegisterSayCmd("showknife", "knife", "cmdShowKnife");
	RegisterSayCmd("hideknife", "hknife", "cmdShowKnife");

	register_clcmd("chooseteam", "blockCmd");
	register_clcmd("jointeam", "blockCmd");
	register_clcmd("joinclass", "blockCmd");
	register_clcmd("nightvision", "mainMatchMenu");

	RegisterSayCmd("pub", "public", "cmdPubMode", access, "Public mode");
	RegisterSayCmd("dm", "DM", "cmdDMMode", access, "Public mode");
	RegisterSayCmd("specall", "specall", "cmdTransferSpec", access, "Spec Transfer");
	RegisterSayCmd("ttall", "ttall", "cmdTransferTT", access, "TT Transfer");
	RegisterSayCmd("ctall", "ctall", "cmdTransferCT", access, "CT Transfer");
	RegisterSayCmd("startmix", "start", "cmdStartRound", access, "Starts Round");
	RegisterSayCmd("kniferound", "kf", "cmdKnifeRound", access, "Knife Round");
	RegisterSayCmd("captain", "cap", "cmdCaptain", access, "Captain Mode");
	RegisterSayCmd("stop", "st", "cmdStopMode", access, "Stop Current Mode");
	RegisterSayCmd("skill", "skill", "cmdSkillMode", access, "Skill mode");
	RegisterSayCmd("boost", "boost", "cmdBoostMode", access, "Boost mode");
	RegisterSayCmd("aa10", "10aa", "cmdAa10", access, "10aa");
	RegisterSayCmd("aa100", "100aa", "cmdAa100", access, "100aa");
	RegisterSayCmd("rr", "restart", "cmdRestartRound", access, "Restart round");
	RegisterSayCmd("swap", "swap", "cmdSwapTeams", access, "Swap Teams");
	RegisterSayCmd("mix", "mix", "mainMatchMenu", access, "Main menu admin");
	RegisterSayCmd("pause", "ps", "cmdStartPause", access, "Start pause");
	RegisterSayCmd("live", "unpause", "cmdStopPause", access, "Unpause");
	RegisterSayCmd("surrender", "sur", "cmdSurrender", 0, "Surrender vote");
	RegisterSayCmd("score", "s", "cmdShowTimers", 0, "Score");
	RegisterSayCmd("pick", "pick", "cmdPick", 0, "Pick player");
	RegisterSayCmd("back", "spec", "cmdTeamSpec", 0, "Spec/Back player");
	RegisterSayCmd("np", "noPlay", "cmdNoplay", 0, "No play");
	RegisterSayCmd("ip", "play", "cmdPlay", 0, "Play play");

	hook_init();
	event_init();
	ham_init();
	forward_init();
	message_init();     

	set_task(0.5, "taskDelayedMode");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	registerMode();
	loadPlayers();

	afk_init();

	register_dictionary("mixsystem.txt");
}

public taskDelayedMode() {
	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		taskPrepareMode(e_mTraining);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 0) {
		taskPrepareMode(e_mTraining);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 1) {
		taskPrepareMode(e_mPublic);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 2) {
		taskPrepareMode(e_mDM);
	} else {
		taskPrepareMode(e_mTraining);
	}
}

public registerMode() {
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);
}

loadPlayers() {
	if (!equali(g_eMatchInfo[e_mMapName], knifeMap))
		g_bPlayersListLoaded = PDS_GetString("playerslist", g_szBuffer, charsmax(g_szBuffer));

	if (g_bPlayersListLoaded) {
		new JSON:arrayRoot = json_parse(g_szBuffer);

		if (!json_is_array(arrayRoot)) {
			if (arrayRoot != Invalid_JSON)
				json_free(arrayRoot);

			server_print("Root value is not array!");
			return;
		}
		decodeArray(arrayRoot);
		json_free(arrayRoot);
	}
}

decodeArray(&JSON:array) {
	new JSON:arrayValue;
	for (new i = 0; i < json_array_get_count(array); i++) {
		arrayValue = json_array_get_value(array, i);

		if (json_get_type(arrayValue) == JSONObject)
			decodeObject(arrayValue);

		json_free(arrayValue);
	}
}

decodeObject(&JSON:object) {
	new szKey[30];
	new JSON:objValue;
	new eTempPlayer[PlayersLoad_s], iSave;
	for (new i = 0; i < json_object_get_count(object); i++) {
		json_object_get_name(object, i, szKey, charsmax(szKey));
		objValue = json_object_get_value_at(object, i);

		switch (json_get_type(objValue)) {
			case JSONString: {
				json_get_string(objValue, eTempPlayer[e_pAuth], charsmax(eTempPlayer[e_pAuth]));
				iSave++;
			}
			case JSONNumber: {
				eTempPlayer[e_pTeam] = json_get_number(objValue);
				iSave++;
			}
		}

		if (iSave == 2) {
			ArrayPushArray(g_aPlayersLoadData, eTempPlayer);
			arrayset(eTempPlayer, 0, PlayersLoad_s);
			iSave = 0;
		}
		json_free(objValue);
	}
}

public PDS_Save() {
	if (equali(g_eMatchInfo[e_mMapName], knifeMap)) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
}

public plugin_end() {
	ArrayDestroy(g_aPlayersLoadData);
}

public client_putinserver(id) {
	g_bOnOff[id] = false;
}

public client_disconnected(id) {
	g_bHooked[id] = false;
}

public is_hooked(id) {
	return g_bHooked[id];
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

	if (equali(szArgs, "/wintime", 8)) {
		trim(szTarget);

		if (!(get_user_flags(id) & access))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_num(g_eCvars[e_cCapTime], str_to_num(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_WINTIME", prefix, getUserName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/Roundtime", 10)) {
		trim(szTarget);

		if (!(get_user_flags(id) & access))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_float(g_eCvars[e_cRoundTime], str_to_float(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_ROUNDTIME", prefix, getUserName(id), str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public cmdShowKnife(id) {
	g_bOnOff[id] = !g_bOnOff[id];

	client_print_color(id, print_team_blue, "%L", id, "SHOW_KNIFE", prefix, g_bOnOff[id] ? "^3in" : "^3");

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
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mPublic) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mPublic);
			client_print_color(0, print_team_blue, "%L", id, "PUB_ACTIVATED", prefix, getUserName(id));
		}
	} else {
		client_print_color(id, print_team_blue, "%L", id, "PUB_ALREADY", prefix, getUserName(id));
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
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mDM) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mDM);
			client_print_color(0, print_team_blue, "%L", id, "DM_ACTIVATED", prefix, getUserName(id));
		}
	} else {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			client_print_color(id, print_team_blue, "%L", id, "DM_ALREADY", prefix, getUserName(id));
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
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_SPEC", prefix, getUserName(id));
	transferUsers(TEAM_SPECTATOR);
	return PLUGIN_HANDLED;
}

public cmdTransferTT(id) {
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_TT", prefix, getUserName(id));
	transferUsers(TEAM_TERRORIST);
	return PLUGIN_HANDLED;
}

public cmdTransferCT(id) {
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_CT", prefix, getUserName(id));
	transferUsers(TEAM_CT);
	return PLUGIN_HANDLED;
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
		client_print_color(id, print_team_blue, "%L", id, "SUR_WAIT", prefix, szTime);
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", getUserTeam(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (iNum != g_eMatchInfo[e_mTeamSizeTT])
		return;

	g_eSurrenderData[e_sStarted] = true;
	g_eSurrenderData[e_sInitiator] = id;
	g_eSurrenderData[e_sFlDelay] = get_gametime() + surrenderTimeDelay;
	client_print_color(0, print_team_blue, "%L", id, "SUR_PLAYER", prefix, id, getUserTeam(id) == TEAM_TERRORIST ? "TERRORISTS" : "CTS");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		surrenderMenu(iPlayer);
	}
	set_task(1.0, "taskSurrender", .flags = "b");
}

public cmdNoplay(id) {
	if (!g_bNoplay[id]) {
		g_bNoplay[id] = true;
		client_print_color(0, print_team_blue, "%L", id, "STATUS_NOPLAY", prefix, getUserName(id));
	}
}

public cmdPlay(id) {
	if (g_bNoplay[id]) {
		g_bNoplay[id] = false;
		client_print_color(0, print_team_blue, "%L", id, "STATUS_PLAY", prefix, getUserName(id));
	}
}

public blockCmd(id) {
	if (g_iCurrentMode != e_mTraining)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public cmdTeamSpec(id) {
	if (g_iCurrentMode != e_mPublic)
		return;

	if (g_iCurrentMode != e_mDM)
		return;

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

public cmdStartPause(id) {
	if (id && ~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mMatch) {
		g_iCurrentMode = e_mPaused;

		if (g_bGameStarted) {
			g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;

			g_bSurvival = false;
			g_bGameStarted = false;
		} else {
			if (id)
				client_print_color(id, print_team_blue,  "%L", id, "GAME_NOTSTARTED", prefix);
		}

		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "ac");

		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			rg_remove_all_items(iPlayer);
			rg_give_item(iPlayer, "weapon_knife");
			setUserGodmode(iPlayer, true);
			rg_reset_maxspeed(iPlayer);
		}

		set_task(1.0, "taskHudPaused", _, _, _, "b");

		if (id) {
			client_print_color(0, print_team_blue, "%L", id, "GAME_PAUSED", prefix, getUserName(id));
		}

		rg_send_audio(0, "fvox/activated.wav");
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
	if (id && ~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mPaused) {
		g_iCurrentMode = e_mMatch;

		if (id) {
			client_print_color(0, print_team_blue, "%L", id, "GAME_UNPAUSED", prefix, getUserName(id));
		}

		rg_send_audio(0, "fvox/deactivated.wav");
		g_bGameStarted = true;

		setTaskHud(0, 1.0, 1, 255, 255, 0, 3.0, "Game Unpause^nLive Live Live");

		restartRound();
		removeHook(id);

		if (get_pcvar_num(g_eCvars[e_cSemiclip]) == 1) {
			set_cvar_num("mp_freezetime", 5);
			enableSemiclip(3);
		} else {
			set_cvar_num("mp_freezetime", 15);
			disableSemiclip();
		}
		loadMapCFG();
	}
	return PLUGIN_HANDLED;
}

public cmdSwapTeams(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "GAME_SWAP", prefix, getUserName(id));

	restartRound();
	rg_swap_all_players();
	removeHook(id);
	g_iCurrentSW = !g_iCurrentSW;

	return PLUGIN_HANDLED;
}

public cmdRestartRound(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "GAME_RESTART", prefix, getUserName(id));
	restartRound();
	removeHook(id);

	return PLUGIN_HANDLED;
}


public cmdSkillMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TYPE_SKILL", prefix, getUserName(id));

	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		enableSemiclip(0);
	} else {
		if (g_iCurrentMode == e_mTraining)
			enableSemiclip(0);
		else
			enableSemiclip(3);
	}

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 5);
		set_pcvar_num(g_eCvars[e_cFlashNum], 1);
		set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
	}

	set_pcvar_num(g_eCvars[e_cSemiclip], 1);

	return PLUGIN_HANDLED;
}

public cmdBoostMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TYPE_BOOST", prefix, getUserName(id));

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 15);
		set_pcvar_num(g_eCvars[e_cFlashNum], 3);
		set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
	}
	set_pcvar_num(g_eCvars[e_cSemiclip], 0);
	disableSemiclip();

	return PLUGIN_HANDLED;
}

public cmdAa10(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "AA_10", prefix, getUserName(id));

	set_cvar_num("sv_airaccelerate", 10);
	set_pcvar_num(g_eCvars[e_cAA], 10);

	return PLUGIN_HANDLED;
}

public cmdAa100(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "AA_100", prefix, getUserName(id));

	set_cvar_num("sv_airaccelerate", 100);
	set_pcvar_num(g_eCvars[e_cAA], 100);

	return PLUGIN_HANDLED;
}

public cmdStartRound(id) {
	if (get_user_flags(id) & access) {
		if (g_iCurrentMode != e_mTraining) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_START_MIX", prefix);
			return;
		} else {
			if (equali(g_eMatchInfo[e_mMapName], knifeMap))
				return;

			client_print_color(0, print_team_blue, "%L", id, "START_MIX", prefix, getUserName(id));
			g_eSurrenderData[e_sFlDelay] = get_gametime() + surrenderTimeDelay;
			pfStartMatch();
		}
	}
}

stock pfStartMatch() {
	rg_send_audio(0, "plats/elevbell1.wav");
	set_task(2.5, "taskPrepareMode", e_mMatch);
	setTaskHud(0, 0.0, 1, 255, 255, 0, 3.0, "Going Live in 3 second!");
	setTaskHud(0, 3.1, 1, 255, 255, 0, 3.0, "Live! Live! Live!^nGood Luck & Have Fun!");
}

public cmdStopMode(id) {
	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
		verifMenu(id);
	} else {
		cmdStop(id);
	}
}

public cmdStop(id) {
	if (id && ~get_user_flags(id) & access)
		return;

	if (!g_iCurrentMode)
		return;

	if (!id) {
		if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
			g_bGameStarted = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
			taskPrepareMode(e_mTraining);
			return;
		}

		rg_send_audio(0, "fvox/fuzz.wav");
		taskPrepareMode(e_mTraining);
		return;
	}

	switch (g_iCurrentMode) {
		case e_mPaused, e_mMatch: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_MIX", prefix, getUserName(id));
			g_bGameStarted = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
		}
		case e_mKnife: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_KNIFE", prefix, getUserName(id));
		}
		case e_mCaptain: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_CAP", prefix, getUserName(id));
			resetCaptainData();
			return;
		}
		case e_mPublic: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_PUB", prefix, getUserName(id));
		}
		case e_mDM: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_DM", prefix, getUserName(id));
		}
	}
	rg_send_audio(0, "fvox/fuzz.wav");
	taskPrepareMode(e_mTraining);
}

public cmdKnifeRound(id) {
	if (get_user_flags(id) & access) {
		if (g_iCurrentMode != e_mTraining) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_START_KNIFE", prefix);
			return;
		} else {
			pfKnifeRound(id);
			removeHook(id);
		}
	}
}

stock pfKnifeRound(id) {
	taskPrepareMode(e_mKnife);
	setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, "Knife Round Started");

	if (id)
		client_print_color(0, print_team_blue, "%L", id, "START_KNIFE", prefix, getUserName(id));

	return PLUGIN_HANDLED;
}

public cmdShowTimers(id) {
	if (g_bGameStarted || g_iCurrentMode == e_mPaused) {
		new timeToWin[2][24];
		fnConvertTime((get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0) - g_flSidesTime[g_iCurrentSW], timeToWin[0], 23);
		fnConvertTime((get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0) - g_flSidesTime[!g_iCurrentSW], timeToWin[1], 23);

		new timeDiff[2][24];
		fnConvertTime(g_flSidesTime[g_iCurrentSW] - g_flSidesTime[!g_iCurrentSW], timeDiff[0], 23, false);
		fnConvertTime(g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[g_iCurrentSW], timeDiff[1], 23, false);

		new iPlayers[MAX_PLAYERS], TTsize, CTSize;
		get_players(iPlayers, TTsize, "ce", "TERRORIST");
		get_players(iPlayers, CTSize, "ce", "CT");

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
		client_print_color(id, print_team_blue, "%L", id, "SCORE_NOT", prefix);
	}
}

public taskPrepareMode(mode) {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem/mode", szPath);
	switch (mode) {
		case e_mTraining: {
			g_iCurrentMode = e_mTraining;
			server_cmd("exec %s/training.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);
			disableSemiclip();
		}
		case e_mKnife: {
			g_iCurrentMode = e_mKnife;
			server_cmd("exec %s/knife.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);
			disableSemiclip();
		}
		case e_mMatch: {
			g_iCurrentMode = e_mMatch;
			g_flSidesTime[0] = 0.0;
			g_flSidesTime[1] = 0.0;
			g_iCurrentSW = 1;
			g_bGameStarted = true;

			server_cmd("exec %s/match.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);

			if (get_pcvar_num(g_eCvars[e_cSemiclip]) == 1) {
				set_cvar_num("mp_freezetime", 5);
				set_pcvar_num(g_eCvars[e_cFlashNum], 1);
				set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
				set_pcvar_num(g_eCvars[e_cSemiclip], 1);
				enableSemiclip(3);
				loadMapCFG();
			} else {
				set_cvar_num("mp_freezetime", 15);
				set_pcvar_num(g_eCvars[e_cFlashNum], 3);
				set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
				set_pcvar_num(g_eCvars[e_cSemiclip], 0);
				disableSemiclip();
				loadMapCFG();
			}

			loadMapCFG();

			new iPlayers[MAX_PLAYERS], iNum;
			get_players(iPlayers, iNum, "ce", "TERRORIST");
			g_eMatchInfo[e_mTeamSizeTT] = iNum;

			fnConvertTime(get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0, g_eMatchInfo[e_mWinTime], charsmax(g_eMatchInfo[e_mWinTime]));
			rg_send_audio(0, "sound/barney/ba_bring.wav");
		}
		case e_mPublic: {
			g_iCurrentMode = e_mPublic;
			server_cmd("exec %s/public.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cFlashNum], 1);
			set_pcvar_num(g_eCvars[e_cLastMode], 1);
			enableSemiclip(3);
			loadMapCFG();
		}
		case e_mDM: {
			g_iCurrentMode = e_mDM;
			server_cmd("exec %s/deathmatch.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cFlashNum], 1);
			set_pcvar_num(g_eCvars[e_cLastMode], 2);
			enableSemiclip(3);
		} 
		case e_mCaptain: {
			g_iCurrentMode = e_mCaptain;
			server_cmd("exec %s/captain.cfg", szPath);
			enableSemiclip(0);
		}
	}
	restartRound();
}

restartRound(Float:delay = 0.5) {
	if (g_bSurvival) {
		g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;
	}
	g_bSurvival = false;
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
}

stock setTaskHud(id, Float:Time, Dhud, Red, Green, Blue, Float:HoldTime, const Text[], any: ...) {
	new szMessage[128]; vformat(szMessage, charsmax(szMessage), Text, 9);
	new szArgs[7];
	szArgs[0] = id;
	szArgs[1] = encodeText(szMessage);
	szArgs[2] = Red;
	szArgs[3] = Green;
	szArgs[4] = Blue;
	szArgs[5] = Dhud;
	szArgs[6] = _:HoldTime;
	if (Time > 0.0)
		set_task(Time, "taskHudMessage", 89000, szArgs, 7);
	else
		taskHudMessage(szArgs);
}

public taskHudMessage(Params[]) {
	new id, Text[128], RRR, GGG, BBB, dhud, Float:HoldTime;
	id = Params[0];
	decodeText(Params[1], Text, charsmax(Text));
	RRR = Params[2];
	GGG = Params[3];
	BBB = Params[4];
	dhud = Params[5];
	HoldTime = Float:Params[6];

	if (!id || is_user_connected(id)) {
		if (dhud) {
			set_dhudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1);

			show_dhudmessage(id, Text);
		} else {
			set_hudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1, -1);
			show_hudmessage(id, Text);
		}
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

stock encodeText(const text[]) {
	return engfunc(EngFunc_AllocString, text);
}

stock decodeText(const text, string[], const length) {
	global_get(glb_pStringBase, text, string, length);
}

public cmdCaptain(id) {
	if (~get_user_flags(id) & access)
		return;

	if (!equali(g_eMatchInfo[e_mMapName], knifeMap))
		return;

	if (g_iCurrentMode != e_mTraining)
		return;

	resetCaptainData();
	g_iCurrentMode = e_mCaptain;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (getUserTeam(iPlayer) == TEAM_SPECTATOR)
			continue;

		transferUserToSpec(iPlayer);
	}
	chooseCapsMenu(id);
	client_print_color(0, print_team_blue, "%L", id, "CAP_CHOOSE", prefix, id);
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

stock loadMapCFG() {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem", szPath);
	if (!dir_exists(szPath))
		mkdir(szPath);

	format(szPath, 127, "%s/mapcfg/%s.cfg", szPath, g_eMatchInfo[e_mMapName]);

	if (file_exists(szPath))
		server_cmd("exec %s", szPath);
	else
		server_cmd("mp_roundtime 3.5");
}

fnConvertTime(Float:time, convert_time[], len, bool:with_intpart = true) {
	new szTemp[24];
	new Float:flSeconds = time, iMinutes;

	iMinutes = floatround(flSeconds / 60.0, floatround_floor);
	flSeconds -= iMinutes * 60.0;
	new intpart = floatround(flSeconds, floatround_floor);
	new Float:decpart = (flSeconds - intpart) * 100.0;

	if (with_intpart) {
		intpart = floatround(decpart);
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f.%d", iMinutes, flSeconds, intpart);
	} else {
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f", iMinutes, flSeconds);
	}

	formatex(convert_time, len, szTemp);

	return (PLUGIN_HANDLED);
}

enableSemiclip(team) {
	server_cmd("semiclip_option semiclip 1");
	server_cmd("semiclip_option team %d", team);
	server_cmd("semiclip_option time 0");
}

disableSemiclip() {
	server_cmd("semiclip_option semiclip 0");
	server_cmd("semiclip_option team 0");
	server_cmd("semiclip_option time 0");
}

// Спасибо: Cultura, Garey, Medusa, Ruffman, Conor
