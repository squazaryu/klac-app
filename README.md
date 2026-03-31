# Клац (macOS)

Клац — menu bar приложение для macOS, которое воспроизводит звуки механической клавиатуры при глобальном вводе.

Текущая стабильная версия: `2.1.1`.
Полная история изменений: [`CHANGELOG.md`](CHANGELOG.md).

## Содержание
- [Что умеет приложение](#что-умеет-приложение)
- [Интерфейс](#интерфейс)
- [Режимы блока «Уровни»](#режимы-блока-уровни)
- [Встроенные sound packs](#встроенные-sound-packs)
- [Требования](#требования)
- [Запуск из исходников](#запуск-из-исходников)
- [Сборка и установка `.app`](#сборка-и-установка-app)
- [Релиз в GitHub (`zip + dmg`)](#релиз-в-github-zip--dmg)
- [Права macOS (TCC)](#права-macos-tcc)
- [Диагностика проблем](#диагностика-проблем)
- [Структура проекта](#структура-проекта)
- [Лицензия](#лицензия)

## Что умеет приложение
- Глобальный перехват клавиш через `CGEventTap`.
- Fallback на `NSEvent` global monitor, если `CGEventTap` недоступен.
- Профили свитчей на `wav/mp3/ogg`.
- Раздельные параметры звука: `Громкость`, `Нажатие`, `Отпускание`, `Space/Enter`, `Вариативность`, `Pitch var`.
- Anti-overlap параметры для плотной печати: `Min gap`, `Duck release`, `Duck window`, `Tail tight`.
- `Stack-режим` и лимитер пиков.
- `A/B` сравнение аудионастроек прямо в UI.
- Автокомпенсация/нормализация относительно системной громкости.
- Режимы настройки уровней: простой ползунок или детальная кривая.
- Персональные настройки по устройствам вывода (сохранение отдельно для каждого устройства).
- Проверка обновлений через GitHub Releases.

## Интерфейс

### Popover (иконка в menu bar)
- Включение/выключение перехвата.
- Статусы `AX`, `Input`, `Tap`.
- Выбор профиля свитчей.
- Кнопки:
  - `Проверить обновления`
  - `Settings...`
  - `Проверить доступы`
  - `Восстановить доступы`
  - `Quit`

### Окно `Klac — Настройки`
- Полный доступ ко всем аудиопараметрам.
- Ресайзабельное окно с сохранением позиции/размера.
- Разделы: `Звук`, `Layers`, `Пак звуков`, `Уровни`, `Устройство вывода`, `Инфографика`, `Система`.

## Режимы блока «Уровни»

`Авто-нормализация (inverse-кривая)` включает нормализацию относительно системной громкости macOS.

Доступны 2 режима:

1. `Простой`
- Одна настройка: `Цель @100%`.
- Быстрая базовая калибровка.

2. `Кривая`
- Детальная 5-точечная кривая (`L`, `LM`, `M`, `HM`, `H`) с drag-and-drop.
- Более плавная и точная реакция на разные уровни системной громкости.

## Встроенные sound packs
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
- собранный bundle: `dist/Klac.app`
- установленная копия: `/Applications/Klac.app`

По умолчанию локальная сборка получает build number по времени (`YYYYMMDDHHMM`) и тег `dev`.

Пример ручной сборки с явными метаданными:
```bash
APP_VERSION="2.1.1" BUILD_NUMBER="202603311200" BUILD_TAG="local" ./scripts/build_app.sh --install
```

## Релиз в GitHub (`zip + dmg`)
```bash
cd "/path/to/klac-app"
./scripts/release.sh v2.1.1
```

Скрипт автоматически:
1. собирает релизный `.app`;
2. формирует `dist/Klac-vX.Y.Z.zip`;
3. формирует `dist/Klac-vX.Y.Z.dmg` (внутри есть ярлык `Applications`);
4. создает git tag;
5. пушит `main` и tag;
6. публикует GitHub Release и прикладывает `zip + dmg`.

Полезные флаги:
```bash
./scripts/release.sh v2.1.1 --dry-run
./scripts/release.sh v2.1.1 --notes-file RELEASE_NOTES.md
./scripts/release.sh v2.1.1 --skip-push
./scripts/release.sh v2.1.1 --zip-only
```

## Права macOS (TCC)
Для работы глобального перехвата нужны оба разрешения:
- `Privacy & Security -> Accessibility`
- `Privacy & Security -> Input Monitoring`

После обновления всегда запускайте копию из `/Applications/Klac.app`, чтобы избежать конфликтов прав между разными сборками.

## Диагностика проблем

### 1) Нет звука или не идет перехват
- Нажмите `Проверить доступы`.
- Если не помогло: `Восстановить доступы`, затем повторно выдайте права в системных настройках.

Ручной сброс прав:
```bash
tccutil reset Accessibility com.klacapp.klac
tccutil reset ListenEvent com.klacapp.klac
```

### 2) Открывается «старая» версия
Частая причина — запущено несколько копий из разных путей.
```bash
pkill -f KlacApp || true
open -a "/Applications/Klac.app"
```

### 3) Звук некорректный после смены устройства вывода
- Убедитесь, что приложение обновлено до актуальной версии.
- Проверьте раздел `Устройство вывода` (автопресет и калибровка).
- При необходимости перезапустите приложение из `/Applications`.

## Структура проекта
- `Sources/KlacApp/ContentView.swift` — UI
- `Sources/KlacApp/KeyboardSoundService.swift` — обработка клавиш, аудиологика, TCC, обновления
- `Sources/KlacApp/AppDelegate.swift` — статус-элемент и popover
- `scripts/build_app.sh` — сборка `.app`
- `scripts/release.sh` — релизный пайплайн (`zip + dmg + GitHub release`)

## Лицензия
GPL-3.0. Подробности в файле [`LICENSE`](LICENSE).
