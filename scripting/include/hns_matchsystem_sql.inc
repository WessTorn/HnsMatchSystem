#if defined _hns_matchsystem_sql_included
	#endinput
#endif
#define _hns_matchsystem_sql_included

native hns_sql_get_table_name(table_name[], len);
native hns_sql_get_player_id(id);

forward hns_sql_connection(Handle:hSqlTuple);
forward hns_sql_player_authorized(id);
