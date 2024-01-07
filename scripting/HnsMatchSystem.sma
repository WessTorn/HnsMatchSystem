#include <hns-match/index>

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	precache_sound(sndUseSound);
}

public plugin_init() {
	g_PluginId = register_plugin("Hide'n'Seek Match System", "2.0.0", "OpenHNS"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor, Juice

	rh_get_mapname(g_szMapName, charsmax(g_szMapName));

	cvars_init();
	init_gameplay();
	mode_init();
	InitGameModes();

	cmds_init();
	auto_join_init();

	register_forward(FM_EmitSound, "fwdEmitSoundPre", 0);
	register_forward(FM_ClientKill, "fwdClientKill");

	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "rgPlayerSpawnPost", true);

	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgResetMaxSpeed", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgOnRoundFreezeEnd", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);
	RegisterHookChain(RH_SV_DropClient, "rgDropClient", false);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Knife_PrimaryAttack", false);

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	loadPlayers();

	forward_init();

	registerMode();

	register_dictionary("mixsystem.txt");
}

public forward_init() {
	g_hForwards[MATCH_START] = CreateMultiForward("hns_match_started", ET_CONTINUE);
	g_hForwards[MATCH_RESET_ROUND] = CreateMultiForward("hns_match_reset_round", ET_CONTINUE);
	g_hForwards[MATCH_FINISH] = CreateMultiForward("hns_match_finished", ET_CONTINUE, FP_CELL);
	g_hForwards[MATCH_CANCEL] = CreateMultiForward("hns_match_canceled", ET_CONTINUE);
}

public plugin_natives() {
	register_native("hns_get_prefix", "native_get_prefix");

	register_native("hns_get_mode", "native_get_mode");
	register_native("hns_set_mode", "native_set_mode");

	register_native("hns_get_status", "native_get_status");
	register_native("hns_get_state", "native_get_state");
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
	enum { argMode = 1 };
	g_iCurrentMode = get_param(argMode);
	// taskPrepareMode(argMode);
}

public MATCH_STATUS:native_get_status(amxx, params) {
	return g_iMatchStatus;
}

public MODE_STATES:native_get_state(amxx, params) {
	return g_eMatchState;
}



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
	} else if (g_iCurrentMode == MODE_MIX && g_flRoundTime < 90.0) {
		chat_print(id, "%L", id, "KILL_NOT_MIX");
		return FMRES_SUPERCEDE;
	} else {
		chat_print(0, "%L", LANG_PLAYER, "KILL_HIMSELF", id);
	}
	return FMRES_IGNORED;
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
		rg_remove_entity(szRemoveEntities[iCount]);
	}
}

public rgRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if (event == ROUND_GAME_COMMENCE) {
		set_member_game(m_bGameStarted, true);
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	// if (status == WINSTATUS_DRAW && event == ROUND_END_DRAW) {
	// 	return HC_CONTINUE;
	// }

	if (g_GPFuncs[g_iCurrentGameplay][GP_ROUNDEND])
		ExecuteForward(g_GPFuncs[g_iCurrentGameplay][GP_ROUNDEND], _, (status == WINSTATUS_CTS) ? true : false);

	if (g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDEND])
		ExecuteForward(g_ModFuncs[g_iCurrentMode][MODEFUNC_ROUNDEND], _, (status == WINSTATUS_CTS) ? true : false);

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
}

public rgPlayerSpawn(id) {
	if (!is_user_alive(id))
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

public rgDropClient(id) {
	arrayset(g_ePlayerPtsData[id], 0, PTS_DATA);
}

public Knife_PrimaryAttack(ent)
{
	new id = get_member(ent, m_pPlayer);

	if (get_member(id, m_iTeam) == _:CS_TEAM_CT || g_iCurrentGameplay == GAMEPLAY_KNIFE)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public plugin_cfg() {
	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	format(szPath, charsmax(szPath), "%s/mixsystem/%s", szPath, "matchsystem.cfg");
	server_cmd("exec %s", szPath);
}

restartRound(Float:delay = 0.5) {
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
}


public plugin_end() {
	ArrayDestroy(g_aPlayersLoadData);
}
