#if defined _showinfo_included
  #endinput
#endif

#define _showinfo_included

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
				set_hudmessage( .red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.20, .holdtime = 1.0);
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
					fnConvertTime(g_ePlayerInfo[id][e_plrSurviveTime], szTime, charsmax(szTime), false);
					formatex(szBuffer, charsmax(szBuffer), "Survive time: %s", szTime);
				}
			}
		}
	}
}

public ShowTop(player) {
	if (!player) {
		new Float:flBestTime[10];
		new iPlayers[MAX_PLAYERS], iNum;
		get_players(iPlayers, iNum, "c");
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
								</tr>\
							</thead>\
						<tbody>");
	new szSurvTime[24];
	for (new i = 0; i < 10; i++) {
		new id = find_player_ex(FindPlayer_MatchAuthId, g_iBestAuth[i]);

		if (!is_user_connected(id))
			continue;

		fnConvertTime(g_ePlayerInfo[id][e_plrSurviveTime], szSurvTime, 23);
		iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "<tr><td>%n</td><td>%s</td></tr>", id, szSurvTime);
	}
	iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</tbody>\
								</table>\
							</div>\
						</body>\
						</html>");
	show_motd(player, szMotd);
	//log_to_file("motd.txt", szMotd);
}
