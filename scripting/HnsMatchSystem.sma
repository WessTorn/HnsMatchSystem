#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
	precache_sound(sndUseSound);
}

public plugin_init() {
	g_PluginId = register_plugin("Hide'n'Seek Match System", "1.2.5.1", "OpenHNS"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor, Juice

	get_mapname(g_eMatchInfo[e_mMapName], charsmax(g_eMatchInfo[e_mMapName]));

	cvars_init();

	register_clcmd("say", "sayHandle");

	hookOnOff_init();
	cmds_init();
	ham_init();
	forward_init();
	message_init();

	stats_init();

	register_forward(FM_EmitSound, "fwdEmitSoundPre", 0);
	register_forward(FM_ClientKill, "fwdClientKill");
	register_forward(FM_GetGameDescription, "fwdGameNameDesc");

	unregister_forward(FM_Spawn, g_iRegisterSpawn, 1);

	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgResetMaxSpeed", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgOnRoundFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rgFlPlayerFallDamage", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "rgTakeDamage", true);
	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);
	RegisterHookChain(RG_PM_Move, "rgPlayerMovePost", true);

	register_event("DeathMsg", "EventDeathMsg", "a");

	set_task(0.5, "taskDelayedMode");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	registerMode();
	loadPlayers();

	g_MsgSync = CreateHudSyncObj();
	g_tPlayerInfo = TrieCreate();

	g_bFreezePeriod = true;
	register_dictionary("mixsystem.txt");
}

public fwdEmitSoundPre(id, iChannel, szSample[], Float:volume, Float:attenuation, fFlags, pitch) {
	if (equal(szSample, "weapons/knife_deploy1.wav")) {
		return FMRES_SUPERCEDE;
	}

	if (is_user_alive(id) && getUserTeam(id) == TEAM_TERRORIST && equal(szSample, sndDenySelect)) {
		emit_sound(id, iChannel, sndUseSound, volume, attenuation, fFlags, pitch);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fwdGameNameDesc() {
	static gameName[32];
	get_game_description(gameName, 31);
	forward_return(FMV_STRING, gameName);

	return FMRES_SUPERCEDE;
}

public fwdClientKill(id) {
	if (g_iCurrentMode == e_mDM) {
		chat_print(0, "%L", id, "KILL_NOT");
		return FMRES_SUPERCEDE;
	} else {
		chat_print(0, "%L", id, "KILL_HIMSELF", getUserName(id));
	}
	return FMRES_IGNORED;
}

public fwdSpawn(entid) {
	static szClassName[32];
	if (pev_valid(entid)) {
		pev(entid, pev_classname, szClassName, 31);

		if (equal(szClassName, "func_buyzone"))
			engfunc(EngFunc_RemoveEntity, entid);

		for (new i = 0; i < sizeof szDefaultEntities; i++) {
			if (equal(szClassName, szDefaultEntities[i])) {
				engfunc(EngFunc_RemoveEntity, entid);
				break;
			}
		}
	}
}

public rgRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if (g_iCurrentMode == e_mMatch) {
		if (!g_bFreezePeriod) {
			statsApply();
		}
	}

	if (event == ROUND_TARGET_SAVED || event == ROUND_HOSTAGE_NOT_RESCUED) {
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_TERRORISTS);
		SetHookChainArg(2, ATYPE_INTEGER, ROUND_TERRORISTS_ESCAPED);
	}

	if (event == ROUND_GAME_COMMENCE) {
		set_member_game(m_bGameStarted, true);
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	switch (g_iCurrentMode) {
		case e_mPublic: {
			if (status == WINSTATUS_CTS) {
				rg_swap_all_players();
			}
		}
		case e_mMatch: {
			g_bSurvival = false;
			if (status == WINSTATUS_TERRORISTS) {
				new players[MAX_PLAYERS], pnum;
				get_players(players, pnum, "ace", "CT");
				if (!pnum) {
					new Float:roundtime = get_pcvar_float(get_round_time()) * 60.0;
					g_flSidesTime[g_iCurrentSW] += roundtime - g_flRoundTime;
				}
			}
			if (g_bGameStarted) {
				new iWinTeam = -1;
				new szTime[24];
				new Float:flTimeToWinTT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_iRoundsPlayed[g_iCurrentSW]);
				new Float:flTimeToWinCT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_iRoundsPlayed[!g_iCurrentSW]);
				if (g_flSidesTime[g_iCurrentSW] + flTimeToWinTT < g_flSidesTime[!g_iCurrentSW]) {
					iWinTeam = !g_iCurrentSW;
				} else if (g_flSidesTime[!g_iCurrentSW] + flTimeToWinCT < g_flSidesTime[g_iCurrentSW]) {
					iWinTeam = g_iCurrentSW;
				}
				g_iRoundsPlayed[g_iCurrentSW]++;
				if (iWinTeam != -1) {
					MixFinishedMR(iWinTeam == g_iCurrentSW ? 1 : 2);
				} else if(g_iRoundsPlayed[g_iCurrentSW] + g_iRoundsPlayed[!g_iCurrentSW] >= (get_max_rounds() * 2)) {				
					if (floatabs(g_flSidesTime[!g_iCurrentSW]-g_flSidesTime[g_iCurrentSW]) <= 1.0)
					{
						g_iCurrentSW = !g_iCurrentSW;
						rg_swap_all_players();
						chat_print(0, "%L", "SAME_TIMER");
						set_max_rounds(get_max_rounds() + 2);
						g_bLastRound = false;
					}
				} else if (g_iRoundsPlayed[g_iCurrentSW] + g_iRoundsPlayed[!g_iCurrentSW] >= (get_max_rounds() * 2) - 1) {
					if (!g_bLastRound) {
						g_iCurrentSW = !g_iCurrentSW;
						rg_swap_all_players();
					}
					if (g_flSidesTime[!g_iCurrentSW] > g_flSidesTime[g_iCurrentSW]) {
						if (!g_bLastRound) {
							fnConvertTime(g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[g_iCurrentSW], szTime, charsmax(szTime));
							setTaskHud(0, 3.0, 1, 255, 153, 0, 5.0, fmt("%L", LANG_SERVER, "HUD_TIMETOWIN", szTime));
							g_bLastRound = true;
						}
					}
				} else {
					if (!g_bLastRound) {
						g_iCurrentSW = !g_iCurrentSW;
						rg_swap_all_players();
					}
				}
			}
		}
		case e_mKnife: {
			if (g_bCaptainsBattle) {
				if (status == WINSTATUS_CTS)
					g_iCaptainPick = g_eCaptain[e_cCT];
				else
					g_iCaptainPick = g_eCaptain[e_cTT];

				setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, fmt("%L", LANG_SERVER, "HUD_CAPWIN", g_iCaptainPick));

				taskPrepareMode(e_mCaptain);
				g_bCaptainsBattle = false;

				pickMenu(g_iCaptainPick);
			} else {
				setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, "Team %s Win", status == WINSTATUS_CTS ? "CTS" : "Terrorists");

				savePlayers(status == WINSTATUS_CTS ? TEAM_CT : TEAM_TERRORIST);
				taskPrepareMode(e_mTraining);
			}
		}
	}
	return HC_CONTINUE;
}

stock savePlayers(TeamName:team_winners) {
	new JSON:arrayRoot = json_init_array();

	new iPlayers[MAX_PLAYERS], iNum, szAuth[24];
	get_players(iPlayers, iNum, "ch");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];

		if (getUserTeam(id) == TEAM_SPECTATOR) continue;

		get_user_authid(id, szAuth, charsmax(szAuth));

		arrayAppendValue(arrayRoot, json_init_string(fmt("player_%i", i + 1)));

		new JSON:object = json_init_object();
		json_object_set_string(object, "e_pAuth", fmt("%s", szAuth));
		new TeamName:iTeam = TeamName:getUserTeam(id) == team_winners ? TEAM_TERRORIST : TEAM_CT;
		json_object_set_number(object, "e_pTeam", _:iTeam);
		arrayAppendValue(arrayRoot, object);
		json_free(object);
	}

	json_serial_to_string(arrayRoot, g_szBuffer, charsmax(g_szBuffer), true);
	server_print("Players saved (%d bytes)", json_serial_size(arrayRoot, true));
	json_free(arrayRoot);
}

arrayAppendValue(JSON:array, JSON:node) {
	json_array_append_value(array, node);
	json_free(node);
}

public rgResetMaxSpeed(id) {
	if (get_member_game(m_bFreezePeriod)) {
		if (g_iCurrentMode == e_mTraining || g_iCurrentMode == e_mPaused) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}

		if (getUserTeam(id) == TEAM_TERRORIST) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public rgRestartRound() {
	remove_task();
	g_bFreezePeriod = true;

	if (g_bGameStarted)
		cmdShowTimers(0);

	g_flRoundTime = 0.0;
	EnableHamForward(playerKilledPre);

	new iPlayers[MAX_PLAYERS], iNum;

	get_players(iPlayers, iNum, "ch");
	for (new j; j < iNum; j++) {
		new id = iPlayers[j];
		arrayset(g_eRoundStats[id], 0, STATS_PLAYER);
	}

	get_players(iPlayers, iNum, "che", "TERRORIST");
	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		if (g_bLastFlash[iPlayer]) {
			g_bLastFlash[iPlayer] = false;
			show_menu(iPlayer, 0, "^n", 1);
		}
	}
	g_eMatchInfo[e_mTeamSizeTT] = iNum;

	if (g_iCurrentMode == e_mMatch) {
		ResetAfkData();
		set_task(0.3, "taskSaveAfk");
	}

	set_task(1.0, "taskDestroyBreakables");
}

public taskDestroyBreakables() {
	new iEntity = -1;
	while ((iEntity = rg_find_ent_by_class(iEntity, "func_breakable"))) {
		if (get_entvar(iEntity, var_takedamage)) {
			set_entvar(iEntity, var_origin, Float:{ 10000.0, 10000.0, 10000.0 });
		}
	}
}

public rgOnRoundFreezeEnd() {
	g_bFreezePeriod = false;
	if (g_iCurrentMode != e_mMatch)
		return;

	if (g_bGameStarted)
		g_bSurvival = true;

	set_task(is_semiclip() ? 3.0 : 5.0, "taskCheckAfk");
	set_task(1.0, "task_ShowPlayerInfo", .flags = "b");

	set_task(0.25, "taskRoundEvent", .flags = "b");
}

public rgFlPlayerFallDamage(id) {
	if (g_iCurrentMode != e_mMatch)
		return;

	new damage = floatround(Float:GetHookChainReturn(ATYPE_FLOAT));

	ExecuteForward(g_StatsFuncs[STATSFUNCS_DAMAGE], _, id, damage);
}

public taskRoundEvent() {
	if (g_bSurvival) {
		new iPlayers[32], count;
		get_players(iPlayers, count, "che", "TERRORIST");

		for(new i; i < 10; i++) {
			g_iBestAuth[i] = "";
		}

		g_flRoundTime += 0.25;
		g_flSidesTime[g_iCurrentSW] += 0.25;
		for (new i; i < count; i++) {
			new id = iPlayers[i];
			if (!is_user_alive(id))
				continue;

			g_ePlayerInfo[id][e_plrSurviveTime] += 0.25;
			g_eRoundStats[id][e_flSurviveTime] += 0.25;
		}
	}
	if ((g_flRoundTime / 60.0) >= get_pcvar_float(get_round_time())) {
		if (g_bGameStarted)
			g_bSurvival = false;

		remove_task();
	}
	
	new iWinTeam = -1;
	new Float:flTimeToWinTT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_iRoundsPlayed[g_iCurrentSW]);
	new Float:flTimeToWinCT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_iRoundsPlayed[!g_iCurrentSW]);
	if (g_flSidesTime[g_iCurrentSW] + flTimeToWinTT < g_flSidesTime[!g_iCurrentSW]) {
		iWinTeam = !g_iCurrentSW;
	} else if (g_flSidesTime[!g_iCurrentSW] + flTimeToWinCT < g_flSidesTime[g_iCurrentSW]) {
		iWinTeam = g_iCurrentSW;
	}
	if (iWinTeam != -1) {
		MixFinishedMR(iWinTeam == g_iCurrentSW ? 1 : 2);
	}
}

public MixFinishedMR(iWinTeam) {
	g_bGameStarted = false;
	g_bSurvival = false;
	g_bLastRound = false;
	new Float:TimeDiff = floatabs(g_flSidesTime[g_iCurrentSW] - g_flSidesTime[!g_iCurrentSW]);
	new szTime[24];
	fnConvertTime(TimeDiff, szTime, 23);
	chat_print(0, "%L", 0, "MR_WIN", iWinTeam == 1 ? "TT" : "CT", szTime);
	chat_print(0, "%L", 0, "SHOW_TOP");

	#if defined USE_PTS
		if (g_flMatchDelay > get_gametime()) {
			chat_print(0, "^3Not pts (mix time < 10 min)");
		} else {
			if (get_num_players_in_match() < 5) {
				chat_print(0, "^3Not pts (Players <= 5");
			} else {
				if (iWinTeam == 1)
					hns_set_pts_tt();
				else
					hns_set_pts_ct()
			}
		}
	#endif

	setTaskHud(0, 1.0, 1, 255, 255, 0, 4.0, "%L", LANG_SERVER, "HUD_GAMEOVER");
	taskPrepareMode(e_mTraining);

	g_bPlayersListLoaded = false;
	g_iRoundsPlayed[!g_iCurrentSW] = g_iRoundsPlayed[g_iCurrentSW] = 0;
	g_flSidesTime[!g_iCurrentSW] = g_flSidesTime[g_iCurrentSW] = 0.0;
	ShowTop(0);

	ExecuteForward(g_hForwards[MATCH_FINISHED], _, iWinTeam);
}

stock get_num_players_in_match() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");
	new numGameplr;
	for (new i; i < iNum; i++) {
		new tempid = iPlayers[i];
		if (getUserTeam(tempid) == TEAM_SPECTATOR) continue;
		numGameplr++;
	}
	return numGameplr;
}

public rgPlayerSpawn(id) {
	if (!is_user_alive(id))
		return;

	if (g_iCurrentMode <= 1 || g_iCurrentMode == e_mCaptain)
		setUserGodmode(id, 1);

	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) {
		if (get_hp_mode() == 1) {
			set_entvar(id, var_health, 1.0);
		}
	}

	setUserRole(id);
}

public rgTakeDamage(victim, inflictor, attacker, Float:damage, damage_bits) {
	if (g_iCurrentMode == e_mMatch) {
		if (is_user_connected(attacker) && getUserTeam(victim) != getUserTeam(attacker)) {
			ExecuteForward(g_StatsFuncs[STATSFUNCS_DAMAGE], _, attacker);
		}
	} else if (g_iCurrentMode == e_mTraining) {
		if(damage_bits & DMG_FALL) {
			damageHit(victim, damage);
		}
	}
}

public rgPlayerPreThink(id)
{
	if (g_iCurrentMode != e_mMatch)
		return

	ExecuteForward(g_StatsFuncs[STATSFUNCS_PRETHINK], _, id);
}

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold) {
	if (g_iCurrentMode == e_mMatch) {
		if (getUserTeam(index) != getUserTeam(attacker))
			ExecuteForward(g_StatsFuncs[STATSFUNCS_DAMAGE], _, attacker, fadeHold);
	}

	if (getUserTeam(index) == TEAM_TERRORIST || getUserTeam(index) == TEAM_SPECTATOR)
		return HC_SUPERCEDE;

	return HC_CONTINUE;
}

public rgPlayerMakeBomber(const this) {
	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}

public rgPlayerMovePost(const PlayerMove:ppmove, const server) {
	static Float:velocity[3];
	new const id = get_pmove(pm_player_index) + 1;

	if (g_iCurrentMode > e_mPaused && g_iCurrentMode != e_mCaptain) {
		removeHook(id);
		return;
	}

	if(g_bHooked[id]) {
		velocity_by_aim(id, 550, velocity);
		set_pmove(pm_velocity, velocity);
	}
}

public taskDelayedMode() {
	get_knife_map(knifemap, charsmax(knifemap));

	if (equali(knifemap, g_eMatchInfo[e_mMapName])) {
		taskPrepareMode(e_mTraining);
	} else if (get_last_mode() == 0) {
		taskPrepareMode(e_mTraining);
	} else if (get_last_mode() == 1) {
		taskPrepareMode(e_mPublic);
	} else if (get_last_mode() == 2) {
		taskPrepareMode(e_mDM);
	} else {
		taskPrepareMode(e_mTraining);
	}

	get_prefix(prefix, charsmax(prefix));
	format(prefix, charsmax(prefix), "%s", prefix);
}

public registerMode() {
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);
}

loadPlayers() {
	if (!equali(g_eMatchInfo[e_mMapName], knifemap))
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
	if (equali(g_eMatchInfo[e_mMapName], knifemap)) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
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

public EventDeathMsg() {
	if (g_iCurrentMode != e_mDM) {
		return;
	}

	new killer = read_data(1);
	new victim = read_data(2);

	if(killer == 0)  {
		if(getUserTeam(victim) == TEAM_TERRORIST) {
			new lucky = GetRandomCT();
			if(lucky) {
				rg_set_user_team(lucky, TEAM_TERRORIST);
				chat_print(lucky, "%L", lucky, "DM_TRANSF")
				rg_set_user_team(victim, TEAM_CT);
				setUserRole(lucky);
			}
		}
	} else if(killer != victim && getUserTeam(killer) == TEAM_CT) {
		rg_set_user_team(killer, TEAM_TERRORIST);
		rg_set_user_team(victim, TEAM_CT);

		setUserRole(killer);
	}

	set_task(float(get_dm_resp()), "RespawnPlayer", victim);
}

public RespawnPlayer(id) {
	if (!is_user_connected(id))
		return;

	if (getUserTeam(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

GetRandomCT() {
	static iPlayers[32], iCTNum
	get_players(iPlayers, iCTNum, "ache", "CT");

	if(!iCTNum)
		return 0

	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
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
			set_last_mode(0);
			disableSemiclip();
		}
		case e_mKnife: {
			g_iCurrentMode = e_mKnife;
			server_cmd("exec %s/knife.cfg", szPath);
			set_last_mode(0);
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
			set_last_mode(0);

			if (is_semiclip()) {
				set_cvar_num("mp_freezetime", 5);
				set_flash_num(1);
				set_smoke_num(1);
				set_semiclip(true);
				enableSemiclip(3);
			} else {
				set_cvar_num("mp_freezetime", 15);
				set_flash_num(3);
				set_smoke_num(1);
				set_semiclip(false);
				disableSemiclip();
			}

			loadMapCFG();

			new iPlayers[MAX_PLAYERS], iNum;
			get_players(iPlayers, iNum, "e", "TERRORIST");
			g_eMatchInfo[e_mTeamSizeTT] = iNum;

			rg_send_audio(0, "sound/barney/ba_bring.wav");

			addStats();

			ExecuteForward(g_hForwards[MATCH_STARTED], _);
		}
		case e_mPublic: {
			g_iCurrentMode = e_mPublic;
			server_cmd("exec %s/public.cfg", szPath);
			set_flash_num(1);
			set_last_mode(1);
			enableSemiclip(3);
			loadMapCFG();
		}
		case e_mDM: {
			g_iCurrentMode = e_mDM;
			server_cmd("exec %s/deathmatch.cfg", szPath);
			set_flash_num(1);
			set_last_mode(2);
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
	format(szPath, charsmax(szPath), "%s/mixsystem/%s", szPath, "matchsystem.cfg");
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
		g_ePlayerInfo[id][e_plrSurviveTime] -= g_eRoundStats[id][e_flSurviveTime];
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

	formatex(convert_time, len, "%s", szTemp);

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

/*stock get_num_players_in_mix() {
	new iPlayer;
	for(new id = 1; id <= MaxClients; id++) {
		if (!is_user_connected(id)) continue;

		if (get_member(id, m_iTeam) == TEAM_SPECTATOR) continue;

		iPlayer++;
	}
	return iPlayer;
}*/