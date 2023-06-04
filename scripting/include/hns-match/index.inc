#if defined _index_included
  #endinput
#endif

#define _index_included

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>
#include <json>
#include <PersistentDataStorage>

#if defined USE_PTS
	#include <hns_matchsystem_pts>
#endif

#include <hns-match/globals>
#include <hns-match/utils>
#include <hns-match/forward>
#include <hns-match/stats>
#include <hns-match/ham>
#include <hns-match/message>
#include <hns-match/save>
#include <hns-match/user>
#include <hns-match/hud>

#include <hns-match/addition/cmds>
#include <hns-match/addition/cvars>
#include <hns-match/addition/say>
#include <hns-match/addition/surrender>
#include <hns-match/addition/afk>
#include <hns-match/addition/hookOnOff>
#include <hns-match/addition/captain>
#include <hns-match/addition/hnsmenu>
#include <hns-match/addition/showinfo>
#include <hns-match/addition/training>