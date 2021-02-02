/*
	В след. версиях:
	Добавить g_iGameMode Boost/Skill;
	Доделать mapcfg;
	убрать лишние проверки на access.

*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <fun>
#include <reapi>
#include <json>
#include <PersistentDataStorage>

#define prefix "^1>"
#define access ADMIN_MAP
#define knifeMap "35hp_2"
#define surrenderTimeDelay 120
#define surrenderVoteTime 10

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

enum {
	e_mTraining,
	e_mPaused,
	e_mKnife,
	e_mCaptain,
	e_mMatch,
	e_mPublic,
	e_mDM
}
new g_iCurrentMode;

enum _:PlayersLoad_s {
	e_pAuth[24],
	e_pTeam
};

new Array:g_aPlayersLoadData;

enum _:CaptainTeam_s {
	e_cTT,
	e_cCT
};
new g_eCaptain[CaptainTeam_s], g_iCaptainPick;
new bool:g_bCaptainsBattle;

enum _:MatchInfo_s {
	e_mMapName[32],
	e_mTeamSizeTT,
	e_mWinTime[24]
};
new g_eMatchInfo[MatchInfo_s];

enum _:SurrenderData_s {
	bool:e_sStarted,
	e_sInitiator,
	Float:e_sFlDelay,
	Float:e_sFlTime
};
enum _:SurrenderVote {
	e_sYes,
	e_sNo
};
new g_eSurrenderData[SurrenderData_s], g_eSurrenderVotes[SurrenderVote];
new bool:g_bSurrenderVoted[MAX_PLAYERS + 1];

enum _:Cvars_s {
	e_cCapTime,
	e_cRoundTime,
	e_cGameName,
	e_cFlashNum,
	e_cSmokeNum,
	e_cAA,
	e_cLastMode,
	e_cSemiclip,
	e_cHpMode,
	e_cDMRespawn
};
new g_eCvars[Cvars_s];

enum _:AfkData_s {
	bool:is_afk,
	afk_timer
};

new g_eAfkData[MAX_PLAYERS + 1][AfkData_s], g_iPlayersAfk;
new Float:g_flAfkOrigin[MAX_PLAYERS + 1][3];
new g_MsgSync;

new bool:g_bSurvival;
new bool:g_bGameStarted;
new bool:g_bHooked[MAX_PLAYERS + 1];
new bool:g_bNoplay[MAX_PLAYERS + 1];
new bool:g_bSpec[MAX_PLAYERS + 1];
new bool:g_bPlayersListLoaded;
new bool:g_bLastFlash[MAX_PLAYERS + 1];
new bool:g_bOnOff[33];


new Float:g_flRoundTime;
new Float:g_flSidesTime[2];

new g_iCurrentSW;
new g_iRegisterSpawn;
new g_iGiveNadesTo;
new g_iAllocKnifeModel;
new g_iHostageEnt;
new g_szBuffer[2048];

new TeamName:hTeam[MAX_PLAYERS + 1];
new HamHook:playerKilledPre;

static const knifeModel[] = "models/v_knife.mdl";
new const g_sndDenySelect[] = "common/wpn_denyselect.wav";
new const g_sndUseSound[] = "buttons/blip1.wav";
new const g_szDefaultEntities[][] = {
	"func_hostage_rescue",
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity",
	"monster_scentist"
}

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
	precache_sound(g_sndUseSound);
}

public plugin_init() {
	register_plugin("Hide'n'Seek Match System", "1.0.8", "??"); // Спасибо: Cultura, Garey, Medusa, Ruffman, Conor

	get_mapname(g_eMatchInfo[e_mMapName], charsmax(g_eMatchInfo[e_mMapName]));

	g_eCvars[e_cRoundTime] = get_cvar_pointer("mp_roundtime");
	

	g_eCvars[e_cCapTime]	= register_cvar("hns_wintime", "15");
	g_eCvars[e_cFlashNum]	= register_cvar("hns_flash", "2", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSmokeNum]	= register_cvar("hns_smoke", "1", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cLastMode]	= register_cvar("hns_lastmode", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cAA]			= register_cvar("hns_aa", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cSemiclip]	= register_cvar("hns_semiclip", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cHpMode]		= register_cvar("hns_hpmode", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cDMRespawn] 	= register_cvar("hns_dmrespawn", "3", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_eCvars[e_cGameName]	= register_cvar("hns_gamename", "Hide'n'Seek");

	g_iAllocKnifeModel = engfunc(EngFunc_AllocString, knifeModel);

	register_clcmd("say", "sayHandle");

	register_clcmd("+hook", "hookOn");
	register_clcmd("-hook", "hookOff");

	RegisterSayCmd("showknife", "knife", "cmdShowKnife");
	RegisterSayCmd("hideknife", "hknife", "cmdShowKnife");

	register_clcmd("chooseteam", "blockCmd");
	register_clcmd("jointeam", "blockCmd");
	register_clcmd("joinclass", "blockCmd");
	register_clcmd("nightvision", "mainMatchMenu");

	RegisterSayCmd("pub", "public", "cmdPubMode", access, "Public mode");
	RegisterSayCmd("dm", "DM", "cmdDMMode", access, "Public mode");
	RegisterSayCmd("specall", "specall", "cmdTransferSpec", access, "Spec Transfer");
	RegisterSayCmd("ttall", "ttall", "cmdTransferTT", access, "TT Transfer");
	RegisterSayCmd("ctall", "ctall", "cmdTransferCT", access, "CT Transfer");
	RegisterSayCmd("startmix", "start", "cmdStartRound", access, "Starts Round");
	RegisterSayCmd("kniferound", "kf", "cmdKnifeRound", access, "Knife Round");
	RegisterSayCmd("captain", "cap", "cmdCaptain", access, "Captain Mode");
	RegisterSayCmd("stop", "st", "cmdStopMode", access, "Stop Current Mode");
	RegisterSayCmd("skill", "skill", "cmdSkillMode", access, "Skill mode");
	RegisterSayCmd("boost", "boost", "cmdBoostMode", access, "Boost mode");
	RegisterSayCmd("aa10", "10aa", "cmdAa10", access, "10aa");
	RegisterSayCmd("aa100", "100aa", "cmdAa100", access, "100aa");
	RegisterSayCmd("rr", "restart", "cmdRestartRound", access, "Restart round");
	RegisterSayCmd("swap", "swap", "cmdSwapTeams", access, "Swap Teams");
	RegisterSayCmd("mix", "mix", "mainMatchMenu", access, "Main menu admin");
	RegisterSayCmd("pause", "ps", "cmdStartPause", access, "Start pause");
	RegisterSayCmd("live", "unpause", "cmdStopPause", access, "Unpause");
	RegisterSayCmd("surrender", "sur", "cmdSurrender", 0, "Surrender vote");
	RegisterSayCmd("score", "s", "cmdShowTimers", 0, "Score");
	RegisterSayCmd("pick", "pick", "cmdPick", 0, "Pick player");
	RegisterSayCmd("back", "spec", "cmdTeamSpec", 0, "Spec/Back player");
	RegisterSayCmd("np", "noPlay", "cmdNoplay", 0, "No play");
	RegisterSayCmd("ip", "play", "cmdPlay", 0, "Play play");

	RegisterHookChain(RG_RoundEnd, "rgRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgResetMaxSpeed", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgOnRoundFreezeEnd", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind", false);
	RegisterHookChain(RG_CBasePlayer_MakeBomber, "rgPlayerMakeBomber", false);
	RegisterHookChain(RG_PM_Move, "rgPlayerMovePost", true);
	register_event("DeathMsg", "EventDeathMsg", "a");

	playerKilledPre = RegisterHam(Ham_Killed, "player", "fwdPlayerKilledPre", 0);
	register_menucmd(register_menuid("NadesMenu"), 3, "handleNadesMenu");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fwdDeployKnife", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fwdKnifePrim");

	register_forward(FM_Voice_SetClientListening, "fwdSetClientListening");
	register_forward(FM_EmitSound, "fwdEmitSoundPre", 0);
	register_forward(FM_ClientKill, "fwdClientKill");
	register_forward(FM_GetGameDescription, "fwdGameNameDesc");

	unregister_forward(FM_Spawn, g_iRegisterSpawn, 1);
	
	register_message(get_user_msgid("HostagePos"), "msgHostagePos");
	register_message(get_user_msgid("ShowMenu"), "msgShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msgVguiMenu");
	register_message(get_user_msgid("HideWeapon"), "msgHideWeapon");

	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET);      

	set_task(0.5, "taskDelayedMode");

	g_aPlayersLoadData = ArrayCreate(PlayersLoad_s);
	registerMode();
	loadPlayers();

	g_MsgSync = CreateHudSyncObj();

	register_dictionary("mixsystem.txt");
}

public taskDelayedMode() {
	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		taskPrepareMode(e_mTraining);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 0) {
		taskPrepareMode(e_mTraining);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 1) {
		taskPrepareMode(e_mPublic);
	} else if (get_pcvar_num(g_eCvars[e_cLastMode]) == 2) {
		taskPrepareMode(e_mDM);
	} else {
		taskPrepareMode(e_mTraining);
	}
}

public registerMode() {
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);
}

loadPlayers() {
	if (!equali(g_eMatchInfo[e_mMapName], knifeMap))
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

public PDS_Save() {
	if (equali(g_eMatchInfo[e_mMapName], knifeMap)) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
}

public plugin_end() {
	ArrayDestroy(g_aPlayersLoadData);
}

public client_putinserver(id) {
	g_bOnOff[id] = false;
}

public client_disconnected(id) {
	g_bHooked[id] = false;
}

public EventDeathMsg() {
	if (g_iCurrentMode != e_mDM) {
		return;
	}

	new killer = read_data(1);
	new victim = read_data(2);
	
	if(killer == 0)  {
		if(rg_get_user_team(victim) == TEAM_TERRORIST) {
			new lucky = GetRandomCT();
			if(lucky) {
				rg_set_user_team(lucky, TEAM_TERRORIST);
				client_print_color(lucky, print_team_blue, "%L", lucky, "DM_TRANSF", prefix)
				rg_set_user_team(victim, TEAM_CT);
				setRole(lucky);
			}
		}
	} else if(killer != victim && rg_get_user_team(killer) == TEAM_CT) {
		rg_set_user_team(killer, TEAM_TERRORIST); 
		rg_set_user_team(victim, TEAM_CT); 
		
		setRole(killer);
	}
	
	set_task(get_pcvar_float(g_eCvars[e_cDMRespawn]), "RespawnPlayer", victim);
}

public RespawnPlayer(id) {
	if (!is_user_connected(id))
		return;
	
	if (rg_get_user_team(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

GetRandomCT() {
	static iPlayers[32], iCTNum
	get_players(iPlayers, iCTNum, "ae", "CT");
		
	if(!iCTNum)
		return 0
		
	return iCTNum > 1 ? iPlayers[random(iCTNum)] : iPlayers[iCTNum - 1];
}

public rgRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if (event == ROUND_TARGET_SAVED || event == ROUND_HOSTAGE_NOT_RESCUED) {
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_TERRORISTS);
		SetHookChainArg(2, ATYPE_INTEGER, ROUND_TERRORISTS_ESCAPED);
		return HC_CONTINUE;
	}

	if (event == ROUND_GAME_COMMENCE) {
		set_member_game(m_bGameStarted, true);
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	switch (g_iCurrentMode) {
		case e_mPublic: {
			if (status == WINSTATUS_CTS) {
				rg_swap_all_players();
			}
		}
		case e_mMatch: {
			if (status == WINSTATUS_CTS) {
				g_bSurvival = false;
				g_iCurrentSW = !g_iCurrentSW;
				rg_swap_all_players();
			}
		}
		case e_mKnife: {
			if (g_bCaptainsBattle) {
				if (status == WINSTATUS_CTS)
					g_iCaptainPick = g_eCaptain[e_cCT];
				else
					g_iCaptainPick = g_eCaptain[e_cTT];

				setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, fmt("Captain %n win!", g_iCaptainPick));

				taskPrepareMode(e_mCaptain);
				g_bCaptainsBattle = false;

				pickMenu(g_iCaptainPick);
			} else {
				setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, "Team %s Win", status == WINSTATUS_CTS ? "CTS" : "Terrorists");

				savePlayers(status == WINSTATUS_CTS ? TEAM_CT : TEAM_TERRORIST);
				taskPrepareMode(e_mTraining);
			}
		}
	}
	return HC_CONTINUE;
}

public rgResetMaxSpeed(id) {
	if (get_member_game(m_bFreezePeriod)) {
		if (g_iCurrentMode == e_mTraining || g_iCurrentMode == e_mPaused) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}

		if (rg_get_user_team(id) == TEAM_TERRORIST) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public rgRestartRound() {
	remove_task();

	if (g_bGameStarted)
		cmdShowTimers(0);

	g_flRoundTime = 0.0;
	EnableHamForward(playerKilledPre);

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", "TERRORIST");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		if (g_bLastFlash[iPlayer]) {
			g_bLastFlash[iPlayer] = false;
			show_menu(iPlayer, 0, "^n", 1);
		}
	}
	g_eMatchInfo[e_mTeamSizeTT] = iNum;

	if (g_iCurrentMode == e_mMatch) {
		ResetAfkData();
		set_task(0.3, "taskSaveAfk");
	}

	set_task(1.0, "taskDestroyBreakables");
}

public taskSaveAfk() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ace", "TERRORIST");

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];
		get_entvar(id, var_origin, g_flAfkOrigin[id]);
	}
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
	if (g_iCurrentMode != e_mMatch)
		return;

	if (g_bGameStarted)
		g_bSurvival = true;

	set_task(g_eCvars[e_cSemiclip] ? 3.0 : 5.0, "taskCheckAfk");

	set_task(0.25, "taskRoundEnd", .flags = "b");
}

public taskCheckAfk() {
	if (g_iCurrentMode != e_mMatch) {
		ResetAfkData();
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ace", "TERRORIST");

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];

		if (PlayerIsAfk(id)) {
			g_eAfkData[id][is_afk] = true;
			g_iPlayersAfk++;
		}
	}

	if (g_iPlayersAfk) {
		cmdStartPause(0);
		client_print_color(0, print_team_blue, "%L", 0, "AFK_PAUSE", prefix, g_iPlayersAfk);
		set_task(1.0, "taskAfk", .flags = "b");
	}
}

public taskAfk() {
	if (g_iCurrentMode != e_mPaused) {
		ResetAfkData();
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum, szBuffer[512];
	get_players(iPlayers, iNum, "c");

	add(szBuffer, charsmax(szBuffer), "AFK Players [wait time]:^n");

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];
		new szTime[16];

		if (g_eAfkData[id][is_afk]) {
			if (TeamName:get_member(id, m_iTeam) == TEAM_SPECTATOR || !is_user_alive(id)) {
				arrayset(g_eAfkData[id], 0, AfkData_s);
				arrayset(g_flAfkOrigin[id], 0.0, sizeof(g_flAfkOrigin[]));
				g_iPlayersAfk--;
				continue;
			}

			if (!PlayerIsAfk(id)) {
				arrayset(g_eAfkData[id], 0, AfkData_s);
				arrayset(g_flAfkOrigin[id], 0.0, sizeof(g_flAfkOrigin[]));
				g_iPlayersAfk--;
			} else {
				g_eAfkData[id][afk_timer]++;
				fnConvertTime(g_eAfkData[id][afk_timer] * 1.0, szTime, 23, false);
				add(szBuffer, charsmax(szBuffer), fmt("%n (%s)^n", id, szTime));
			}
		}
	}

	if (!g_iPlayersAfk) {
		cmdStopPause(0);
		client_print_color(0, print_team_blue, "%L", 0, "AFK_UNPAUSE", prefix);
	} else {
		set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.15, .y = 0.20, .holdtime = 1.0);
		ShowSyncHudMsg(0, g_MsgSync, "%s", szBuffer);
	}
}

ResetAfkData() {
	remove_task();
	g_iPlayersAfk = 0;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];
		arrayset(g_eAfkData[id], 0, AfkData_s);
		arrayset(g_flAfkOrigin[id], 0.0, sizeof(g_flAfkOrigin[]));
	}
}

stock bool:PlayerIsAfk(id) {
	new Float:origin[3]; get_entvar(id, var_origin, origin);

	if (get_distance_f(g_flAfkOrigin[id], origin) <= 1.0)
		return true;

	return false;
}

public taskRoundEnd() {
	if (g_bSurvival) {
		new iPlayers[32], count;
		get_players(iPlayers, count, "ce", "TERRORIST");

		g_flRoundTime += 0.25;
		g_flSidesTime[g_iCurrentSW] += 0.25;
		for (new i; i < count; i++) {
			new id = iPlayers[i];
			if (!is_user_alive(id))
				continue;
		}

		if (g_flSidesTime[g_iCurrentSW] >= get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0) {
			g_bGameStarted = false;
			g_bSurvival = false;
			new Float:flTimeDiff;
			if (g_iCurrentSW)
				flTimeDiff = g_flSidesTime[g_iCurrentSW] - g_flSidesTime[0];
			else
				flTimeDiff = g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[1];

			new szTime[24];
			fnConvertTime(flTimeDiff, szTime, 23, false);
			client_print_color(0, print_team_blue, "%L", 0, "TT_WIN", prefix, szTime);

			setTaskHud(0, 1.0, 1, 255, 255, 0, 4.0, "Game Over");
			taskPrepareMode(e_mTraining);

			g_bPlayersListLoaded = false;
		}
	}
	if ((g_flRoundTime / 60.0) >= get_pcvar_float(g_eCvars[e_cRoundTime])) {
		if (g_bGameStarted)
			g_bSurvival = false;

		remove_task();
	}
}

public rgPlayerSpawn(id) {

	if (!is_user_alive(id))
		return;

	if (g_iCurrentMode <= 1 || g_iCurrentMode == e_mCaptain)
		setUserGodmode(id, 1);

	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) {
		if (get_pcvar_num(g_eCvars[e_cHpMode]) == 1) {
			set_entvar(id, var_health, 1.0);
		}
	}

	setRole(id);
}

public setRole(id) {
	new TeamName:team = rg_get_user_team(id);
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

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3]) {
	if (rg_get_user_team(index) == TEAM_TERRORIST || rg_get_user_team(index) == TEAM_SPECTATOR)
		return HC_SUPERCEDE;

	return HC_CONTINUE;
}

public rgPlayerMakeBomber(const this) {
	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}

public rgPlayerMovePost(const PlayerMove:ppmove, const server) {
	static Float:velocity[3];
	new const id = get_pmove(pm_player_index) + 1;

	if (g_iCurrentMode > e_mPaused && g_iCurrentMode != e_mCaptain) {
		removeHook(id);
		return;
	}

	if(g_bHooked[id]) {
		velocity_by_aim(id, 550, velocity);
		set_pmove(pm_velocity, velocity);     
	}
}

public hookOn(id) {
	if (g_iCurrentMode > e_mPaused && g_iCurrentMode != e_mCaptain)
		return PLUGIN_HANDLED;

	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	g_bHooked[id] = true;

	return PLUGIN_HANDLED;
}

public hookOff(id) {
	removeHook(id);

	return PLUGIN_HANDLED;
}

public is_hooked(id) {
	return g_bHooked[id];
}

public removeHook(id) {
	if (task_exists(id + 9999))
		remove_task(id + 9999);

	if (!is_entity(id))
		return;

	g_bHooked[id] = false;
	set_entvar(id, var_gravity, 1.0);
}

public fwdPlayerKilledPre(id) {
	if (rg_get_user_team(id) != TEAM_TERRORIST)
		return;

	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPublic) {
		new iPlayers[32], iNum, index;
		get_players(iPlayers, iNum, "ace", "TERRORIST");

		if (iNum == 1) {
			index = iPlayers[0];
			g_bLastFlash[index] = true;
			g_iGiveNadesTo = index;
			show_menu(index, 3, "\rDo you need some nades?^n^n\r1. \wYes^n\r2. \wNo", -1, "NadesMenu");
			DisableHamForward(playerKilledPre);
		}
	}
}

public handleNadesMenu(id, szKey) {
	if (!g_bLastFlash[id] || id != g_iGiveNadesTo || !is_user_alive(id) || rg_get_user_team(id) != TEAM_TERRORIST)
		return;

	if (!szKey) {
		if (user_has_weapon(id, CSW_SMOKEGRENADE)) {
			rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) + 1);
		} else {
			rg_give_item(id, "weapon_smokegrenade");
		}

		if (user_has_weapon(id, CSW_FLASHBANG)) {
			rg_set_user_bpammo(id, WEAPON_FLASHBANG, rg_get_user_bpammo(id, WEAPON_FLASHBANG) + 1);
		} else {
			rg_give_item(id, "weapon_flashbang");
		}
	}

	g_bLastFlash[id] = false;
	g_iGiveNadesTo = 0;

}

public fwdDeployKnife(const iEntity) {
	new iClient = get_member(iEntity, m_pPlayer);

	if (g_bOnOff[iClient]) {
		set_pev(iClient, pev_viewmodel, 0);
	} else {
		set_pev(iClient, pev_viewmodel, g_iAllocKnifeModel);
	}

	if (get_user_team(iClient) == 1 && g_iCurrentMode != e_mKnife) {
		set_member(iEntity, m_Weapon_flNextPrimaryAttack, 9999.0);
		set_member(iEntity, m_Weapon_flNextSecondaryAttack, 9999.0);
	}
}

public fwdKnifePrim(const iPlayer) {
	if (g_iCurrentMode) {
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iPlayer);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public fwdSetClientListening(iReceiver, iSender, bool:bListen) {
	if (g_iCurrentMode <= e_mPaused || g_iCurrentMode == e_mCaptain || g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) {
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
		forward_return(FMV_CELL, true);
		return FMRES_SUPERCEDE;
	}

	if (is_user_connected(iReceiver) && is_user_connected(iSender)) {
		if (get_user_team(iReceiver) == get_user_team(iSender)) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			forward_return(FMV_CELL, true);
			return FMRES_SUPERCEDE;
		} else if (get_user_team(iReceiver) != 1 && get_user_team(iReceiver) != 2) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			forward_return(FMV_CELL, true);
			return FMRES_SUPERCEDE;
		}
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
	forward_return(FMV_CELL, false);
	return FMRES_SUPERCEDE;
}

public fwdEmitSoundPre(id, iChannel, szSample[], Float:volume, Float:attenuation, fFlags, pitch) {
	if (equal(szSample, "weapons/knife_deploy1.wav")) {
		return FMRES_SUPERCEDE;
	}

	if (is_user_alive(id) && rg_get_user_team(id) == TEAM_TERRORIST && equal(szSample, g_sndDenySelect)) {
		emit_sound(id, iChannel, g_sndUseSound, volume, attenuation, fFlags, pitch);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fwdClientKill(id) {
	client_print_color(0, print_team_blue, "%L", id, "KILL_HIMSELF", prefix, getName(id));
}

public fwdSpawn(entid) {
	static szClassName[32];
	if (pev_valid(entid)) {
		pev(entid, pev_classname, szClassName, 31);

		if (equal(szClassName, "func_buyzone"))
			engfunc(EngFunc_RemoveEntity, entid);

		for (new i = 0; i < sizeof g_szDefaultEntities; i++) {
			if (equal(szClassName, g_szDefaultEntities[i])) {
				engfunc(EngFunc_RemoveEntity, entid);
				break;
			}
		}
	}
}

public fwdGameNameDesc() {
	static gameName[32];
	get_pcvar_string(g_eCvars[e_cGameName], gameName, 31);
	forward_return(FMV_STRING, gameName);

	return FMRES_SUPERCEDE;
}

public msgHostagePos(msgid, dest, id) {
	return PLUGIN_HANDLED;
}

public msgShowMenu(msgid, dest, id) {
	if (!shouldAutoJoin(id))
		return (PLUGIN_CONTINUE);

	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);
	if (!equal(menu_text_code, team_select))
		return (PLUGIN_CONTINUE);

	setForceTeamJoinTask(id, msgid);

	return (PLUGIN_HANDLED);
}

public msgVguiMenu(msgid, dest, id) {
	if (get_msg_arg_int(1) != 2 || !shouldAutoJoin(id))
		return (PLUGIN_CONTINUE);

	setForceTeamJoinTask(id, msgid);

	return (PLUGIN_HANDLED);
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
		transferToSpec(id);
		return;
	}

	if (g_iCurrentMode == e_mTraining) {
		if (equali(g_eMatchInfo[e_mMapName], knifeMap)) {
			rg_round_respawn(id);
			g_bNoplay[id] = true;
			set_task(2.0, "taskPlay", id);
			return;
		}

		if (g_bPlayersListLoaded) {
			if (!checkPlayer(id))
				transferToSpec(id);
			else
				rg_round_respawn(id);
		}
		else
			rg_round_respawn(id);
	}
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
		case 1: client_print_color(0, print_team_blue, "%L", id, "STATUS_NOPLAY", prefix, getName(id));
	}
}

public sayHandle(id) {
	new szArgs[64];

	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if (!szArgs[0])
		return PLUGIN_HANDLED;

	if (szArgs[0] != '/')
		return PLUGIN_CONTINUE;

	new szTarget[32];

	parse(szArgs, \
	      szArgs, charsmax(szArgs), \
	      szTarget, charsmax(szTarget));

	if (equali(szArgs, "/wintime", 8)) {
		trim(szTarget);

		if (!(get_user_flags(id) & access))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_num(g_eCvars[e_cCapTime], str_to_num(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_WINTIME", prefix, getName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/Roundtime", 10)) {
		trim(szTarget);

		if (!(get_user_flags(id) & access))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_float(g_eCvars[e_cRoundTime], str_to_float(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_ROUNDTIME", prefix, getName(id), str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public cmdShowKnife(id) {
	g_bOnOff[id] = !g_bOnOff[id];

	client_print_color(id, print_team_blue, "%L", id, "SHOW_KNIFE", prefix, g_bOnOff[id] ? "^3in" : "^3");

	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (get_user_weapon(id) == CSW_KNIFE) {
		if (g_bOnOff[id]){
			set_pev(id, pev_viewmodel, 0);
		} else {
			new iWeapon = get_member(id, m_pActiveItem);
			if (iWeapon != -1)
				ExecuteHamB(Ham_Item_Deploy, iWeapon);
		}
	}

	return PLUGIN_CONTINUE;
}

public cmdPubMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mPublic) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mPublic);
			client_print_color(0, print_team_blue, "%L", id, "PUB_ACTIVATED", prefix, getName(id));
		}
	} else {
		client_print_color(id, print_team_blue, "%L", id, "PUB_ALREADY", prefix, getName(id));
	}

	if (containi(g_eMatchInfo[e_mMapName], "boost") != -1) {
		disableSemiclip();
	} else {
		enableSemiclip(3);
	}

	removeHook(id);

	return PLUGIN_HANDLED;
}

public cmdDMMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode != e_mDM) {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			taskPrepareMode(e_mDM);
			client_print_color(0, print_team_blue, "%L", id, "DM_ACTIVATED", prefix, getName(id));
		}
	} else {
		if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mKnife && g_iCurrentMode != e_mPaused) {
			client_print_color(id, print_team_blue, "%L", id, "DM_ALREADY", prefix, getName(id));
		}
	}

	if (containi(g_eMatchInfo[e_mMapName], "boost") != -1) {
		disableSemiclip();
	} else {
		enableSemiclip(3);
	}

	removeHook(id);

	return PLUGIN_HANDLED;
}

public cmdTransferSpec(id) {
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_SPEC", prefix, getName(id));
	transferPlayers(TEAM_SPECTATOR);
	return PLUGIN_HANDLED;
}

public cmdTransferTT(id) {
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_TT", prefix, getName(id));
	transferPlayers(TEAM_TERRORIST);
	return PLUGIN_HANDLED;
}

public cmdTransferCT(id) {
	if (!(get_user_flags(id) & access))
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TRANSF_CT", prefix, getName(id));
	transferPlayers(TEAM_CT);
	return PLUGIN_HANDLED;
}

public cmdSurrender(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!playerInMatch(id))
		return;

	if (g_eSurrenderData[e_sStarted])
		return;

	if (g_eSurrenderData[e_sFlDelay] > get_gametime()) {
		new szTime[24];
		fnConvertTime(g_eSurrenderData[e_sFlDelay] - get_gametime(), szTime, 23, false);
		client_print_color(id, print_team_blue, "%L", id, "SUR_WAIT", prefix, szTime);
		return;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", rg_get_user_team(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (iNum != g_eMatchInfo[e_mTeamSizeTT])
		return;

	g_eSurrenderData[e_sStarted] = true;
	g_eSurrenderData[e_sInitiator] = id;
	g_eSurrenderData[e_sFlDelay] = get_gametime() + surrenderTimeDelay;
	client_print_color(0, print_team_blue, "%L", id, "SUR_PLAYER", prefix, id, rg_get_user_team(id) == TEAM_TERRORIST ? "TERRORISTS" : "CTS");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		surrenderMenu(iPlayer);
	}
	set_task(1.0, "taskSurrender", .flags = "b");
}

public taskSurrender() {
	new id = g_eSurrenderData[e_sInitiator];
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ce", rg_get_user_team(id) == TEAM_TERRORIST ? "TERRORIST" : "CT");

	if (!is_user_connected(id)) {
		resetSurrenderData();
		return;
	}

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused) {
		resetSurrenderData();
		return;
	}

	if (rg_get_user_team(id) == TEAM_SPECTATOR) {
		resetSurrenderData();
		return;
	}

	if (iNum != g_eMatchInfo[e_mTeamSizeTT]) {
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderVotes[e_sYes] == g_eMatchInfo[e_mTeamSizeTT]) {
		autoLose(rg_get_user_team(id));
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderVotes[e_sNo] == g_eMatchInfo[e_mTeamSizeTT]) {
		resetSurrenderData();
		return;
	}

	if (g_eSurrenderData[e_sFlTime] == surrenderVoteTime) {
		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			client_print_color(iPlayer, print_team_blue, "%L", id, "SUR_NEED", prefix, g_eMatchInfo[e_mTeamSizeTT], g_eMatchInfo[e_mTeamSizeTT]);
		}
		resetSurrenderData();
		return;
	}
	g_eSurrenderData[e_sFlTime]++;
}

public surrenderMenu(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!playerInMatch(id))
		return;

	new iPlayer = g_eSurrenderData[e_sInitiator];
	if (rg_get_user_team(id) != rg_get_user_team(iPlayer))
		return;

	new iMenu = menu_create(fmt("\ySurrender?^n\dVote by %n", iPlayer), "surrenderMenuHandler");

	menu_additem(iMenu, "Yes");
	menu_additem(iMenu, "No");

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, iMenu, 0);
}

public surrenderMenuHandler(id, iMenu, item) {
	menu_destroy(iMenu);
	if (!is_user_connected(id))
		return;

	if (item == MENU_EXIT)
		return;

	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return;

	if (!playerInMatch(id))
		return;

	new iPlayer = g_eSurrenderData[e_sInitiator];
	if (rg_get_user_team(id) != rg_get_user_team(iPlayer))
		return;

	if (g_bSurrenderVoted[id])
		return;

	g_eSurrenderVotes[item]++;
	g_bSurrenderVoted[id] = true;
}

autoLose(TeamName:iTeam) {
	client_print_color(0, print_team_blue, "%L", 0, "SUR_END", prefix, iTeam == TEAM_TERRORIST ? "TERRORISTS" : "CTS");
	setTaskHud(0, 0.0, 1, 255, 255, 0, 4.0, "Game Over");
	cmdStop(0);
}

resetSurrenderData() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];
		g_bSurrenderVoted[id] = false;
	}

	arrayset(g_eSurrenderVotes, 0, SurrenderVote);
	arrayset(g_eSurrenderData, 0, SurrenderData_s);
	remove_task();
}

stock bool:playerInMatch(id) {
	if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused)
		return false;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (rg_get_user_team(iPlayer) == TEAM_SPECTATOR)
			continue;

		if (id == iPlayer)
			return true;
	}
	return false;
}

public cmdNoplay(id) {
		if (!g_bNoplay[id]) {
			g_bNoplay[id] = true;
			client_print_color(0, print_team_blue, "%L", id, "STATUS_NOPLAY", prefix, getName(id));
		}
}

public cmdPlay(id) {
		if (g_bNoplay[id]) {
			g_bNoplay[id] = false;
			client_print_color(0, print_team_blue, "%L", id, "STATUS_PLAY", prefix, getName(id));
		}
}

public blockCmd(id) {
	if (g_iCurrentMode != e_mTraining)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public cmdTeamSpec(id) {
	if (g_iCurrentMode != e_mPublic)
		return;

	if (g_iCurrentMode != e_mDM)
		return;

	g_bSpec[id] = !g_bSpec[id];

	if (g_bSpec[id]) {
		if (rg_get_user_team(id) == TEAM_SPECTATOR) {
			g_bSpec[id] = false;
			return;
		}
		hTeam[id] = rg_get_user_team(id);
		transferToSpec(id);
	} else {
		if (rg_get_user_team(id) != TEAM_SPECTATOR) {
			g_bSpec[id] = true;
			return;
		}
		rg_set_user_team(id, hTeam[id]);
	}
}

public cmdStartPause(id) {
	if (id && ~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mMatch) {
		g_iCurrentMode = e_mPaused;

		if (g_bGameStarted) {
			g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;

			g_bSurvival = false;
			g_bGameStarted = false;
		} else {
			if (id)
				client_print_color(id, print_team_blue,  "%L", id, "GAME_NOTSTARTED", prefix);
		}

		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "ac");

		for (new i; i < iNum; i++) {
			new iPlayer = iPlayers[i];
			rg_remove_all_items(iPlayer);
			rg_give_item(iPlayer, "weapon_knife");
			setUserGodmode(iPlayer, true);
			rg_reset_maxspeed(iPlayer);
		}

		set_task(1.0, "taskHudPaused", _, _, _, "b");

		if (id) {
			client_print_color(0, print_team_blue, "%L", id, "GAME_PAUSED", prefix, getName(id));
		}

		rg_send_audio(0, "fvox/activated.wav");
		disableSemiclip();
	}
	return PLUGIN_HANDLED;
}

public taskHudPaused() {
	if (g_iCurrentMode == e_mPaused) {
		set_dhudmessage(100, 100, 100, -1.0, 0.75, 0, 0.0, 1.01, 0.0, 0.0);
		show_dhudmessage(0, "GAME PAUSE");
	}
}

public cmdStopPause(id) {
	if (id && ~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	if (g_iCurrentMode == e_mPaused) {
		g_iCurrentMode = e_mMatch;

		if (id) {
			client_print_color(0, print_team_blue, "%L", id, "GAME_UNPAUSED", prefix, getName(id));
		}

		rg_send_audio(0, "fvox/deactivated.wav");
		g_bGameStarted = true;

		setTaskHud(0, 1.0, 1, 255, 255, 0, 3.0, "Game Unpause^nLive Live Live");

		restartRound();
		removeHook(id);

		if (get_pcvar_num(g_eCvars[e_cSemiclip]) == 1) {
			set_cvar_num("mp_freezetime", 5);
			enableSemiclip(3);
		} else {
			set_cvar_num("mp_freezetime", 15);
			disableSemiclip();
		}
		loadMapCFG();
	}
	return PLUGIN_HANDLED;
}

public cmdSwapTeams(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "GAME_SWAP", prefix, getName(id));

	restartRound();
	rg_swap_all_players();
	removeHook(id);
	g_iCurrentSW = !g_iCurrentSW;

	return PLUGIN_HANDLED;
}

public cmdRestartRound(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "GAME_RESTART", prefix, getName(id));
	restartRound();
	removeHook(id);

	return PLUGIN_HANDLED;
}


public cmdSkillMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TYPE_SKILL", prefix, getName(id));

	if (equali(knifeMap, g_eMatchInfo[e_mMapName])) {
		enableSemiclip(0);
	} else {
		if (g_iCurrentMode == e_mTraining)
			enableSemiclip(0);
		else
			enableSemiclip(3);
	}

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 5);
		set_pcvar_num(g_eCvars[e_cFlashNum], 1);
		set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
	}

	set_pcvar_num(g_eCvars[e_cSemiclip], 1);

	return PLUGIN_HANDLED;
}

public cmdBoostMode(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "TYPE_BOOST", prefix, getName(id));

	if (g_iCurrentMode == e_mMatch) {
		set_cvar_num("mp_freezetime", 15);
		set_pcvar_num(g_eCvars[e_cFlashNum], 3);
		set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
	}
	set_pcvar_num(g_eCvars[e_cSemiclip], 0);
	disableSemiclip();

	return PLUGIN_HANDLED;
}

public cmdAa10(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "AA_10", prefix, getName(id));

	set_cvar_num("sv_airaccelerate", 10);
	set_pcvar_num(g_eCvars[e_cAA], 10);

	return PLUGIN_HANDLED;
}

public cmdAa100(id) {
	if (~get_user_flags(id) & access)
		return PLUGIN_HANDLED;

	client_print_color(0, print_team_blue, "%L", id, "AA_100", prefix, getName(id));

	set_cvar_num("sv_airaccelerate", 100);
	set_pcvar_num(g_eCvars[e_cAA], 100);

	return PLUGIN_HANDLED;
}

public mainMatchMenu(id) {
	if (!is_user_connected(id))
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
				if ((g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) && get_user_flags(id) & access) {
					return 0;
				}
				else if (g_iCurrentMode == e_mTraining && get_user_flags(id) & access)
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
				if (g_iCurrentMode != e_mMatch && g_iCurrentMode != e_mPaused && get_user_flags(id) & access) {
					if (g_iCurrentMode == e_mKnife && get_user_flags(id) & access)
						cmdStop(id);
					else
						cmdKnifeRound(id);
				}
			} else {
				if (g_iCurrentMode == e_mTraining && get_user_flags(id) & access)
					customMenu(id);
				else if ((g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) && get_user_flags(id) & access)
					cmdStop(id);
				else {
					if (g_iCurrentMode != e_mPaused && get_user_flags(id) & access)
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
			amxclient_cmd(id, "amx_teammenu");
		}
		case 7: {
			amxclient_cmd(id, "amx_mapmenu");
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

public cmdStartRound(id) {
	if (get_user_flags(id) & access) {
		if (g_iCurrentMode != e_mTraining) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_START_MIX", prefix);
			return;
		} else {
			if (equali(g_eMatchInfo[e_mMapName], knifeMap))
				return;

			client_print_color(0, print_team_blue, "%L", id, "START_MIX", prefix, getName(id));
			g_eSurrenderData[e_sFlDelay] = get_gametime() + surrenderTimeDelay;
			pfStartMatch();
		}
	}
}

public cmdStopMode(id) {
	if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
		verifMenu(id);
	} else {
		cmdStop(id);
	}
}

public cmdStop(id) {
	if (id && ~get_user_flags(id) & access)
		return;

	if (!g_iCurrentMode)
		return;

	if (!id) {
		if (g_iCurrentMode == e_mMatch || g_iCurrentMode == e_mPaused) {
			g_bGameStarted = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
			taskPrepareMode(e_mTraining);
			return;
		}

		rg_send_audio(0, "fvox/fuzz.wav");
		taskPrepareMode(e_mTraining);
		return;
	}

	switch (g_iCurrentMode) {
		case e_mPaused, e_mMatch: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_MIX", prefix, getName(id));
			g_bGameStarted = false;
			g_bSurvival = false;
			g_bPlayersListLoaded = false;
		}
		case e_mKnife: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_KNIFE", prefix, getName(id));
		}
		case e_mCaptain: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_CAP", prefix, getName(id));
			resetCaptainData();
			return;
		}
		case e_mPublic: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_PUB", prefix, getName(id));
		}
		case e_mDM: {
			client_print_color(0, print_team_blue, "%L", id, "STOP_DM", prefix, getName(id));
		}
	}
	rg_send_audio(0, "fvox/fuzz.wav");
	taskPrepareMode(e_mTraining);
}

public cmdKnifeRound(id) {
	if (get_user_flags(id) & access) {
		if (g_iCurrentMode != e_mTraining) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_START_KNIFE", prefix);
			return;
		} else {
			pfKnifeRound(id);
			removeHook(id);
		}
	}
}

public pfStartMatch() {
	rg_send_audio(0, "plats/elevbell1.wav");
	set_task(2.5, "taskPrepareMode", e_mMatch);
	setTaskHud(0, 0.0, 1, 255, 255, 0, 3.0, "Going Live in 3 second!");
	setTaskHud(0, 3.1, 1, 255, 255, 0, 3.0, "Live! Live! Live!^nGood Luck & Have Fun!");
}

public pfKnifeRound(id) {
	taskPrepareMode(e_mKnife);
	setTaskHud(0, 2.0, 1, 255, 255, 0, 3.0, "Knife Round Started");

	if (id)
		client_print_color(0, print_team_blue, "%L", id, "START_KNIFE", prefix, getName(id));

	return PLUGIN_HANDLED;
}

public cmdShowTimers(id) {
	if (g_bGameStarted || g_iCurrentMode == e_mPaused) {
		new timeToWin[2][24];
		fnConvertTime((get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0) - g_flSidesTime[g_iCurrentSW], timeToWin[0], 23);
		fnConvertTime((get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0) - g_flSidesTime[!g_iCurrentSW], timeToWin[1], 23);

		new timeDiff[2][24];
		fnConvertTime(g_flSidesTime[g_iCurrentSW] - g_flSidesTime[!g_iCurrentSW], timeDiff[0], 23, false);
		fnConvertTime(g_flSidesTime[!g_iCurrentSW] - g_flSidesTime[g_iCurrentSW], timeDiff[1], 23, false);

		new iPlayers[MAX_PLAYERS], TTsize, CTSize;
		get_players(iPlayers, TTsize, "ce", "TERRORIST");
		get_players(iPlayers, CTSize, "ce", "CT");

		if (g_flSidesTime[!g_iCurrentSW] > g_flSidesTime[g_iCurrentSW]) {
			if (!g_iCurrentSW)
				client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME1", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[1]);
			else
				client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME2", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[1]);
		} else if(g_flSidesTime[!g_iCurrentSW] < g_flSidesTime[g_iCurrentSW]) {
			if (!g_iCurrentSW)
				client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME3", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[0]);
			else
				client_print_color(id, print_team_red, "%L", 0, "SCORE_TIME4", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[0]);
		} else {
			if (!g_iCurrentSW)
				client_print_color(id, print_team_blue, "%L", 0, "SCORE_TIME5", timeToWin[g_iCurrentSW], TTsize, CTSize, timeToWin[!g_iCurrentSW], timeDiff[0]);
			else
				client_print_color(id, print_team_blue, "%L", 0, "SCORE_TIME6", timeToWin[!g_iCurrentSW], TTsize, CTSize, timeToWin[g_iCurrentSW], timeDiff[1]);
		}
	} else {
		client_print_color(id, print_team_blue, "%L", id, "SCORE_NOT", prefix);
	}
}

public getName(id) {
	new szName[128];
	get_user_name(id, szName, charsmax(szName));
	return szName;
}

public taskPrepareMode(mode) {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem/mode", szPath);
	switch (mode) {
		case e_mTraining: {
			g_iCurrentMode = e_mTraining;
			server_cmd("exec %s/training.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);
			disableSemiclip();
		}
		case e_mKnife: {
			g_iCurrentMode = e_mKnife;
			server_cmd("exec %s/knife.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);
			disableSemiclip();
		}
		case e_mMatch: {
			g_iCurrentMode = e_mMatch;
			g_flSidesTime[0] = 0.0;
			g_flSidesTime[1] = 0.0;
			g_iCurrentSW = 1;
			g_bGameStarted = true;

			server_cmd("exec %s/match.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cLastMode], 0);

			if (get_pcvar_num(g_eCvars[e_cSemiclip]) == 1) {
				set_cvar_num("mp_freezetime", 5);
				set_pcvar_num(g_eCvars[e_cFlashNum], 1);
				set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
				set_pcvar_num(g_eCvars[e_cSemiclip], 1);
				enableSemiclip(3);
				loadMapCFG();
			} else {
				set_cvar_num("mp_freezetime", 15);
				set_pcvar_num(g_eCvars[e_cFlashNum], 3);
				set_pcvar_num(g_eCvars[e_cSmokeNum], 1);
				set_pcvar_num(g_eCvars[e_cSemiclip], 0);
				disableSemiclip();
				loadMapCFG();
			}

			loadMapCFG();

			new iPlayers[MAX_PLAYERS], iNum;
			get_players(iPlayers, iNum, "ce", "TERRORIST");
			g_eMatchInfo[e_mTeamSizeTT] = iNum;

			fnConvertTime(get_pcvar_float(g_eCvars[e_cCapTime]) * 60.0, g_eMatchInfo[e_mWinTime], charsmax(g_eMatchInfo[e_mWinTime]));
			rg_send_audio(0, "sound/barney/ba_bring.wav");
		}
		case e_mPublic: {
			g_iCurrentMode = e_mPublic;
			server_cmd("exec %s/public.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cFlashNum], 1);
			set_pcvar_num(g_eCvars[e_cLastMode], 1);
			enableSemiclip(3);
			loadMapCFG();
		}
		case e_mDM: {
			g_iCurrentMode = e_mDM;
			server_cmd("exec %s/deathmatch.cfg", szPath);
			set_pcvar_num(g_eCvars[e_cFlashNum], 1);
			set_pcvar_num(g_eCvars[e_cLastMode], 2);
			enableSemiclip(3);
		} 
		case e_mCaptain: {
			g_iCurrentMode = e_mCaptain;
			server_cmd("exec %s/captain.cfg", szPath);
			enableSemiclip(0);
		}
	}
	restartRound();
}

restartRound(Float:delay = 0.5) {
	if (g_bSurvival) {
		g_flSidesTime[g_iCurrentSW] -= g_flRoundTime;
	}
	g_bSurvival = false;
	rg_round_end(delay, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Restarted", "none");
}

public setTaskHud(id, Float:Time, Dhud, Red, Green, Blue, Float:HoldTime, const Text[], any: ...) {
	new szMessage[128]; vformat(szMessage, charsmax(szMessage), Text, 9);
	new szArgs[7];
	szArgs[0] = id;
	szArgs[1] = encodeText(szMessage);
	szArgs[2] = Red;
	szArgs[3] = Green;
	szArgs[4] = Blue;
	szArgs[5] = Dhud;
	szArgs[6] = _:HoldTime;
	if (Time > 0.0)
		set_task(Time, "taskHudMessage", 89000, szArgs, 7);
	else
		taskHudMessage(szArgs);
}

public taskHudMessage(Params[]) {
	new id, Text[128], RRR, GGG, BBB, dhud, Float:HoldTime;
	id = Params[0];
	decodeText(Params[1], Text, charsmax(Text));
	RRR = Params[2];
	GGG = Params[3];
	BBB = Params[4];
	dhud = Params[5];
	HoldTime = Float:Params[6];

	if (!id || is_user_connected(id)) {
		if (dhud) {
			set_dhudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1);

			show_dhudmessage(id, Text);
		} else {
			set_hudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1, -1);
			show_hudmessage(id, Text);
		}
	}
}

stock RegisterSayCmd(const szCmd[], const szShort[], const szFunc[], flags = -1, szInfo[] = "") {
	new szTemp[65], szInfoLang[65];
	format(szInfoLang, 64, "%L", LANG_SERVER, szInfo);

	format(szTemp, 64, "say /%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say /%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	return 1;
}

stock encodeText(const text[]) {
	return engfunc(EngFunc_AllocString, text);
}

stock decodeText(const text, string[], const length) {
	global_get(glb_pStringBase, text, string, length);
}

public cmdCaptain(id) {
	if (~get_user_flags(id) & access)
		return;

	if (!equali(g_eMatchInfo[e_mMapName], knifeMap))
		return;

	if (g_iCurrentMode != e_mTraining)
		return;

	resetCaptainData();
	g_iCurrentMode = e_mCaptain;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new iPlayer = iPlayers[i];

		if (rg_get_user_team(iPlayer) == TEAM_SPECTATOR)
			continue;

		transferToSpec(iPlayer);
	}
	chooseCapsMenu(id);
	client_print_color(0, print_team_blue, "%L", id, "CAP_CHOOSE", prefix, id);
}

public chooseCapsMenu(id) {
	if (!is_user_connected(id))
		return;

	if (~get_user_flags(id) & access)
		return;

	if (g_iCurrentMode != e_mCaptain)
		return;

	new iMenu = menu_create("\yChoose captains", "chooseCapsHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "c");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		if (iPlayer == g_eCaptain[e_cTT] || iPlayer == g_eCaptain[e_cCT])
			continue;

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(iMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(iMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(iMenu, MPROP_SHOWPAGE, 0);
	menu_display(id, iMenu, 0);
}

public chooseCapsHandler(id, iMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(iMenu);
		return;
	}

	if (g_iCurrentMode != e_mCaptain) {
		menu_destroy(iMenu);
		return;
	}

	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		chooseCapsMenu(id);
		return;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(iMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		chooseCapsMenu(id);
		return;
	}

	if (g_bNoplay[iPlayer]) {
		chooseCapsMenu(id);
		return;
	}

	if (!g_eCaptain[e_cTT]) {
		g_eCaptain[e_cTT] = iPlayer;
		client_print_color(0, print_team_blue, "%L", id, "CAP_FIRST", prefix, iPlayer);

		chooseCapsMenu(id);
	} else if (!g_eCaptain[e_cCT]) {
		g_eCaptain[e_cCT] = iPlayer;
		client_print_color(0, print_team_blue, "%L", id, "CAP_SECOND", prefix, iPlayer);

		if (is_user_connected(g_eCaptain[e_cTT]) && is_user_connected(g_eCaptain[e_cCT])) {
			rg_set_user_team(g_eCaptain[e_cTT], TEAM_TERRORIST);
			rg_set_user_team(g_eCaptain[e_cCT], TEAM_CT);

			g_bCaptainsBattle = true;
			pfKnifeRound(0);
		} else {
			client_print_color(0, print_team_blue, "%L", id, "CAP_HAS_LEFT", prefix);
			resetCaptainData();
		}
	}
}

public cmdPick(id) {
	if (!is_user_connected(id))
		return;

	if (g_iCurrentMode != e_mCaptain)
		return;

	if (id != g_iCaptainPick)
		return;

	pickMenu(id);
}

public pickMenu(id) {
	new iMenu = menu_create("\yPick player", "pickHandler");

	new iPlayers[MAX_PLAYERS], iNum, szPlayer[10], iPlayer;
	get_players(iPlayers, iNum, "ce", "SPECTATOR");

	new szBuffer[256];
	for (new i; i < iNum; i++) {
		iPlayer = iPlayers[i];

		num_to_str(iPlayer, szPlayer, charsmax(szPlayer));
		add(szBuffer, charsmax(szBuffer), fmt("%n ", iPlayer));

		if (g_bNoplay[iPlayer])
			add(szBuffer, charsmax(szBuffer), "\r[Noplay] ");

		menu_additem(iMenu, szBuffer, szPlayer);
		szBuffer = "";
	}

	menu_setprop(iMenu, MPROP_EXITNAME, "Refresh");
	menu_setprop(iMenu, MPROP_SHOWPAGE, false);
	menu_display(id, iMenu, 0);
}

public pickHandler(id, iMenu, item) {
	if (!is_user_connected(id)) {
		menu_destroy(iMenu);
		return;
	}

	if (g_iCurrentMode != e_mCaptain) {
		menu_destroy(iMenu);
		return;
	}

	if (id != g_iCaptainPick) {
		menu_destroy(iMenu);
		return;
	}

	if (rg_get_user_team(id) == TEAM_SPECTATOR) {
		menu_destroy(iMenu);
		return;
	}

	if (item == MENU_EXIT) {
		menu_destroy(iMenu);
		pickMenu(id);
		return;
	}

	new szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(iMenu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);
	menu_destroy(iMenu);

	new iPlayer = str_to_num(szData);

	if (!is_user_connected(iPlayer)) {
		pickMenu(id);
		return;
	}

	if (g_bNoplay[iPlayer]) {
		pickMenu(id);
		return;
	}

	client_print_color(0, print_team_blue, "%L", id, "PLAYER_CHOOSE", prefix, id, iPlayer);
	rg_set_user_team(iPlayer, rg_get_user_team(id));
	rg_round_respawn(iPlayer);

	g_iCaptainPick = id == g_eCaptain[e_cTT] ? g_eCaptain[e_cCT] : g_eCaptain[e_cTT];

	pickMenu(g_iCaptainPick);

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "c");

	new iTotalPlayers;
	for (new i; i < iNum; i++) {
		new tempid = iPlayers[i];

		if (rg_get_user_team(tempid) == TEAM_SPECTATOR) continue;

		iTotalPlayers++;
	}

	if (iTotalPlayers == 10) {
		resetCaptainData();
		client_print_color(0, print_team_blue, "%L", id, "TEAM_FULL", prefix);
	}
}

resetCaptainData() {
	g_iCaptainPick = 0;
	g_bCaptainsBattle = false;

	for (new i; i < sizeof(g_eCaptain); i++) {
		if (is_user_connected(g_eCaptain[i])) {
			show_menu(g_eCaptain[i], 0, "^n", 1);
		}

		g_eCaptain[i] = 0;
	}

	taskPrepareMode(e_mTraining);
}

public loadMapCFG() {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem", szPath);
	if (!dir_exists(szPath))
		mkdir(szPath);

	format(szPath, 127, "%s/mapcfg/%s.cfg", szPath, g_eMatchInfo[e_mMapName]);

	if (file_exists(szPath))
		server_cmd("exec %s", szPath);
	else
		server_cmd("mp_roundtime 3.5");
}

public bool:checkPlayer(id) {
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
			ArrayPushArray(g_aPlayersLoadData, eTempPlayer);
			arrayset(eTempPlayer, 0, PlayersLoad_s);
			iSave = 0;
		}
		json_free(objValue);
	}
}

public savePlayers(TeamName:team_winners) {
	new JSON:arrayRoot = json_init_array();

	new iPlayers[MAX_PLAYERS], iNum, szAuth[24];
	get_players(iPlayers, iNum, "c");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];

		if (rg_get_user_team(id) == TEAM_SPECTATOR) continue;

		get_user_authid(id, szAuth, charsmax(szAuth));

		arrayAppendValue(arrayRoot, json_init_string(fmt("player_%i", i + 1)));

		new JSON:object = json_init_object();
		json_object_set_string(object, "e_pAuth", fmt("%s", szAuth));
		new TeamName:iTeam = TeamName:rg_get_user_team(id) == team_winners ? TEAM_TERRORIST : TEAM_CT;
		json_object_set_number(object, "e_pTeam", _:iTeam);
		arrayAppendValue(arrayRoot, object);
		json_free(object);
	}

	json_serial_to_string(arrayRoot, g_szBuffer, charsmax(g_szBuffer), true);
	server_print("Players saved (%d bytes)", json_serial_size(arrayRoot, true));
	json_free(arrayRoot);
}

arrayAppendValue(JSON:array, JSON:node) {
	json_array_append_value(array, node);
	json_free(node);
}

public transferPlayers(TeamName:iTeam) {
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

		if (rg_get_user_team(id) != team)
			setTeam(id, TeamName:team);
	}
}

stock setUserGodmode(index, godmode = 0) {
	set_entvar(index, var_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);

	return 1;
}

fnConvertTime(Float:time, convert_time[], len, bool:with_intpart = true) {
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

	formatex(convert_time, len, szTemp);

	return (PLUGIN_HANDLED);
}

stock transferToSpec(id) {
	setTeam(id, TEAM_SPECTATOR);
	set_entvar(id, var_solid, SOLID_NOT);
	set_entvar(id, var_movetype, MOVETYPE_FLY);
}

enableSemiclip(team) {
	server_cmd("semiclip_option semiclip 1");
	server_cmd("semiclip_option team %d", team);
	server_cmd("semiclip_option time 0");
}

disableSemiclip() {
	server_cmd("semiclip_option semiclip 0");
	server_cmd("semiclip_option team 0");
	server_cmd("semiclip_option time 0");
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

// Спасибо: Cultura, Garey, Medusa, Ruffman, Conor
