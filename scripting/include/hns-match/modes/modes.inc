enum _:HNS_MODES
{
	MODE_TRAINING,
	MODE_KNIFE,
	MODE_PUB,
	MODE_DM,
	MODE_ZM,
	MODE_MIX
}
new g_iCurrentMode; 

enum _:MODE_FUNCS
{
	MODEFUNC_START,
	MODEFUNC_PAUSE,
	MODEFUNC_UNPAUSE,
	MODEFUNC_END,
	MODEFUNC_ROUNDSTART,
	MODEFUNC_ROUNDEND,
	MODEFUNC_FREEZEEND,
	MODEFUNC_KILL,
	MODEFUNC_RESTARTROUND,
	MODEFUNC_SWAP,
	MODEFUNC_PLAYER_JOIN,
	MODEFUNC_PLAYER_LEAVE,
	MODEFUNC_FALLDAMAGE
};

new g_ModFuncs[HNS_MODES][MODE_FUNCS];

public InitGameModes() {
	mix_init();
	kniferound_init();
	pub_init();
	dm_init();
	zm_init();
	mode_init();
	trainingmode_init();
}

public set_cvars_mode(iMode) {
	new szPath[128];
	get_configsdir(szPath, 127);
	format(szPath, 127, "%s/mixsystem/mode", szPath);

	switch (iMode) {
		case MODE_TRAINING: server_cmd("exec %s/training.cfg", szPath);
		case MODE_KNIFE: server_cmd("exec %s/knife.cfg", szPath);
		case MODE_PUB: server_cmd("exec %s/public.cfg", szPath);
		case MODE_DM: server_cmd("exec %s/deathmatch.cfg", szPath);
		case MODE_MIX: server_cmd("exec %s/match.cfg", szPath);
		case MODE_ZM: server_cmd("exec %s/zombie.cfg", szPath);
	}
}