#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
	precache_sound(sndUseSound);
}

public plugin_init() {
	g_PluginId = register_plugin("Hide'n'Seek Match System", "1.2.9.1", "OpenHNS"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor, Juice

	get_mapname(g_szMapName, charsmax(g_szMapName));

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
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);
	RegisterHookChain(RG_PM_Move, "rgPlayerMovePost", true);

	set_task(0.5, "taskDelayedMode");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	registerMode();
	loadPlayers();

	g_MsgSync = CreateHudSyncObj();
	register_dictionary("mixsystem.txt");

	g_tSaveData = TrieCreate();

	g_hResetBugForward = CreateMultiForward("fwResetBug", ET_IGNORE, FP_CELL);
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
		chat_print(id, "%L", id, "KILL_NOT");
		return FMRES_SUPERCEDE;
	} else {
		chat_print(0, "%L", 0, "KILL_HIMSELF", id);
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
			g_eMatchInfo[e_sRoundInfo] = ROUND_NOT;
			if (status == WINSTATUS_TERRORISTS) {
				new players[MAX_PLAYERS], pnum;
				get_players(players, pnum, "ace", "CT");
				if (!pnum) {
					new Float:roundtime = get_pcvar_float(get_round_time()) * 60.0;
					g_eMatchInfo[e_flSidesTime][g_isTeamTT] += roundtime - g_flRoundTime;
				}
			}
			if (g_eMatchInfo[e_bStarted]) {
				new HNS_TEAM:iWinTeam;
				new bool:bFinish = false;
				new szTime[24];
				new Float:flTimeToWinTT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_eMatchInfo[e_iRoundsPlayed][g_isTeamTT]);
				new Float:flTimeToWinCT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM:!g_isTeamTT]);
				if (g_eMatchInfo[e_flSidesTime][g_isTeamTT] + flTimeToWinTT < g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT]) {
					iWinTeam = HNS_TEAM:!g_isTeamTT;
					bFinish = true;
				} else if (g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT] + flTimeToWinCT < g_eMatchInfo[e_flSidesTime][g_isTeamTT]) {
					iWinTeam = g_isTeamTT;
					bFinish = true;
				}
				g_eMatchInfo[e_iRoundsPlayed][g_isTeamTT]++;
				if (bFinish) {
					MixFinishedMR(iWinTeam == g_isTeamTT ? 1 : 2);
				} else if(g_eMatchInfo[e_iRoundsPlayed][g_isTeamTT] + g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM:!g_isTeamTT] >= (get_max_rounds() * 2)) {				
					if (floatabs(g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT] - g_eMatchInfo[e_flSidesTime][g_isTeamTT]) <= 1.0)
					{
						switchHnsTeamValue();
						rg_swap_all_players();
						chat_print(0, "%L", 0, "SAME_TIMER");
						set_max_rounds(get_max_rounds() + 2);
						g_eMatchInfo[e_bLastRound] = false;
					}
				} else if (g_eMatchInfo[e_iRoundsPlayed][g_isTeamTT] + g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM:!g_isTeamTT] >= (get_max_rounds() * 2) - 1) {
					if (!g_eMatchInfo[e_bLastRound]) {
						switchHnsTeamValue();
						rg_swap_all_players();
					}
					if (g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT] > g_eMatchInfo[e_flSidesTime][g_isTeamTT]) {
						if (!g_eMatchInfo[e_bLastRound]) {
							fnConvertTime(g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT] - g_eMatchInfo[e_flSidesTime][g_isTeamTT], szTime, charsmax(szTime));
							setTaskHud(0, 3.0, 1, 255, 153, 0, 5.0, fmt("%L", LANG_SERVER, "HUD_TIMETOWIN", szTime));
							g_eMatchInfo[e_bLastRound] = true;
						}
					}
				} else {
					if (!g_eMatchInfo[e_bLastRound]) {
						switchHnsTeamValue()
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
	g_eMatchInfo[e_sRoundInfo] = ROUND_FREEZE

	if (g_eMatchInfo[e_bStarted])
		cmdShowTimers(0);

	g_flRoundTime = 0.0;

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

	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused)
		g_flRetry = get_gametime() + RETRY_TIME;
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
	if (g_iCurrentMode != e_mMatch)
		return;

	if (g_eMatchInfo[e_bStarted])
		g_eMatchInfo[e_sRoundInfo] = ROUND_START;

	set_task(is_semiclip() ? 3.0 : 5.0, "taskCheckAfk");
	set_task(1.0, "task_ShowPlayerInfo", .flags = "b");

	set_task(0.25, "taskRoundEvent", .flags = "b");
	
	if (g_iCurrentMode == e_mPaused)
		g_flRetry = get_gametime() + RETRY_TIME;
}

public rgFlPlayerFallDamage(id) {
	if (g_iCurrentMode != e_mMatch)
		return;

	new damage = floatround(Float:GetHookChainReturn(ATYPE_FLOAT));

	ExecuteForward(g_StatsFuncs[STATSFUNCS_DAMAGE], _, id, damage);
}

public taskRoundEvent() {
	if (g_eMatchInfo[e_sRoundInfo] == ROUND_START) {
		new iPlayers[MAX_PLAYERS], count;
		get_players(iPlayers, count, "che", "TERRORIST");

		g_flRoundTime += 0.25;
		g_eMatchInfo[e_flSidesTime][g_isTeamTT] += 0.25;
		for (new i; i < count; i++) {
			new id = iPlayers[i];
			if (!is_user_alive(id))
				continue;

			iStats[id][e_flSurviveTime] += 0.25;
			g_eRoundStats[id][e_flSurviveTime] += 0.25;
		}
	}
	if ((g_flRoundTime / 60.0) >= get_pcvar_float(get_round_time())) {
		if (g_eMatchInfo[e_bStarted])
			g_eMatchInfo[e_sRoundInfo] = ROUND_NOT;

		remove_task();
	}
	
	new HNS_TEAM:iWinTeam;
	new bool:bFinish = false;
	new Float:flTimeToWinTT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_eMatchInfo[e_iRoundsPlayed][g_isTeamTT]);
	new Float:flTimeToWinCT = Float:(get_pcvar_float(get_round_time()) * 60.0) * (get_max_rounds() - g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM:!g_isTeamTT]);
	if (g_eMatchInfo[e_flSidesTime][g_isTeamTT] + flTimeToWinTT < g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT]) {
		iWinTeam = HNS_TEAM:!g_isTeamTT;
		bFinish = true;
	} else if (g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT] + flTimeToWinCT < g_eMatchInfo[e_flSidesTime][g_isTeamTT]) {
		iWinTeam = g_isTeamTT;
		bFinish = true;
	}
	if (bFinish) {
		MixFinishedMR(iWinTeam == g_isTeamTT ? 1 : 2);
	}
}

public MixFinishedMR(iWinTeam) {
	ExecuteForward(g_hForwards[MATCH_FINISHED], _, iWinTeam);
	new Float:TimeDiff = floatabs(g_eMatchInfo[e_flSidesTime][g_isTeamTT] - g_eMatchInfo[e_flSidesTime][HNS_TEAM:!g_isTeamTT]);
	new szTime[24];
	fnConvertTime(TimeDiff, szTime, 23);
	chat_print(0, "%L", 0, "MR_WIN", iWinTeam == 1 ? "TT" : "CT", szTime);
	chat_print(0, "%L", 0, "SHOW_TOP");

	setTaskHud(0, 1.0, 1, 255, 255, 0, 4.0, "%L", LANG_SERVER, "HUD_GAMEOVER");
	taskPrepareMode(e_mTraining);

	g_bPlayersListLoaded = false;
	arrayset(g_eMatchInfo, 0, MatchInfo_s);
	ShowTop(0);
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
	ExecuteForward(g_hResetBugForward, _, id);
}

public rgTakeDamage(victim, inflictor, attacker, Float:damage, damage_bits) {
	if (g_iCurrentMode == e_mMatch) {
		if (is_user_connected(attacker) && getUserTeam(victim) != getUserTeam(attacker)) {
			ExecuteForward(g_StatsFuncs[STATSFUNCS_STAB], _, attacker);
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

public rgPlayerKilled(victim, attacker) {
	if (g_iCurrentMode == e_mDM) {
		if (attacker == 0 || !is_user_connected(attacker)) {
			if (getUserTeam(victim) == TEAM_TERRORIST) {
				new lucky = GetRandomCT();
				if (lucky) {
					rg_set_user_team(lucky, TEAM_TERRORIST);
					chat_print(0, "%L", 0, "DM_TRANSF", lucky)
					rg_set_user_team(victim, TEAM_CT);
					setUserRole(lucky);
				}
			}
		} else if (attacker != victim && getUserTeam(attacker) == TEAM_CT) {
			rg_set_user_team(attacker, TEAM_TERRORIST);
			rg_set_user_team(victim, TEAM_CT);

			setUserRole(attacker);
		}

		//chat_print(0, "rgPlayerKilled (victim %n attacker %n)", victim, attacker)
		set_task(float(get_dm_resp()), "RespawnPlayer", victim);
	}

	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPublic) {
		if (getUserTeam(victim) == TEAM_TERRORIST) {
			new iPlayers[MAX_PLAYERS], iNum, index;
			get_players(iPlayers, iNum, "ache", "TERRORIST");

			if (iNum == 1) {
				index = iPlayers[0];
				g_bLastFlash[index] = true;
				iGiveNadesTo = index;
				show_menu(index, 3, "\rDo you need some nades?^n^n\r1. \wYes^n\r2. \wNo", -1, "NadesMenu");
			}
		}
	}

	if (g_iCurrentMode == e_mMatch || is_user_connected(attacker)) 
		ExecuteForward(g_StatsFuncs[STATSFUNCS_KD], _, victim, attacker);
}

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold) {
	if (g_iCurrentMode == e_mMatch) {
		if (getUserTeam(index) != getUserTeam(attacker))
			ExecuteForward(g_StatsFuncs[STATSFUNCS_FALSHEDTIME], _, attacker, fadeHold);
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

	if (equali(knifemap, g_szMapName)) {
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

public client_putinserver(id) {
	g_bOnOff[id] = false;

	training_putin(id);
}

public client_disconnected(id) {
	g_bHooked[id] = false;

	savePlayerStats(id);
}

public RespawnPlayer(id) {
	if (!is_user_connected(id))
		return;

	if (getUserTeam(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

GetRandomCT() {
	static iPlayers[MAX_PLAYERS], iCTNum
	get_players(iPlayers, iCTNum, "ache", "CT");

	if(!iCTNum)
		return 0

	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
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
			set_semiclip(SEMICLIP_OFF);
		}
		case e_mKnife: {
			g_iCurrentMode = e_mKnife;
			server_cmd("exec %s/knife.cfg", szPath);
			set_last_mode(0);
			set_semiclip(SEMICLIP_OFF);
		}
		case e_mMatch: {
			g_iCurrentMode = e_mMatch;

			arrayset(g_eMatchInfo, 0, MatchInfo_s);
			g_isTeamTT = HNS_TEAM_A;
			g_eMatchInfo[e_bStarted] = true;

			server_cmd("exec %s/match.cfg", szPath);
			set_last_mode(0);

			if (is_semiclip()) {
				set_cvar_num("mp_freezetime", 5);
				set_flash_num(1);
				set_smoke_num(1);
				set_semiclip(SEMICLIP_ON, true);
			} else {
				set_cvar_num("mp_freezetime", 15);
				set_flash_num(3);
				set_smoke_num(1);
				set_semiclip(SEMICLIP_OFF);
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
			set_semiclip(SEMICLIP_ON, true);
			loadMapCFG();
		}
		case e_mDM: {
			g_iCurrentMode = e_mDM;
			server_cmd("exec %s/deathmatch.cfg", szPath);
			set_flash_num(1);
			set_last_mode(2);
			set_semiclip(SEMICLIP_ON, true);
		}
		case e_mCaptain: {
			g_iCurrentMode = e_mCaptain;
			server_cmd("exec %s/captain.cfg", szPath);
			set_semiclip(SEMICLIP_ON);
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

restartRound(Float:delay = 0.5) {
	if (g_eMatchInfo[e_sRoundInfo] == ROUND_START) {
		new iPlayers[MAX_PLAYERS], iNum;
		get_players(iPlayers, iNum, "ch");

		g_eMatchInfo[e_flSidesTime][g_isTeamTT] -= g_flRoundTime;

		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			ResetPlayerRoundStats(iPlayer);
		}
	}
	g_eMatchInfo[e_sRoundInfo] = ROUND_NOT;
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
}

stock loadMapCFG() {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem", szPath);
	if (!dir_exists(szPath))
		mkdir(szPath);

	format(szPath, 127, "%s/mapcfg/%s.cfg", szPath, g_szMapName);

	if (file_exists(szPath))
		server_cmd("exec %s", szPath);
	else
		server_cmd("mp_roundtime 3.5");
}


public plugin_end() {
	TrieDestroy(g_tSaveData);
	ArrayDestroy(g_aPlayersLoadData);
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