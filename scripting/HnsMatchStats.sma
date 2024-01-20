#include <amxmodx>
#include <reapi>
#include <xs>

#include <hns_matchsystem>
#include <hns_matchsystem_pts>

forward hns_ownage(iToucher, iTouched);

#define TASK_TIMER 54345

new g_szPrefix[24];

enum _: PLAYER_STATS {
	PLR_STATS_KILLS,
	PLR_STATS_DEATHS,
	PLR_STATS_ASSISTS,
	PLR_STATS_STABS,
	PLR_STATS_DMG_CT,
	PLR_STATS_DMG_TT,
	Float:PLR_STATS_AVG_SPEED,
	Float:PLR_STATS_RUNNED,
	Float:PLR_STATS_RUNTIME,
	Float:PLR_STATS_FLASHTIME,
	Float:PLR_STATS_SURVTIME,
	PLR_STATS_OWNAGES,
	PLR_STATS_STOPS,
	bool:PLR_MATCH,
	TeamName:PLR_TEAM
}

new iStats[MAX_PLAYERS + 1][PLAYER_STATS];
new g_StatsRound[MAX_PLAYERS + 1][PLAYER_STATS];

new g_iGameStops;

new iLastAttacker[MAX_PLAYERS + 1];

new Float:last_position[MAX_PLAYERS+ 1][3];

new Trie:g_tSaveData;
new Trie:g_tSaveRoundData;

new best_auth[10][MAX_AUTHID_LENGTH];

public plugin_init() {
	register_plugin("Match: Stats", "1.0", "OpenHNS"); // Garey

	RegisterSayCmd("top", "tops", "ShowTop", 0, "Show top");

	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "rgPlayerTakeDamage", false);
	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRoundStart", true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rgPlayerFallDamage", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgRoundFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", true);
	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);

	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");

	g_tSaveData = TrieCreate();
	g_tSaveRoundData = TrieCreate();
}

public plugin_cfg() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public plugin_natives() {
	register_native("hns_get_stats_stabs", "native_get_stats_stabs");
	register_native("hns_get_stats_surv", "native_get_stats_surv");
}

public native_get_stats_stabs(amxx, params) {
	enum { id = 1 };
	return iStats[get_param(id)][PLR_STATS_STABS];
}

public Float:native_get_stats_surv(amxx, params) {
	enum { id = 1 };
	return iStats[get_param(id)][PLR_STATS_SURVTIME];
}

public msgShowMenu(msgid, dest, id) {
	if (!shouldAutoJoin(id))
		return PLUGIN_CONTINUE;

	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);
	if (!equal(menu_text_code, team_select))
		return (PLUGIN_CONTINUE);

	setForceTeamJoinTask(id, msgid);

	return PLUGIN_HANDLED;
}

public msgVguiMenu(msgid, dest, id) {
	if (get_msg_arg_int(1) != 2 || !shouldAutoJoin(id))
		return (PLUGIN_CONTINUE);

	setForceTeamJoinTask(id, msgid);

	return PLUGIN_HANDLED;
}

bool:shouldAutoJoin(id) {
	return (!get_user_team(id) && !task_exists(id));
}

setForceTeamJoinTask(id, menu_msgid) {
	static param_menu_msgid[2];
	param_menu_msgid[0] = menu_msgid;

	set_task(0.1, "taskForceTeamJoin", id, param_menu_msgid, sizeof param_menu_msgid);
}

public taskForceTeamJoin(menu_msgid[], id) {
	if (get_user_team(id))
		return;

	forceTeamJoin(id, menu_msgid[0], "5", "5");
}


stock forceTeamJoin(id, menu_msgid, team[] = "5", class[] = "0") {
	static jointeam[] = "jointeam";
	if (class[0] == '0') {
		engclient_cmd(id, jointeam, team);
		return;
	}

	static msg_block, joinclass[] = "joinclass";
	msg_block = get_msg_block(menu_msgid);
	set_msg_block(menu_msgid, BLOCK_SET);
	engclient_cmd(id, jointeam, team);
	engclient_cmd(id, joinclass, class);
	set_msg_block(menu_msgid, msg_block);

	TrieGetArray(g_tSaveData, getUserKey(id), iStats[id], PLAYER_STATS);
	TrieGetArray(g_tSaveRoundData, getUserKey(id), g_StatsRound[id], PLAYER_STATS);

	set_task(0.2, "taskSetPlayerTeam", id);
}

public taskSetPlayerTeam(id) {
	if (!is_user_connected(id))
		return;

	if (hns_get_mode() == MODE_MIX || hns_get_state() == STATE_PAUSED) {
		if (iStats[id][PLR_STATS_STOPS] < g_iGameStops) {
			iStats[id][PLR_STATS_KILLS] -= g_StatsRound[id][PLR_STATS_KILLS]
			iStats[id][PLR_STATS_DEATHS] -= g_StatsRound[id][PLR_STATS_DEATHS]
			iStats[id][PLR_STATS_ASSISTS] -= g_StatsRound[id][PLR_STATS_ASSISTS]

			SetScoreInfo(id);
		} else {
			SetScoreInfo(id);
		}
	} else
		arrayset(iStats[id], 0, PLAYER_STATS);
}


public client_disconnected(id) {
	if ((iStats[id][PLR_TEAM] == TEAM_TERRORIST || iStats[id][PLR_TEAM] == TEAM_CT) && (hns_get_mode() == MODE_MIX || hns_get_state() == STATE_PAUSED)) {
		iStats[id][PLR_STATS_STOPS] = g_iGameStops;
	}
	TrieSetArray(g_tSaveData, getUserKey(id), iStats[id], PLAYER_STATS);
	TrieSetArray(g_tSaveRoundData, getUserKey(id), g_StatsRound[id], PLAYER_STATS);
}

public hns_match_reset_round() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "h");
	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		ResetPlayerRoundStats(iPlayer);
	}
}

public hns_match_started() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "h");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];
		arrayset(iStats[id], 0, PLAYER_STATS);
		arrayset(g_StatsRound[id], 0, PLAYER_STATS);
		SetScoreInfo(id);
	}

	for (new i; i < 10; i++) {
		best_auth[i] = "";
	}
}

public hns_ownage(iToucher, iTouched) {
	g_StatsRound[iToucher][PLR_STATS_OWNAGES]++;
	iStats[iToucher][PLR_STATS_OWNAGES]++;
}

public rgPlayerKilled(victim, attacker) {
	if (hns_get_mode() != MODE_MIX) {
		return;
	}
	
	if (is_user_connected(attacker) && victim != attacker) {
		g_StatsRound[attacker][PLR_STATS_KILLS]++;
		iStats[attacker][PLR_STATS_KILLS]++;
	}

	if (iLastAttacker[victim] && iLastAttacker[victim] != attacker) {
		g_StatsRound[iLastAttacker[victim]][PLR_STATS_ASSISTS]++;
		iStats[iLastAttacker[victim]][PLR_STATS_ASSISTS]++;
		iLastAttacker[victim] = 0;
	}
}

public rgPlayerTakeDamage(iVictim, iWeapon, iAttacker, Float:fDamage) { // Проверить не засчитывает ли урон по своим
	if (hns_get_mode() != MODE_MIX || hns_get_state() != STATE_ENABLED) {
		return;
	}

	if (is_user_alive(iAttacker) && iVictim != iAttacker) {
		new Float:fHealth; get_entvar(iVictim, var_health, fHealth);
		if (fDamage < fHealth) {
			iLastAttacker[iVictim] = iAttacker;
		}

		g_StatsRound[iAttacker][PLR_STATS_STABS]++;
		iStats[iAttacker][PLR_STATS_STABS]++;
	}
}

public rgPlayerFallDamage(id) {
	if (hns_get_mode() != MODE_MIX || hns_get_state() != STATE_ENABLED) {
		return;
	}

	new dmg = floatround(Float:GetHookChainReturn(ATYPE_FLOAT));

	if (rg_get_user_team(id) == TEAM_TERRORIST) {
		g_StatsRound[id][PLR_STATS_DMG_TT] += dmg;
		iStats[id][PLR_STATS_DMG_TT] += dmg;
	} else {
		g_StatsRound[id][PLR_STATS_DMG_CT] += dmg;
		iStats[id][PLR_STATS_DMG_CT] += dmg;
	}
}

public PlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha) {
	if (rg_get_user_team(index) == rg_get_user_team(attacker)) {
		return;
	}
	g_StatsRound[attacker][PLR_STATS_FLASHTIME] += fadeHold;
	iStats[attacker][PLR_STATS_FLASHTIME] += fadeHold;
}

public rgPlayerPreThink(id) {
	static Float:origin[3];
	static Float:velocity[3];
	static Float:last_updated[MAX_PLAYERS + 1];
	static Float:frametime;
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_velocity, velocity);

	frametime = get_gametime() - last_updated[id];
	if (frametime > 1.0) {
		frametime = 1.0;
	}

	if (hns_get_state() == STATE_ENABLED) {
		if (is_user_alive(id)) {
			if (rg_get_user_team(id) == TEAM_TERRORIST) {
				if (vector_length(velocity) * frametime >= get_distance_f(origin, last_position[id])) {
					velocity[2] = 0.0;
					if (vector_length(velocity) > 125.0) {
						g_StatsRound[id][PLR_STATS_RUNNED] += vector_length(velocity) * frametime;
						g_StatsRound[id][PLR_STATS_RUNTIME] += frametime;
						iStats[id][PLR_STATS_RUNNED] += vector_length(velocity) * frametime;
						iStats[id][PLR_STATS_RUNTIME] += frametime;
						if (g_StatsRound[id][PLR_STATS_RUNTIME]) {
							g_StatsRound[id][PLR_STATS_AVG_SPEED] = g_StatsRound[id][PLR_STATS_RUNNED] / g_StatsRound[id][PLR_STATS_RUNTIME];
							iStats[id][PLR_STATS_AVG_SPEED] = iStats[id][PLR_STATS_RUNNED] / iStats[id][PLR_STATS_RUNTIME];
						}
					}
				}

			}
		}
	}

	last_updated[id] = get_gametime();
	xs_vec_copy(origin, last_position[id]);
}

public rgRoundFreezeEnd() {
	set_task(0.25, "taskRoundEvent", .id = TASK_TIMER, .flags = "b");
}

public rgRestartRound() {
	remove_task(TASK_TIMER);
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "h");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];
		iStats[id][PLR_TEAM] = rg_get_user_team(id);
	}
}

public taskRoundEvent() {
	if (hns_get_state() != STATE_ENABLED || hns_get_mode() != MODE_MIX)
	{
		remove_task(TASK_TIMER);
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "aech", "TERRORIST");

	for (new i = 0; i < iNum; i++)
	{
		new id = iPlayers[i];
		g_StatsRound[id][PLR_STATS_SURVTIME] += 0.25;
		iStats[id][PLR_STATS_SURVTIME] += 0.25;
	}
}

public rgRoundEnd(WinStatus: status, ScenarioEventEndRound: event, Float:tmDelay) {
	remove_task(TASK_TIMER);
}

public rgRoundStart() {
	if (hns_get_mode() != MODE_MIX) {
		return;
	}
	
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
		arrayset(g_StatsRound[id], 0, PLAYER_STATS);
		arrayset(last_position[id], 0, 3);
	
		iLastAttacker[id] = 0;
	}
	
}

stock ResetPlayerRoundStats(id) {
	if (rg_get_user_team(id) == TEAM_TERRORIST)
		iStats[id][PLR_STATS_SURVTIME] -= g_StatsRound[id][PLR_STATS_SURVTIME];

	if (rg_get_user_team(id) == TEAM_TERRORIST || rg_get_user_team(id) == TEAM_CT) {
		iStats[id][PLR_STATS_STABS] -= g_StatsRound[id][PLR_STATS_STABS];
		iStats[id][PLR_STATS_DMG_CT] -= g_StatsRound[id][PLR_STATS_DMG_CT];
		iStats[id][PLR_STATS_RUNNED] -= g_StatsRound[id][PLR_STATS_RUNNED];
		iStats[id][PLR_STATS_FLASHTIME] -= g_StatsRound[id][PLR_STATS_FLASHTIME];

		iStats[id][PLR_STATS_KILLS] -= g_StatsRound[id][PLR_STATS_KILLS];
		iStats[id][PLR_STATS_DEATHS] -= g_StatsRound[id][PLR_STATS_DEATHS];
		iStats[id][PLR_STATS_ASSISTS] -= g_StatsRound[id][PLR_STATS_ASSISTS];
		SetScoreInfo(id);
	}
	g_iGameStops++;

	arrayset(g_StatsRound[id], 0, PLAYER_STATS);
}

stock SetScoreInfo(id) {
	set_entvar(id, var_frags, float(iStats[id][PLR_STATS_KILLS]));
	set_member(id, m_iDeaths, iStats[id][PLR_STATS_DEATHS]);
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

public hns_match_stopped_post() {
	client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "STATS_TOP", g_szPrefix);
	ShowTop(0);
}

public hns_match_surrendered() {
	client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "STATS_TOP", g_szPrefix);
	ShowTop(0);
}

public hns_match_finished() {
	client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "STATS_TOP", g_szPrefix);
	ShowTop(0);
}


public ShowTop(player) {
	if (!player) {
		new Float:best_time[10];
		new iPlayers[MAX_PLAYERS], iNum;
		get_players(iPlayers, iNum, "ch");
		new bid = 0;
		for (new i; i < iNum; i++) {
			new id = iPlayers[i];

			if (rg_get_user_team(id) == TEAM_SPECTATOR)
				continue;

			if (bid >= 10)
				break;

			get_user_authid(id, best_auth[bid], charsmax(best_auth[]));
			best_time[bid] = iStats[id][PLR_STATS_SURVTIME];
			bid++;
		}

		for (new i = 0; i < 10; i++) {
			for (new j = 0; j < 10; j++) {
				if (best_time[j] < best_time[i]) {
					new Float:tmp = best_time[i];
					new tmpauth[MAX_AUTHID_LENGTH];
					copy(tmpauth, charsmax(tmpauth), best_auth[i]);
					best_time[i] = best_time[j];
					best_time[j] = tmp;
					copy(best_auth[i], charsmax(best_auth[]), best_auth[j]);
					copy(best_auth[j], charsmax(best_auth[]), tmpauth);
				}
			}
		}
	}
	new szMotd[MAX_MOTD_LENGTH], iLen;
	iLen = formatex(szMotd, charsmax(szMotd), "<html><head><meta charset=UTF-8>\
					<link rel=^"stylesheet^" href=^"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css^">\
					</head>\
						<body>\
							<div id=^"wrapper^">\
								<table id=^"keywords^" cellspacing=^"0^" cellpadding=^"0^" class=^"table^">\
									<thead>\
										<tr>\
										<th>Player</th>\
										<th>SDA</th>\
										<th>Survive time</th>\
										<th>DMG</th>\
										<th>RUN</th>\
										<th>Flash time</th>\
										<th>Stabs</th>\
										</tr>\
									</thead>\
									<tbody>");
	new surv_time[24]; new flash_time[24];
	for (new i = 0; i < 10; i++) {
		new id = find_player_ex(FindPlayer_MatchAuthId, best_auth[i]);

		if (!is_user_connected(id))
			continue;

		fnConvertTime(iStats[id][PLR_STATS_SURVTIME], surv_time, 23);
		fnConvertTime(iStats[id][PLR_STATS_FLASHTIME], flash_time, 23);
		iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "<tr><td>%n</td><td>%.1f</td><td>%s</td><td>%.0f</td><td>%.1fK</td><td>%s</td><td>%d</td></tr>",
			id,
			(float(iStats[id][PLR_STATS_STABS]) + float(iStats[id][PLR_STATS_ASSISTS])) / float(iStats[id][PLR_STATS_DEATHS]),
			surv_time,
			iStats[id][PLR_STATS_DMG_TT] + iStats[id][PLR_STATS_DMG_CT],
			iStats[id][PLR_STATS_RUNNED] / 1000.0,
			flash_time,
			iStats[id][PLR_STATS_STABS]);
	}
	iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</tbody>\
								</table>\
							</div>\
						</body>\
						</html>");
	show_motd(player, szMotd);
	//log_to_file("motd.txt", szMotd);
}


public plugin_end() {
	TrieDestroy(g_tSaveData);
	TrieDestroy(g_tSaveRoundData);
}

stock getUserKey(id) {
	new szAuth[24];
	get_user_authid(id, szAuth, charsmax(szAuth));
	return szAuth;
}

stock fnConvertTime(Float:time, convert_time[], len, bool:with_intpart = true) {
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

	return PLUGIN_HANDLED;
}

public get_matchstats_str(MATCH_STATUS:iStatus) {
	new szOut[32];
	switch (iStatus) {
		case MATCH_CAPTAINPICK .. MATCH_CAPTAINKNIFE: {
			formatex(szOut, charsmax(szOut), "Captain mode");
		}
		case MATCH_TEAMPICK: {
			formatex(szOut, charsmax(szOut), "Team pick");
		}
		case MATCH_TEAMKNIFE: {
			formatex(szOut, charsmax(szOut), "Knife round");
		}
		case MATCH_MAPPICK: {
			formatex(szOut, charsmax(szOut), "Map pick");
		}
		case MATCH_WAITCONNECT: {
			formatex(szOut, charsmax(szOut), "Wait players");
		}
	}
	return szOut;
}