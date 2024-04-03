#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <hns_matchsystem>

new bool: g_playerHideKnife[MAX_PLAYERS + 1][TeamName];

public plugin_init() {
	register_plugin("HNS: Hideknife", "1.0.0", "ufame, OpenHNS"); // ufame (https://github.com/ufame/brohns/blob/master/server/src/scripts/hns/hns_hideknife.sma)

	RegisterSayCmd("hideknife", "showknife", "commandHideKnife", 0, "Show knife");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "knifeDeploy", 1);

	register_dictionary("match_additons.txt");
}

public commandHideKnife(id) {
	new szMsg[64];
	new szMsgYesNo[16];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "KNIFE_HIDE");
	new hMenu = menu_create(szMsg, "hideknifeHandler");

	formatex(szMsgYesNo, charsmax(szMsgYesNo), "%L", LANG_PLAYER, g_playerHideKnife[id][TEAM_TERRORIST] ? "MENU_YES" : "MENU_NO");
	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "KNIFE_TT", szMsgYesNo);
	menu_additem(hMenu, szMsg);

	formatex(szMsgYesNo, charsmax(szMsgYesNo), "%L", LANG_PLAYER, g_playerHideKnife[id][TEAM_CT] ? "MENU_YES" : "MENU_NO");
	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "KNIFE_CT", szMsgYesNo);
	menu_additem(hMenu, szMsg);

	menu_display(id, hMenu);

	return PLUGIN_HANDLED;
}

public hideknifeHandler(const id, const menu, const item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	new bool: hideKnife;
	new TeamName: hideTeam;

	switch (item) {
	case 0: {
		hideTeam = TEAM_TERRORIST;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];

		commandHideKnife(id);
	}
	case 1: {
		hideTeam = TEAM_CT;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];

		commandHideKnife(id);
	}
	}

	if (is_user_alive(id) && hideTeam == get_member(id, m_iTeam)) {
		new activeItem = get_member(id, m_pActiveItem);

		if (is_nullent(activeItem) || get_member(activeItem, m_iId) != WEAPON_KNIFE)
			return PLUGIN_HANDLED;

		set_entvar(id, var_viewmodel, hideKnife ? "" : "models/v_knife.mdl");
	}

	return PLUGIN_HANDLED;
}

public knifeDeploy(const entity) {
	new player = get_member(entity, m_pPlayer);
	new TeamName: team = get_member(player, m_iTeam);

	if (g_playerHideKnife[player][team])
		set_entvar(player, var_viewmodel, "");
}