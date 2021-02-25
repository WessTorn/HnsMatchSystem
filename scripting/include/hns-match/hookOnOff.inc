#if defined _hookOnOff_included
  #endinput
#endif

#define _hookOnOff_included

stock hookOnOff_init() {
	register_clcmd("+hook", "hookOn");
	register_clcmd("-hook", "hookOff");
}

public hookOn(id) {
	if (g_iCurrentMode > e_mPaused && g_iCurrentMode != e_mCaptain)
		return PLUGIN_HANDLED;

	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	g_bHooked[id] = true;

	return PLUGIN_HANDLED;
}

public hookOff(id) {
	removeHook(id);

	return PLUGIN_HANDLED;
}

stock removeHook(id) {
	if (task_exists(id + 9999))
		remove_task(id + 9999);

	if (!is_entity(id))
		return;

	g_bHooked[id] = false;
	set_entvar(id, var_gravity, 1.0);
}