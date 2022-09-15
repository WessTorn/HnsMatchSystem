#if defined _message_included
  #endinput
#endif

#define _message_included

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
	set_task(0.1, "taskSetPlayerTeam", id);
}


public taskSetPlayerTeam(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode >= e_mPaused && g_iCurrentMode != e_mPublic && g_iCurrentMode != e_mDM) {
		transferUserToSpec(id);
		return;
	}

	if (g_iCurrentMode == e_mTraining) {
		if (equali(g_eMatchInfo[e_mMapName], knifemap)) {
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

stock bool:checkPlayer(id) {
	new eTempPlayer[PlayersLoad_s], iSize = ArraySize(g_aPlayersLoadData);
	new szAuth[24]; get_user_authid(id, szAuth, charsmax(szAuth));
	for (new i; i < iSize; i++) {
		ArrayGetArray(g_aPlayersLoadData, i, eTempPlayer);
		if (equal(szAuth, eTempPlayer[e_pAuth])) {
			rg_set_user_team(id, eTempPlayer[e_pTeam]);
			return true;
		}
	}
	return false;
}

public taskPlay(id) {
	if (!is_user_connected(id))
		return;

	new iMenu = menu_create("\rYou play?", "handlePlayMenu");

	menu_additem(iMenu, "Yes");
	menu_additem(iMenu, "No");

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, iMenu, 0);
}

public handlePlayMenu(id, iMenu, item) {
	if (!is_user_connected(id))
		return;

	if (item == MENU_EXIT)
		return;

	menu_destroy(iMenu);

	switch (item) {
		case 0: cmdPlay(id);
		case 1: chat_print(0, "%L", id, "STATUS_NOPLAY", getUserName(id));
	}
}