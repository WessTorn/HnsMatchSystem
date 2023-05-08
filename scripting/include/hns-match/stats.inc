// in e_mMatch

enum _:STATS_FUNCS
{
	STATSFUNCS_STAB,
	STATSFUNCS_DAMAGE,
	STATSFUNCS_FALSHEDTIME,
	STATSFUNCS_PRETHINK
};

new g_StatsFuncs[STATS_FUNCS];

enum _:STATS_PLAYER
{
	Float:e_flSurviveTime,
	Float:e_flDmg,
	Float:e_flRunDistance,
	Float:e_flFlashedTime,
	e_iStabs
};

new g_eRoundStats[MAX_PLAYERS + 1][STATS_PLAYER];
new iStats[MAX_PLAYERS + 1][STATS_PLAYER];

new Float:last_position[MAX_PLAYERS+ 1][3];

public stats_init()
{
	g_StatsFuncs[STATSFUNCS_STAB]			= CreateOneForward(g_PluginId, "stats_stab", FP_CELL);
	g_StatsFuncs[STATSFUNCS_DAMAGE]			= CreateOneForward(g_PluginId, "stats_dmg", FP_CELL, FP_CELL);
	g_StatsFuncs[STATSFUNCS_FALSHEDTIME]	= CreateOneForward(g_PluginId, "stats_flashedtime", FP_CELL, FP_CELL);
	g_StatsFuncs[STATSFUNCS_PRETHINK]		= CreateOneForward(g_PluginId, "stats_prethink", FP_CELL);
}

public stats_stab(attacker) {
	g_eRoundStats[attacker][e_iStabs]++;
}

public stats_dmg(id, Float:damage) {
	g_eRoundStats[id][e_flDmg] += damage;
}

public stats_flashedtime(attacker, Float:fadeHold) {
	g_eRoundStats[attacker][e_flFlashedTime] += fadeHold;
}

public stats_prethink(id) {
	static Float:origin[3];
	static Float:velocity[3];
	static Float:last_updated[MAX_PLAYERS + 1];
	static Float:frametime;
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_velocity, velocity);

	frametime = get_gametime() - last_updated[id];
	if (frametime > 1.0)
	{
		frametime = 1.0;
	}
	if (!g_bFreezePeriod)
	{

		if (is_user_alive(id))
		{
			if (getUserTeam(id) == TEAM_TERRORIST)
			{
				if (vector_length(velocity) * frametime >= get_distance_f(origin, last_position[id]))
				{
					velocity[2] = 0.0;
					if (vector_length(velocity) > 125.0)
					{
						g_eRoundStats[id][e_flRunDistance] += vector_length(velocity) * frametime;
					}
				}

			}
		}
	}
	last_updated[id] = get_gametime();
	xs_vec_copy(origin, last_position[id]);
}

