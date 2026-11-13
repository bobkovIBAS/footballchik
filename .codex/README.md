# Codex в FootballIntegration

Открывай в Codex папку `FootballIntegration` для работы над этой игрой. Корневой [AGENTS.md](../AGENTS.md) подключает инструкции проекта.

| Папка | Содержимое |
| --- | --- |
| [common](common) | Локальная копия Roblox Standards 0.2.1 и общий навык `roblox-asset-artist`. Документация, шаблоны и скрипт инициализации хранятся рядом со своими навыками |
| [project](project) | Правила FootballIntegration, пять навыков по проекту и агент `fotball-roblox-qa` |

Codex обнаруживает проектные навыки через ссылки в `.agents/skills/`. Ссылки ведут в `.codex/project/skills/`, где хранится редактируемая копия. Общие навыки Roblox Standards предоставляет установленный плагин. Локальные файлы в `common/skills/` также можно открыть по ссылке из проектных инструкций.

Проектный агент хранится в `.codex/project/agents/` и доступен через стандартный путь `.codex/agents/`. Для запуска явно поручите Codex проверку конкретного сценария через агента `fotball-roblox-qa`.

Правила создания объектов и архитектуры — инструкции проекта, которые подключает `AGENTS.md`. Формат `.rules` в Codex управляет разрешениями shell-команд. Для этой игры специальных правил запуска команд не найдено. Общие разрешения других проектов здесь не копируются.

Team Create передаёт общий Place, а локальные инструкции и навыки остаются на компьютере. См. [порядок подключения к общей игре](../docs/TEAM_CREATE.md).

Документация OpenAI по [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [обнаружению навыков](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills), [агентам](https://learn.chatgpt.com/docs/agent-configuration/subagents#custom-agents) и [правилам команд](https://learn.chatgpt.com/docs/agent-configuration/rules).
