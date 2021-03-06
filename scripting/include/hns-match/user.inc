#if defined _user_included
  #endinput
#endif

#define _user_included

stock TeamName:getUserTeam(id) {
	return get_member(id, m_iTeam);
}

stock getUserName(id) {
	new szName[128];
	get_user_name(id, szName, charsmax(szName));
	return szName;
}

stock getUserKey(id) {
	new szAuth[24];
	get_user_authid(id, szAuth, charsmax(szAuth));
	return szAuth;
}

stock bool:getUserInMatch(id) {
	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return false;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (getUserTeam(iPlayer) == TEAM_SPECTATOR)
			continue;

		if (id == iPlayer)
			return true;
	}
	return false;
}

stock bool:getUserInAccess(id) {
	if (get_user_flags(id) & access)
		return true;
	else
		return false;
}

stock setUserGodmode(index, godmode = 0) {
	set_entvar(index, var_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);

	return 1;
}

stock setUserRole(id) {
	new TeamName:team = getUserTeam(id);
	rg_remove_all_items(id);
	if (g_iCurrentMode > e_mKnife && g_iCurrentMode != e_mCaptain) {
		switch (team) {
			case TEAM_TERRORIST: {
				set_user_footsteps(id, 1);
				rg_give_item(id, "weapon_knife");

				if (get_pcvar_num(g_eCvars[e_cFlashNum]) >= 1) {
					rg_give_item(id, "weapon_flashbang");
					rg_set_user_bpammo(id, WEAPON_FLASHBANG, get_pcvar_num(g_eCvars[e_cFlashNum]));
				}

				if (get_pcvar_num(g_eCvars[e_cSmokeNum]) >= 1) {
					rg_give_item(id, "weapon_smokegrenade");
					rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, get_pcvar_num(g_eCvars[e_cSmokeNum]));
				}

				if (g_iCurrentMode == e_mDM) {
					if (get_pcvar_num(g_eCvars[e_cHpMode]) == 100)
						set_entvar(id, var_health, 100.0);
					else 
						set_entvar(id, var_health, 1.0);
				}
			}
			case TEAM_CT: {
				set_user_footsteps(id, 0);
				rg_give_item(id, "weapon_knife");
			}
		}
	} else {
		rg_give_item(id, "weapon_knife");
	}
}

stock transferUserToSpec(id) {
	setTeam(id, TEAM_SPECTATOR);
	set_entvar(id, var_solid, SOLID_NOT);
	set_entvar(id, var_movetype, MOVETYPE_FLY);
}

stock transferUsers(TeamName:iTeam) {
	new Float:flTime;
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");
	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
		if (is_user_connected(id)) {
			switch (id) {
				case 1 ..8: flTime = 0.1;
				case 9 ..16: flTime = 0.2;
				case 17 ..24: flTime = 0.3;
				case 25 ..32: flTime = 0.4;
			}

			new taskParams[2];
			taskParams[0] = id;
			taskParams[1] = _:iTeam;

			if (task_exists(id))
				remove_task(id);

			set_task(flTime, "taskToTeam", id, taskParams, sizeof taskParams);
		}
	}
}

public taskToTeam(Params[]) {
	new id = Params[0];
	new team = Params[1];
	if (is_user_connected(id)) {
		if (is_user_alive(id))
			user_silentkill(id);

		if (getUserTeam(id) != TeamName:team)
			setTeam(id, TeamName:team);
	}
}

setTeam(id, TeamName:iTeam) {
	set_member(id, m_bTeamChanged, false);

	if (is_user_alive(id))
		user_silentkill(id);

	switch (iTeam) {
		case TEAM_TERRORIST: {
			rg_internal_cmd(id, "jointeam", "1");
			rg_internal_cmd(id, "joinclass", "5");
		}
		case TEAM_CT: {
			rg_internal_cmd(id, "jointeam", "2");
			rg_internal_cmd(id, "joinclass", "5");
		}
		case TEAM_SPECTATOR: {
			rg_internal_cmd(id, "jointeam", "6");
		}
	}
}