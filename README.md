# Клац (macOS)

Клац — menu bar приложение для macOS, которое имитирует звуки механической клавиатуры при глобальном вводе.
Проект является самостоятельным и не аффилирован с другими приложениями с похожим назначением.

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
cd "/path/to/project"
swift build
swift run
```

## Сборка и установка `.app`
```bash
cd "/path/to/project"
./scripts/build_app.sh --install
```

Итоговая сборка:
- локальный артефакт: `dist/*.app`
- установленная копия: `/Applications/<название приложения>.app`

## Права macOS (обязательно)
Для глобального перехвата нужны оба разрешения:
- `Privacy & Security -> Accessibility`
- `Privacy & Security -> Input Monitoring`

После установки/обновления запускай только копию из `/Applications`, чтобы не было конфликтов TCC между разными копиями приложения.

## Если доступы «сломались»
В UI есть кнопка `Сбросить доступ` (рядом с `Проверить доступ`), она запускает `tccutil reset` для текущего `bundle id`.

Вручную:
```bash
BUNDLE_ID="$(defaults read /Applications/*.app/Contents/Info CFBundleIdentifier 2>/dev/null | head -n 1)"
tccutil reset Accessibility "$BUNDLE_ID"
tccutil reset ListenEvent "$BUNDLE_ID"
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
cd "/path/to/project"
./scripts/release.sh v1.0.0
```

Что делает `release.sh`:
1. Собирает релизный `.app` в `dist/`
2. Упаковывает архив `dist/*-vX.Y.Z.zip`
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
- `Sources/<AppTarget>/ContentView.swift` — UI и настройки
- `Sources/<AppTarget>/KeyboardSoundService.swift` — логика клавиш/аудио/TCC
- `Sources/<AppTarget>/AppDelegate.swift` — menu bar статус-элемент и popover
- `scripts/build_app.sh` — сборка `.app`
- `scripts/release.sh` — выпуск релизов в GitHub
