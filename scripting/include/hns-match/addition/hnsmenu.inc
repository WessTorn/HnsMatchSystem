#if defined _hnsmenu_included
  #endinput
#endif

#define _hnsmenu_included

public mainMatchMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id))
		return PLUGIN_HANDLED;

	static szMsg[128];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MIX_TITLE");
	new hMenu = menu_create(szMsg, "mainMatchMenuHandler");

	if (equali(g_iSettings[KNIFEMAP], g_szMapName)) {
		if (g_iCurrentMode == MODE_TRAINING && g_iMatchStatus == MATCH_NONE)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_CAP");
		else if (g_iMatchStatus == MATCH_CAPTAINPICK || g_iMatchStatus == MATCH_CAPTAINKNIFE || g_iMatchStatus == MATCH_TEAMPICK)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPCAP");
		else
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_NOTCAP");
	} else {
		if (g_iCurrentMode == MODE_PUB || g_iCurrentMode == MODE_DM || g_iCurrentMode == MODE_ZM)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPCUSTOM");
		else if (g_iCurrentMode == MODE_TRAINING && g_iMatchStatus <= MATCH_WAITCONNECT)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_MIX");
		else {
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPMIX");
		}
	}

	menu_additem(hMenu, szMsg, "1");


	if (equali(g_iSettings[KNIFEMAP], g_szMapName)) {
		if (g_iMatchStatus == MATCH_CAPTAINPICK || g_iMatchStatus == MATCH_CAPTAINKNIFE || g_iMatchStatus == MATCH_TEAMPICK)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_NOTSTARTKF");
		else if (g_iCurrentMode == MODE_KNIFE)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPKF");
		else
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STARTKF");
	} else {
		if (g_iCurrentMode == MODE_TRAINING)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_CUSTOM");
		else if (g_iCurrentMode == MODE_PUB || g_iCurrentMode == MODE_DM || g_iCurrentMode == MODE_ZM)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_BLEND");
		else {
			if (g_eMatchState != STATE_PAUSED)
				formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_PAUSE");
			else
				formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_UNPAUSE");
		}
	}
	
	menu_additem(hMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_SETTINGS");
	menu_additem(hMenu, szMsg, "3");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_RESTART");
	menu_additem(hMenu, szMsg, "4");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_SWAP");
	menu_additem(hMenu, szMsg, "5");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_TEAM");
	menu_additem(hMenu, szMsg, "6");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_MAP");
	menu_additem(hMenu, szMsg, "7");

	menu_display(id, hMenu, 0);

	return PLUGIN_HANDLED;
}

public mainMatchMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new iKey = str_to_num(szData);
	
	switch (iKey) {
		case 1: {
			if (equali(g_iSettings[KNIFEMAP], g_szMapName)) {
				if (g_iCurrentMode == MODE_TRAINING && g_iMatchStatus == MATCH_NONE)
					cmdCaptain(id);
				else if (g_iMatchStatus == MATCH_CAPTAINPICK || g_iMatchStatus == MATCH_CAPTAINKNIFE|| g_iMatchStatus == MATCH_TEAMPICK)
					cmdStop(id);
				else
					mainMatchMenu(id);
			} else {
				if (g_iCurrentMode == MODE_PUB || g_iCurrentMode == MODE_DM || g_iCurrentMode == MODE_ZM) {
					cmdStop(id);
				}
				else if (g_iCurrentMode == MODE_TRAINING && g_iMatchStatus <= MATCH_WAITCONNECT)
					cmdStartMatch(id);
				else {
					verifMenu(id);
				}
			}
		}
		case 2: {
			if (equali(g_iSettings[KNIFEMAP], g_szMapName)) {
				if (g_iMatchStatus == MATCH_CAPTAINPICK || g_iMatchStatus == MATCH_CAPTAINKNIFE || g_iMatchStatus == MATCH_TEAMPICK)
					mainMatchMenu(id);
				else if (g_iCurrentMode == MODE_KNIFE)
					cmdStop(id);
				else
					cmdKnifeRound(id);
			} else {
				if (g_iCurrentMode == MODE_TRAINING)
					customMenu(id);
				else if ((g_iCurrentMode == MODE_DM || g_iCurrentMode == MODE_PUB || g_iCurrentMode == MODE_ZM))
					cmdBlend(id);
				else {
					if (g_eMatchState != STATE_PAUSED)
						cmdStartPause(id);
					else
						cmdStopPause(id);
				}
			}
		}
		case 3: {
			settingsMatchMenu(id);
		}
		case 4: {
			cmdRestartRound(id);
		}
		case 5: {
			cmdSwapTeams(id);
		}
		case 6: {
			client_cmd(id, "amx_teammenu");
		}
		case 7: {
			client_cmd(id, "amx_mapmenu");
		}
	}

	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}

public customMenu(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MIX_TITLE");
	new hMenu = menu_create(szMsg, "customMenuHandler");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_CUSTOM_PUB");
	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_CUSTOM_DM");
	menu_additem(hMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "Zombie");
	menu_additem(hMenu, szMsg, "3");

	menu_display(id, hMenu, 0);
	return PLUGIN_HANDLED;
}

public customMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(hMenu);
	new iKey = str_to_num(szData);

	switch (iKey) {
		case 1: {
			cmdPubMode(id);
		}
		case 2: {
			cmdDMMode(id);
		}
		case 3: {
			cmdZMMode(id);
		}
	}
	return PLUGIN_HANDLED;
}

public settingsMatchMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id))
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MIX_TITLE");
	new hMenu = menu_create(szMsg, "settingsMatchMenuHandler");

	if (g_iCurrentMode == MODE_TRAINING)
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ROUNDTIME_TRNG");
	else
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ROUNDTIME", get_cvar_float("mp_roundtime"));

	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_FREEZETIME", get_cvar_num("mp_freezetime"));
	menu_additem(hMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_MAXROUND", g_iSettings[MAXROUNDS], g_iSettings[MAXROUNDS] * 2);
	menu_additem(hMenu, szMsg, "3");

	if (g_iSettings[ONEHPMODE] == 0)
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ONEHP_ON");
	else
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ONEHP_OFF");
	
	menu_additem(hMenu, szMsg, "4");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_FLASH", g_iSettings[FLASH]);
	menu_additem(hMenu, szMsg, "5");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_SMOKE", g_iSettings[SMOKE]);
	menu_additem(hMenu, szMsg, "6");

	menu_display(id, hMenu, 0);
	return PLUGIN_HANDLED;
}

public settingsMatchMenuHandler(id, hMenu, item) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		mainMatchMenu(id);
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

	new iKey = str_to_num(szData);
	switch (iKey) {
		case 1: {
			if (get_cvar_float("mp_roundtime") <= 2.5)
				set_cvar_float("mp_roundtime", 3.0);
			else if (get_cvar_float("mp_roundtime") <= 3.0)
				set_cvar_float("mp_roundtime", 3.5);
			else if (get_cvar_float("mp_roundtime") <= 3.5)
				set_cvar_float("mp_roundtime", 4.0);
			else if (get_cvar_float("mp_roundtime") >= 4.0)
				set_cvar_float("mp_roundtime", 2.5);

			settingsMatchMenu(id);
		}
		case 2: {
			if (get_cvar_num("mp_freezetime") == 0)
				set_cvar_num("mp_freezetime", 5);
			else if (get_cvar_num("mp_freezetime") <= 5)
				set_cvar_num("mp_freezetime", 10);
			else if (get_cvar_num("mp_freezetime") <= 10)
				set_cvar_num("mp_freezetime", 15);
			else if (get_cvar_num("mp_freezetime") >= 15)
				set_cvar_num("mp_freezetime", 0);

			settingsMatchMenu(id);
		}
		case 3: {
			if (g_iSettings[MAXROUNDS] <= 6)
				g_iSettings[MAXROUNDS] = 8;
			else if (g_iSettings[MAXROUNDS] <= 8)
				g_iSettings[MAXROUNDS] = 10;
			else if (g_iSettings[MAXROUNDS] >= 10)
				g_iSettings[MAXROUNDS] = 6;

			settingsMatchMenu(id);
		}
		case 4: {
			if (!g_iSettings[ONEHPMODE])
				g_iSettings[ONEHPMODE] = 1;
			else
				g_iSettings[ONEHPMODE] = 0;

			settingsMatchMenu(id);
		}
		case 5: {
			if (g_iSettings[FLASH] == 0)
				g_iSettings[FLASH] = 1;
			else if (g_iSettings[FLASH] <= 1)
				g_iSettings[FLASH] = 2;
			else if (g_iSettings[FLASH] <= 2)
				g_iSettings[FLASH] = 3;
			else if (g_iSettings[FLASH] >= 3)
				g_iSettings[FLASH] = 0;

			settingsMatchMenu(id);
		}
		case 6: {
			if (g_iSettings[SMOKE] <= 1)
				g_iSettings[SMOKE] = 2;
			else if (g_iSettings[SMOKE] >= 2)
				g_iSettings[SMOKE] = 1;

			settingsMatchMenu(id);
		}
	}

	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}


public verifMenu(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_VERIF_TITLE");
	new hMenu = menu_create(szMsg, "verifMenuHandler");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_NO");
	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_YES");
	menu_additem(hMenu, szMsg, "2");

	menu_display(id, hMenu, 0);
	return PLUGIN_HANDLED;
}

public verifMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			menu_destroy(hMenu);
			return PLUGIN_HANDLED;
		}
		case 1: {
			cmdStop(id);
		}
	}
	return PLUGIN_HANDLED;
}