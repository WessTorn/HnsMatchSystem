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

	if (equali(knifemap, g_szMapName)) {
		if (g_iCurrentMode != e_mCaptain && g_iCurrentMode != e_mKnife)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_CAP");
		else if (g_iCurrentMode == e_mKnife)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_NOTCAP");
		else
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPCAP");
	} else {
		if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_NOTSTART");
		else if (g_iCurrentMode == e_mTraining)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_MIX");
		else {
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPMIX");
		}
	}

	menu_additem(hMenu, szMsg, "1");


	if (equali(knifemap, g_szMapName)) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
			if (g_iCurrentMode == e_mKnife)
				formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPKF");
			else if (g_iCurrentMode == e_mCaptain)
				formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_NOTSTARTKF");
			else
				formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STARTKF");
		}
	} else {
		if (g_iCurrentMode == e_mTraining)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_CUSTOM");
		else if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MAIN_STOPCUSTOM");
		else {
			if (g_iCurrentMode != e_mPaused)
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
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	
	new iKey = str_to_num(szData);
	switch (iKey) {
		case 1: {
			if (equali(knifemap, g_szMapName)) {
				if (g_iCurrentMode != e_mCaptain && g_iCurrentMode != e_mKnife)
					cmdCaptain(id);
				else if (g_iCurrentMode == e_mKnife)
					cmdCaptain(id);
				else
					cmdStop(id);
			} else {
				if ((g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)) {
					return 0;
				}
				else if (g_iCurrentMode == e_mTraining)
					cmdStartRound(id);
				else {
					verifMenu(id);
				}
			}
		}
		case 2: {
			if (equali(knifemap, g_szMapName)) {
				if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
					if (g_iCurrentMode == e_mKnife)
						cmdStop(id);
					else
						cmdKnifeRound(id);
				}
			} else {
				if (g_iCurrentMode == e_mTraining)
					customMenu(id);
				else if ((g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM))
					cmdStop(id);
				else {
					if (g_iCurrentMode != e_mPaused)
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
	}
	return PLUGIN_HANDLED;
}

public settingsMatchMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id))
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_MIX_TITLE");
	new hMenu = menu_create(szMsg, "settingsMatchMenuHandler");

	if (g_iCurrentMode == e_mTraining)
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ROUNDTIME_TRNG");
	else
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ROUNDTIME", get_cvar_float("mp_roundtime"));

	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_FREEZETIME", get_cvar_num("mp_freezetime"));
	menu_additem(hMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_MAXROUND", get_max_rounds());
	menu_additem(hMenu, szMsg, "3");

	if (get_hp_mode() == 100)
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ONEHP_ON");
	else
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_ONEHP_OFF");
	
	menu_additem(hMenu, szMsg, "4");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_FLASH", get_flash_num());
	menu_additem(hMenu, szMsg, "5");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_SMOKE", get_smoke_num());
	menu_additem(hMenu, szMsg, "6");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_STNGS_AA", get_aa_mode());
	menu_additem(hMenu, szMsg, "7");

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
			if (get_cvar_float("mp_roundtime") == 2.5)
				set_cvar_float("mp_roundtime", 3.0);
			else if (get_cvar_float("mp_roundtime") == 3.0)
				set_cvar_float("mp_roundtime", 3.5);
			else if (get_cvar_float("mp_roundtime") == 3.5)
				set_cvar_float("mp_roundtime", 4.0);
			else if (get_cvar_float("mp_roundtime") >= 4.0)
				set_cvar_float("mp_roundtime", 2.5);

			settingsMatchMenu(id);
		}
		case 2: {
			if (get_cvar_num("mp_freezetime") == 0)
				set_cvar_num("mp_freezetime", 5);
			else if (get_cvar_num("mp_freezetime") == 5)
				set_cvar_num("mp_freezetime", 10);
			else if (get_cvar_num("mp_freezetime") == 10)
				set_cvar_num("mp_freezetime", 15);
			else if (get_cvar_num("mp_freezetime") >= 15)
				set_cvar_num("mp_freezetime", 0);

			settingsMatchMenu(id);
		}
		case 3: {
			if (get_max_rounds() <= 6)
				set_max_rounds(8);
			else if (get_max_rounds() == 8)
				set_max_rounds(10);
			else if (get_max_rounds() >= 10)
				set_max_rounds(6);

			settingsMatchMenu(id);
		}
		case 4: {
			if (get_hp_mode() == 100)
				set_hp_mode(1);
			else
				set_hp_mode(100);

			settingsMatchMenu(id);
		}
		case 5: {
			if (get_flash_num() == 0)
				set_flash_num(1);
			else if (get_flash_num() == 1)
				set_flash_num(2);
			else if (get_flash_num() == 2)
				set_flash_num(3);
			else if (get_flash_num() >= 3)
				set_flash_num(0);

			settingsMatchMenu(id);
		}
		case 6: {
			if (get_smoke_num() == 1)
				set_smoke_num(2);
			else if (get_smoke_num() >= 2)
				set_smoke_num(1);

			settingsMatchMenu(id);
		}
		case 7: {
			if (get_aa_mode() < 100)
				cmdAa100(id);
			else
				cmdAa10(id);

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

public trainingMenu(id) {
	if (!is_user_connected(id) || g_iCurrentMode != e_mTraining)
		return PLUGIN_HANDLED;

	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_TITLE");
	new hMenu = menu_create(szMsg, "trainingMenuHandler");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_CPNT");
	menu_additem(hMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_TLPRT");
	menu_additem(hMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_NOCLIP");
	menu_additem(hMenu, szMsg, "3");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_RESPAWN");
	menu_additem(hMenu, szMsg, "4");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "MENU_TRNING_DAMAGE");
	menu_additem(hMenu, szMsg, "5");

	menu_display(id, hMenu, 0);

	return PLUGIN_HANDLED;
}

public trainingMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	new iKey = str_to_num(szData);

	switch (iKey) {
		case 1: {
			cmdCheckpoint(id);
			trainingMenu(id);
		}
		case 2: {
			cmdGoCheck(id);
			trainingMenu(id);
		}
		case 3: {
			cmdClipMode(id);
			trainingMenu(id);
		}
		case 4: {
			cmdRespawn(id);
			trainingMenu(id);
		}
		case 5: {
			cmdShowDamage(id);
			trainingMenu(id);
		}
	}
	
	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}