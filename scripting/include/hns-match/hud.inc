#if defined _hud_included
  #endinput
#endif

#define _hud_included

stock setTaskHud(id, Float:Time, Dhud, Red, Green, Blue, Float:HoldTime, const Text[], any: ...) {
	new szMessage[128]; vformat(szMessage, charsmax(szMessage), Text, 9);
	new szArgs[7];
	szArgs[0] = id;
	szArgs[1] = encodeText(szMessage);
	szArgs[2] = Red;
	szArgs[3] = Green;
	szArgs[4] = Blue;
	szArgs[5] = Dhud;
	szArgs[6] = _:HoldTime;
	if (Time > 0.0)
		set_task(Time, "taskHudMessage", 89000, szArgs, 7);
	else
		taskHudMessage(szArgs);
}

public taskHudMessage(Params[]) {
	new id, Text[128], RRR, GGG, BBB, dhud, Float:HoldTime;
	id = Params[0];
	decodeText(Params[1], Text, charsmax(Text));
	RRR = Params[2];
	GGG = Params[3];
	BBB = Params[4];
	dhud = Params[5];
	HoldTime = Float:Params[6];

	if (!id || is_user_connected(id)) {
		if (dhud) {
			set_dhudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1);

			show_dhudmessage(id, Text);
		} else {
			set_hudmessage(RRR, GGG, BBB, -1.0, 0.2, 0, 0.0, HoldTime, 0.1, 0.1, -1);
			show_hudmessage(id, Text);
		}
	}
}

stock encodeText(const text[]) {
	return engfunc(EngFunc_AllocString, text);
}

stock decodeText(const text, string[], const length) {
	global_get(glb_pStringBase, text, string, length);
}