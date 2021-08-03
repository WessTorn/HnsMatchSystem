// #define USE_PTS

#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
	precache_sound(sndUseSound);
}

public plugin_init() {
	register_plugin("Hide'n'Seek Match System", "1.2.3.1", "??"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor 

	get_mapname(g_eMatchInfo[e_mMapName], charsmax(g_eMatchInfo[e_mMapName]));

	g_eCvars[e_cRoundTime] = get_cvar_pointer("mp_roundtime");
	
	g_eCvars[e_cCapTime]			= register_cvar("hns_wintime", "15");
	g_eCvars[e_cMaxRounds]			= register_cvar("hns_rounds", "6");
	g_eCvars[e_cFlashNum]			= register_cvar("hns_flash", "2", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSmokeNum]			= register_cvar("hns_smoke", "1", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cLastMode]			= register_cvar("hns_lastmode", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cAA]					= register_cvar("hns_aa", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSemiclip]			= register_cvar("hns_semiclip", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cHpMode]				= register_cvar("hns_hpmode", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cDMRespawn] 			= register_cvar("hns_dmrespawn", "3", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSurVoteTime] 		= register_cvar("hns_survotetime", "10", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSurTimeDelay] 		= register_cvar("hns_surtimedelay", "120", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cCheckPlayNoPlay] 	= register_cvar("hns_checkplay", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cRules] 				= register_cvar("hns_rules", "0");
	g_eCvars[e_cGameName]			= register_cvar("hns_gamename", "Hide'n'Seek");
	get_pcvar_string(register_cvar("hns_knifemap", "35hp_2", FCVAR_ARCHIVE | FCVAR_SERVER), g_eCvars[e_cKnifeMap], 24);

	register_clcmd("say", "sayHandle");

	hookOnOff_init();
	cmds_init();
	hook_init();
	event_init();
	ham_init();
	forward_init();
	message_init();

	set_task(0.5, "taskDelayedMode");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	registerMode();
	loadPlayers();

	g_MsgSync = CreateHudSyncObj();
	g_tPlayerInfo = TrieCreate();

	g_bFreezePeriod = true;
	register_dictionary("mixsystem.txt");
}

public taskDelayedMode() {
	if (equali(g_eCvars[e_cKnifeMap], g_eMatchInfo[e_mMapName])) {
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

	if(get_pcvar_num(g_eCvars[e_cRules]) == 1) {
		g_iCurrentRules = e_mMR;
	} else {
		g_iCurrentRules = e_mTimer;		
	}
}

public registerMode() {
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);
}

loadPlayers() {
	if (!equali(g_eMatchInfo[e_mMapName], g_eCvars[e_cKnifeMap]))
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
	if (equali(g_eMatchInfo[e_mMapName], g_eCvars[e_cKnifeMap])) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
}

public plugin_end() {
	TrieDestroy(g_tPlayerInfo);
	ArrayDestroy(g_aPlayersLoadData);
}

public client_putinserver(id) {
	g_bOnOff[id] = false;

	statsGetArray(id);
	training_putin(id);

	TrieGetArray(g_tPlayerInfo, getUserKey(id), g_ePlayerInfo[id], PlayerInfo_s);
	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
		if (g_ePlayerInfo[id][e_plrRetryGameStops] < g_iGameStops) {
			if (g_ePlayerInfo[id][e_plrRetryTime]) {
				g_ePlayerInfo[id][e_plrSurviveTime] -= g_ePlayerInfo[id][e_plrRetryTime];
				g_ePlayerInfo[id][e_plrRetryTime] = 0.0;
			}
		}
	} else {
		arrayset(g_ePlayerInfo[id], 0, PlayerInfo_s);
	}
}

public client_disconnected(id) {
	g_bHooked[id] = false;
	statsSetArray(id);
}

public is_hooked(id) {
	return g_bHooked[id];
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
			g_iRoundsPlayed[0] = 0;
			g_iRoundsPlayed[1] = 0;
			g_iCurrentSW = 1;
			g_bGameStarted = true;
			g_bLastRound = false;

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
			get_players(iPlayers, iNum, "e", "TERRORIST");
			g_eMatchInfo[e_mTeamSizeTT] = iNum;

			fnConvertTime(get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0, g_eMatchInfo[e_mWinTime], charsmax(g_eMatchInfo[e_mWinTime]));
			rg_send_audio(0, "sound/barney/ba_bring.wav");

			addStats();
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

public plugin_cfg() {
	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	formatex(szPath, charsmax(szPath), "%s/mixsystem/%s", szPath, "matchsystem.cfg");
	server_cmd("exec %s", szPath);
}

public plugin_natives() {
	register_native("hns_get_prefix", "native_get_prefix");

	register_native("hns_get_mode", "native_get_mode");
	register_native("hns_set_mode", "native_set_mode");
}

public native_get_prefix(amxx, params) {
	enum { argPrefix = 1, argLen };
	set_string(argPrefix, prefix, get_param(argLen));
}

public native_get_mode(amxx, params) {
	return g_iCurrentMode;
}

public native_set_mode(amxx, params) {
	enum { argMode = 1 };
	g_iCurrentMode = get_param(argMode);
	taskPrepareMode(argMode);
}

restartRound(Float:delay = 0.5) {
	if (g_bSurvival) {
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum);

		g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;

		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			ResetPlayerRoundData(iPlayer);
		}
	}
	g_bSurvival = false;
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
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

ResetPlayerRoundData(id) {
	if (getUserTeam(id) == TEAM_TERRORIST)
		g_ePlayerInfo[id][e_plrSurviveTime] -= g_eRoundInfo[id][e_flSurviveTime];
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

/*stock get_num_players_in_mix() {
	new iPlayer;
	for(new id = 1; id <= MaxClients; id++) {
		if (!is_user_connected(id)) continue;

		if (get_member(id, m_iTeam) == TEAM_SPECTATOR) continue;

		iPlayer++;
	}
	return iPlayer;
}*/