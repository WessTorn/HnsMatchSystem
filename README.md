## HnsMatchSystem
Counter-Strike Hide'n'Seek Match System plugins

## Add ptssadasd
https://github.com/OpenHNS/HnsMatchSystem-additions PTS (Test)

## Требование | Requirements
- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://dev-cs.ru/resources/405/)
- [Reapi 5.19 (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL 5.20 (last)](https://dev-cs.ru/resources/67/updates)
- [ReSemiclip 2.3.9 (last)](https://dev-cs.ru/resources/71/updates)

## Характеристики | Characteristics
- Public / DeathMatch / Knife / Captain mode
- Timer / MR match mode
- Watcher (admin) menu (N)
- Training menu
- Система зависит от администратора | The system depends on the administrator
- Surrender
- AFK contol

## Установка | Installation
 
1. Скомпилируйте плагин.

- Compile the plugin.

2. Скопируйте скомпилированный файл `.amxx` в директорию: `amxmodx/plugins/`

- Copy the compiled `.amxx` file to the directory: `amxmodx / plugins /`

3. Скопируйте содержимое папки `configs/` в директорию: `amxmodx/configs/`

- Copy the contents of the `configs/` folder to the directory: `amxmodx/configs/`

4. Скопируйте содержимое папки `data/lang/` в директорию: `amxmodx/data/lang/`

- Copy the contents of the `data/lang/` folder to the directory: `amxmodx/data/lang/`

5. Скопируйте содержимое папки `modules/` (Если у вас сервер на линуксе, то берем файл `.so` , если винда `.dll`) в директорию: `amxmodx/modules/`

- Copy the contents of the `modules/` folder (If you have a server on Linux, then we take the `.so` file, if the Windows `.dll`) into the directory: `amxmodx/modules/`

6. Пропишите `.amxx` в файле `amxmodx/configs/plugins.ini`

- Add `.amxx` in the file `amxmodx/configs/plugins.ini`

7. Перезапустите сервер или поменяйте карту.

- Restart the server or change the card.

## Cvars

| Cvar                 | Default    | Description |
| :------------------- | :--------: | :--------------------------------------------------- |
| hns_wintime          | 15         | Кол-во минут для победы ТТ / Number of minutes to win TT |
| hns_rounds           | 15         | Кол-во раундов для победы / Number of rounds to win |
| hns_flash	           | 2          | Кол-во флешек (Плагин сам изменяет) / Number of flash drives (the plugin itself changes) |
| hns_smoke            | 3          | Кол-во дыма (Плагин сам изменяет) / The amount of smoke (the plugin changes itself) |
| hns_aa               | 100        | sv_airaccelerate <br/>`100`<br/>`10`                          |
| hns_semiclip         | 0          | Проходить сквозь друг друга / Pass through each other `0` off `1` on (Плагин сам изменяет)   |
| hns_hpmode           | 100        | Кол-во HP / Number hp `100` `1` (работает только во время / only works during Public/DM/Match) |
| hns_dmrespawn        | 3          | Время (в секундах), в течение которого игрок возродится в режиме DM / Time (in seconds) during which the player will respawn in DM mode |
| hns_survotetime      | 10         | Время (в секундах), в течение которого идет голосование (surrender) / Time (in seconds) during which the vote is in progress (surrender) |
| hns_checkplay        | 1          | Меню play/nolay при входе на кнайф карте / Play / nolay menu at the entrance to the knife map `0` off `1` on |
| hns_knifemap         | 35hp_2     | Кнайф карта / Knife map |
| hns_rules         | 0     | Игровой режим / Game Mode `0` Timer `1` MR |

## Комманды | Commands

- Комманды в чат / Chat commands

- Admin (ADMIN_MAP)

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| mix | Админ меню / Admin menu |
| mode / type | Мод меню / Mode menu |
| training | Тренировочное меню / Training menu |
| pub / public | Паблик мод / Public mode |
| dm / deathmatch | ДМ мод / DeathMatch mode |
| specall | Перенести всех за наблюдателей / Move all spectator |
| ttall | Перенести всех за ТТ / Move all for TT |
| ctall | Перенести всех за КТ / Move all for CT |
| startmix / start | Запустить матч / Start the match |
| kniferound / kf | Запустить ножевой раунд / Start the knife Round |
| captain / cap | Запустить капитан мод / Launch сaptain mod |
| stop / cancel | Остановить текущий режим / Stop сurrent ьode  |
| skill | Скилл мод / Skill mode |
| boost | Буст мод / Boost mode |
| aa10 / 10aa | Set sv_airaccelerate 10 |
| aa100 / 100aa | Set sv_airaccelerate 100 |
| rr / restart | Рестарт раунда / Restart round |
| swap / swap | Поменять команды местами / Swap Teams |
| pause / ps | Пауза / pause |
| live / unpause | Запуск / unpause |
| mr / maxround | Мод по раундам / Max Rounds mode |
| timer | Таймер мод / Timer mode |

- Player

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| hideknife / showknife / knife | Спрятать, Показать нож / Hide, Show knife |
| surrender / sur | Голосование за сдачу / Surrender vote |
| score / s | Счет / Score |
| pick | Меню пика / Pick player |
| back / spec | Перейти или вернуться за наблюдателей / Spec/Back player |
| np / noplay | Не играю / No play |
| ip / play | Играю / Play |
| checkpoint / cp | Чекпоинт / Сheckpoint |
| teleport / tp | Телепорт к чекпоинту / Teleport to checkpoint |
| gocheck / gc | Чекпоинт / Сheckpoin |
| damage / showdamade | Дамаг / Damage |
| noclip / clip | Ноуклип / Noclip |
| respawn / resp | Заспавниться / Respawn |
| top / tops | Топ / Top |



## Список задач | Things to do
- Новый pts
- Captain на всех картах
- Инклуд для взаимодействия с другими плагинами
- Переделать motd top players

## Благодарности / Aвторы других плагинов
[Garey - Мixsystem](https://github.com/Garey27)

[Medusa - Мixsystem](https://dev-cs.ru/members/65/)
