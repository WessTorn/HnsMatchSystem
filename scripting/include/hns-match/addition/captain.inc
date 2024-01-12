#if defined _captain_included
  #endinput
#endif

#define _captain_included

enum _:CaptainTeam_s {
	e_cTT,
	e_cCT
};
new g_eCaptain[CaptainTeam_s], g_iCaptainPick;

public captain_start(id) {
	resetCaptainData();

	g_iMatchStatus = MATCH_CAPTAINPICK;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");
	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (getUserTeam(iPlayer) == TEAM_SPECTATOR)
			continue;

		transferUserToSpec(iPlayer);
	}
	
	chooseCapsMenu(id);

	chat_print(0, "%L", LANG_PLAYER, "CAP_CHOOSE", id);
}

public chooseCapsMenu(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	if (g_iMatchStatus != MATCH_CAPTAINPICK)
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_CAP_CHOSE");
	new hMenu = menu_create(szMsg, "chooseCapsHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "ch");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		if (iPlayer == g_eCaptain[e_cTT] || iPlayer == g_eCaptain[e_cCT])
			continue;

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_ePlayerPtsData[iPlayer][e_bInit]) {
			new szPts[16];
			formatex(szPts, charsmax(szPts), "\d%d (%s) ", g_ePlayerPtsData[iPlayer][e_iPts], g_ePlayerPtsData[iPlayer][e_szRank]);
			add(szBuffer, charsmax(szBuffer), szPts);
		}

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(hMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(hMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(hMenu, MPROP_SHOWPAGE, 0);
	menu_display(id, hMenu, 0);
	return PLUGIN_HANDLED;
}

public chooseCapsHandler(id, hMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (g_iMatchStatus != MATCH_CAPTAINPICK) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		chooseCapsMenu(id);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(hMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		chooseCapsMenu(id);
		return PLUGIN_HANDLED;
	}

	if (g_bNoplay[iPlayer]) {
		chooseCapsMenu(id);
		return PLUGIN_HANDLED;
	}

	if (!g_eCaptain[e_cTT]) {
		g_eCaptain[e_cTT] = iPlayer;
		
		if (g_ePlayerPtsData[iPlayer][e_bInit])
			chat_print(0, "%L", LANG_PLAYER, "CAP_FIRST_PTS", iPlayer, g_ePlayerPtsData[iPlayer][e_iPts], g_ePlayerPtsData[iPlayer][e_szRank]);
		else
			chat_print(0, "%L", LANG_PLAYER, "CAP_FIRST", iPlayer);

		chooseCapsMenu(id);
	} else if (!g_eCaptain[e_cCT]) {
		g_eCaptain[e_cCT] = iPlayer;

		if (g_ePlayerPtsData[iPlayer][e_bInit])
			chat_print(0, "%L", LANG_PLAYER, "CAP_SECOND_PTS", iPlayer, g_ePlayerPtsData[iPlayer][e_iPts], g_ePlayerPtsData[iPlayer][e_szRank]);
		else
			chat_print(0, "%L", LANG_PLAYER, "CAP_SECOND", iPlayer);

		if (is_user_connected(g_eCaptain[e_cTT]) && is_user_connected(g_eCaptain[e_cCT])) {
			rg_set_user_team(g_eCaptain[e_cTT], TEAM_TERRORIST);
			rg_set_user_team(g_eCaptain[e_cCT], TEAM_CT);

			g_iMatchStatus = MATCH_CAPTAINKNIFE;

			kniferound_start();
		} else {
			chat_print(0, "%L", LANG_PLAYER, "CAP_HAS_LEFT");
			resetCaptainData();
		}
	}
	return PLUGIN_HANDLED;
}

public pickMenu(id) {
	if (!is_user_connected(id)) {
		return PLUGIN_HANDLED;
	}

	if (g_iMatchStatus != MATCH_TEAMPICK) {
		return PLUGIN_HANDLED;
	}

	if (id != g_iCaptainPick) {
		return PLUGIN_HANDLED;
	}

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_CAP_PICK");
	new hMenu = menu_create(szMsg, "pickHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "che", "SPECTATOR");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_ePlayerPtsData[iPlayer][e_bInit]) {
			new szPts[16];
			formatex(szPts, charsmax(szPts), "\d%d (%s) ", g_ePlayerPtsData[iPlayer][e_iPts], g_ePlayerPtsData[iPlayer][e_szRank]);
			add(szBuffer, charsmax(szBuffer), szPts);
		}

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(hMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(hMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(hMenu, MPROP_SHOWPAGE, false);
	menu_display(id, hMenu, 0);

	return PLUGIN_HANDLED;
}

public pickHandler(id, hMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (g_iMatchStatus != MATCH_TEAMPICK) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (id != g_iCaptainPick) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (getUserTeam(id) == TEAM_SPECTATOR) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		pickMenu(id);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(hMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		pickMenu(id);
		return PLUGIN_HANDLED;
	}

	if (g_bNoplay[iPlayer]) {
		pickMenu(id);
		return PLUGIN_HANDLED;
	}

	if (g_ePlayerPtsData[iPlayer][e_bInit])
		chat_print(0, "%L", LANG_PLAYER, "PLAYER_CHOOSE_PTS", id, iPlayer, g_ePlayerPtsData[iPlayer][e_iPts], g_ePlayerPtsData[iPlayer][e_szRank]);
	else
		chat_print(0, "%L", LANG_PLAYER, "PLAYER_CHOOSE", id, iPlayer);

	rg_set_user_team(iPlayer, getUserTeam(id));
	rg_round_respawn(iPlayer);

	g_iCaptainPick = id == g_eCaptain[e_cTT] ? g_eCaptain[e_cCT] : g_eCaptain[e_cTT];

	pickMenu(g_iCaptainPick);

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	new iTotalPlayers;
	for (new i; i < iNum; i++) {
		new tempid = iPlayers[i];

		if (getUserTeam(tempid) == TEAM_SPECTATOR) continue;

		iTotalPlayers++;
	}

	if (iTotalPlayers == 10) {
		resetCaptainData();
		chat_print(0, "%L", LANG_PLAYER, "TEAM_FULL");
		g_iMatchStatus = MATCH_TEAMKNIFE;
		kniferound_start();
	}

	return PLUGIN_HANDLED;
}

resetCaptainData() {
	g_iCaptainPick = 0;

	for (new i; i < sizeof(g_eCaptain); i++) {
		if (is_user_connected(g_eCaptain[i])) {
			show_menu(g_eCaptain[i], 0, "^n", 1);
		}

		g_eCaptain[i] = 0;
	}
}
