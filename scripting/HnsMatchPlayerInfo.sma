#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <hns_matchsystem>
#include <hns_matchsystem_pts>
#include <hns_matchsystem_stats>

new g_szPrefix[24];

new bool:g_HudOnOff[MAX_PLAYERS + 1];

new bool:g_bDmgThisRound[MAX_PLAYERS + 1];
new Float:g_flHealthBefore[MAX_PLAYERS + 1];
new Float:g_flDmg[MAX_PLAYERS + 1];
new Float:g_flDmgTime[MAX_PLAYERS + 1];
new Float:g_flCmdNextUseTime[MAX_PLAYERS + 1];

new g_MsgSync;

public plugin_init() {
	register_plugin("Match: Player info", "1.0", "OpenHNS");

	register_clcmd("say", "sayHandle");

	RegisterSayCmd("hud", "hudinfo", "cmdHUDInfo", 0, "Show hud info");

	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRoundStart", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "rgTakeDamage", true);

	set_task(1.0, "task_ShowPlayerInfo", .flags = "b");
	
	g_MsgSync = CreateHudSyncObj();
}

public client_putinserver(id) {
	g_HudOnOff[id] = true;
}

public plugin_cfg() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public cmdHUDInfo(id) {
	g_HudOnOff[id] = !g_HudOnOff[id]
	client_print_color(id, print_team_blue, "%s HUD info is now %sabled", g_szPrefix, g_HudOnOff[id] ? "^3En" : "^4Dis");
	return PLUGIN_HANDLED;
}

public sayHandle(id) {
	new szArgs[64];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if (szArgs[0] != '/') {
		return PLUGIN_CONTINUE;
	}

	new pattern[32];
	strtok2(szArgs, szArgs, charsmax(szArgs), pattern, charsmax(pattern), ' ');

	if(!equali(szArgs, "/dmg")) {
		return PLUGIN_CONTINUE;
	}

	trim(pattern);

	new Float:flGameTime = get_gametime();

	if(g_flCmdNextUseTime[id] > flGameTime) {
		client_print_color(id, print_team_blue, "%s Please wait ^3%.1f^1 seconds between commands!", g_szPrefix, g_flCmdNextUseTime[id] - flGameTime);
		return PLUGIN_CONTINUE;
	}

	g_flCmdNextUseTime[id] = flGameTime + 5.0; // 5 sec

	new iTarget = pattern[0] ? cmd_target(id, pattern, CMDTARGET_ALLOW_SELF) : id;

	if (!iTarget) {
		client_print_color(id, print_team_blue, "%s There is no OR multiple players with matching pattern -> ^4%s", g_szPrefix, pattern);
		return PLUGIN_CONTINUE;
	}

	if (g_flDmg[iTarget]) {
		client_print_color(0, print_team_blue, "%s ^3%n^1's fall damage ^3%.0f^1 HP - before ^3%.0f^1 - ^3%s^1 HP, ^3%.1f^1 seconds ago.", g_szPrefix, iTarget, g_flDmg[iTarget], g_flHealthBefore[iTarget], g_bDmgThisRound[iTarget] ? "^4Этот раунд" : "Не этот раунд", get_gametime() - g_flDmgTime[iTarget]);
	}

	return PLUGIN_CONTINUE;
}

public rgRoundStart(id) {
	arrayset(g_bDmgThisRound, false, sizeof(g_bDmgThisRound));
}

public rgTakeDamage(victim, inflictor, attacker, Float:damage, damagebits) {
	if (~damagebits & DMG_FALL || damage < 1.0) {
		return;
	}

	g_flDmg[victim] = damage;
	g_flDmgTime[victim] = get_gametime();
	get_entvar(victim, var_health, g_flHealthBefore[victim]);
	g_flHealthBefore[victim] += damage;
	g_bDmgThisRound[victim] = true;
}

public task_ShowPlayerInfo() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum);

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];

		if(is_user_connected(id) && g_HudOnOff[id]) {
			new show_id = is_user_alive(id) ? id : get_entvar(id, var_iuser2);

			if (!show_id) {
				continue;
			}

			set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.25, .holdtime = 1.0);
			new szHudMess[128], iLen;

			if (show_id != id) {
				if (g_ePlayerPtsData[show_id][e_bInit]) {
					iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
					Player: %n (#%d)^n\
					PTS: %d [%s]^n", 
					show_id, g_ePlayerPtsData[show_id][e_iTop],
					g_ePlayerPtsData[show_id][e_iPts], g_ePlayerPtsData[show_id][e_szRank]);
				} else {
					iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
					Player: %n^n", 
					show_id);	
				}
			}

			if (hns_get_mode() == MODE_MIX && hns_get_state() != STATE_PAUSED) {
				new szTime[24];
				fnConvertTime(hns_get_stats_surv(show_id), szTime, charsmax(szTime), false);
				iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
				Survive time: %s^n\
				Stabs: %d",
				szTime,
				hns_get_stats_stabs(show_id));
			}

			if (hns_get_status() != MATCH_NONE && hns_get_status() != MATCH_STARTED) {
				iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "%s", get_matchstats_str(hns_get_status()));
			}

			ShowSyncHudMsg(id, g_MsgSync, "%s", szHudMess);
		}

	}
}

public get_matchstats_str(MATCH_STATUS:iStatus) {
	new szOut[32];
	switch (iStatus) {
		case MATCH_CAPTAINPICK .. MATCH_CAPTAINKNIFE: {
			formatex(szOut, charsmax(szOut), "Captain mode");
		}
		case MATCH_TEAMPICK: {
			formatex(szOut, charsmax(szOut), "Team pick");
		}
		case MATCH_TEAMKNIFE: {
			formatex(szOut, charsmax(szOut), "Knife round");
		}
		case MATCH_MAPPICK: {
			formatex(szOut, charsmax(szOut), "Map pick");
		}
		case MATCH_WAITCONNECT: {
			formatex(szOut, charsmax(szOut), "Wait players");
		}
	}
	return szOut;
}

stock fnConvertTime(Float:time, convert_time[], len, bool:with_intpart = true) {
	new szTemp[24];
	new Float:flSeconds = time, iMinutes;

	iMinutes = floatround(flSeconds / 60.0, floatround_floor);
	flSeconds -= iMinutes * 60.0;
	new intpart = floatround(flSeconds, floatround_floor);
	new Float:decpart = (flSeconds - intpart) * 100.0;

	if (with_intpart) {
		intpart = floatround(decpart);
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f.%d", iMinutes, flSeconds, intpart);
	} else {
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f", iMinutes, flSeconds);
	}

	formatex(convert_time, len, "%s", szTemp);

	return PLUGIN_HANDLED;
}