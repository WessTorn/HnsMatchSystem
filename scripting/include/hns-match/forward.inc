#if defined _forward_included
  #endinput
#endif

#define _forward_included

new const sndDenySelect[] = "common/wpn_denyselect.wav";
new const sndUseSound[] = "buttons/blip1.wav";
new const szDefaultEntities[][] = {
	"func_hostage_rescue",
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity",
	"monster_scentist"
}

stock forward_init() {
	//register_forward(FM_Voice_SetClientListening, "fwdSetClientListening");
	register_forward(FM_EmitSound, "fwdEmitSoundPre", 0);
	register_forward(FM_ClientKill, "fwdClientKill");
	register_forward(FM_GetGameDescription, "fwdGameNameDesc");

	unregister_forward(FM_Spawn, g_iRegisterSpawn, 1);
}

/*public fwdSetClientListening(iReceiver, iSender, bool:bListen) {
	if (g_iCurrentMode <= e_mPaused || g_iCurrentMode == e_mCaptain || g_iCurrentMode == e_mPublic || g_iCurrentMode == e_mDM) {
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
		forward_return(FMV_CELL, true);
		return FMRES_SUPERCEDE;
	}

	if (is_user_connected(iReceiver) && is_user_connected(iSender)) {
		if (get_user_team(iReceiver) == get_user_team(iSender)) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			forward_return(FMV_CELL, true);
			return FMRES_SUPERCEDE;
		} else if (get_user_team(iReceiver) != 1 && get_user_team(iReceiver) != 2) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			forward_return(FMV_CELL, true);
			return FMRES_SUPERCEDE;
		}
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
	forward_return(FMV_CELL, false);
	return FMRES_SUPERCEDE;
}*/

public fwdEmitSoundPre(id, iChannel, szSample[], Float:volume, Float:attenuation, fFlags, pitch) {
	if (equal(szSample, "weapons/knife_deploy1.wav")) {
		return FMRES_SUPERCEDE;
	}

	if (is_user_alive(id) && getUserTeam(id) == TEAM_TERRORIST && equal(szSample, sndDenySelect)) {
		emit_sound(id, iChannel, sndUseSound, volume, attenuation, fFlags, pitch);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fwdGameNameDesc() {
	static gameName[32];
	get_pcvar_string(g_eCvars[e_cGameName], gameName, 31);
	forward_return(FMV_STRING, gameName);

	return FMRES_SUPERCEDE;
}

public fwdClientKill(id) {
	if (g_iCurrentMode == e_mDM) {
		client_print_color(0, print_team_blue, "%s Kill during deathmatch is not available.", hns_tag);
		return FMRES_SUPERCEDE;
	} else {
		client_print_color(0, print_team_blue, "%L", id, "KILL_HIMSELF", prefix, getUserName(id));
	}
	return FMRES_IGNORED;
}

public fwdSpawn(entid) {
	static szClassName[32];
	if (pev_valid(entid)) {
		pev(entid, pev_classname, szClassName, 31);

		if (equal(szClassName, "func_buyzone"))
			engfunc(EngFunc_RemoveEntity, entid);

		for (new i = 0; i < sizeof szDefaultEntities; i++) {
			if (equal(szClassName, szDefaultEntities[i])) {
				engfunc(EngFunc_RemoveEntity, entid);
				break;
			}
		}
	}
}
