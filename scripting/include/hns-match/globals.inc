#if defined _globals_included
  #endinput
#endif

#define _globals_included

#define prefix "^1>"
#define access ADMIN_MAP
#define knifeMap "35hp_2"

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
new g_eSurrenderData[SurrenderData_s];

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
new g_iHostageEnt;
new g_szBuffer[2048];

new TeamName:hTeam[MAX_PLAYERS + 1];
new HamHook:playerKilledPre;
