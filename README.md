## HnsMatchSystem
Counter-Strike Hide'n'Seek Match System plugins

## Требование
- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://www.amxmodx.org/downloads-new.php)
- [Reapi 5.19 (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL 5.19 (last)](https://dev-cs.ru/resources/67/updates)
- [ReSemiclip 2.3.9 (last)](https://dev-cs.ru/resources/71/updates)

## Установка
 
1. Скомпилируйте плагин.

2. Скопируйте скомпилированный файл `.amxx` в директорию: `amxmodx/plugins/`

3. Скопируйте содержимое папки `configs/` в директорию: `amxmodx/configs/`

4. Скопируйте содержимое папки `data/lang/` в директорию: `amxmodx/data/lang/`

5. Скопируйте содержимое папки `modules/` (Если у вас сервер на линуксе, то берем файл `.so` , если винда `.dll`) в директорию: `amxmodx/modules/`

6. Пропишите `.amxx` в файле `amxmodx/configs/plugins.ini`

7. Перезапустите сервер или поменяйте карту.

## Cvars

| Cvar                 | Default    | Descripción |
| :------------------- | :--------: | :--------------------------------------------------- |
| hns_wintime              | 15 | Кол-во минут для победы ТТ                                  |
| hns_flash	           | 2         | Кол-во флешек (Плагин сам изменяет)                  |
| hns_smoke       |     3     | Кол-во дыма (Плагин сам изменяет)                        |
| hns_aa        | 100          | sv_airaccelerate <br/>`100`<br/>`10`                          |
| hns_semiclip       | 0          | Проходить сквозь друг друга `0` off `1` on (Плагин сам изменяет)   |
| hns_hpmode   |    100   | Кол-во HP `100` `1` (работает только во время Public/DM/Match)  |
| hns_dmrespawn     |      3     | Время (в секундах), в течение которого игрок возродится в режиме DM  |
| hns_survotetime     |      10     | Время (в секундах), в течение которого идет голосование (surrender)  |
| hns_checkplay     |      1     | Меню play/nolay при входе на кнайф карте `0` off `1` on |
| hns_knifemap     |      35hp_2     | Кнайф карта |

## Дела, которые необходимо сделать
- Новый pts
- Captain на всех картах
- Нормальный config файл для большей настройки
- Инклуд для взаимодействия с другими плагинами
- Переделать readme :>

## Благодарности / Aвторы других плагинов
[Garey - Мixsystem](https://github.com/Garey27)

[Medusa - Мixsystem](https://dev-cs.ru/members/65/)
