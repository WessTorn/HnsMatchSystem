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
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if(g_iCurrentRules == e_mMR) {
			chat_print(id, "%L", id, "NOT_SET_TIME");
			return PLUGIN_HANDLED;
		}

		if (is_str_num(szTarget)) {
			set_cap_time(str_to_num(szTarget));
			chat_print(0, "%L", id, "SET_WINTIME", getUserName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/roundtime", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_round_time(szTarget);
			chat_print(0, "%L", id, "SET_ROUNDTIME", getUserName(id), str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/maxround", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if(g_iCurrentRules == e_mTimer) {
			chat_print(id, "%L", id, "NOT_SET_MR");
			return PLUGIN_HANDLED;
		}

		if (is_str_num(szTarget)) {
			set_max_rounds(str_to_num(szTarget));
			chat_print(0, "%L", id, "SET_MAXROUNDS", getUserName(id), str_to_num(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/tt", 15)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if(g_iCurrentRules != e_mTimer) {
			return PLUGIN_HANDLED;
		}

		new szMinutes[10], szSeconds[16];
		replace(szTarget, charsmax(szTarget), ":", " ");
		replace(szTarget, charsmax(szTarget), ".", " ");

		if (!parse(szTarget, szMinutes, charsmax(szMinutes), szSeconds, charsmax(szSeconds))) {
			chat_print(id, "%L", id, "NOT_SET_TT");
			return PLUGIN_HANDLED;
		}

		if (!szMinutes[0] || !szSeconds[0]) {
			chat_print(id, "%L", id, "NOT_SET_TT");
			return PLUGIN_HANDLED;
		}

		new minutes = str_to_num(szMinutes);
		new seconds = str_to_num(szSeconds);

		if (seconds >= 60) {
			chat_print(id, "%L", id, "NOT_SET_TT");
			return PLUGIN_HANDLED;
		}

		g_flSidesTime[!g_iCurrentSW] = (float(get_cap_time()) - (minutes + (seconds / 60.0))) * 60.0;
		chat_print(0, "%L", 0, "SER_TIME_TT", id, szMinutes, szSeconds);
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/ct", 15)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if(g_iCurrentRules != e_mTimer) {
			return PLUGIN_HANDLED;
		}

		new szMinutes[10], szSeconds[16];
		replace(szTarget, charsmax(szTarget), ":", " ");
		replace(szTarget, charsmax(szTarget), ".", " ");

		if (!parse(szTarget, szMinutes, charsmax(szMinutes), szSeconds, charsmax(szSeconds))) {
			chat_print(id, "%L", id, "NOT_SET_СT");
			return PLUGIN_HANDLED;
		}

		if (!szMinutes[0] || !szSeconds[0]) {
			chat_print(id, "%L", id, "NOT_SET_СT");
			return PLUGIN_HANDLED;
		}

		new minutes = str_to_num(szMinutes);
		new seconds = str_to_num(szSeconds);

		if (seconds >= 60) {
			chat_print(id, "%L", id, "NOT_SET_СT");
			return PLUGIN_HANDLED;
		}

		g_flSidesTime[!g_iCurrentSW] = (float(get_cap_time()) - (minutes + (seconds / 60.0))) * 60.0;
		chat_print(0, "%L", 0, "SER_TIME_CT", id, szMinutes, szSeconds);
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}