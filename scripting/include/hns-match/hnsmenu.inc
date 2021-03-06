#if defined _hnsmenu_included
  #endinput
#endif

#define _hnsmenu_included

public mainMatchMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id))
		return;

	new iMenu = menu_create("\yHide'n'Seek mix system", "mainMatchMenuHandler");

	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		if (g_iCurrentMode != e_mCaptain && g_iCurrentMode != e_mKnife)
			menu_additem(iMenu, "Start captain mod", "1");
		else if (g_iCurrentMode == e_mKnife)
			menu_additem(iMenu, "\dStart captain mod", "1");
		else
			menu_additem(iMenu, "\rStop captain mod", "1");
	} else {
		if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			menu_additem(iMenu, "\dStart mix match", "1");
		else if (g_iCurrentMode == e_mTraining)
			menu_additem(iMenu, "Start mix match", "1");
		else {
			if (get_user_flags(id) & ADMIN_BAN)
				menu_additem(iMenu, "\rStop mix match", "1");
			else
				menu_additem(iMenu, "\dStop mix match", "1");
		}
	}


	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
			if (g_iCurrentMode == e_mKnife)
				menu_additem(iMenu, "\rStop Kniferound^n", "2");
			else if (g_iCurrentMode == e_mCaptain)
				menu_additem(iMenu, "\dStart Kniferound^n", "2");
			else
				menu_additem(iMenu, "Start Kniferound^n", "2");
		}
	} else {
		if (g_iCurrentMode == e_mTraining)
			menu_additem(iMenu, "Start custom mode^n", "2");
		else if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			menu_additem(iMenu, "\rStop custom mode^n", "2");
		else {
			if (g_iCurrentMode != e_mPaused)
				menu_additem(iMenu, "Pause match^n", "2");
			else
				menu_additem(iMenu, "Unpause match^n", "2");
		}
	}

	menu_additem(iMenu, "Mix system settings^n", "3");

	menu_additem(iMenu, "Restart round", "4");
	menu_additem(iMenu, "Swap teams^n", "5");
	menu_additem(iMenu, "Team Transfer Player", "6");
	menu_additem(iMenu, "Change map", "7");

	menu_display(id, iMenu);
}

public mainMatchMenuHandler(id, iMenu, item) {
	if (item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	new iKey = str_to_num(szData);

	switch (iKey) {
		case 1: {
			if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
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
					if (get_user_flags(id) & ADMIN_BAN)
						verifMenu(id);
					else
						client_print_color(id, print_team_blue, "%L", id, "HAS_NOT_STOP", prefix);
				}
			}
		}
		case 2: {
			if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
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
	return PLUGIN_HANDLED;
}

public customMenu(id) {
	if (!is_user_connected(id))
		return;

	new iMenu = menu_create("\yHide'n'Seek mix system", "customMenuHandler");

	menu_additem(iMenu, "Publick", "1");

	menu_additem(iMenu, "DeathMatch", "2");


	menu_display(id, iMenu, 0);
}

public customMenuHandler(id, iMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(iMenu);
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
	if (~get_user_flags(id) & access)
		return;

	if (!is_user_connected(id))
		return;

	new title[64];
	formatex(title, 63, "\yMix system settings");
	new iMenu = menu_create(title, "settingsMatchMenuHandler");
	new titleRoundtime[64];
	if (g_iCurrentMode == e_mTraining)
		formatex(titleRoundtime, 63, "Roundtime: \dcannot changed in training");
	else
		formatex(titleRoundtime, 63, "Roundtime: \y%.1f", get_cvar_float("mp_roundtime"));

	new titleFreeztime[64]; formatex(titleFreeztime, 63, "Freezetime: \y%d", get_cvar_num("mp_freezetime"));
	new titleWintime[64]; formatex(titleWintime, 63, "Wintime: \y%d", get_pcvar_num(g_eCvars[e_cCapTime]));

	new titleHP[64];
	if (get_pcvar_num(g_eCvars[e_cHpMode]) == 100)
		formatex(titleHP, 63, "1 HP Mode (Skill): \yOff^n");
	else
		formatex(titleHP, 63, "1 HP Mode (Skill): \yOn^n");

	new titleFlahs[64]; formatex(titleFlahs, 63, "Flash: \y%d", get_pcvar_num(g_eCvars[e_cFlashNum]));
	new titleSmoke[64]; formatex(titleSmoke, 63, "Smoke: \y%d^n", get_pcvar_num(g_eCvars[e_cSmokeNum]));
	new titleAA[64]; formatex(titleAA, 63, "Airaccelerate \y%d^n", get_pcvar_num(g_eCvars[e_cAA]));

	menu_additem(iMenu, titleRoundtime, "1");
	menu_additem(iMenu, titleFreeztime, "2");
	menu_additem(iMenu, titleWintime, "3");
	menu_additem(iMenu, titleHP, "4");

	menu_additem(iMenu, titleFlahs, "5");
	menu_additem(iMenu, titleSmoke, "6");

	menu_additem(iMenu, titleAA, "7");
	menu_display(id, iMenu, 0);
}

public settingsMatchMenuHandler(id, iMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		mainMatchMenu(id);
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
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
			if (get_pcvar_num(g_eCvars[e_cCapTime]) == 5)
				set_pcvar_num(g_eCvars[e_cCapTime], 10);
			else if (get_pcvar_num(g_eCvars[e_cCapTime]) == 10)
				set_pcvar_num(g_eCvars[e_cCapTime], 15);
			else if (get_pcvar_num(g_eCvars[e_cCapTime]) == 15)
				set_pcvar_num(g_eCvars[e_cCapTime], 20);
			else if (get_pcvar_num(g_eCvars[e_cCapTime]) >= 20)
				set_pcvar_num(g_eCvars[e_cCapTime], 5);

			settingsMatchMenu(id);
		}
		case 4: {
			if (get_pcvar_num(g_eCvars[e_cHpMode]) == 100)
				set_pcvar_num(g_eCvars[e_cHpMode], 1);
			else 
				set_pcvar_num(g_eCvars[e_cHpMode], 100);

			settingsMatchMenu(id);
		}
		case 5: {
			if (get_pcvar_num(g_eCvars[e_cFlashNum]) == 0)
				set_pcvar_num(g_eCvars[e_cFlashNum], 1);
			else if (get_pcvar_num(g_eCvars[e_cFlashNum]) == 1)
				set_pcvar_num(g_eCvars[e_cFlashNum], 2);
			else if (get_pcvar_num(g_eCvars[e_cFlashNum]) == 2)
				set_pcvar_num(g_eCvars[e_cFlashNum], 3);
			else if (get_pcvar_num(g_eCvars[e_cFlashNum]) >= 3)
				set_pcvar_num(g_eCvars[e_cFlashNum], 0);

			settingsMatchMenu(id);
		}
		case 6: {
			if (get_pcvar_num(g_eCvars[e_cSmokeNum]) == 1)
				set_pcvar_num(g_eCvars[e_cSmokeNum], 2);
			else if (get_pcvar_num(g_eCvars[e_cSmokeNum]) >= 2)
				set_pcvar_num(g_eCvars[e_cSmokeNum], 1);

			settingsMatchMenu(id);
		}
		case 7: {
			if (get_pcvar_num(g_eCvars[e_cAA]) < 100)
				cmdAa100(id);
			else
				cmdAa10(id);

			settingsMatchMenu(id);
		}
	}

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}


public verifMenu(id) {
	if (!is_user_connected(id))
		return;

	new iMenu = menu_create("\yVerification iMenu^n^n\dAre you sure you want to stop this mod:", "verifMenuHandler");

	menu_additem(iMenu, "No");
	menu_additem(iMenu, "Yes");

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, iMenu);
}

public verifMenuHandler(id, iMenu, item) {
	menu_destroy(iMenu);

	if (item == MENU_EXIT)
		return;

	switch (item) {
		case 0: {
			menu_destroy(iMenu);
			return;
		}
		case 1: {
			cmdStop(id);
		}
	}
}