static g_pCapTime;
static g_pMaxRounds;
static g_pRoundTime;
static g_pGameName;
static g_pFlashNum;
static g_pSmokeNum;
static g_pAA;
static g_pLastMode;
static g_pSemiclip;
static g_pHpMode;
static g_pDMRespawn;
static g_pRules;
static g_pKnifeMap;
static g_pSurVoteTime;
static g_pSurTimeDelay;
static g_pCheckPlayNoPlay;
static g_pPrefix;

stock cvars_init() {
	g_pRoundTime = get_cvar_pointer("mp_roundtime");

	g_pCapTime			= register_cvar("hns_wintime", "15", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pMaxRounds		= register_cvar("hns_rounds", "6", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pFlashNum			= register_cvar("hns_flash", "2", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pSmokeNum			= register_cvar("hns_smoke", "1", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pLastMode			= register_cvar("hns_lastmode", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pAA				= register_cvar("hns_aa", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pSemiclip			= register_cvar("hns_semiclip", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pHpMode			= register_cvar("hns_hpmode", "100", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pDMRespawn 		= register_cvar("hns_dmrespawn", "3", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pSurVoteTime 		= register_cvar("hns_survotetime", "10", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pSurTimeDelay 	= register_cvar("hns_surtimedelay", "120", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pCheckPlayNoPlay 	= register_cvar("hns_checkplay", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pRules 			= register_cvar("hns_rules", "0", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pGameName			= register_cvar("hns_gamename", "Hide'n'Seek", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pKnifeMap			= register_cvar("hns_knifemap", "35hp_2", FCVAR_ARCHIVE | FCVAR_SERVER);
	g_pPrefix			= register_cvar("hns_prefix", "Match", FCVAR_ARCHIVE | FCVAR_SERVER);
}

stock get_round_time() {
	return g_pRoundTime;
}

stock set_round_time(str[]) {
	set_pcvar_float(g_pRoundTime, str_to_float(str));
}

stock get_cap_time() {
	get_pcvar_num(g_pCapTime);
}

stock set_cap_time(num) {
	set_pcvar_num(g_pCapTime, num);
}

stock get_max_rounds() {
	return get_pcvar_num(g_pMaxRounds);
}

stock set_max_rounds(num) {
	set_pcvar_num(g_pMaxRounds, num);
}

stock get_game_description(description[], size) {
	get_pcvar_string(g_pGameName, description, size);
}

stock get_flash_num() {
	return get_pcvar_num(g_pFlashNum);
}

stock set_flash_num(num) {
	set_pcvar_num(g_pFlashNum, num);
}

stock get_smoke_num() {
	return get_pcvar_num(g_pSmokeNum);
}

stock set_smoke_num(num) {
	set_pcvar_num(g_pSmokeNum, num);
}

stock get_aa_mode() {
	return get_pcvar_num(g_pAA);
}

stock set_aa_mode(num) {
	set_pcvar_num(g_pAA, num);
}

stock is_semiclip() {
	return get_pcvar_num(g_pSemiclip) ? true : false;
}

stock set_semiclip(bool:isClip) {
	if (isClip)
		set_pcvar_num(g_pSemiclip, 1);
	else
		set_pcvar_num(g_pSemiclip, 0);
}

stock get_hp_mode() {
	return get_pcvar_num(g_pHpMode);
}

stock set_hp_mode(num) {
	set_pcvar_num(g_pHpMode, num);
}

stock get_dm_resp() {
	return get_pcvar_num(g_pDMRespawn);
}

stock get_vote_time() {
	return get_pcvar_num(g_pSurVoteTime);
}

stock get_sur_delay() {
	return get_pcvar_num(g_pSurTimeDelay);
}

stock is_check_play() {
	return get_pcvar_num(g_pCheckPlayNoPlay) ? true : false;
}

stock get_last_mode() {
	return get_pcvar_num(g_pLastMode);
}

stock set_last_mode(num) {
	set_pcvar_num(g_pLastMode, num);
}

stock get_rules_mode() {
	return get_pcvar_num(g_pRules);
}

stock set_rules_mode(num) {
	set_pcvar_num(g_pRules, num);
}

stock get_knife_map(map[], size) {
	return get_pcvar_string(g_pKnifeMap, map, size);
}

stock get_prefix (prefix[], size) {
	get_pcvar_string(g_pPrefix, prefix, size);
}