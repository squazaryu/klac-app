# KlacApp (macOS)

Приложение имитирует звуки механической клавиатуры и воспроизводит их глобально при нажатиях клавиш.

## Что реализовано
- Глобальный перехват `keyDown/keyUp` через `CGEventTap` (низкая задержка).
- Несколько звуковых профилей на реальных `wav/mp3`-сэмплах:
  - `G915 Tactile`
  - `Holy Panda`
  - `Gateron Black Ink`
  - `MX Brown`
  - `MX Black`
  - `Gateron Red Ink`
  - `Alpaca`
- Отдельные звуки для `Space`, `Enter`, `Delete/Backspace`.
- Вариативность (небольшая случайная разница между кликами).
- Опциональный звук отпускания клавиши.
- Тонкая калибровка громкости: `Нажатие`, `Отпускание`, `Space/Enter`.
- Импорт/экспорт пресета настроек в JSON (в `Дополнительно`).

## Запуск
```bash
swift build
swift run
```

## Сборка отдельного .app
```bash
./scripts/build_app.sh --install
```
Приложение будет установлено в `/Applications/Klac.app`.

Чтобы права `Accessibility/Input Monitoring` не сбрасывались после пересборки,
используй стабильную подпись:
```bash
security find-identity -v -p codesigning
SIGN_IDENTITY="Apple Development: YOUR_NAME (TEAMID)" ./scripts/build_app.sh --install
```

## Релиз в GitHub
```bash
./scripts/release.sh v1.0.0
```
Скрипт:
- соберет `dist/Klac.app`
- запакует `dist/Klac-v1.0.0.zip`
- создаст git tag
- запушит `main` и tag
- создаст GitHub Release через `gh`

При первом запуске macOS попросит выдать Accessibility-доступ:
`System Settings -> Privacy & Security -> Accessibility`.

Также нужно выдать:
`System Settings -> Privacy & Security -> Input Monitoring`.

Без этого доступа глобальный перехват клавиш работать не будет.

## Источник сэмплов
Встроенные сэмплы взяты из открытого проекта [Keyboard Sounds](https://github.com/nathan-fiscaletti/keyboardsounds) (GPL-3.0).
