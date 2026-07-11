# windows-firewall-manager
<p align="center">
  <img src="https://img.shields.io/badge/Windows_Firewall_Manager-1.1.0-18181B?style=for-the-badge&labelColor=F4F4F5" alt="version"/>
</p>

<h1 align="center">Windows Firewall Manager</h1>

<p align="center">
  <strong>iptables для Windows — с русским GUI, CLI и JSON-бэкапами</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-16A34A?style=flat-square" alt="MIT"/></a>
  <a href="#"><img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell"/></a>
  <a href="#"><img src="https://img.shields.io/badge/Platform-Windows_10%2F11-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Windows"/></a>
  <a href="#"><img src="https://img.shields.io/badge/Open_Source-Yes-success?style=flat-square" alt="Open Source"/></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square" alt="PRs welcome"/></a>
</p>

<p align="center">
  <a href="docs/ИНСТРУКЦИЯ.md">📘 Инструкция</a> •
  <a href="docs/instruction.html">HTML</a> •
  <a href="#-быстрый-старт">Быстрый старт</a> •
  <a href="#-возможности">Возможности</a> •
  <a href="#-скриншоты">Скриншоты</a> •
  <a href="#-документация">Документация</a> •
  <a href="#-opensource">Open Source</a> •
  <a href="#-english">English</a>
</p>

---

## О проекте

**Windows Firewall Manager** — бесплатный open-source инструмент для управления правилами брандмауэра Windows 10/11. Вдохновлён простотой `iptables` в Linux, но с современным графическим интерфейсом на WPF.

> Создавайте именованные правила, фильтруйте трафик по портам и IP, делайте резервные копии — всё в одной группе `FirewallManager_Custom`, без риска затронуть системные правила.

---

## 📘 Инструкция пользователя

Полное руководство для загрузки и публикации:

| Формат | Файл | Для чего |
|--------|------|----------|
| **Markdown** | [`docs/ИНСТРУКЦИЯ.md`](docs/ИНСТРУКЦИЯ.md) | GitHub, красивый рендер |
| **HTML** | [`docs/instruction.html`](docs/instruction.html) | Сайт, браузер, Release |

---

## ⚡ Быстрый старт

### Скачать

| Способ | Команда / ссылка |
|--------|------------------|
| **Release (ZIP)** | [`releases/windows-firewall-manager-v1.0.0-etalon.zip`](releases/windows-firewall-manager-v1.0.0-etalon.zip) |
| **Git** | `git clone https://github.com/YOUR_USERNAME/windows-firewall-manager.git` |

### Запустить GUI

```bat
Run-GUI-Admin.bat
```

UAC запросит права администратора — это **обязательно** для работы с брандмауэром.

### Первое правило за 30 секунд

1. `Ctrl+N` или **+ Новое правило**
2. **Входящие** / **Исходящие** → **Разрешить** / **Заблокировать**
3. Протокол + порты → **Создать**

---

## ✨ Возможности

| | GUI (WPF) | CLI (PowerShell) |
|---|:---:|:---:|
| Создание правил с именем | ✅ | ✅ |
| Входящие / исходящие | ✅ | ✅ |
| Allow / Block | ✅ | ✅ |
| 12+ протоколов (TCP, UDP, ICMP…) | ✅ | ✅ |
| Порты: один, список, диапазон | ✅ | ✅ |
| Фильтр по IP (IPv4/IPv6/CIDR) | ✅ | ✅ |
| Профили: Domain / Private / Public | ✅ | ✅ |
| Вкл / выкл без удаления | ✅ | ✅ |
| Экспорт / импорт JSON | ✅ | ✅ |
| Поиск и фильтры | ✅ | — |
| Карточки статистики | ✅ | — |
| Горячие клавиши | ✅ | — |

---

## 🖥 Скриншоты

> Добавьте скриншоты в папку `docs/screenshots/` после публикации на GitHub.

```
docs/screenshots/
├── main-window.png      # Главное окно со списком правил
├── create-rule.png      # Модальное окно создания
└── stats-filters.png    # Карточки и фильтры
```

Схема интерфейса:

```
┌─────────────────────────────────────────────────────────────────┐
│ SIDEBAR              │  Правила                                   │
│ ◆ Брандмауэр         │  [12] [8 активн.] [4 откл.] [5 исход.]    │
│   • Правила          │  ┌──────────────────────────────────────┐  │
│   • Резервные копии  │  │ 🔍 Поиск...    [Обновить] [+ Новое]  │  │
│                      │  │ Направление: [Все][Вх][Исх]          │  │
│ Сейчас: 12 правил    │  │ Статус: [Все][Актив][Откл]           │  │
│                      │  ├──────────────────────────────────────┤  │
│                      │  │ ● My Rule    [Вх] [Разреш] [Вкл]     │  │
│                      │  └──────────────────────────────────────┘  │
│                      │  [Включить][Отключить][Удалить] [Экспорт] │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📖 Документация

### Горячие клавиши

| Клавиша | Действие |
|---------|----------|
| `Ctrl+N` | Новое правило |
| `Ctrl+F` | Поиск |
| `F5` | Обновить список |
| `Delete` | Удалить выбранное |
| `Esc` | Закрыть модалку |
| Двойной клик | Вкл / выкл правило |

### Протоколы

`TCP` · `UDP` · `ICMPv4` · `ICMPv6` · `GRE` · `IGMP` · `SCTP` · `ESP` · `AH` · `TCP+UDP` · `Любой`

### Формат портов

```
80                 один порт
443, 8080          список
1000-1010          диапазон
(пусто)            все порты
```

### IP-адреса

```
192.168.1.1        один адрес
10.0.0.0/24        подсеть
fe80::1            IPv6
(пусто)            любые
```

### iptables → Windows

| Linux | Windows Firewall Manager |
|-------|--------------------------|
| `-A INPUT` | Входящие |
| `-A OUTPUT` | Исходящие |
| `-j ACCEPT` | Разрешить |
| `-j DROP` | Заблокировать |
| `-p tcp --dport 80` | TCP, порт `80` |
| `-s 10.0.0.0/8` | Удалённые IP `10.0.0.0/8` |

### CLI

```powershell
powershell -ExecutionPolicy Bypass -File .\FirewallManager.ps1
```

### Резервная копия

```json
// examples/backup-example.json
{
  "DisplayName": "Allow HTTP In",
  "Direction": "Inbound",
  "Action": "Allow",
  "Protocol": "TCP",
  "LocalPort": "80"
}
```

---

## 🛠 Установка и требования

| Требование | Версия |
|------------|--------|
| ОС | Windows 10 / 11 |
| PowerShell | 5.1+ (встроен) |
| Права | Администратор |
| Модуль | `NetSecurity` (встроен) |
| Зависимости | **Нет** — чистый PowerShell + WPF |

### Execution Policy

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# или разовый запуск:
powershell -ExecutionPolicy Bypass -File .\FirewallManager.Gui.ps1
```

---

## 📁 Структура проекта

```
windows-firewall-manager/
├── FirewallManager.Core.ps1      # 🔧 Общий API (CLI + GUI)
├── FirewallManager.Gui.ps1       # 🖥 GUI logic
├── FirewallManager.Gui.xaml       # 🎨 UI layout
├── FirewallManager.ps1            # ⌨️  CLI menu
├── Run-GUI-Admin.bat              # ▶️  Launch GUI (UAC)
├── Run-FirewallManager.bat        # ▶️  Launch CLI
├── examples/backup-example.json
├── releases/                      # 📦 ZIP releases
├── LICENSE                        # MIT
├── CONTRIBUTING.md
├── SECURITY.md
├── CHANGELOG.md
├── OPTIMIZATION.md
└── README.md
```

---

## 🔒 Безопасность

- Изменяются **только** правила группы `FirewallManager_Custom`
- Брандмауэр **не отключается** целиком
- Удаление — с подтверждением
- Нет сетевых запросов, нет телеметрии
- Код открыт для аудита

Сообщить об уязвимости: [SECURITY.md](SECURITY.md)

---

## 🌐 Open Source

Проект распространяется под лицензией **[MIT](LICENSE)**.

### Что это значит

| Можно | Нельзя (без ответственности) |
|-------|------------------------------|
| ✅ Использовать бесплатно | ❌ Автор не гарантирует отсутствие багов |
| ✅ Изменять код | ❌ Автор не отвечает за блокировку сети |
| ✅ Распространять | |
| ✅ Использовать в коммерции | |
| ✅ Форкнуть на GitHub | |

### Участие

Мы рады PR и Issue! Читайте [CONTRIBUTING.md](CONTRIBUTING.md).

```powershell
# Быстрый форк-флоу
git clone https://github.com/YOUR_USERNAME/windows-firewall-manager.git
cd windows-firewall-manager
# ... правки ...
git commit -m "feat: your improvement"
git push origin main
```

### Публикация на GitHub (для автора)

<details>
<summary>📤 Пошаговая инструкция публикации</summary>

**1. Создайте репозиторий**

- [github.com/new](https://github.com/new) → `windows-firewall-manager`
- Public, **без** автогенерации README
- License: **MIT**

**2. Загрузите код**

```powershell
cd C:\Users\white\windows-firewall-manager
git init
git add .
git commit -m "feat: release v1.1.0 — Windows Firewall Manager"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/windows-firewall-manager.git
git push -u origin main
```

**3. Настройте репозиторий**

| Поле | Значение |
|------|----------|
| Description | `iptables-like Windows Firewall manager. Russian WPF GUI + PowerShell CLI. MIT.` |
| Topics | `windows`, `firewall`, `powershell`, `wpf`, `security`, `iptables`, `open-source` |
| Website | (опционально) ссылка на Release |

**4. Создайте Release**

- Tag: `v1.1.0`
- Title: `v1.1.0 — Optimized GUI + unified Core API`
- Attach: `releases/windows-firewall-manager-v1.0.0-etalon.zip`

**5. Включите**

- ✅ Issues
- ✅ Discussions (опционально)
- ✅ Security advisories

Или используйте скрипт:

```powershell
.\publish-to-github.ps1 -GitHubUsername YOUR_USERNAME
```

</details>

---

## 📋 Версии

| Версия | Описание |
|--------|----------|
| **1.1.0** | Оптимизация GUI, единый Core API |
| **1.0.0-etalon** | Стабильная эталонная сборка → [ETALON.md](ETALON.md) |

Полная история: [CHANGELOG.md](CHANGELOG.md)

---

## 💡 Примеры

<details>
<summary>Заблокировать UDP Steam (порт 27015)</summary>

GUI: Исходящие → Заблокировать → UDP → `27015`

</details>

<details>
<summary>Разрешить входящий HTTP (80)</summary>

GUI: Входящие → Разрешить → TCP → `80`

</details>

<details>
<summary>Заблокировать торрент-порты</summary>

Исходящие → Заблокировать → TCP+UDP → `6881-6889`

</details>

<details>
<summary>Заблокировать IP</summary>

Входящие → Заблокировать → Удалённые IP: `203.0.113.50`

</details>

---

## 🌍 English

**Windows Firewall Manager** is a free, open-source (MIT) tool for managing Windows Firewall rules on Windows 10/11. Think of it as iptables with a clean Russian GUI.

- Named inbound/outbound allow/block rules
- Ports, IP filters, 12+ protocols
- JSON backup/restore
- PowerShell CLI + WPF GUI
- No dependencies, no telemetry

```bat
Run-GUI-Admin.bat
```

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📜 License

```
MIT License — Copyright (c) 2026 white
```

Free to use, modify, distribute, and sublicense. See [LICENSE](LICENSE) for full text.

---

<p align="center">
  Сделано с ❤️ для тех, кто устал кликать по 20 окнам брандмауэра Windows
</p>

<p align="center">
  <a href="https://github.com/YOUR_USERNAME/windows-firewall-manager/stargazers">⭐ Star on GitHub</a>
</p>
