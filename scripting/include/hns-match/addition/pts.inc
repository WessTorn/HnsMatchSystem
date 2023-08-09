forward hns_pts_init_player(id, iPts, iWins, iLoss, iTop);

public hns_pts_init_player(id, iPts, iWins, iLoss, iTop) {
	g_ePlayerPtsData[id][e_bInit] = true;
	g_ePlayerPtsData[id][e_iPts] = iPts;
	g_ePlayerPtsData[id][e_iWins] = iWins;
	g_ePlayerPtsData[id][e_iLoss] = iLoss;
	g_ePlayerPtsData[id][e_iTop] = iTop;
	g_ePlayerPtsData[id][e_szRank] = get_skill_player(g_ePlayerPtsData[id][e_iPts]);
	//console_print(0, "%n %d %d %d %d", id, iPts, iWins, iLoss, iTop)
}

enum _:SKILL_INFO
{
	SKILL_PTS,
	SKILL_LVL[10]
};

new const g_eSkillData[][SKILL_INFO] = {
	// pts	 skill
	{ 0,	"L-" },
	{ 650,	"L" },
	{ 750,	"L+" },
	{ 850,	"M-" },
	{ 950,	"M" },
	{ 1050,	"M+" },
	{ 1150,	"H-" },
	{ 1250,	"H" },
	{ 1350,	"H+" },
	{ 1450,	"P-" },
	{ 1550,	"P" },
	{ 1650,	"P+" },
	{ 1750,	"G-" },
	{ 1850,	"G" },
	{ 1950,	"G+" },
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