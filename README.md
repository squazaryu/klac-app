# Клац (macOS)

Клац — приложение в строке меню macOS, которое воспроизводит звуки механической клавиатуры при глобальном вводе.

Текущая стабильная версия: `2.1.4`.
История изменений: [`CHANGELOG.md`](CHANGELOG.md).

## Содержание
- [Возможности](#возможности)
- [Интерфейс](#интерфейс)
- [Блок «Уровни»](#блок-уровни)
- [Профили звука](#профили-звука)
- [Требования](#требования)
- [Запуск из исходников](#запуск-из-исходников)
- [Сборка и установка `.app`](#сборка-и-установка-app)
- [Релиз в GitHub](#релиз-в-github)
- [Права macOS (TCC)](#права-macos-tcc)
- [Диагностика](#диагностика)
- [Структура проекта](#структура-проекта)
- [Лицензия](#лицензия)

## Возможности
- Глобальный перехват клавиш через `CGEventTap`.
- Fallback на `NSEvent` global monitor, если `CGEventTap` недоступен.
- Профили свитчей на `wav/mp3/ogg`.
- Отдельные параметры звука: `Громкость`, `Нажатие`, `Отпускание`, `Space/Enter`, `Вариативность`, `Pitch var`.
- Anti-overlap параметры: `Min gap`, `Duck release`, `Duck window`, `Tail tight`.
- `Stack-режим`, лимитер пиков и `A/B` сравнение.
- Нормализация/компенсация относительно системной громкости.
- Персональные настройки для каждого устройства вывода.
- Проверка обновлений через GitHub Releases (кнопка открывает страницу релиза).

## Интерфейс

### Popover (иконка в menu bar)
- Включение/выключение.
- Статусы `AX`, `Input`, `Tap`.
- Выбор профиля свитчей.
- Действия:
  - `Проверить обновления`
  - `Settings...`
  - `Проверить доступы`
  - `Восстановить доступы`
  - `Quit`

### Окно `Klac — Настройки`
Открывается по `Settings...`, ресайзабельное, запоминает размер и позицию.

Разделы:
- `Звук`
- `Layers`
- `Пак звуков`
- `Уровни`
- `Устройство вывода`
- `Инфографика`
- `Система`

## Блок «Уровни»
`Авто-нормализация (inverse-кривая)` — режим нормализации относительно системной громкости.

Когда авто-нормализация **включена**:
- доступен выбор режима настройки:
  - `Простой` — только `Цель @100%`;
  - `Кривая` — детальная 5-точечная кривая (`L`, `LM`, `M`, `HM`, `H`).

Когда авто-нормализация **выключена**:
- применяется ручная кривая уровней (5 точек) без strict-нормализации.

## Профили звука
Встроенные профили:
- `Custom Pack`
- `Kalih Box White`
- `Mechvibes: Gateron Browns - Revolt`
- `Mechvibes: HyperX Aqua`
- `Mechvibes: Box Jade`
- `Mechvibes: Opera GX`
- `Mechvibes: CherryMX Black - ABS`
- `Mechvibes: CherryMX Black - PBT`
- `Mechvibes: EG Crystal Purple`
- `Mechvibes: EG Oreo`

### Custom Pack
UI-импорт отключен. `Custom Pack` загружается из директории:
`~/Library/Application Support/Klac/SoundPacks/Custom`

## Требования
- macOS 13+
- Xcode Command Line Tools
- Swift 5.9+

## Запуск из исходников
```bash
cd "/path/to/klac-app"
swift build
swift run
```

## Сборка и установка `.app`
```bash
cd "/path/to/klac-app"
./scripts/build_app.sh --install
```

Результат:
- `dist/Klac.app`
- `/Applications/Klac.app`

По умолчанию локальная сборка использует:
- `BUILD_NUMBER` = текущее время (`YYYYMMDDHHMM`)
- `BUILD_TAG` = `dev`

Пример ручной сборки:
```bash
APP_VERSION="2.1.4" BUILD_NUMBER="202604031300" BUILD_TAG="local" ./scripts/build_app.sh --install
```

## Релиз в GitHub
```bash
cd "/path/to/klac-app"
./scripts/release.sh v2.1.4
```

Скрипт:
1. собирает релизный `.app`;
2. создает `zip` и `dmg`;
3. создает git tag;
4. пушит `main` и tag;
5. публикует GitHub Release с ассетами.

Полезные флаги:
```bash
./scripts/release.sh v2.1.4 --dry-run
./scripts/release.sh v2.1.4 --notes-file RELEASE_NOTES.md
./scripts/release.sh v2.1.4 --skip-push
./scripts/release.sh v2.1.4 --zip-only
```

## Права macOS (TCC)
Нужны оба разрешения:
- `Privacy & Security -> Accessibility`
- `Privacy & Security -> Input Monitoring`

После обновления запускайте приложение из `/Applications/Klac.app`.

## Диагностика

### Нет звука или не работает перехват
1. Нажмите `Проверить доступы`.
2. Если не помогло — `Восстановить доступы`, затем повторно выдайте права.

Ручной сброс:
```bash
tccutil reset Accessibility com.klacapp.klac
tccutil reset ListenEvent com.klacapp.klac
```

### Открывается старая копия
```bash
pkill -f KlacApp || true
open -a "/Applications/Klac.app"
```

### После смены устройства вывода звук некорректный
- Проверьте раздел `Устройство вывода` (`Автопресет`, `Персональные настройки`, `Калибровка`).
- При необходимости перезапустите приложение из `/Applications`.

## Структура проекта
- `Sources/KlacApp/ContentView.swift` — UI
- `Sources/KlacApp/KeyboardSoundService.swift` — логика клавиш, аудио, TCC, обновления
- `Sources/KlacApp/AppDelegate.swift` — статус-элемент и popover
- `scripts/build_app.sh` — сборка `.app`
- `scripts/release.sh` — релизный пайплайн (`zip + dmg + GitHub release`)

## Лицензия
GPL-3.0. См. [`LICENSE`](LICENSE).
