#if defined _message_included
  #endinput
#endif

#define _message_included

new iNumPlayers;

stock message_init() {
	register_message(get_user_msgid("HostagePos"), "msgHostagePos");
	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");
	register_message(get_user_msgid("HideWeapon"), "msgHideWeapon");
	

	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET);
}

public msgHostagePos(msgid, dest, id) {
	return PLUGIN_HANDLED;
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

public msgHideWeapon(msgid, dest, id) {
	const money = (1 << 5);
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | money);
}

bool:shouldAutoJoin(id) {
	return (!get_user_team(id) && !task_exists(id));
}

setForceTeamJoinTask(id, menu_msgid) {
	static param_menu_msgid[2];
	param_menu_msgid[0] = menu_msgid;

	setPlayerStats(id);

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "e", iStats[id][e_szSaveTeam]);
	iNumPlayers = iNum;

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

	//setPlayerStats(id);

	set_task(0.2, "taskSetPlayerTeam", id);
}

public taskSetPlayerTeam(id) {
	if (!is_user_connected(id))
		return;

	switch(g_iCurrentMode) {
		case e_mMatch, e_mPaused: {
			if (iStats[id][isPlrInMatch]) {
				if (iNumPlayers < g_eMatchInfo[e_mTeamSizeTT]) {
					rg_set_user_team(id, iStats[id][e_szSaveTeam][0] == 'T' ? TEAM_TERRORIST : TEAM_CT);

					if (g_iCurrentMode == e_mPaused)
						rg_round_respawn(id);

					console_print(0, "Player %n joined!", id);
					chat_print(0, "Player %n joined!", id);

				} else {
					iStats[id][isPlrInMatch] = false;
					transferUserToSpec(id);
					return;
				}
			} else {
				transferUserToSpec(id);
				return;
			}
		}
		case e_mKnife, e_mCaptain: {
			transferUserToSpec(id);
			return;
		}
		case e_mTraining: {
			if (equali(g_szMapName, knifemap)) {
				rg_round_respawn(id);
				if (is_check_play()) {
					g_bNoplay[id] = true;
					set_task(2.0, "taskPlay", id);
				}
				return;
			}

			if (g_bPlayersListLoaded) {
				if (!checkPlayer(id))
					transferUserToSpec(id);
				else
					rg_round_respawn(id);
			}
			else
				rg_round_respawn(id);
		}
	}
}

public taskPlay(id) {
	if (!is_user_connected(id))
		return;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_VERIF_TITLE");
	new hMenu = menu_create(szMsg, "handlePlayMenu");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_YES");
	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_NO");
	menu_additem(hMenu, szMsg, "2");

	menu_display(id, hMenu, 0);
}

public handlePlayMenu(id, hMenu, item) {
	if (!is_user_connected(id))
		return;

	if (item == MENU_EXIT)
		return;

	menu_destroy(hMenu);

	switch (item) {
		case 0: cmdPlay(id);
		case 1: chat_print(0, "%L", 0, "STATUS_NOPLAY", id);
	}
}