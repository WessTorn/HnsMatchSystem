new bool:bDamage[33];
new bool:g_bSaveAngles[33];

new Float:flCheckpointAngles[33][3];
new Float:flCheckpoints[33][2][3];
new bool:flCheckpointAlternate[33];

stock checkPoint(id) {
	if(!is_user_alive(id)) {
		client_print_color(id, print_team_blue, "%L", id, "CP_NOTALIVE", prefix);
	} else {
		get_entvar(id, var_origin, flCheckpoints[id][flCheckpointAlternate[id] ? 1 : 0]);
		get_entvar(id, var_v_angle, flCheckpointAngles[id]);
		flCheckpointAlternate[id] = !flCheckpointAlternate[id];
		client_print_color(id, print_team_blue, "%L", id, "CP_SAVE", prefix);
	}
}

stock goCheck(id) {
	if(!flCheckpoints[id][0][0]) {
		client_print_color(id, print_team_blue, "%L", id, "CP_NOT", prefix);
	}
	if(!is_user_alive(id)) {
		client_print_color(id, print_team_blue, "%L", id, "CP_NOTALIVE", prefix);
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
		client_print_color(id, print_team_blue, "%L", id, "CP_NOTSTUCK", prefix);
	}
	if(!is_user_alive(id)) {
		client_print_color(id, print_team_blue, "%L", id, "CP_NOTALIVE", prefix);
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
	client_print_color(id, print_team_blue,"%s Damage show ^3%sabled.", prefix, bDamage[id] ? "en" : "dis");
}

stock damageHit(id, Float:damage) {
	if(bDamage[id]) {
		client_print_color(id, print_team_blue, "%L", id, "DAMAGE_INFO", prefix, floatround(damage, floatround_ceil));
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