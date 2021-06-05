#if defined _say_included
  #endinput
#endif

#define _say_included

public sayHandle(id) {
	new szArgs[64];

	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if (!szArgs[0])
		return PLUGIN_HANDLED;

	if (szArgs[0] != '/')
		return PLUGIN_CONTINUE;

	new szTarget[32];

	parse(szArgs, \
		  szArgs, charsmax(szArgs), \
		  szTarget, charsmax(szTarget));

	if (equali(szArgs, "/wintime", 8)) {
		if(g_iCurrentRules == e_mMR) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_SET_TIME", prefix);
			return PLUGIN_HANDLED;
		}
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_num(g_eCvars[e_cCapTime], str_to_num(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_WINTIME", prefix, getUserName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/roundtime", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_float(g_eCvars[e_cRoundTime], str_to_float(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_ROUNDTIME", prefix, getUserName(id), str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/maxround", 10)) {
		if(g_iCurrentRules == e_mTimer) {
			client_print_color(id, print_team_blue, "%L", id, "NOT_SET_MR", prefix);
			return PLUGIN_HANDLED;
		}
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_pcvar_num(g_eCvars[e_cMaxRounds], str_to_num(szTarget));
			client_print_color(0, print_team_blue, "%L", id, "SET_MAXROUNDS", prefix, getUserName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}