# Refactor Notes (2026-04-17)

## Что уже сделано
- `KeyboardSoundService` оставлен как facade для UI, но часть логики вынесена в отдельные модули:
  - `KlacVersioning`
  - `AudioCompensationMath`
  - `OutputDeviceClassifier`
  - `TypingMetricsEngine`
  - `KlacUpdateService`
  - `DebugLogService`
  - `PlaybackQueueController`
  - `PlaybackBufferRenderer`
  - `SamplePackParsers`
  - `PermissionsService`
  - `OutputDeviceService`
  - `SettingsStore`
  - `StressTestService`
  - `LaunchAtLoginService`
  - `SystemAudioMonitor`
  - `UpdateCheckService`
  - `TypingMetricsService`
  - `AppMetadataService`
  - `SoundPresetService`
  - `SettingsRepository`
  - `AudioGraphController`
  - `PlaybackScheduler`
  - `AudioMixResolver`
  - `MenuBarViewModel`
  - `AdvancedSettingsViewModel`
- Разделены runtime-файлы:
  - `Input/GlobalKeyEventTap.swift` (перехват клавиш)
  - `Audio/KeyboardAudioRuntime.swift` (`ClickSoundEngine`)
  - `Audio/SoundProfile.swift` (модель профилей)
  - `Audio/SoundProfileCatalog.swift` (маппинг профиля -> источник пака)
- Загрузка/парсинг/подготовка паков вынесены в `Audio/SamplePackLoader.swift`.
- Общие модели банка вынесены в `Audio/SoundBankModels.swift`.
- Выбор не-повторяющихся сэмплов вынесен в `Audio/SamplePicker.swift`.
- Polling системной громкости/устройства вывода вынесен в `Services/SystemAudioMonitor.swift`.
- Проверка обновлений (decision logic: up-to-date / update-available / invalid-link) вынесена в `Services/UpdateCheckService.swift`.
- Таймер деградации CPS/WPM и движок метрик печати вынесены из facade в `Services/TypingMetricsService.swift`.
- Runtime-утилиты версии/билда/bundle-id вынесены в `Services/AppMetadataService.swift`.
- Пресеты звука (наушники/динамики/profile-based) вынесены в `Services/SoundPresetService.swift`.
- Typed загрузка persisted-настроек + legacy migration вынесены в `Services/SettingsRepository.swift`.
- Lifecycle `AVAudioEngine/AVAudioPlayerNode` вынесен в `Audio/AudioGraphController.swift`.
- Планирование буферов и queue-overflow interrupt вынесены в `Audio/PlaybackScheduler.swift`.
- Gain/layer/release-logic вынесены в чистый `Audio/AudioMixResolver.swift`.
- Для popover UI введен тонкий фасад `MenuBarViewModel`, чтобы `ContentView` не зависел напрямую от полного surface-area `KeyboardSoundService`.
- Для `AdvancedSettingsView` введен `AdvancedSettingsViewModel` с двусторонними биндингами через keypath-based facade.
- UI-энумы вынесены из `KeyboardSoundService` в `Core/KlacUIEnums.swift` с `typealias` для обратной совместимости.
- `didSet`-цепочки в `KeyboardSoundService` частично нормализованы через typed sync-хелперы:
  - `syncSoundScalar`, `syncClampedSoundScalar`, `syncSoundFlag`
  - `syncCompensationScalar`, `syncCompensationMode`, `syncDynamicCompensationFlag`
  - `syncTypingAdaptationFlag`, `syncLayerThreshold`
  - `syncStrictNormalizationFlag`, `syncLaunchAtLoginFlag`, `syncSelectedProfile`
- Инициализация `KeyboardSoundService` разрезана на этапы:
  - `restorePersistedState(_:)`
  - `configureSoundEngine()`
  - `startRuntimeServices()`
  - `configureEventTap()`
  - `registerTerminationObserver()`
- Модели настроек нормализованы в отдельные структуры:
  - `SoundSettings`
  - `CompensationSettings`
  - `SystemSettings`
  - `DeviceSoundSnapshot`

## Ограничения текущего шага
- `KeyboardSoundService` всё ещё крупный из-за большого количества `@Published` полей и `didSet` с побочными эффектами.
- `ClickSoundEngine` всё ещё orchestrator-heavy, но основная mix-математика и audio-graph lifecycle уже вынесены.
- Тесты добавлены как `testTarget`, но в текущем окружении раннера может быть недоступен `XCTest`.  
  Файлы тестов обёрнуты в `#if canImport(XCTest)` для совместимости.

## Следующий безопасный шаг (без rewrite)
1. Довести `didSet`-нормализацию до конца (оставшиеся разрозненные ветки launch/profile/system), затем зафиксировать единый стиль синхронизации состояния.
2. Разделить `ClickSoundEngine` ещё на:
   - `SamplePackLoader` (manifest/config/sample loading)
3. Ввести тонкий `KeyboardPlaybackFacade` для UI, чтобы `ContentView` зависел от меньшего публичного surface area.
4. Запустить тесты в полноценном Xcode/CLI toolchain с `XCTest` и снять baseline по latency/CPU на stress тесте.
