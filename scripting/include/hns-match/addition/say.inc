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

	if (equali(szArgs, "/roundtime", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;

		if (is_str_num(szTarget)) {
			set_round_time(szTarget);
			chat_print(0, "%L", 0, "SET_ROUNDTIME", id, str_to_float(szTarget));
		}
		return PLUGIN_CONTINUE;
	}

	if (equali(szArgs, "/mr", 10)) {
		trim(szTarget);

		if (!getUserInAccess(id))
			return PLUGIN_HANDLED;
			
		if (!is_str_num(szTarget))
			return PLUGIN_HANDLED;

		if (str_to_num(szTarget) > 0) {
			set_max_rounds(str_to_num(szTarget));
			chat_print(0, "%L", 0, "SET_MAXROUNDS", id, str_to_num(szTarget), str_to_num(szTarget) * 2);
		}
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}