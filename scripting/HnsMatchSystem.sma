#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	precache_sound(sndUseSound);
}

public plugin_init() {
	g_PluginId = register_plugin("Hide'n'Seek Match System", "2.0.3", "OpenHNS"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor, Juice

	rh_get_mapname(g_szMapName, charsmax(g_szMapName));

	cvars_init();
	init_gameplay();
	mode_init();
	InitGameModes();

	cmds_init();

	register_forward(FM_EmitSound, "fwdEmitSoundPre", 0);
	register_forward(FM_ClientKill, "fwdClientKill");
	register_forward(FM_GetGameDescription, "fwdGameNameDesc");

	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "rgPlayerSpawnPost", true);

	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgResetMaxSpeed", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgOnRoundFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rgFlPlayerFallDamage", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Knife_PrimaryAttack", false);
        RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");

	register_message(get_user_msgid("HostagePos"), "msgHostagePos");
	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");
	register_message(get_user_msgid("HideWeapon"), "msgHideWeapon");
	

	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET);
	set_msg_block(g_msgMoney = get_user_msgid("Money"), BLOCK_SET);

	set_task(0.1, "ShowTimeAsMoney", 15671983, .flags="b");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	loadPlayers();

	forward_init();

	registerMode();

	g_PlayersLeaveData = TrieCreate();

	register_dictionary("mixsystem.txt");

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	format(szPath, charsmax(szPath), "%s/mixsystem/%s", szPath, "matchsystem.cfg");
	server_cmd("exec %s", szPath);
}

public forward_init() {
	g_hForwards[MATCH_START] = CreateMultiForward("hns_match_started", ET_CONTINUE);
	g_hForwards[MATCH_RESET_ROUND] = CreateMultiForward("hns_match_reset_round", ET_CONTINUE);
	g_hForwards[MATCH_FINISH] = CreateMultiForward("hns_match_finished", ET_CONTINUE, FP_CELL);
	g_hForwards[MATCH_CANCEL] = CreateMultiForward("hns_match_canceled", ET_CONTINUE);

	g_hForwards[HNS_ROUND_START] = CreateMultiForward("hns_round_start", ET_CONTINUE);
	g_hForwards[HNS_ROUND_FREEZEEND] = CreateMultiForward("hns_round_freezeend", ET_CONTINUE);
	g_hForwards[HNS_ROUND_END] = CreateMultiForward("hns_round_end", ET_CONTINUE);
}

public plugin_natives() {
	register_native("hns_get_prefix", "native_get_prefix");

	register_native("hns_get_mode", "native_get_mode");
	register_native("hns_set_mode", "native_set_mode");

	register_native("hns_get_status", "native_get_status");
	register_native("hns_get_state", "native_get_state");

	register_native("hns_get_rules", "native_get_rules");

	//register_native("hns_get_score_tt", "native_get_score_TT");
	//register_native("hns_get_score_ct", "native_get_score_CT");
}

public native_get_prefix(amxx, params) {
	enum { argPrefix = 1, argLen };
	new szPrefix[24];
	format(szPrefix, charsmax(szPrefix), "[^3%s^1]", g_iSettings[PREFIX]);
	set_string(argPrefix, szPrefix, get_param(argLen));
}

public native_get_mode(amxx, params) {
	return g_iCurrentMode;
}

public native_set_mode(amxx, params) {
	enum { iSetMode = 1 };
	switch (get_param(iSetMode)) {
		case MODE_TRAINING: {
			training_start()
		}
		case MODE_KNIFE: {
			kniferound_start()
		}
		case MODE_PUB: {
			pub_start()
		}
		case MODE_DM: {
			dm_start()
		}
		case MODE_ZM: {
			zm_start()
		}
		case MODE_MIX: {
			mix_start()
		}
	}
}

public MATCH_STATUS:native_get_status(amxx, params) {
	return g_iMatchStatus;
}

public MODE_STATES:native_get_state(amxx, params) {
	return g_eMatchState;
}

public NATCH_RULES:native_get_rules(amxx, params) {
	return g_iCurrentRules;
}

/* public native_get_score_TT(amxx, params) {
  if (g_isTeamTT == HNS_TEAM_A) {
    return g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_A];
    } else {
    return g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_B];
  }
}*/

//TEST NATIVES

/*public native_get_score_CT(amxx, params) {
  if (g_isTeamTT == HNS_TEAM_A) {
	return g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_B];
  }	 else {
    return g_eMatchInfo[e_iRoundsPlayed][HNS_TEAM_A];
  }
} */

public fwdEmitSoundPre(id, iChannel, szSample[], Float:volume, Float:attenuation, fFlags, pitch) {
	if (equal(szSample, "weapons/knife_deploy1.wav")) {
		return FMRES_SUPERCEDE;
	}

	if (is_user_alive(id) && getUserTeam(id) == TEAM_TERRORIST && equal(szSample, sndDenySelect)) {
		emit_sound(id, iChannel, sndUseSound, volume, attenuation, fFlags, pitch);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fwdClientKill(id) {
	if (g_iCurrentMode == MODE_DM) {
		chat_print(id, "%L", id, "KILL_NOT");
		return FMRES_SUPERCEDE;
	} else if (g_iCurrentMode == MODE_MIX && g_iCurrentRules == RULES_MR && g_flRoundTime < 90.0) {
		chat_print(id, "%L", id, "KILL_NOT_MIX");
		return FMRES_SUPERCEDE;
	} else {
		chat_print(0, "%l", "KILL_HIMSELF", id);
	}
	return FMRES_IGNORED;
}

public fwdGameNameDesc()
{
	static gamename[32];
	get_pcvar_string(pCvar[GAMENAME], gamename, 31);
	forward_return(FMV_STRING, gamename);
	return FMRES_SUPERCEDE;
}

public rgPlayerSpawnPost() {
	new const szRemoveEntities[][] = {
		"func_hostage_rescue",
		"info_hostage_rescue",
		"func_bomb_target",
		"info_bomb_target",
		"func_vip_safetyzone",
		"info_vip_start",
		"func_escapezone",
		"hostage_entity",
		"monster_scientist",
		"func_buyzone"
	};
	
	for(new iCount = 0, iSize = sizeof(szRemoveEntities); iCount < iSize; iCount++) {
		remove_entity_m(szRemoveEntities[iCount]);
	}
}

public rgRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if (event == ROUND_GAME_COMMENCE) {
		set_member_game(m_bGameStarted, true);
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	if (g_iCurrentMode == MODE_ZM && event == ROUND_TERRORISTS_WIN) {
        set_member_game(m_bGameStarted, true);
        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_SUPERCEDE;
    }

	if (g_GPFuncs[g_iCurrentGameplay][GP_ROUNDEND])
		ExecuteForward(g_GPFuncs[g_iCurrentGameplay][GP_ROUNDEND], _, (status == WINSTATUS_CTS) ? true : false);

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDEND])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDEND], _, (status == WINSTATUS_CTS) ? true : false);

	g_bPlayersListLoaded = false;

	ExecuteForward(g_hForwards[HNS_ROUND_END]);
	
	return HC_CONTINUE;
}


public rgResetMaxSpeed(id) {
	if (get_member_game(m_bFreezePeriod)) {
		if (g_iCurrentMode == MODE_TRAINING) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}

		if (getUserTeam(id) == TEAM_TERRORIST) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public rgRestartRound() { // Сделать красиво
	set_task(1.0, "taskDestroyBreakables");

	if (g_GPFuncs[g_iCurrentGameplay][GP_ROUNDSTART])
		ExecuteForward(g_GPFuncs[g_iCurrentGameplay][GP_ROUNDSTART], _);

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDSTART])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDSTART], _);

	ExecuteForward(g_hForwards[HNS_ROUND_START]);
}

public taskDestroyBreakables() {
	new iEntity = -1;
	while ((iEntity = rg_find_ent_by_class(iEntity, "func_breakable"))) {
		if (get_entvar(iEntity, var_takedamage)) {
			set_entvar(iEntity, var_origin, Float:{ 10000.0, 10000.0, 10000.0 });
		}
	}
}

public rgOnRoundFreezeEnd() {
	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_FREEZEEND])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_FREEZEEND], _);

	ExecuteForward(g_hForwards[HNS_ROUND_FREEZEEND]);
}

public rgFlPlayerFallDamage(const id) {
	new Float:flDmg = Float:GetHookChainReturn(ATYPE_FLOAT);

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_FALLDAMAGE])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_FALLDAMAGE], _, id, flDmg);
}

public rgPlayerSpawn(id) {
	if (!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))
		return;

	if (g_GPFuncs[g_iCurrentGameplay][GP_SETROLE])
	{
		ExecuteForward(g_GPFuncs[g_iCurrentGameplay][GP_SETROLE], _, id);
	}
}

public rgPlayerKilled(victim, attacker) {
	if (g_GPFuncs[g_iCurrentGameplay][GP_KILLED])
		ExecuteForward(g_GPFuncs[g_iCurrentGameplay][GP_KILLED], _, victim, attacker);

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_KILL])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_KILL], _, victim, attacker);
}

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, alpha) {
	if (getUserTeam(index) == TEAM_TERRORIST || getUserTeam(index) == TEAM_SPECTATOR)
		return HC_SUPERCEDE;

	return HC_CONTINUE;
}

public rgPlayerMakeBomber(const this) {
	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}

public registerMode() {
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);
}

public client_disconnected(id) {
	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_PLAYER_LEAVE])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_PLAYER_LEAVE], _, id);

	arrayset(g_ePlayerPtsData[id], 0, PTS_DATA);
}

public Knife_PrimaryAttack(ent)
{
	//new id = get_member(ent, m_pPlayer); // TODO
	/* get_member(id, m_iTeam) == _:CS_TEAM_CT */ // Условие тоже TODO

	if (g_iCurrentMode || g_iCurrentGameplay == GAMEPLAY_KNIFE)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_TraceAttack(attacker, victim,Float:damage, Float:direction[3], tr, damage_type)
{
	if(!(g_iCurrentGameplay == GAMEPLAY_KNIFE))
	{
		if(get_user_team(attacker) == 2 && get_user_team(victim) == 1)
		{
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
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
	if (g_iCurrentMode != MODE_MIX) {
		const money = (1 << 5);
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | money);
	}
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

	set_task(0.2, "taskSetPlayerTeam", id);
}

public taskSetPlayerTeam(id) {
	if (!is_user_connected(id))
		return;

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_PLAYER_JOIN])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_PLAYER_JOIN], _, id);
}

public PDS_Save() {
	if (equali(g_szMapName, g_iSettings[KNIFEMAP])) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
	PDS_SetCell("match_status",		g_iMatchStatus);
	PDS_SetCell("match_mode",		g_iCurrentMode);
	PDS_SetCell("match_gameplay",   g_iCurrentGameplay);
	PDS_SetCell("match_rules",	 	g_iCurrentRules);
}

stock savePlayers(TeamName:team_winners) {
	new JSON:arrayRoot = json_init_array();

	new iPlayers[MAX_PLAYERS], iNum, szAuth[24];
	get_players(iPlayers, iNum, "ch");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];

		if (getUserTeam(id) == TEAM_SPECTATOR) continue;

		get_user_authid(id, szAuth, charsmax(szAuth));

		arrayAppendValue(arrayRoot, json_init_string(fmt("player_%i", i + 1)));

		new JSON:object = json_init_object();
		json_object_set_string(object, "e_pAuth", fmt("%s", szAuth));
		new TeamName:iTeam = TeamName:getUserTeam(id) == team_winners ? TEAM_TERRORIST : TEAM_CT;
		json_object_set_number(object, "e_pTeam", _:iTeam);
		arrayAppendValue(arrayRoot, object);
		json_free(object);
		server_print("save (%s %s)", szAuth, _:iTeam)
	}

	json_serial_to_string(arrayRoot, g_szBuffer, charsmax(g_szBuffer), true);
	json_free(arrayRoot);
}

arrayAppendValue(JSON:array, JSON:node) {
	json_array_append_value(array, node);
	json_free(node);
}

loadPlayers() {
	if (!equali(g_szMapName, g_iSettings[KNIFEMAP]))
		g_bPlayersListLoaded = PDS_GetString("playerslist", g_szBuffer, charsmax(g_szBuffer));

	if (g_bPlayersListLoaded) {
		new JSON:arrayRoot = json_parse(g_szBuffer);

		if (!json_is_array(arrayRoot)) {
			if (arrayRoot != Invalid_JSON)
				json_free(arrayRoot);

			server_print("Root value is not array!");
			return;
		}
		decodeArray(arrayRoot);
		json_free(arrayRoot);
	}
}

decodeArray(&JSON:array) {
	new JSON:arrayValue;
	for (new i = 0; i < json_array_get_count(array); i++) {
		arrayValue = json_array_get_value(array, i);

		if (json_get_type(arrayValue) == JSONObject)
			decodeObject(arrayValue);

		json_free(arrayValue);
	}
}

decodeObject(&JSON:object) {
	new szKey[30];
	new JSON:objValue;
	new eTempPlayer[PlayersLoad_s], iSave;
	if (!g_aPlayersLoadData) {
		server_print("FAIL")
		return;
	}
	server_print("(%d)", json_object_get_count(object))
	for (new i = 0; i < json_object_get_count(object); i++) {
		json_object_get_name(object, i, szKey, charsmax(szKey));
		objValue = json_object_get_value_at(object, i);

		switch (json_get_type(objValue)) {
			case JSONString: {
				json_get_string(objValue, eTempPlayer[e_pAuth], charsmax(eTempPlayer[e_pAuth]));
				iSave++;
			}
			case JSONNumber: {
				eTempPlayer[e_pTeam] = json_get_number(objValue);
				iSave++;
			}
		}

		if (iSave == 2) {
			server_print("(%s %d [%d])", eTempPlayer[e_pAuth], eTempPlayer[e_pTeam], i)
			ArrayPushArray(g_aPlayersLoadData, eTempPlayer);
			arrayset(eTempPlayer, 0, PlayersLoad_s);
			iSave = 0;
		}
		json_free(objValue);
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

public ShowTimeAsMoney()
{
	if (g_iCurrentMode == MODE_MIX && g_iMatchStatus == MATCH_STARTED && g_iCurrentRules == RULES_TIMER) {
		static players[32], num, id
		get_players(players, num, "ac");
		for(--num; num>=0; num--)
		{
			id = players[num];

			message_begin(MSG_ONE, g_msgMoney, .player=id);
			write_long(floatround((g_iSettings[WINTIME]*60.0) - g_eMatchInfo[e_flSidesTime][g_isTeamTT], floatround_floor));
			write_byte(0);
			message_end();
		}
	}
}

restartRound(Float:delay = 0.5) {
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
}


public plugin_end() {
	TrieDestroy(g_PlayersLeaveData);
	ArrayDestroy(g_aPlayersLoadData);
}
