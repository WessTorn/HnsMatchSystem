public knife_init()
{
    g_GPFuncs[GAMEPLAY_KNIFE][GP_ENABLE]      = CreateOneForward(g_PluginId, "knife_enable_rules");
    g_GPFuncs[GAMEPLAY_KNIFE][GP_SETROLE]     = CreateOneForward(g_PluginId, "knife_setrole", FP_CELL);
}

public knife_enable_rules()
{
    set_semiclip(SEMICLIP_OFF);
    g_iCurrentGameplay = GAMEPLAY_KNIFE;
}


public knife_setrole(id)
{
    rg_remove_all_items(id);
    rg_give_item(id, "weapon_knife");
    rg_set_user_footsteps(id, false);
}