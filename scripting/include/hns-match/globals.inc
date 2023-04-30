#if defined _globals_included
  #endinput
#endif

#define _globals_included

#define access ADMIN_MAP

new g_PluginId;

stock knifemap[24];

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

new g_iGameStops;

enum _:CaptainTeam_s {
	e_cTT,
	e_cCT
};
new g_eCaptain[CaptainTeam_s], g_iCaptainPick;
new bool:g_bCaptainsBattle;

enum _:MatchInfo_s {
	e_mMapName[32],
	e_mTeamSizeTT
};
new g_eMatchInfo[MatchInfo_s];

enum _:SurrenderData_s {
	bool:e_sStarted,
	e_sInitiator,
	Float:e_sFlDelay,
	Float:e_sFlTime
};
new g_eSurrenderData[SurrenderData_s];

enum _:Cvars_s {
	e_cKnifeMap[25]
};

new bool:g_bSurvival;
new bool:g_bGameStarted;
new bool:g_bLastRound;
new bool:g_bHooked[MAX_PLAYERS + 1];
new bool:g_bNoplay[MAX_PLAYERS + 1];
new bool:g_bSpec[MAX_PLAYERS + 1];
new bool:g_bPlayersListLoaded;
new bool:g_bLastFlash[MAX_PLAYERS + 1];
new bool:g_bOnOff[33];
new bool:g_bFreezePeriod = false;

new Float:g_flRoundTime;
new Float:g_flSidesTime[2];

new g_iCurrentSW;
new g_iRoundsPlayed[2];
new g_iRegisterSpawn;
new g_iHostageEnt;
new g_szBuffer[2048];

new TeamName:hTeam[MAX_PLAYERS + 1];
new HamHook:playerKilledPre;

new g_MsgSync;

new g_iBestAuth[10][MAX_AUTHID_LENGTH];

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