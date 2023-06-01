#if defined _globals_included
  #endinput
#endif

#define _globals_included

#define access ADMIN_MAP

new g_PluginId;

stock knifemap[24];

const RETRY_TIME = 30;
new Float:g_flRetry;
const TASK_SET_TEAM = 23456;
const Float:RETRY_HP = 95.0;

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

enum _:CaptainTeam_s {
	e_cTT,
	e_cCT
};
new g_eCaptain[CaptainTeam_s], g_iCaptainPick;
new bool:g_bCaptainsBattle;

enum HNS_TEAM {
	HNS_TEAM_B = 0,
	HNS_TEAM_A
}

new HNS_TEAM:g_isTeamTT;

enum {
	ROUND_NOT,
	ROUND_FREEZE,
	ROUND_START
}

enum _:MatchInfo_s {
	bool:e_bStarted,
	bool:e_bLastRound,
	e_mTeamSizeTT,
	e_sRoundInfo,
	e_iGameStops,
	Float:e_flSidesTime[HNS_TEAM],
	e_iRoundsPlayed[HNS_TEAM]
};

new g_eMatchInfo[MatchInfo_s];

enum _:SurrenderData_s {
	bool:e_sStarted,
	e_sInitiator,
	Float:e_sFlDelay,
	Float:e_sFlTime
};
new g_eSurrenderData[SurrenderData_s];

new bool:g_bHooked[MAX_PLAYERS + 1];
new bool:g_bNoplay[MAX_PLAYERS + 1];
new bool:g_bPlayersListLoaded;
new bool:g_bLastFlash[MAX_PLAYERS + 1];
new bool:g_bOnOff[MAX_PLAYERS + 1];

new Float:g_flRoundTime;

new g_szMapName[32]
new g_iRegisterSpawn;
new g_iHostageEnt;

new bool:g_bSpec[MAX_PLAYERS + 1];
new TeamName:hTeam[MAX_PLAYERS + 1];

new g_MsgSync;


// const
new const sndDenySelect[] = "common/wpn_denyselect.wav";
new const sndUseSound[] = "buttons/blip1.wav";
new const szDefaultEntities[][] = {
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

new g_hResetBugForward;