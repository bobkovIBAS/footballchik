# Инструкции FootballIntegration

- [Работа с исходниками и Studio](rules/workflow.md) — рабочий Place, синхронизация, локальное сохранение и проверка.
- [Знания о проекте](rules/project-knowledge.md) — где читать общую документацию и как обновлять её при изменении механик.
- [Стек и архитектура](rules/architecture.md) — Luau, Rojo, Lune, UI V2, серверные правила и данные.
- [Создание объектов игры](rules/world-objects.md) — модели, материалы, коллизии, привязки и проверка с персонажем.

Профиль проекта и карточки компонентов описывают существующие визуальные решения. Для изменений по референсу используй утверждённый пользователем образец и [визуальный гайд](../../VISUAL_STYLE_GUIDE.md). [Профиль](../../docs/design/README.md) · [Карточки компонентов](../../docs/design/components/README.md)

Подбирай навыки по конкретной задаче. При изменении видимого результата подключай визуальную проверку. Производительность измеряй при заметном изменении нагрузки или по запросу.

| Навык проекта | Когда использовать |
| --- | --- |
| [roblox-ui-designer](skills/roblox-ui-designer/SKILL.md) | HUD, меню, состояния, ввод и адаптивность |
| [roblox-environment-artist](skills/roblox-environment-artist/SKILL.md) | Локации, композиция, модели, материалы и свет |
| [roblox-vfx-animation](skills/roblox-vfx-animation/SKILL.md) | Анимации, эффекты, звук и синхронизация |
| [roblox-visual-qa](skills/roblox-visual-qa/SKILL.md) | Видимые изменения, проверка в Play и сравнение кадров |
| [roblox-performance](skills/roblox-performance/SKILL.md) | Время кадра, память, рендер и загрузка |

Плагин Roblox Standards предоставляет общие навыки `roblox-init`, `roblox-setup`, `roblox-ui`, `roblox-world`, `roblox-vfx` и `roblox-testing`. Если плагин недоступен, открой соответствующий `SKILL.md` в [локальной копии](../common/skills). Для авторских 3D-моделей используй [roblox-asset-artist](../common/skills/roblox-asset-artist/SKILL.md).

Агент [fotball-roblox-qa](agents/fotball-roblox-qa.toml) предназначен для явно запрошенной делегации проверки в Roblox Studio. Передай ему сценарий. По умолчанию используется один персонаж. Передавай разрешение на мультиплеер только при явном запросе пользователя.
