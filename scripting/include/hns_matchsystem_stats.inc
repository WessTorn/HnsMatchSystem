#if defined _hns_matchsystem_stats_included
	#endinput
#endif
#define _hns_matchsystem_stats_included

/*
* Gets players stabs.
*
* @param id Client index
*
* @return stabs num
*/
native hns_get_stats_stabs(id);

/*
* Gets players survive time.
*
* @param id Client index
*
* @return Float: survive time
*/
native Float:hns_get_stats_surv(id);