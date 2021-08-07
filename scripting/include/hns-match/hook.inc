#if defined _hook_included
  #endinput
#endif

#define _hook_included

stock hook_init() {
	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgResetMaxSpeed", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgOnRoundFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rgFlPlayerFallDamage", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "rgTakeDamage", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);
	RegisterHookChain(RG_PM_Move, "rgPlayerMovePost", true);
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
			if (g_iCurrentRules == e_mTimer && status == WINSTATUS_CTS) {
				g_iCurrentSW = !g_iCurrentSW;
				rg_swap_all_players();
			}
			if (g_iCurrentRules == e_mMR) {
				if (status == WINSTATUS_TERRORISTS) {
					new players[MAX_PLAYERS], pnum;
					get_players(players, pnum, "ace", "CT");
					if (!pnum) {
						new Float:roundtime = get_round_time() * 60.0;
						g_flSidesTime[g_iCurrentSW] += roundtime - g_flRoundTime;
					}
				}
				if (g_bGameStarted) {
					new iWinTeam = -1;
					new szTime[24];		
					new Float:flTimeToWinTT = Float:(get_round_time() * 60.0) * (get_max_rounds() - g_iRoundsPlayed[g_iCurrentSW]);
					new Float:flTimeToWinCT = Float:(get_round_time() * 60.0) * (get_max_rounds() - g_iRoundsPlayed[!g_iCurrentSW]);
					if (g_flSidesTime[g_iCurrentSW] + flTimeToWinTT < g_flSidesTime[!g_iCurrentSW]) {
						iWinTeam = !g_iCurrentSW;
					} else if (g_flSidesTime[!g_iCurrentSW] + flTimeToWinCT < g_flSidesTime[g_iCurrentSW]) {
						iWinTeam = g_iCurrentSW;
					}
					g_iRoundsPlayed[g_iCurrentSW]++;
					if (iWinTeam != -1) {
						MixFinishedMR(iWinTeam == g_iCurrentSW ? 1 : 2);
					} else if (g_iRoundsPlayed[g_iCurrentSW] + g_iRoundsPlayed[!g_iCurrentSW] >= (get_max_rounds() * 2) - 1) {
						if (!g_bLastRound) {
							g_iCurrentSW = !g_iCurrentSW;
							rg_swap_all_players();
						}
						if (g_flSidesTime[!g_iCurrentSW] > g_flSidesTime[g_iCurrentSW]) {
							if (!g_bLastRound) {
								fnConvertTime(g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[g_iCurrentSW], szTime, charsmax(szTime));
								setTaskHud(0, 3.0, 1, 255, 153, 0, 5.0, fmt("Last Round!^n TT Need %s Time to Win!", szTime));
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
		}
		case e_mKnife: {
			if (g_bCaptainsBattle) {
				if (status == WINSTATUS_CTS)
					g_iCaptainPick = g_eCaptain[e_cCT];
				else
					g_iCaptainPick = g_eCaptain[e_cTT];

				setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, fmt("Captain %n win!", g_iCaptainPick));

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
		arrayset(g_eRoundInfo[id], 0, RoundInfo_s);
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
	set_task(2.5, "task_MainThink", .flags = "b");

	set_task(0.25, "taskRoundEvent", .flags = "b");
}

public rgFlPlayerFallDamage(id) {
	if (g_iCurrentMode == e_mMatch) {
		statsDmg(id);
	}
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
			g_eRoundInfo[id][e_flSurviveTime] += 0.25;
		}

		if (g_iCurrentRules == e_mTimer) {
			if (g_flSidesTime[g_iCurrentSW] >= float(get_cap_time()) * 60.0) {
				g_bGameStarted = false;
				g_bSurvival = false;
				new Float:flTimeDiff;
				if (g_iCurrentSW)
					flTimeDiff = g_flSidesTime[g_iCurrentSW] - g_flSidesTime[0];
				else
					flTimeDiff = g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[1];

				new szTime[24];
				fnConvertTime(flTimeDiff, szTime, 23, false);
				chat_print(0, "%L", 0, "TT_WIN", szTime);
				chat_print(0, "%L", 0, "SHOW_TOP");

				#if defined USE_PTS
					if (g_flMatchDelay > get_gametime()) {
						chat_print(0, "^3Not pts (mix time < 10 min)");
					} else {
						if (get_num_players_in_match() < 5) {
							chat_print(0, "^3Not pts (Players <= 5");
						} else {
							hns_set_pts_tt();
						}
					}
				#endif

				setTaskHud(0, 1.0, 1, 255, 255, 0, 4.0, "Game Over");
				taskPrepareMode(e_mTraining);

				g_bPlayersListLoaded = false;
				ShowTop(0);
			}
		}	
	}
	if ((g_flRoundTime / 60.0) >= get_round_time()) {
		if (g_bGameStarted)
			g_bSurvival = false;

		remove_task();
	}
	if (g_iCurrentRules == e_mMR) {
		new iWinTeam = -1;
		new Float:flTimeToWinTT = Float:(get_round_time() * 60.0) * (get_max_rounds() - g_iRoundsPlayed[g_iCurrentSW]);
		new Float:flTimeToWinCT = Float:(get_round_time() * 60.0) * (get_max_rounds() - g_iRoundsPlayed[!g_iCurrentSW]);
		if (g_flSidesTime[g_iCurrentSW] + flTimeToWinTT < g_flSidesTime[!g_iCurrentSW]) {
			iWinTeam = !g_iCurrentSW;
		} else if (g_flSidesTime[!g_iCurrentSW] + flTimeToWinCT < g_flSidesTime[g_iCurrentSW]) {
			iWinTeam = g_iCurrentSW;
		}
		if (iWinTeam != -1) {
			MixFinishedMR(iWinTeam == g_iCurrentSW ? 1 : 2);
		}
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

	setTaskHud(0, 1.0, 1, 255, 255, 0, 4.0, "Game Over");
	taskPrepareMode(e_mTraining);

	g_bPlayersListLoaded = false;
	g_iRoundsPlayed[!g_iCurrentSW] = g_iRoundsPlayed[g_iCurrentSW] = 0;
	g_flSidesTime[!g_iCurrentSW] = g_flSidesTime[g_iCurrentSW] = 0.0;
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
	lastOrigin(id);

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
			statsStabs(attacker);
		}
	} else if (g_iCurrentMode == e_mTraining) {
		if(damage_bits & DMG_FALL) {
			damageHit(victim, damage);
		}
	}
}

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3]) {
	if (g_iCurrentMode == e_mMatch) {
		if (getUserTeam(index) != getUserTeam(attacker))
			statsFlashedTime(attacker, fadeHold);
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