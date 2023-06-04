#if defined _hns_matchsystem_pts_included
	#endinput
#endif
#define _hns_matchsystem_pts_included

enum _:Info
{
    pts,
    wins,
    loss,
    rank,
    top,
    skill[10]
};

enum _:SKILL_INFO
{
    SKILL_PTS,
    SKILL_LVL[10]
};

native hns_pts_get_player_info(id, info);

new const g_eSkillData[][SKILL_INFO] = {
	// pts     skill
	{ 0,       "L-" },
	{ 650,     "L" },
	{ 750,     "L+" },
	{ 850,     "M-" },
	{ 950,     "M" },
	{ 1050,     "M+" },
	{ 1150,     "H-" },
	{ 1250,    "H" },
	{ 1350,    "H+" },
	{ 1450,    "P-" },
	{ 1550,    "P" },
	{ 1650,    "P+" },
	{ 1750,    "G-" },
	{ 1850,    "G" },
	{ 1950,    "G+" },
	
};

stock get_skill_player(iPts) {
	new iPtr[10];
	for (new i; i < sizeof(g_eSkillData); i++) {
		if (iPts >= g_eSkillData[i][SKILL_PTS]) {
			formatex(iPtr, charsmax(iPtr), "%s", g_eSkillData[i][SKILL_LVL]);
		}
	}
	return iPtr;
}
