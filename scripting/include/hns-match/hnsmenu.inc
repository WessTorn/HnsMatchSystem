#if defined _hnsmenu_included
  #endinput
#endif

#define _hnsmenu_included

public mainMatchMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id))
		return;

	new hMenu = menu_create("\yHide'n'Seek mix system", "mainMatchMenuHandler");

	if (equali(g_eCvars[e_cKnifeMap], g_eMatchInfo[e_mMapName])) {
		if (g_iCurrentMode != e_mCaptain && g_iCurrentMode != e_mKnife)
			menu_additem(hMenu, "Start captain mod", "1");
		else if (g_iCurrentMode == e_mKnife)
			menu_additem(hMenu, "\dStart captain mod", "1");
		else
			menu_additem(hMenu, "\rStop captain mod", "1");
	} else {
		if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			menu_additem(hMenu, "\dStart mix match", "1");
		else if (g_iCurrentMode == e_mTraining)
			menu_additem(hMenu, "Start mix match", "1");
		else {
			if (get_user_flags(id) & ADMIN_BAN)
				menu_additem(hMenu, "\rStop mix match", "1");
			else
				menu_additem(hMenu, "\dStop mix match", "1");
		}
	}


	if (equali(g_eCvars[e_cKnifeMap], g_eMatchInfo[e_mMapName])) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
			if (g_iCurrentMode == e_mKnife)
				menu_additem(hMenu, "\rStop Kniferound^n", "2");
			else if (g_iCurrentMode == e_mCaptain)
				menu_additem(hMenu, "\dStart Kniferound^n", "2");
			else
				menu_additem(hMenu, "Start Kniferound^n", "2");
		}
	} else {
		if (g_iCurrentMode == e_mTraining)
			menu_additem(hMenu, "Start custom mode^n", "2");
		else if (g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM)
			menu_additem(hMenu, "\rStop custom mode^n", "2");
		else {
			if (g_iCurrentMode != e_mPaused)
				menu_additem(hMenu, "Pause match^n", "2");
			else
				menu_additem(hMenu, "Unpause match^n", "2");
		}
	}

	menu_additem(hMenu, "Mix system settings^n", "3");

	menu_additem(hMenu, "Restart round", "4");
	menu_additem(hMenu, "Swap teams^n", "5");
	menu_additem(hMenu, "Team Transfer Player", "6");
	menu_additem(hMenu, "Change map", "7");

	menu_display(id, hMenu, 0);
}

public mainMatchMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	new iKey = str_to_num(szData);

	switch (iKey) {
		case 1: {
			if (equali(g_eCvars[e_cKnifeMap], g_eMatchInfo[e_mMapName])) {
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
			if (equali(g_eCvars[e_cKnifeMap], g_eMatchInfo[e_mMapName])) {
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

	new hMenu = menu_create("\yHide'n'Seek mix system", "customMenuHandler");

	menu_additem(hMenu, "Publick", "1");

	menu_additem(hMenu, "DeathMatch", "2");


	menu_display(id, hMenu, 0);
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
		return;

	new title[64];
	formatex(title, 63, "\yMix system settings");
	new hMenu = menu_create(title, "settingsMatchMenuHandler");
	new titleRoundtime[64];
	if (g_iCurrentMode == e_mTraining)
		formatex(titleRoundtime, 63, "Roundtime: \dcannot changed in training");
	else
		formatex(titleRoundtime, 63, "Roundtime: \y%.1f", get_cvar_float("mp_roundtime"));

	new titleFreeztime[64]; formatex(titleFreeztime, 63, "Freezetime: \y%d", get_cvar_num("mp_freezetime"));

	new titleTimeRound[64]; 
	
	if (g_iCurrentRules == e_mTimer) 
		formatex(titleTimeRound, 63, "Wintime: \y%d^n", get_pcvar_num(g_eCvars[e_cCapTime]));
	else 
		formatex(titleTimeRound, 63, "Maxrounds: \y%d^n", get_pcvar_num(g_eCvars[e_cMaxRounds]));

	new titleHP[64];
	if (get_pcvar_num(g_eCvars[e_cHpMode]) == 100)
		formatex(titleHP, 63, "1 HP Mode (Skill): \yOff^n");
	else
		formatex(titleHP, 63, "1 HP Mode (Skill): \yOn^n");

	new titleFlahs[64]; formatex(titleFlahs, 63, "Flash: \y%d", get_pcvar_num(g_eCvars[e_cFlashNum]));
	new titleSmoke[64]; formatex(titleSmoke, 63, "Smoke: \y%d^n", get_pcvar_num(g_eCvars[e_cSmokeNum]));
	new titleAA[64]; formatex(titleAA, 63, "Airaccelerate \y%d^n", get_pcvar_num(g_eCvars[e_cAA]));

	menu_additem(hMenu, titleRoundtime, "1");
	menu_additem(hMenu, titleFreeztime, "2");
	menu_additem(hMenu, titleTimeRound, "3");
	menu_additem(hMenu, titleHP, "4");

	menu_additem(hMenu, titleFlahs, "5");
	menu_additem(hMenu, titleSmoke, "6");

	menu_additem(hMenu, titleAA, "7");
	menu_display(id, hMenu, 0);
}

public settingsMatchMenuHandler(id, hMenu, item) {
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
			if (g_iCurrentRules == e_mTimer) {
				if (get_pcvar_num(g_eCvars[e_cCapTime]) == 5)
					set_pcvar_num(g_eCvars[e_cCapTime], 10);
				else if (get_pcvar_num(g_eCvars[e_cCapTime]) == 10)
					set_pcvar_num(g_eCvars[e_cCapTime], 15);
				else if (get_pcvar_num(g_eCvars[e_cCapTime]) == 15)
					set_pcvar_num(g_eCvars[e_cCapTime], 20);
				else if (get_pcvar_num(g_eCvars[e_cCapTime]) >= 20)
					set_pcvar_num(g_eCvars[e_cCapTime], 5);
			} else {
				if (get_pcvar_num(g_eCvars[e_cMaxRounds]) == 4)
					set_pcvar_num(g_eCvars[e_cMaxRounds], 5);
				else if (get_pcvar_num(g_eCvars[e_cMaxRounds]) == 5)
					set_pcvar_num(g_eCvars[e_cMaxRounds], 6);
				else if (get_pcvar_num(g_eCvars[e_cMaxRounds]) == 6)
					set_pcvar_num(g_eCvars[e_cMaxRounds], 7);
				else if (get_pcvar_num(g_eCvars[e_cMaxRounds]) >= 7)
					set_pcvar_num(g_eCvars[e_cMaxRounds], 4);
			}

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

	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}


public verifMenu(id) {
	if (!is_user_connected(id))
		return;

	new hMenu = menu_create("\yVerification^n^n\dAre you sure you want to stop this mod:", "verifMenuHandler");

	menu_additem(hMenu, "No");
	menu_additem(hMenu, "Yes");

	menu_setprop(hMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, hMenu, 0);
}

public verifMenuHandler(id, hMenu, item) {
	menu_destroy(hMenu);

	if (item == MENU_EXIT)
		return;

	switch (item) {
		case 0: {
			menu_destroy(hMenu);
			return;
		}
		case 1: {
			cmdStop(id);
		}
	}
}

public trainingMenu(id) {
	if (!is_user_connected(id) || g_iCurrentMode != e_mTraining)
		return;
	
	new hMenu = menu_create("\yTrainig menu:", "trainingMenuHandler");

	menu_additem(hMenu, "Checkpoint", "1");
	menu_additem(hMenu, "Teleport", "2");
	menu_additem(hMenu, "No Clip", "3");
	menu_additem(hMenu, "Respawn", "4");
	menu_additem(hMenu, "Damage", "5");

	menu_display(id, hMenu, 0);
}

public trainingMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
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
	return PLUGIN_HANDLED;
}

public modeSelectMenu(id) {
	if (!is_user_connected(id) || !getUserInAccess(id) || g_iCurrentMode != e_mTraining)
		return;

	new hMenu = menu_create("\yChoose game mode", "HandlerSelectMode");

	menu_additem(hMenu, "MR System", "1");
	menu_additem(hMenu, "Timer", "2");

	menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, hMenu, 0);
}

public HandlerSelectMode(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}
	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(hMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	new iKey = str_to_num(szData);

	switch (iKey) {
		case 1: {
			cmdMrMode(id);
		}
		case 2: {
			cmdTimerMode(id);
		}
	}
	return PLUGIN_HANDLED;
}