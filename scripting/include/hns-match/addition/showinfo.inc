#if defined _showinfo_included
  #endinput
#endif

#define _showinfo_included

addStats() {
	for (new i = 1; i <= MaxClients; i++) {
		arrayset(iStats[i], 0, STATS_PLAYER);
	}

	for(new i; i < 10; i++) {
		g_iBestAuth[i] = "";
	}
}

public task_ShowPlayerInfo() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum);

	for(new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if(is_user_alive(iPlayer)) {
			if(g_iCurrentMode == e_mMatch) {
				new szTime[24];
				fnConvertTime(iStats[iPlayer][e_flSurviveTime], szTime, charsmax(szTime), false);
				set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.20, .holdtime = 1.0);
				ShowSyncHudMsg(iPlayer, g_MsgSync, "Survive time: %s", szTime);
			}
			continue;
		}

		for(new j = 1; j <= MaxClients; j++) {
			new id = j;

			if(!is_user_alive(id))
				continue;

			if(get_entvar(iPlayer, var_iuser2) == id) {
				new szTime[24], szBuffer[64];

				if(g_iCurrentMode == e_mMatch) {
					fnConvertTime(iStats[id][e_flSurviveTime], szTime, charsmax(szTime), false);
					formatex(szBuffer, charsmax(szBuffer), "Survive time: %s^nStabs: %d", szTime, iStats[id][e_iStabs]);
				}

				set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.20, .holdtime = 1.0);
				#if defined USE_PTS
					ShowSyncHudMsg(iPlayer, g_MsgSync, "Player: %n (#%d)^n\
						%s^n\
						PTS: %d^n\
						Wins: %d / Loss: %d",
						id, hns_pts_get_player_info(id, rank),
						g_iCurrentMode == e_mMatch ? szBuffer : "",
						hns_pts_get_player_info(id, pts),
						hns_pts_get_player_info(id, wins), hns_pts_get_player_info(id, loss));
				#else
					ShowSyncHudMsg(iPlayer, g_MsgSync, "Player: %n^n\
						%s",
						id,
						g_iCurrentMode == e_mMatch ? szBuffer : "");
				#endif

			}
		}
	}
}

public ShowTop(player) {
	if (!player) {
		new Float:flBestTime[10];
		new iPlayers[MAX_PLAYERS], iNum;
		get_players(iPlayers, iNum, "ch");
		new iBid = 0;
		for (new i; i < iNum; i++) {
			new id = iPlayers[i];

			if (getUserTeam(id) == TEAM_SPECTATOR)
				continue;

			if (iBid >= 10)
				break;

			get_user_authid(id, g_iBestAuth[iBid], charsmax(g_iBestAuth[]));
			flBestTime[iBid] = iStats[id][e_flSurviveTime];
			iBid++;
		}

		for (new i = 0; i < 10; i++) {
			for (new j = 0; j < 10; j++) {
				if (flBestTime[j] < flBestTime[i]) {
					new Float:flTmp = flBestTime[i];
					new szTmpAuth[MAX_AUTHID_LENGTH];
					copy(szTmpAuth, charsmax(szTmpAuth), g_iBestAuth[i]);
					flBestTime[i] = flBestTime[j];
					flBestTime[j] = flTmp;
					copy(g_iBestAuth[i], charsmax(g_iBestAuth[]), g_iBestAuth[j]);
					copy(g_iBestAuth[j], charsmax(g_iBestAuth[]), szTmpAuth);
				}
			}
		}
	}

	new szMotd[MAX_MOTD_LENGTH], iLen;
	iLen = formatex(szMotd, charsmax(szMotd), "<html><head> \
							<meta charset=UTF-8> \
							<style> \
							body { font-family: sans-serif } \
							table { margin: auto; text-align: center; border: 2px solid #007bff!important; border-radius: .88rem; } \
							.table td { padding: .75rem; vertical-align: top; border-top: 1px solid #dee2e6; } \
							.table th { padding: .75rem; } \
							</style></head><body><div class=^"card border-primary^">\
           					<table class=^"table table-hover^">\
                			<thead class=^"text-center^"><tr>\
							<th>Player</th>\
							<th>Survive time</th>\
							<th>Stabs</th>\
							<th>Damaged</th>\
							<th>Flashed</th>\
							<th>Run</th>\
						</tr></thead><tbody>");
	new szSurvTime[24];
	new szTimeFlash[24];
	for (new i = 0; i < 10; i++) {
		new id = find_player_ex(FindPlayer_MatchAuthId, g_iBestAuth[i]);

		if (!is_user_connected(id))
			continue;

		fnConvertTime(iStats[id][e_flSurviveTime], szSurvTime, charsmax(szSurvTime), false);
		fnConvertTime(iStats[id][e_flFlashedTime], szTimeFlash, charsmax(szTimeFlash), false);
		iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "<tr>\
		<td>%n</td>\
		<td>%s</td>\
		<td>%d</td>\
		<td>%.0f</td>\
		<td>%s</td>\
		<td>%.1fK</td></tr>", id, szSurvTime, iStats[id][e_iStabs], iStats[id][e_flDmg], szTimeFlash, iStats[id][e_flRunDistance] / 1000);
	}
	iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</tbody>\
								</table>\
							</div>\
						</body>\
						</html>");
	show_motd(player, szMotd);
}
