## [README in English](https://github.com/WessTorn/HnsMatchSystem/blob/main/README_ENG.md)

## HnsMatchSystem
Counter-Strike Hide'n'Seek Match System plugins

## Add pts
https://github.com/OpenHNS/HnsMatchSystem-additions ПТС плагин.

Для использования PTS вам необходимо:
1. Скомпилировать и установить эти 2 плагина на сервер:
- [HnsMatch-sql.sma](https://github.com/OpenHNS/HnsMatchSystem-additions/blob/main/scripting/HnsMatch-sql.sma)
- [HnsMatch-pts.sma](https://github.com/OpenHNS/HnsMatchSystem-additions/blob/main/scripting/HnsMatch-pts.sma)

2. Раскомментировать 1-ю линию (удалить - //) в плагине: [HnsMatchSystem.sma] https://github.com/WessTorn/HnsMatchSystem/blob/main/scripting/HnsMatchSystem.sma

3. После 2-го действия необходимо опять скомпилировать HnsMatchSystem.sma, поставить на сервер и перезапустить сервер.

4. Далее, появится конфиг файл с настройкой базы данных (/addons/amxmodx/configs/plugins/hnsmatch-sql.cfg), туда вводим данные от базы данных и перезапускаем сервер.

## Требование
- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://dev-cs.ru/resources/405/)
- [Reapi 5.22 (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL 5.21 (last)](https://dev-cs.ru/resources/67/updates)
- [ReSemiclip 2.3.9 (last)](https://dev-cs.ru/resources/71/updates)

## Характеристики
- Public / DeathMatch / Knife / Captain mode
- Timer / MR match mode
- Watcher (admin) menu (N)
- Training menu
- Система зависит от администратора
- Surrender
- AFK contol

## Установка
 
1. Скомпилируйте плагин.

2. Скопируйте скомпилированный файл `.amxx` в директорию: `amxmodx/plugins/`

3. Скопируйте содержимое папки `configs/` в директорию: `amxmodx/configs/`

4. Скопируйте содержимое папки `data/lang/` в директорию: `amxmodx/data/lang/`

5. Скопируйте содержимое папки `modules/` (Если у вас сервер на линуксе, то берем файл `.so` , если винда `.dll`) в директорию: `amxmodx/modules/`

6. Пропишите `.amxx` в файле `amxmodx/configs/plugins.ini`

7. Перезапустите сервер или поменяйте карту.

## Cvars

| Cvar                 | Default    | Description |
| :------------------- | :--------: | :--------------------------------------------------- |
| hns_wintime          | 15         | Кол-во минут для победы ТТ |
| hns_rounds           | 15         | Кол-во раундов для победы |
| hns_flash	           | 2          | Кол-во флешек (Плагин сам изменяет) |
| hns_smoke            | 3          | Кол-во дыма (Плагин сам изменяет) |
| hns_aa               | 100        | sv_airaccelerate <br/>`100`<br/>`10`                          |
| hns_semiclip         | 0          | Проходить сквозь друг друга (Плагин сам изменяет)   |
| hns_hpmode           | 100        | Кол-во HP `100` `1` (работает только во время Public/DM/Match) |
| hns_dmrespawn        | 3          | Время (в секундах), в течение которого игрок возродится в режиме DM |
| hns_survotetime      | 10         | Время (в секундах), в течение которого идет голосование (surrender) |
| hns_checkplay        | 1          | Меню play/nolay при входе на кнайф карте / `0` off `1` on |
| hns_knifemap         | 35hp_2     | Кнайф карта |
| hns_prefix         | ^1>     | Префикс системы (^1 - желтый, ^3 - голубой, ^4 - зеленый) |
| hns_rules         | 0     | Игровой режим `0` Timer `1` MR |

## Комманды

- Комманды в чат

- Admin (ADMIN_MAP)

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| mix | Админ меню |
| mode / type | Мод меню |
| training | Тренировочное меню |
| pub / public | Паблик мод |
| dm / deathmatch | ДМ мод |
| specall | Перенести всех за наблюдателей |
| ttall | Перенести всех за ТТ |
| ctall | Перенести всех за КТ |
| startmix / start | Запустить матч |
| kniferound / kf | Запустить ножевой раунд |
| captain / cap | Запустить капитан мод |
| stop / cancel | Остановить текущий режим  |
| skill | Скилл мод |
| boost | Буст мод |
| aa10 / 10aa | Set sv_airaccelerate 10 |
| aa100 / 100aa | Set sv_airaccelerate 100 |
| rr / restart | Рестарт раунда |
| swap / swap | Поменять команды местами |
| pause / ps | Пауза |
| live / unpause | Запуск |
| mr / maxround | Мод по раундам |
| timer | Таймер мод |

- Player

| Commands | Description |
| :------------------- |  :--------------------------------------------------- |
| hideknife / showknife / knife | Спрятать, Показать нож |
| surrender / sur | Голосование за сдачу |
| score / s | Счет |
| pick | Меню пика |
| back / spec | Перейти или вернуться за наблюдателей |
| np / noplay | Не играю |
| ip / play | Играю |
| checkpoint / cp | Чекпоинт |
| teleport / tp | Телепорт к чекпоинту |
| gocheck / gc | Чекпоинтn |
| damage / showdamade | Дамаг |
| noclip / clip | Ноуклип |
| respawn / resp | Заспавниться |
| top / tops | Топ |



## Список задач
- Новый pts
- Captain на всех картах
- Инклуд для взаимодействия с другими плагинами
- Переделать motd top players

## Благодарности / Aвторы других плагинов
[Garey - Мixsystem](https://github.com/Garey27)

[Medusa - Мixsystem](https://dev-cs.ru/members/65/)
