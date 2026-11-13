# Техническая архитектура

> Архивный аудит прежнего облачного `fotball`. Для текущей сборки используйте [README Football Simulator](../../README.md) и [привязки интегрированного Place](../../INTEGRATION.md).

## Инвентарь исходников

Три ветки ниже соответствуют [default.project.json](../../default.project.json) и экземплярам Edit. Полное имя каждого объекта получается из префикса ветки и имени в таблице. Оба входных скрипта включены, `RunContext = Legacy`.

### Сервер · `ServerScriptService.JuggleServer`

| Instance | Класс | Исходник и ответственность |
| --- | --- | --- |
| `Main` | Script | [Main.server.luau](../../src/server/Main.server.luau) — запуск мира, обработчики, экономика, игровые сессии, ритм, расписание и сохранение. |
| `Profiles` | ModuleScript | [Profiles.luau](../../src/server/Profiles.luau) — нормализация, память Studio, DataStore и блокировка профиля. |
| `Pitch` | ModuleScript | [Pitch.luau](../../src/server/Pitch.luau) — стадион, стартовые маркеры, круги и подготовка проходов. |
| `ClubMap` | ModuleScript | [ClubMap.luau](../../src/server/ClubMap.luau) — дворы, prompt, границы районов, группы коллизии Академии. |
| `CampusArt` | ModuleScript | [CampusArt.luau](../../src/server/CampusArt.luau) — окружение, перекраска, атмосфера, облака и свет. |

### Общие модули · `ReplicatedStorage.Juggle`

| Instance | Класс | Исходник и ответственность |
| --- | --- | --- |
| `Balance` | ModuleScript | [Balance.luau](../../src/shared/Balance.luau) — лимиты, формулы цен и доходов, каталог, дивизионы, флаг Studio DataStore. |
| `ClubRules` | ModuleScript | [ClubRules.luau](../../src/shared/ClubRules.luau) — чистые правила обучения, лицензии, ролей, заданий, ритма и последовательности ударов. |

### Клиент · `StarterPlayer.StarterPlayerScripts.JuggleClient`

| Instance | Класс | Исходник и ответственность |
| --- | --- | --- |
| `Main` | LocalScript | [Main.client.luau](../../src/client/Main.client.luau) — сетевой вход, последовательность ударов, E/R2, запуск HUD и эффектов, камера. |
| `Hud` | ModuleScript | [Hud.luau](../../src/client/Hud.luau) — кошелёк, золотая шкала, удар, комбо, уведомления, компоновка поля. |
| `Clubhouse` | ModuleScript | [Clubhouse.luau](../../src/client/Clubhouse.luau) — меню, покупка улучшений, состав, настройки и переключение страниц. |
| `ClubUI` | ModuleScript | [ClubUI.luau](../../src/client/ClubUI.luau) — карточки финтов, заданий и Академии, обучение и индикатор ритма. |
| `UiKit` | ModuleScript | [UiKit.luau](../../src/client/UiKit.luau) — создание GUI, тема, элементы, формат чисел и tween. |
| `Effects` | ModuleScript | [Effects.luau](../../src/client/Effects.luau) — локальные мячи, напарники, наградные BillboardGui и звук. |
| `KickMotion` | ModuleScript | [KickMotion.luau](../../src/client/KickMotion.luau) — связывание рига, ключевые позы, траектории, восстановление Transform. |

В Play клиентский набор копируется в `Players.<Player>.PlayerScripts.JuggleClient`. Появляются `PlayerGui.JuggleHUD`, `Workspace.LocalJuggleEffects` и `SoundService.JuggleKick` на клиенте. `StarterGui`, `StarterPack`, `ServerStorage` и `Teams` в Edit пусты. В симуляции также присутствуют стандартные `Animate`, `Health`, `RbxCharacterSounds`, `PlayerModule`, Freecam и модули CoreGui. Они относятся к среде Roblox/Studio и отсутствуют среди 14 исходников игры в Edit. Других авторских скриптов или пакетов в Edit не обнаружено.

## Старт и зависимости

```text
Server Main
├── Pitch.build → JuggleArena → prepareTraining
├── ClubMap.build → ClubDistricts → configureAccess
├── CampusArt.build → Lighting / Terrain / CampusScenery
├── Profiles → Balance + ClubRules → memory или DataStore
└── ReplicatedStorage.Juggle.Action
    ├── Client Main → Hud → Clubhouse / ClubUI / UiKit
    └── Client Main → Effects → KickMotion
```

Мир готовится до создания сетевого канала. Затем сервер привязывает четыре prompt и обработчики входа/выхода, выделяет слот и назначает маркер. Клиент ждёт `Action`, создаёт HUD и шлёт `sync` раз в секунду до первого снимка. Доступность ударов, покупок и выплат определяется фазой профиля. `CharacterAdded` возвращает игрока на тот же слот и применяет членскую группу коллизий при доступе в Академию.

`Pitch.build` принимает существующий `JuggleArena`. `ClubMap` переиспользует `ClubDistricts` с `CourtyardLayout`. `NavigationClearance` пропускает повторную подготовку проходов, `TrainingPads.CourtyardLayout` — повторную расстановку маркеров. `CampusArt.build` применяет свет при каждом старте, но ранний выход при наличии `CampusScenery` пропускает повторную перекраску и строительство фона. Эти ветки объясняют, почему совпадающие Luau-файлы сами по себе не гарантируют одинаковую сцену.

## Сетевой протокол

В Edit не найдено RemoteEvents, RemoteFunctions, UnreliableRemoteEvents или проектных Bindables. В обеих моделях Play найден один `RemoteEvent` — `ReplicatedStorage.Juggle.Action`. RemoteFunction не используется.

| Направление | Сообщения и аргументы | Серверная или клиентская реакция |
| --- | --- | --- |
| Клиент → сервер | `kick(sequence)` | Только готовый профиль. Проверяются целая возрастающая последовательность, лимит 14/с с запасом 5 и живой персонаж. Сервер сам рассчитывает начисление. Последовательность помечается до проверки лимита и жизни. |
| Клиент → сервер | `sync`, `retry` | Общий интервал не чаще 0,8 с. `retry` перезагружает фазу `failed`, иначе возвращается состояние. |
| Клиент → сервер | `boots`, `frequency`, `multiplier`, `sign`, `train`, `equip` | `target` — следующий уровень или ранг, `expected` у тренировки — следующий уровень напарника. Команды ограничены общим интервалом 0,08 с. Цена, текущий уровень, владение и доступность проверяются сервером. |
| Клиент → сервер | `trick(id)`, `dailyChoose(id, day)`, `dailyClaim(1, day)` | Проверки финта, контракта, дня, достижения цели и однократности награды. Дистанция проверяется у мирового prompt открытия, а команда меню работает в любом районе. |
| Клиент → сервер | `muted(bool)`, `quiet(bool)` | Сохраняемые флаги представления. |
| Сервер → клиент | `state(phase, data, message, effect, memory, rhythm)` | Полный снимок профиля и поля UI. Присутствуют при входе, командах, принятых ударах, пассивных выплатах и событиях ритма. На клиенте снимок обновляет HUD и открытое меню. |
| Сервер → клиент | `clubOpen(page?)` | Открывает «Команду» или «Прогресс» с prompt. Пустой аргумент закрывает окно при старте ритма. |

Атрибуты на `Player` служат параллельным каналом репликации. `JuggleSlot` — назначенный слот. `JugglePartner` выбирает модель напарника, а `JugglePartnerLevel` передаёт уровень. `JuggleMotion = hits × 4 + trick` читают клиенты для соседей. Собственный удар запускается через `state.effect`. `JuggleHit = hits × 2 + флаг золота` и `JuggleDistrict` записываются сервером. Проектных клиентских читателей `JuggleHit`, `JuggleDistrict`, `JuggleSlot` и `JugglePartnerLevel` не найдено.

## Профиль и жизненный цикл

- **Данные.** `coins, boots, frequency, multiplier, progress, owned, active, levels, muted, quiet, club`. В `club` хранятся `gold, trick, marks, rhythmBest, daily`. В `daily` входят `day, choice, count, claimed`. Активный раунд ритма, последний результат для HUD, слот, лимит и последовательность — состояние текущего сервера. `session` — служебное поле DataStore и в клиентский профиль не попадает.
- **Хранилище.** В Studio с `UseStudioDataStore = false` используется таблица процесса сервера. В опубликованной игре путь к `Juggle_v1`. При специально включённом постоянном режиме Studio с ненулевым PlaceId используется `JuggleStudio_v1`. Ключ — `user_<UserId>`. Аудит подтвердил только ветку памяти.
- **Нормализация.** На чтении и записи применяется белый список полей, целочисленные границы, ограничения рангов, корректировка шага золотого цикла и заполнение уровней подписанных футболистов. Старый профиль без `club` получает нулевые клубные достижения и финт 1. Наличие старого контракта закрывает обучение, но ранее заработанное золото не восстанавливается.
- **Загрузка и блокировка.** `UpdateAsync` проверяет действующую чужую аренду и выдаёт GUID текущей сессии с истечением через 180 с. До трёх попыток загрузки. Фазы — `loading`, `ready`, `failed`, `locked`. При `failed` доступно «Повторить», при `locked` UI просит войти снова.
- **Сохранение.** Каждые 5 с сервер ищет готовые профили, у которых прошло минимум 45 с с успешной записи. Запись проверяет ID аренды и обновляет её. На выходе пишет финальный снимок и снимает блокировку. При закрытии сервера ждёт до 27 с. Ошибки записи повторяются до трёх попыток. Потеря блокировки или длительная неудача записи при автосохранении переводит профиль в `locked`, убирая рабочие данные из записи игрока. Сценарии сбоев и гонок сверены по коду.
- **Регулярные задачи.** Пассивный доход проверяется каждые 0,25 с. Районы, круги, смена UTC-дня и финиш ритма — каждые 0,2 с. Сервер управляет коллизией лицензии и результатом упражнения. На клиенте `PreAnimation` восстанавливает суставы, `PreSimulation` накладывает позу, `RenderStep` двигает косметику.

Код места не использует внешние пакеты, HTTP-запросы, отдельные базы, сервер матчей или стороннюю аналитику. `HttpService` в игровой логике нужен для генерации GUID. Конфигурация Roblox в Creator Dashboard и свойства production DataStore не проверялись.
