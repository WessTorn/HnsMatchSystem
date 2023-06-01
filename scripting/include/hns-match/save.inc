enum _:PlayersLoad_s {
	e_pAuth[24],
	e_pTeam
};

new Array:g_aPlayersLoadData;

new g_szBuffer[2048];

public PDS_Save() {
	if (equali(g_szMapName, knifemap)) {
		if (g_szBuffer[0])
			PDS_SetString("playerslist", g_szBuffer);
	}
}

stock savePlayers(TeamName:team_winners) {
	new JSON:arrayRoot = json_init_array();

	new iPlayers[MAX_PLAYERS], iNum, szAuth[24];
	get_players(iPlayers, iNum, "ch");

	for (new i; i < iNum; i++) {
		new id = iPlayers[i];

		if (getUserTeam(id) == TEAM_SPECTATOR) continue;

		get_user_authid(id, szAuth, charsmax(szAuth));

		arrayAppendValue(arrayRoot, json_init_string(fmt("player_%i", i + 1)));

		new JSON:object = json_init_object();
		json_object_set_string(object, "e_pAuth", fmt("%s", szAuth));
		new TeamName:iTeam = TeamName:getUserTeam(id) == team_winners ? TEAM_TERRORIST : TEAM_CT;
		json_object_set_number(object, "e_pTeam", _:iTeam);
		arrayAppendValue(arrayRoot, object);
		json_free(object);
	}

	json_serial_to_string(arrayRoot, g_szBuffer, charsmax(g_szBuffer), true);
	server_print("Players saved (%d bytes)", json_serial_size(arrayRoot, true));
	json_free(arrayRoot);
}

arrayAppendValue(JSON:array, JSON:node) {
	json_array_append_value(array, node);
	json_free(node);
}

loadPlayers() {
	if (!equali(g_szMapName, knifemap))
		g_bPlayersListLoaded = PDS_GetString("playerslist", g_szBuffer, charsmax(g_szBuffer));

	if (g_bPlayersListLoaded) {
		new JSON:arrayRoot = json_parse(g_szBuffer);

		if (!json_is_array(arrayRoot)) {
			if (arrayRoot != Invalid_JSON)
				json_free(arrayRoot);

			server_print("Root value is not array!");
			return;
		}
		decodeArray(arrayRoot);
		json_free(arrayRoot);
	}
}

decodeArray(&JSON:array) {
	new JSON:arrayValue;
	for (new i = 0; i < json_array_get_count(array); i++) {
		arrayValue = json_array_get_value(array, i);

		if (json_get_type(arrayValue) == JSONObject)
			decodeObject(arrayValue);

		json_free(arrayValue);
	}
}

decodeObject(&JSON:object) {
	new szKey[30];
	new JSON:objValue;
	new eTempPlayer[PlayersLoad_s], iSave;
	for (new i = 0; i < json_object_get_count(object); i++) {
		json_object_get_name(object, i, szKey, charsmax(szKey));
		objValue = json_object_get_value_at(object, i);

		switch (json_get_type(objValue)) {
			case JSONString: {
				json_get_string(objValue, eTempPlayer[e_pAuth], charsmax(eTempPlayer[e_pAuth]));
				iSave++;
			}
			case JSONNumber: {
				eTempPlayer[e_pTeam] = json_get_number(objValue);
				iSave++;
			}
		}

		if (iSave == 2) {
			ArrayPushArray(g_aPlayersLoadData, eTempPlayer);
			arrayset(eTempPlayer, 0, PlayersLoad_s);
			iSave = 0;
		}
		json_free(objValue);
	}
}

stock bool:checkPlayer(id) {
	new eTempPlayer[PlayersLoad_s], iSize = ArraySize(g_aPlayersLoadData);
	new szAuth[24]; get_user_authid(id, szAuth, charsmax(szAuth));
	for (new i; i < iSize; i++) {
		ArrayGetArray(g_aPlayersLoadData, i, eTempPlayer);
		if (equal(szAuth, eTempPlayer[e_pAuth])) {
			rg_set_user_team(id, eTempPlayer[e_pTeam]);
			return true;
		}
	}
	return false;
}