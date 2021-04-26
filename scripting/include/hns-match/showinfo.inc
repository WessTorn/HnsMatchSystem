#if defined _showinfo_included
  #endinput
#endif

#define _showinfo_included

new Float:flLastOrigin[MAX_PLAYERS + 1][3];
new bool:bHiding[MAX_PLAYERS + 1];
new iStats[MAX_PLAYERS + 1][RoundInfo_s];

stock statsDmg(id) {
	new Float:flDamage = GetHookChainReturn(ATYPE_FLOAT);
	g_eRoundInfo[id][e_flDmg] += flDamage;
}

stock statsFlashedTime(attacker, Float:fadeHold) {
	g_eRoundInfo[attacker][e_flFlashedTime] += fadeHold;
}

stock statsStabs(attacker) {
	iStats[attacker][e_iStabs]++;
}

stock lastOrigin(id) {
	get_entvar(id, var_origin, flLastOrigin[id]);
}

public task_MainThink() {
	if(g_iCurrentMode != e_mMatch)
		return;

	if (g_bFreezePeriod)
		return;
	
	new TTPlayers[32], iTTNum;
	get_players(TTPlayers, iTTNum, "ache", "TERRORIST");
	new CTPlayers[32], iCTNum;
	get_players(CTPlayers, iCTNum, "ache", "CT");
	for (new i = 0; i < iTTNum; i++) {
		new tt = TTPlayers[i];
		new Float:origin[3];
		get_entvar(tt, var_origin, origin);
		g_eRoundInfo[tt][e_flRunDistance] += get_distance_f(origin, flLastOrigin[tt]);
		flLastOrigin[tt] = origin;
		new bool:found	= false;
		for (new j = 0; j < iCTNum; j++) {
			new ct = CTPlayers[j];
			if (fm_is_ent_visible(ct, tt) && fm_is_in_viewcone(ct, origin)) {
				if (bHiding[tt]) {
					g_eRoundInfo[ct][e_iFound]++;
				}
				found = true;
				bHiding[tt]	= false;
				break;
			}
		}
		if (!found)
			bHiding[tt] = true;

		if (bHiding[tt]) {
			g_eRoundInfo[tt][e_flHideTime] += 2.5;
		}
	}
}

public statsGetArray(id) {
	TrieGetArray(g_tPlayerInfo, getUserKey(id), iStats[id], RoundInfo_s);
}

public statsSetArray(id) {
	TrieSetArray(g_tPlayerInfo, getUserKey(id), iStats[id], RoundInfo_s);
}

statsApply() {
	apply_stats();
}

addStats() {
	for (new i = 1; i <= MaxClients; i++) {
		arrayset(iStats[i], 0, RoundInfo_s);
	}

	for(new i; i < 10; i++) {
		g_iBestAuth[i] = "";
	}
}

public apply_stats() {
	new TTPlayers[32], iTTNum;
	get_players(TTPlayers, iTTNum, "che", "TERRORIST");
	new CTPlayers[32], iCTNum;
	get_players(CTPlayers, iCTNum, "che", "CT");
	for (new i = 0; i < iTTNum; i++) {
		new id = TTPlayers[i];
		iStats[id][e_flSurviveTime]	= g_ePlayerInfo[id][e_plrSurviveTime];
		iStats[id][e_flDmg] += g_eRoundInfo[id][e_flDmg];
		iStats[id][e_flRunDistance] += g_eRoundInfo[id][e_flRunDistance];
		iStats[id][e_flFlashedTime] += g_eRoundInfo[id][e_flFlashedTime];
		iStats[id][e_flHideTime] += g_eRoundInfo[id][e_flHideTime];
		iStats[id][e_iFound] += g_eRoundInfo[id][e_iFound];
		arrayset(g_eRoundInfo[id], 0, RoundInfo_s);
	}

	for (new i = 0; i < iCTNum; i++) {
		new id = CTPlayers[i];
		iStats[id][e_flSurviveTime]	= g_ePlayerInfo[id][e_plrSurviveTime];
		iStats[id][e_flDmg] += g_eRoundInfo[id][e_flDmg];
		iStats[id][e_flRunDistance] += g_eRoundInfo[id][e_flRunDistance];
		iStats[id][e_flFlashedTime] += g_eRoundInfo[id][e_flFlashedTime];
		iStats[id][e_flHideTime] += g_eRoundInfo[id][e_flHideTime];
		iStats[id][e_iFound] += g_eRoundInfo[id][e_iFound];
		arrayset(g_eRoundInfo[id], 0, RoundInfo_s);
	}
}

public task_ShowPlayerInfo() {
	if(g_iCurrentMode != e_mMatch)
		return;
	
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum);
	
	for(new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		
		if(is_user_alive(iPlayer)) {
			if(g_iCurrentMode == e_mMatch) {
				new szTime[24];
				fnConvertTime(g_ePlayerInfo[iPlayer][e_plrSurviveTime], szTime, charsmax(szTime), false);
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
				new szTimeFlash[24], szBuffer2[64];

				if(g_iCurrentMode == e_mMatch) {
					fnConvertTime(g_ePlayerInfo[id][e_plrSurviveTime], szTime, charsmax(szTime), false);
					formatex(szBuffer, charsmax(szBuffer), "Survive time: %s", szTime);

					fnConvertTime(iStats[id][e_flFlashedTime], szTimeFlash, charsmax(szTimeFlash), false);
					formatex(szBuffer2, charsmax(szBuffer2), "Damaged: %.0fHP^n\
						Flashed: %s^n\
						Found TT: %d^n\
						Stabs: %d^n\
						Run: %.1fK",
						iStats[id][e_flDmg],
						szTimeFlash,
						iStats[id][e_iFound],
						iStats[id][e_iStabs],
						iStats[id][e_flRunDistance] / 1000);
				}

				set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.20, .holdtime = 1.0);
				ShowSyncHudMsg(iPlayer, g_MsgSync, "Player: %n^n\
					%s^n\
					%s",
					id,
					g_iCurrentMode == e_mMatch ? szBuffer : "",
					g_iCurrentMode == e_mMatch ? szBuffer2 : "");
			}
		}
	}
}

public ShowTop(player) {
	if (!player) {
		apply_stats();
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
			flBestTime[iBid] = g_ePlayerInfo[id][e_plrSurviveTime];
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
	iLen = formatex(szMotd, charsmax(szMotd), "<html>\
						<head>\
							<meta charset=^"utf-8^"> \
							<style type=^"text/css^"> \
							table { \
								width:600px; \
								font-family:Arial, Helvetica, sans-serif; \
								color:#666; \
								font-size:12px; \
								text-shadow: 1px 1px 0px #fff; \
								margin:0 auto; \
								border:#ccc 1px solid; \
								-webkit-box-shadow: 2px 2px 3px -1px rgba(0,0,0,0.35); \
							} \
							table th { \
								padding:21px 25px 22px 25px; \
								border-top:1px solid #fafafa; \
								border-bottom:1px solid #e0e0e0; \
								background: #ededed; \
							} \
							table th:first-child{ \
								text-align: left; \
								padding-left:20px; \
							} \
							table tr{ \
								text-align: center; \
								padding-left:20px; \
							} \
							table tr td:first-child{ \
								text-align: left; \
								padding-left:20px; \
							} \
							table tr td { \
								padding:18px; \
								border-top: 1px solid #ffffff; \
								border-bottom:1px solid #e0e0e0; \
								border-left: 1px solid #e0e0e0; \
								background: #fafafa; \
							} \
						</style> \
						</head>\
						<body>\
							<div>\
							<table cellspacing=^"0^">\
							<thead>\
								<tr>\
									<th>Player</th>\
									<th>Survive time</th>\
									<th>Damaged</th>\
									<th>Hide time</th>\
									<th>Flashed</th>\
									<th>Found TT</th>\
									<th>Stabs</th>\
									<th>Run</th>\
								</tr>\
							</thead>\
						<tbody>");
	new szSurvTime[24];
	new szTimeFlash[24];
	new szHideTime[24];
	for (new i = 0; i < 10; i++) {
		new id = find_player_ex(FindPlayer_MatchAuthId, g_iBestAuth[i]);

		if (!is_user_connected(id))
			continue;

		fnConvertTime(iStats[id][e_plrSurviveTime], szSurvTime, charsmax(szSurvTime), false);
		fnConvertTime(iStats[id][e_flFlashedTime], szTimeFlash, charsmax(szTimeFlash), false);
		fnConvertTime(iStats[id][e_flHideTime], szHideTime, charsmax(szHideTime), false);
		iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "<tr><td>%n</td><td>%s</td><td>%.0f</td><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%.1fK</td></tr>", id, szSurvTime, iStats[id][e_flDmg],szHideTime, szTimeFlash, iStats[id][e_iFound], iStats[id][e_iStabs], iStats[id][e_flRunDistance] / 1000);
	}
	iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</tbody>\
								</table>\
							</div>\
						</body>\
						</html>");
	show_motd(player, szMotd);
	log_to_file("motd.txt", szMotd);
}
