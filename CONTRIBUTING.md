# Contributing / Участие в проекте

Спасибо за интерес к **Windows Firewall Manager**! Проект открыт для улучшений.

## Как помочь

| Способ | Описание |
|--------|----------|
| Bug report | Опишите проблему в [Issues](https://github.com/YOUR_USERNAME/windows-firewall-manager/issues) |
| Feature request | Предложите идею с примером сценария |
| Pull Request | Исправление или улучшение кода |
| Документация | Улучшение README, примеров, переводов |
| Star | Поддержите проект звездой на GitHub |

## Перед началом работы

1. Убедитесь, что Issue ещё не создан
2. Для крупных изменений — сначала обсудите в Issue
3. Работайте от ветки `main`
4. Тестируйте на Windows 10/11 с правами администратора

## Настройка окружения

```powershell
git clone https://github.com/YOUR_USERNAME/windows-firewall-manager.git
cd windows-firewall-manager
.\Run-GUI-Admin.bat
```

## Правила кода

- **Одна логика — один Core:** бизнес-логика только в `FirewallManager.Core.ps1`
- GUI меняет только `FirewallManager.Gui.ps1` / `.xaml`
- CLI — тонкая обёртка над Core
- Не вызывайте `Get-NetFirewallRule` из UI-событий (см. `OPTIMIZATION.md`)
- Кириллица в `.ps1` — файл с UTF-8 BOM
- Минимальный diff: без «попутного рефакторинга»

## Коммиты

Формат (рекомендуется):

```
type: краткое описание

feat: новая функция
fix: исправление бага
docs: документация
perf: оптимизация
refactor: рефакторинг без смены поведения
```

Пример:

```
fix: debounce поиска в GUI

Поиск больше не вызывает Get-FirewallRules на каждый символ.
```

## Pull Request

1. Опишите **что** и **зачем**
2. Укажите как тестировали
3. Приложите скриншот для UI-изменений
4. Дождитесь review

## Что не принимаем

- Отключение брандмауэра целиком
- Изменение системных правил вне группы `FirewallManager_Custom`
- Зависимости, требующие интернет при установке
- Код без тестирования на реальной Windows

## Лицензия

Отправляя PR, вы соглашаетесь, что вклад распространяется под [MIT License](LICENSE).

---

## English

1. Fork the repo
2. Create a branch: `git checkout -b fix/my-fix`
3. Test with `Run-GUI-Admin.bat`
4. Commit and push
5. Open a Pull Request

Thank you for making Windows firewall management easier for everyone!