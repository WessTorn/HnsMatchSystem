#if defined _utils_included
  #endinput
#endif

#define _utils_included

enum {
	SEMICLIP_ON,
	SEMICLIP_OFF
}

stock prefix[24];

stock chat_print(const id, const message[], any:...) {
	new msgFormated[191];

	vformat(msgFormated, charsmax(msgFormated), message, 3);

	if (!prefix[0])
		client_print_color(id, print_team_blue, "%s", msgFormated);
	else
		client_print_color(id, print_team_blue, "[^3%s^1] %s", prefix, msgFormated);
}

stock set_semiclip(opt, bool:enemy = false) {
	switch(opt) {
		case SEMICLIP_ON: { 
			server_cmd("semiclip_option semiclip 1"); 
			server_cmd("semiclip_option team %d", enemy ? 3 : 0); 
		}
		case SEMICLIP_OFF: {
			server_cmd("semiclip_option semiclip 0"); // off
			server_cmd("semiclip_option team 0");
		}
	}
	server_cmd("semiclip_option time 0");
}

stock fnConvertTime(Float:time, convert_time[], len, bool:with_intpart = true) {
	new szTemp[24];
	new Float:flSeconds = time, iMinutes;

	iMinutes = floatround(flSeconds / 60.0, floatround_floor);
	flSeconds -= iMinutes * 60.0;
	new intpart = floatround(flSeconds, floatround_floor);
	new Float:decpart = (flSeconds - intpart) * 100.0;

	if (with_intpart) {
		intpart = floatround(decpart);
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f.%d", iMinutes, flSeconds, intpart);
	} else {
		formatex(szTemp, charsmax(szTemp), "%02i:%02.0f", iMinutes, flSeconds);
	}

	formatex(convert_time, len, "%s", szTemp);

	return PLUGIN_HANDLED;
}

stock switchHnsTeamValue() {
	if (g_isTeamTT == HNS_TEAM_A)
		g_isTeamTT = HNS_TEAM_B
	else
		g_isTeamTT = HNS_TEAM_A
}