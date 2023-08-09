#if defined _ham_included
  #endinput
#endif

#define _ham_included

new iGiveNadesTo;
new iAllocKnifeModel;

stock ham_init() {
	iAllocKnifeModel = engfunc(EngFunc_AllocString, "models/v_knife.mdl");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "hamDeployKnife", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "hamKnifePrim");


	register_menucmd(register_menuid("NadesMenu"), 3, "handleNadesMenu");
}

public hamDeployKnife(const iEntity) {
	new iClient = get_member(iEntity, m_pPlayer);

	if (g_bOnOff[iClient]) {
		set_pev(iClient, pev_viewmodel, 0);
	} else {
		set_pev(iClient, pev_viewmodel, iAllocKnifeModel);
	}

	if (get_user_team(iClient) == 1 && g_iCurrentMode != e_mKnife) {
		set_member(iEntity, m_Weapon_flNextPrimaryAttack, 9999.0);
		set_member(iEntity, m_Weapon_flNextSecondaryAttack, 9999.0);
	}
}

public hamKnifePrim(const iPlayer) {
	if (g_iCurrentMode) {
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iPlayer);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public handleNadesMenu(id, szKey) {
	if (!g_bLastFlash[id] || id != iGiveNadesTo || !is_user_alive(id) || getUserTeam(id) != TEAM_TERRORIST)
		return;

	if (!szKey) {
		if (user_has_weapon(id, CSW_SMOKEGRENADE)) {
			rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) + 1);
		} else {
			rg_give_item(id, "weapon_smokegrenade");
		}

		if (user_has_weapon(id, CSW_FLASHBANG)) {
			rg_set_user_bpammo(id, WEAPON_FLASHBANG, rg_get_user_bpammo(id, WEAPON_FLASHBANG) + 1);
		} else {
			rg_give_item(id, "weapon_flashbang");
		}

		/*if (user_has_weapon(id, CSW_HEGRENADE)) {
			rg_set_user_bpammo(id, WEAPON_HEGRENADE, rg_get_user_bpammo(id, WEAPON_HEGRENADE) + 1);
		} else {
			rg_give_item(id, "weapon_hegrenade");
		}*/
	}

	g_bLastFlash[id] = false;
	iGiveNadesTo = 0;

}