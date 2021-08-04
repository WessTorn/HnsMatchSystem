## HnsMatchSystem
Counter-Strike Hide'n'Seek Match System plugins

## Add pts
https://github.com/OpenHNS/HnsMatchSystem-additions PTS

In order to use PTS you need:
1. Install and enable these 2 plugins on the server:
- [HnsMatch-sql.sma](https://github.com/OpenHNS/HnsMatchSystem-additions/blob/main/scripting/HnsMatch-sql.sma)
- [HnsMatch-pts.sma](https://github.com/OpenHNS/HnsMatchSystem-additions/blob/main/scripting/HnsMatch-pts.sma)

2. Uncomment 1 line (remove //) in [HnsMatchSystem.sma] https://github.com/WessTorn/HnsMatchSystem/blob/main/scripting/HnsMatchSystem.sma

3. After the second step, you need to compile HnsMatchSystem.sma again, put it on the server and restart the server.

4. Next, the config file with the database configuration will appear (/addons/amxmodx/configs/plugins/hnsmatch-sql.cfg), enter the data from the database and restart the server.

## Requirements
- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://dev-cs.ru/resources/405/)
- [Reapi 5.19 (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL 5.20 (last)](https://dev-cs.ru/resources/67/updates)
- [ReSemiclip 2.3.9 (last)](https://dev-cs.ru/resources/71/updates)

## Characteristics
- Public / DeathMatch / Knife / Captain mode
- Timer / MR match mode
- Watcher (admin) menu (N)
- Training menu
- The system depends on the administrator
- Surrender
- AFK contol

## Installation
 
1. Compile the plugin.

2. Copy the compiled `.amxx` file to the directory: `amxmodx / plugins /`

3. Copy the contents of the `configs/` folder to the directory: `amxmodx/configs/`

4. Copy the contents of the `data/lang/` folder to the directory: `amxmodx/data/lang/`

5. Copy the contents of the `modules/` folder (If you have a server on Linux, then we take the `.so` file, if the Windows `.dll`) into the directory: `amxmodx/modules/`

6. Add `.amxx` in the file `amxmodx/configs/plugins.ini`

7. Restart the server or change the map.

## Cvars

| Cvar                 | Default    | Description |
| :------------------- | :--------: | :--------------------------------------------------- |
| hns_wintime          | 15         | Number of minutes to win TT |
| hns_rounds           | 15         | Number of rounds to win |
| hns_flash	           | 2          | Number of flash drives (the plugin itself changes) |
| hns_smoke            | 3          | The amount of smoke (the plugin changes itself) |
| hns_aa               | 100        | sv_airaccelerate <br/>`100`<br/>`10`                          |
| hns_semiclip         | 0          | Pass through each other `0` off `1` on   |
| hns_hpmode           | 100        | Number hp `100` `1` (only works during Public/DM/Match) |
| hns_dmrespawn        | 3          | Time (in seconds) during which the player will respawn in DM mode |
| hns_survotetime      | 10         | Time (in seconds) during which the vote is in progress (surrender) |
| hns_checkplay        | 1          | Play / nolay menu at the entrance to the knife map `0` off `1` on |
| hns_knifemap         | 35hp_2     | Knife map |
| hns_prefix         | ^1>     | System prefix (^1 - yellow, ^3 - blue, ^4 - green) |
| hns_rules         | 0     | Game Mode `0` Timer `1` MR |

## Commands

- Chat commands

- Admin (ADMIN_MAP)

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| mix | Admin menu |
| mode / type | Mode menu |
| training | Training menu |
| pub / public | Public mode |
| dm / deathmatch | DeathMatch mode |
| specall | Move all spectator |
| ttall |  Move all for TT |
| ctall | Move all for CT |
| startmix / start | Start the match |
| kniferound / kf | Start the knife Round |
| captain / cap | Launch сaptain mod |
| stop / cancel | Stop сurrent ьode  |
| skill | Skill mode |
| boost | Boost mode |
| aa10 / 10aa | Set sv_airaccelerate 10 |
| aa100 / 100aa | Set sv_airaccelerate 100 |
| rr / restart | Restart round |
| swap / swap | Swap Teams |
| pause / ps | pause |
| live / unpause | unpause |
| mr / maxround | Max Rounds mode |
| timer | Timer mode |

- Player

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| hideknife / showknife / knife | Hide, Show knife |
| surrender / sur | Surrender vote |
| score / s | Score |
| pick | Pick player |
| back / spec | Spec/Back player |
| np / noplay | No play |
| ip / play |Play |
| checkpoint / cp |Сheckpoint |
| teleport / tp | Teleport to checkpoint |
| gocheck / gc |Сheckpoin |
| damage / showdamade | Damage |
| noclip / clip | Noclip |
| respawn / resp | Respawn |
| top / tops |Top |



## Things to do
- New pts
- Captain works all maps
- Include for interacting with other plugins
- Remake motd top players

## Acknowledgments / Authors of other plugins
[Garey - Мixsystem](https://github.com/Garey27)

[Medusa - Мixsystem](https://dev-cs.ru/members/65/)
