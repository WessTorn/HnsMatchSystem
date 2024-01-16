#if defined _hns_matchsystem_sql_included
	#endinput
#endif
#define _hns_matchsystem_sql_included

/*
* Gets players table name.
*
* @param szTabiLename Buffer to copy prefix to
* @param iLen Maximum buffer size
*
* @noreturn
*/
native hns_sql_get_table_name(szTableName[], iLen);

/*
* Gets players id (`id`).
*
* @param id Client index
*
* @return player id
*/
native hns_sql_get_player_id(id);

/*
* Called when it connects to the data base
*
* @param Handle:hSqlTuple Handle to be connected
*
* @noreturn
*/
forward hns_sql_connection(Handle:hSqlTuple);

/*
* Called when we get player data
*
* @param id Client index
*
* @noreturn
*/
forward hns_sql_player_authorized(id);
