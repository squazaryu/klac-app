# Klac (macOS)

Klac — menu bar приложение для macOS, которое имитирует звуки механической клавиатуры при глобальном вводе.

## Возможности
- Глобальный перехват `keyDown/keyUp` через `CGEventTap`.
- Профили свитчей на реальных `wav/mp3` сэмплах.
- Раздельные уровни громкости:
  - `Громкость` (master)
  - `Нажатие`
  - `Отпускание`
  - `Space/Enter`
- `Вариативность` для более живого звучания.
- Отключение звука автоповтора удержания клавиши.
- Автокомпенсация громкости относительно системного volume.
- Импорт/экспорт пресета в JSON (`Дополнительно`).
- Иконка в menu bar + popover интерфейс.
- Автозапуск при входе в систему.

## Требования
- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

## Быстрый старт (из исходников)
```bash
cd "/Users/tumowuh/Projects/Klac app"
swift build
swift run
```

## Сборка и установка `.app`
```bash
cd "/Users/tumowuh/Projects/Klac app"
./scripts/build_app.sh --install
```

Итоговая сборка:
- локальный артефакт: `/Users/tumowuh/Projects/Klac app/dist/Klac.app`
- установленная копия: `/Applications/Klac.app`

## Права macOS (обязательно)
Для глобального перехвата нужны оба разрешения:
- `Privacy & Security -> Accessibility`
- `Privacy & Security -> Input Monitoring`

После установки/обновления запускай только `/Applications/Klac.app`, чтобы не было конфликтов TCC между разными копиями приложения.

## Если доступы «сломались»
В UI есть кнопка `Сбросить доступ` (рядом с `Проверить доступ`), она запускает `tccutil reset` для текущего `bundle id`.

Вручную:
```bash
tccutil reset Accessibility com.tumowuh.klac
tccutil reset ListenEvent com.tumowuh.klac
```

После сброса заново выдай разрешения в системных настройках.

## Подпись приложения и стабильность TCC
По умолчанию сборка подписывается ad-hoc (`-`), из-за чего права могут периодически слетать.

Лучше использовать постоянную подпись:
```bash
security find-identity -v -p codesigning
SIGN_IDENTITY="Apple Development: YOUR_NAME (TEAMID)" ./scripts/build_app.sh --install
```

## Релизы в GitHub
```bash
cd "/Users/tumowuh/Projects/Klac app"
./scripts/release.sh v1.0.0
```

Что делает `release.sh`:
1. Собирает релизный `dist/Klac.app`
2. Упаковывает `dist/Klac-vX.Y.Z.zip`
3. Создает git tag
4. Пушит `main` и tag
5. Создает GitHub Release через `gh` и прикладывает zip

Полезные флаги:
```bash
./scripts/release.sh v1.0.1 --dry-run
./scripts/release.sh v1.0.1 --notes-file RELEASE_NOTES.md
./scripts/release.sh v1.0.1 --skip-push
```

## Лицензия сэмплов
Аудио-сэмплы взяты из проекта Keyboard Sounds (GPL-3.0):
- https://github.com/nathan-fiscaletti/keyboardsounds
- локальная копия лицензии: `LICENSE.third-party-keyboardsounds`

## Структура проекта
- `Sources/KlacApp/ContentView.swift` — UI и настройки
- `Sources/KlacApp/KeyboardSoundService.swift` — логика клавиш/аудио/TCC
- `Sources/KlacApp/AppDelegate.swift` — menu bar статус-элемент и popover
- `scripts/build_app.sh` — сборка `.app`
- `scripts/release.sh` — выпуск релизов в GitHub
