#if defined _index_included
  #endinput
#endif

#define _index_included

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <fun>
#include <reapi>
#include <json>
#include <PersistentDataStorage>

#if defined USE_PTS
	#include <hns_matchsystem_pts>
#endif

#include <hns-match/globals>
#include <hns-match/cmds>
#include <hns-match/say>
#include <hns-match/hook>
#include <hns-match/ham>
#include <hns-match/forward>
#include <hns-match/event>
#include <hns-match/message>

#include <hns-match/user>
#include <hns-match/surrender>
#include <hns-match/afk>
#include <hns-match/hookOnOff>
#include <hns-match/captain>
#include <hns-match/hnsmenu>
#include <hns-match/hud>
#include <hns-match/showinfo>
#include <hns-match/training>