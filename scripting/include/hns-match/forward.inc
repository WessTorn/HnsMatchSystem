#if defined _forward_included
  #endinput
#endif

#define _forward_included

enum _: Forwards {
	MATCH_STARTED,
	MATCH_FINISHED,
	MATCH_CANCELED
};

new g_hForwards[Forwards];

public forward_init() {
	g_hForwards[MATCH_STARTED] = CreateMultiForward("hns_match_started", ET_CONTINUE);
	g_hForwards[MATCH_FINISHED] = CreateMultiForward("hns_match_finished", ET_CONTINUE, FP_CELL);
	g_hForwards[MATCH_CANCELED] = CreateMultiForward("hns_match_canceled", ET_CONTINUE);
}

public plugin_natives() {
	register_native("hns_get_prefix", "native_get_prefix");

	register_native("hns_get_mode", "native_get_mode");
	register_native("hns_set_mode", "native_set_mode");
}

public native_get_prefix(amxx, params) {
	enum { argPrefix = 1, argLen };
	new szPrefix[24];
	get_prefix(szPrefix, charsmax(szPrefix));
	format(szPrefix, charsmax(szPrefix), "[^3%s^1]", szPrefix);
	set_string(argPrefix, szPrefix, get_param(argLen));
}

public native_get_mode(amxx, params) {
	return g_iCurrentMode;
}

public native_set_mode(amxx, params) {
	enum { argMode = 1 };
	g_iCurrentMode = get_param(argMode);
	taskPrepareMode(argMode);
}
