#if defined _utils_included
  #endinput
#endif

#define _utils_included

stock prefix[24];

stock chat_print(const id, const message[], any:...) {
	new msgFormated[191];

	vformat(msgFormated, charsmax(msgFormated), message, 3);

	if (!prefix[0])
        client_print_color(id, print_team_blue, "%s", msgFormated);
	else
		client_print_color(id, print_team_blue, "[^3%s^1] %s", prefix, msgFormated);
}