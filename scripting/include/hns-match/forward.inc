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

stock forward_init() {
	g_hForwards[MATCH_STARTED] = CreateMultiForward("hns_match_started", ET_CONTINUE);
	g_hForwards[MATCH_FINISHED] = CreateMultiForward("hns_match_finished", ET_CONTINUE, FP_CELL);
	g_hForwards[MATCH_CANCELED] = CreateMultiForward("hns_match_canceled", ET_CONTINUE);
}
