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
    skill[10]
};

enum _:SKILL_INFO
{
    SKILL_PTS,
    SKILL_LVL[10]
};

native hns_pts_get_player_info(id, info);
native hns_set_pts_tt();
native hns_set_pts_ct();
