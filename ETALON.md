# Эталонная сборка v1.0.0

**Дата фиксации:** 11 июля 2026  
**Статус:** стабильная, проверенная версия — использовать как эталон для отката и сравнения.

## Что входит в эталон

- Графический интерфейс (WPF) на русском языке
- Консольный менеджер (CLI)
- Общий API (`FirewallManager.Core.ps1`)
- Фильтры по направлению и статусу, поиск, карточки статистики
- Создание правил с портами, IP, 12+ протоколами
- Экспорт / импорт JSON
- Горячие клавиши, tooltips, состояния кнопок
- Исправлен `BrushConverter` (без ошибки `Brush.Parse`)

## Архив

```
releases/windows-firewall-manager-v1.0.0-etalon.zip
```

## Запуск

```bat
Run-GUI-Admin.bat
```

## Проверка

```powershell
[xml]$x = Get-Content .\FirewallManager.Gui.xaml -Encoding UTF8
Add-Type -AssemblyName PresentationFramework
$r = New-Object System.Xml.XmlNodeReader($x)
[void][Windows.Markup.XamlReader]::Load($r)
Write-Host 'OK'
```

---

*Папка `etalon/` — замороженная копия исходников v1.0.0.*
