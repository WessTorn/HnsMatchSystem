#if defined _surrender_included
  #endinput
#endif

#define _surrender_included

#define surrenderTimeDelay 120
#define surrenderVoteTime 10

enum _:SurrenderVote {
	e_sYes,
	e_sNo
};
new g_eSurrenderVotes[SurrenderVote];
new bool:g_bSurrenderVoted[MAX_PLAYERS + 1];

public taskSurrender() {
	new id = g_eSurrenderData[e_sInitiator];
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", getUserTeam(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (!is_user_connected(id)) {
		resetSurrenderData();
		return;
	}

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
		resetSurrenderData();
		return;
	}

	if (getUserTeam(id) == TEAM_SPECTATOR) {
		resetSurrenderData();
		return;
	}

	if (iNum != g_eMatchInfo[e_mTeamSizeTT]) {
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderVotes[e_sYes] == g_eMatchInfo[e_mTeamSizeTT]) {
		autoLose(getUserTeam(id));
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderVotes[e_sNo] == g_eMatchInfo[e_mTeamSizeTT]) {
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderData[e_sFlTime] == surrenderVoteTime) {
		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			client_print_color(iPlayer, print_team_blue, "%L", id, "SUR_NEED", prefix, g_eMatchInfo[e_mTeamSizeTT], g_eMatchInfo[e_mTeamSizeTT]);
		}
		resetSurrenderData();
		return;
	}
	g_eSurrenderData[e_sFlTime]++;
}

stock surrenderMenu(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!getUserInMatch(id))
		return;

	new iPlayer = g_eSurrenderData[e_sInitiator];
	if (getUserTeam(id) != getUserTeam(iPlayer))
		return;

	new iMenu = menu_create(fmt("\ySurrender?^n\dVote by %n", iPlayer), "surrenderMenuHandler");

	menu_additem(iMenu, "Yes");
	menu_additem(iMenu, "No");

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, iMenu, 0);
}

public surrenderMenuHandler(id, iMenu, item) {
	menu_destroy(iMenu);
	if (!is_user_connected(id))
		return;

	if (item == MENU_EXIT)
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!getUserInMatch(id))
		return;

	new iPlayer = g_eSurrenderData[e_sInitiator];
	if (getUserTeam(id) != getUserTeam(iPlayer))
		return;

	if (g_bSurrenderVoted[id])
		return;

	g_eSurrenderVotes[item]++;
	g_bSurrenderVoted[id] = true;
}

resetSurrenderData() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];
		g_bSurrenderVoted[id] = false;
	}

	arrayset(g_eSurrenderVotes, 0, SurrenderVote);
	arrayset(g_eSurrenderData, 0, SurrenderData_s);
	remove_task();
}

autoLose(TeamName:iTeam) {
	client_print_color(0, print_team_blue, "%L", 0, "SUR_END", prefix, iTeam == TEAM_TERRORIST ? "TERRORISTS" : "CTS");
	setTaskHud(0, 0.0, 1, 255, 255, 0, 4.0, "Game Over");
	cmdStop(0);
}
