public trainingmode_init()
{
	g_ModFuncs[MODE_TRAINING][MODEFUNC_START] = CreateOneForward(g_PluginId, "training_start");
}

public training_start()
{
	g_iCurrentMode = MODE_TRAINING;
	ChangeGameplay(GAMEPLAY_TRAINING);
	restartRound(1.0);
	set_cvars_mode(MODE_TRAINING);
}