#if defined _captain_included
  #endinput
#endif

#define _captain_included

stock chooseCapsMenu(id) {
	if (!is_user_connected(id))
		return;

	if (~get_user_flags(id) & access)
		return;

	if (g_iCurrentMode != e_mCaptain)
		return;

	new iMenu = menu_create("\yChoose captains", "chooseCapsHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "c");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		if (iPlayer == g_eCaptain[e_cTT] || iPlayer == g_eCaptain[e_cCT])
			continue;

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(iMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(iMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(iMenu, MPROP_SHOWPAGE, 0);
	menu_display(id, iMenu, 0);
}

public chooseCapsHandler(id, iMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(iMenu);
		return;
	}

	if (g_iCurrentMode != e_mCaptain) {
		menu_destroy(iMenu);
		return;
	}

	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		chooseCapsMenu(id);
		return;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(iMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		chooseCapsMenu(id);
		return;
	}

	if (g_bNoplay[iPlayer]) {
		chooseCapsMenu(id);
		return;
	}

	if (!g_eCaptain[e_cTT]) {
		g_eCaptain[e_cTT] = iPlayer;
		client_print_color(0, print_team_blue, "%L", id, "CAP_FIRST", prefix, iPlayer);

		chooseCapsMenu(id);
	} else if (!g_eCaptain[e_cCT]) {
		g_eCaptain[e_cCT] = iPlayer;
		client_print_color(0, print_team_blue, "%L", id, "CAP_SECOND", prefix, iPlayer);

		if (is_user_connected(g_eCaptain[e_cTT]) && is_user_connected(g_eCaptain[e_cCT])) {
			rg_set_user_team(g_eCaptain[e_cTT], TEAM_TERRORIST);
			rg_set_user_team(g_eCaptain[e_cCT], TEAM_CT);

			g_bCaptainsBattle = true;
			pfKnifeRound(0);
		} else {
			client_print_color(0, print_team_blue, "%L", id, "CAP_HAS_LEFT", prefix);
			resetCaptainData();
		}
	}
}

stock pickMenu(id) {
	new iMenu = menu_create("\yPick player", "pickHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "ce", "SPECTATOR");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(iMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(iMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(iMenu, MPROP_SHOWPAGE, false);
	menu_display(id, iMenu, 0);
}

public pickHandler(id, iMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(iMenu);
		return;
	}

	if (g_iCurrentMode != e_mCaptain) {
		menu_destroy(iMenu);
		return;
	}

	if (id != g_iCaptainPick) {
		menu_destroy(iMenu);
		return;
	}

	if (getUserTeam(id) == TEAM_SPECTATOR) {
		menu_destroy(iMenu);
		return;
	}

	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		pickMenu(id);
		return;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(iMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		pickMenu(id);
		return;
	}

	if (g_bNoplay[iPlayer]) {
		pickMenu(id);
		return;
	}

	client_print_color(0, print_team_blue, "%L", id, "PLAYER_CHOOSE", prefix, id, iPlayer);
	rg_set_user_team(iPlayer, getUserTeam(id));
	rg_round_respawn(iPlayer);

	g_iCaptainPick = id == g_eCaptain[e_cTT] ? g_eCaptain[e_cCT] : g_eCaptain[e_cTT];

	pickMenu(g_iCaptainPick);

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	new iTotalPlayers;
	for (new i; i < iNum; i++) {
		new tempid = iPlayers[i];

		if (getUserTeam(tempid) == TEAM_SPECTATOR) continue;

		iTotalPlayers++;
	}

	if (iTotalPlayers == 10) {
		resetCaptainData();
		client_print_color(0, print_team_blue, "%L", id, "TEAM_FULL", prefix);
	}
}

resetCaptainData() {
	g_iCaptainPick = 0;
	g_bCaptainsBattle = false;

	for (new i; i < sizeof(g_eCaptain); i++) {
		if (is_user_connected(g_eCaptain[i])) {
			show_menu(g_eCaptain[i], 0, "^n", 1);
		}

		g_eCaptain[i] = 0;
	}

	taskPrepareMode(e_mTraining);
}
