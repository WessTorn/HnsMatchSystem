new bool:bDamage[33];
new bool:g_bSaveAngles[33];

new Float:flCheckpointAngles[33][3];
new Float:flCheckpoints[33][2][3];
new bool:flCheckpointAlternate[33];

stock checkPoint(id) {
	if(!is_user_alive(id)) {
		chat_print(id, "%L", id, "CP_NOTALIVE");
	} else {
		get_entvar(id, var_origin, flCheckpoints[id][flCheckpointAlternate[id] ? 1 : 0]);
		get_entvar(id, var_v_angle, flCheckpointAngles[id]);
		flCheckpointAlternate[id] = !flCheckpointAlternate[id];
		chat_print(id, "%L", id, "CP_SAVE");
	}
}

stock goCheck(id) {
	if(!flCheckpoints[id][0][0]) {
		chat_print(id, "%L", id, "CP_NOT");
	}
	if(!is_user_alive(id)) {
		chat_print(id, "%L", id, "CP_NOTALIVE");
	} else {
		set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
		set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
		engfunc(EngFunc_SetOrigin, id, flCheckpoints[id][!flCheckpointAlternate[id]]);
		if(g_bSaveAngles[id]) {
			set_entvar(id, var_angles, flCheckpointAngles[id]);
			set_entvar(id, var_v_angle, flCheckpointAngles[id]);
			set_entvar(id, var_fixangle, 1);
		}
	}
}

stock stuck(id) {
	if(!flCheckpoints[id][0][0] || !flCheckpoints[id][1][0]) {
		chat_print(id, "%L", id, "CP_NOTSTUCK");
	}
	if(!is_user_alive(id)) {
		chat_print(id, "%L", id, "CP_NOTALIVE");
	} else {
		set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
		set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
		engfunc(EngFunc_SetOrigin, id, flCheckpoints[id][flCheckpointAlternate[id]]);
		flCheckpointAlternate[id] = !flCheckpointAlternate[id];
		
		if(g_bSaveAngles[id]) {
			set_entvar(id, var_angles, flCheckpointAngles[id]);
			set_entvar(id, var_fixangle, 1);
		}
	}
}

stock cmdDamade(id) {
	bDamage[id] = !bDamage[id];
	chat_print(id,"%s Damage show ^3%sabled.", bDamage[id] ? "en" : "dis");
}

stock damageHit(id, Float:damage) {
	if(bDamage[id]) {
		chat_print(id, "%L", id, "DAMAGE_INFO", floatround(damage, floatround_ceil));
	}
}

public training_putin(id) {
	bDamage[id] = true;
	g_bSaveAngles[id] = true;
	fnResetData(id);
}

public training_disconnected(id) {
	bDamage[id] = false;
	g_bSaveAngles[id] = false;
	fnResetData(id);
}

fnResetData(id) {
	if (g_iCurrentMode == e_mTraining) {
		flCheckpoints[id][0][0] = 0.0;
		flCheckpoints[id][1][0] = 0.0;
		flCheckpointAlternate[id] = false;
		return 1;
	}
	return PLUGIN_HANDLED;
}