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
- Добавлен `Input/KeyboardInputMonitorCoordinator.swift`:
  - инкапсулирует правила `start/stop/recoverIfNeeded` для перехвата клавиатуры;
  - отделяет `KeyboardSoundService` от конкретной реализации `GlobalKeyEventTap`;
  - позволяет unit-тестировать fail-safe перезапуск перехвата через mock monitor.
- Добавлены DI-адаптеры системных зависимостей:
  - `Services/PermissionsController.swift` (`PermissionsControlling`)
  - `Services/LaunchAtLoginController.swift` (`LaunchAtLoginControlling`)
  - `KeyboardSoundService` больше не дергает статические системные API напрямую.
- `KeyboardSoundService` переведен на единый persistence-path через `SettingsStore`
  вместо прямых `UserDefaults.standard` write-path внутри `didSet`.
- Модели настроек нормализованы в отдельные структуры:
  - `SoundSettings`
  - `CompensationSettings`
  - `SystemSettings`
  - `DeviceSoundSnapshot`
- Stage 2 (2026-04-18):
  - `AdvancedSettingsViewModel` отвязан от concrete `KeyboardSoundService` через узкий `AdvancedSettingsServiceProtocol`.
  - KeyPath-based привязки advanced-экрана заменены на key-based API:
    - `AdvancedBoolSetting`
    - `AdvancedDoubleSetting`
    - `AdvancedEnumSetting<T>`
  - Вынесен ownership per-device state в `PerDeviceSnapshotService`:
    - live maps для boosts/snapshots;
    - clamp/normalize при save/restore;
    - persistence через `SettingsStore` под существующими `SettingsKeys`.
  - Вынесен debug/crash report assembly в `DiagnosticsCoordinator` (`DiagnosticsFileSystem` для тестов).
  - `KeyboardSoundService` оставлен фасадом и делегирует snapshot/diagnostics обязанности.
  - Добавлены тесты stage 2:
    - `Tests/KlacAppTests/AdvancedSettingsViewModelTests.swift`
    - `Tests/KlacAppTests/PerDeviceSnapshotServiceTests.swift`
    - `Tests/KlacAppTests/DiagnosticsCoordinatorTests.swift`
- Дополнительно (2026-04-19): decision-логика `handleSystemAudioPoll` вынесена в
  `Services/SystemAudioPollCoordinator.swift`, side-effects оставлены в `KeyboardSoundService`.
- Добавлены тесты для poll-coordinator:
  - `Tests/KlacAppTests/SystemAudioPollCoordinatorTests.swift`
- Дополнительно (2026-04-19, итерация 2):
  - advanced-UI вынесен из `ContentView.swift` в отдельный `AdvancedSettingsView.swift`
    (без изменения визуального поведения);
  - import/export profile JSON вынесен из `KeyboardSoundService` в
    `Services/ProfileSettingsTransferService.swift` (serialization + clamp + profile fallback);
  - panel/file-system seam добавлен в:
    - `Services/FileDialogService.swift` (`FileDialogPresenting`, `FileReadWriting`);
    - `Services/ProfileSettingsTransferCoordinator.swift` (`ProfileSettingsTransferCoordinating`);
    - `KeyboardSoundService` делегирует import/export через coordinator, не держит inline panel/data orchestration;
  - export debug report делегирован в
    `Services/DebugLogExportCoordinator.swift` (`DebugLogExportCoordinating`);
  - orchestration переключения output-device вынесен в
    `Services/OutputDeviceTransitionCoordinator.swift` (begin/finalize планы:
    snapshot save/restore + preset fallback decision);
  - `handleSystemAudioPoll` в `KeyboardSoundService` упрощен: device-change ветка вынесена
    в `handleOutputDeviceTransition(result:)`;
  - conformance `KeyboardSoundService: AdvancedSettingsServiceProtocol` вынесен в
    отдельный файл `KeyboardSoundService+AdvancedSettingsService.swift`;
  - keycode -> keygroup классификация вынесена из `KeyboardAudioRuntime` в
    `Audio/KeyCodeClassifier.swift` (чистая логика, отдельная точка тестирования);
  - в `KeyboardSoundService` добавлен DI seam для persistence:
    `settingsStore` + `settingsRepository` инъецируются через `init` (дефолтное поведение сохранено);
  - `SystemAudioMonitor` абстрагирован протоколом `SystemAudioMonitoring`, зависимость инъецируется в
    `KeyboardSoundService` (дефолт сохраняет прежнее runtime-поведение);
  - сборка `DiagnosticsRuntimeSnapshot` вынесена в
    `Services/DiagnosticsRuntimeSnapshotFactory.swift` (`AppBuildMetadataProviding`);
  - форматирование `runtimeSettings` для debug-репорта вынесено в
    `Services/RuntimeSettingsSummaryBuilder.swift`;
  - debounce/readiness логика перестройки audio graph при смене output-device вынесена в
    `Audio/OutputDeviceRebuildCoordinator.swift`;
  - presentation-mapping проверки обновлений вынесен в
    `Services/UpdateCheckPresentationCoordinator.swift` (status/debug/action модель);
  - AppKit UI-action зависимости (`NSAlert`, `NSWorkspace.open`) инкапсулированы
    в `Services/UIActionPresenting.swift` (`InfoAlertPresenting`, `URLOpening`) и инъецируются в `KeyboardSoundService`;
  - тайминговая orchestration-логика recovery flow вынесена в
    `Services/AccessRecoveryCoordinator.swift` (`RecoveryScheduling`);
  - decision-логика fail-safe тика вынесена в
    `Services/FailSafeTickCoordinator.swift`;
  - decision-логика авто-пресета output-device вынесена в
    `Services/AutoOutputPresetCoordinator.swift`;
  - profile-switch логика стресс-теста вынесена в
    `Services/StressProfileTransitionCoordinator.swift`;
  - math-логика компенсационной кривой вынесена в
    `Services/CompensationCurveCoordinator.swift`;
  - вычисление dynamic-compensation gain вынесено в
    `Services/DynamicCompensationCoordinator.swift`;
  - вычисление typing-adaptation gain вынесено в
    `Services/TypingAdaptationCoordinator.swift`;
  - decision-логика audio fail-safe (`restart engine` / `resume player`) вынесена в
    `Audio/AudioEngineFailSafeCoordinator.swift`;
  - async orchestration проверки обновлений вынесена в
    `Services/UpdateCheckFlowCoordinator.swift` (`UpdateChecking` / `UpdateCheckFlowCoordinating`);
  - `KeyboardSoundService.applyAutoOutputPresetIfNeeded(...)` переведен на
    `AutoOutputPresetCoordinator.decide(...)` (service оставлен только для side-effects);
  - `MenuBarServiceProtocol` и `MenuBarViewModel` отвязаны от concrete-типа
    `KeyboardSoundService.AppearanceMode` в пользу общего `KlacAppearanceMode`;
  - добавлены unit-тесты `MenuBarViewModel` на protocol-seam и реакцию на `changePublisher`
    (`Tests/KlacAppTests/MenuBarViewModelTests.swift`);
  - применение импортированных настроек профиля и per-device snapshot унифицировано через
    `Services/SoundStatePatchMapper.swift` + единый `applySoundStatePatch(...)` в фасаде,
    чтобы убрать дубли assignment-логики;
  - выбор profile-preset (`settings + label`) вынесен в
    `Services/ProfilePresetCoordinator.swift`;
  - debug/file timestamp-генерация вынесена из фасада в
    `Services/DiagnosticsTimestampProvider.swift`;
  - маппинг текущего runtime-state устройства в `DeviceSoundStateDTO` вынесен в
    `Services/DeviceSoundStateMapper.swift`;
  - обработка update-check UI-actions (`show alert` / `open release URL`) вынесена в
    `Services/UpdateCheckActionExecutor.swift`;
  - восстановление persisted state в `KeyboardSoundService` разделено на явные apply-блоки:
    `applyPersistedSoundState`, `applyPersistedCompensationState`, `applyPersistedSystemState`;
  - маппинг `SettingsRepository.State -> persisted apply plan` вынесен в
    `Services/PersistedStateCoordinator.swift` (уменьшена связность фасада с shape persistence-state);
  - `KeyboardSoundService` отвязан от статических вызовов `AppMetadataService` через DI seam
    `AppMetadataProviding` (`SystemAppMetadataProvider` по умолчанию);
  - decision-часть access-recovery flow вынесена в
    `Services/AccessRecoveryPlanCoordinator.swift` (TCC services + hint messages);
  - сборка `DiagnosticsRuntimeContext` для debug-export вынесена в
    `Services/DiagnosticsRuntimeContextMapper.swift`;
  - сборка `RuntimeSettingsSummaryInput` из runtime-состояния вынесена в
    `Services/RuntimeSettingsSummaryMapper.swift` (удалены inline model-builders из фасада);
  - `OutputDeviceTransitionCoordinator.finalizePlan(...)` теперь возвращает `statusLabel`,
    что убрало status-string бизнес-логику из `KeyboardSoundService`;
  - decision-логика keyboard event handling вынесена из `configureEventTap` в
    `Input/KeyboardInputEventCoordinator.swift` (enabled/down/up/autorepeat/playKeyUp);
  - policy выбора источника банка профиля вынесен из `ClickSoundEngine` в
    `Audio/ProfileBankLoadCoordinator.swift`;
  - policy custom-pack fallback (custom root -> default custom dir -> bundled fallback) вынесен из
    `ClickSoundEngine` в `Audio/CustomPackFallbackCoordinator.swift`;
  - bundled fallback asset-paths для `kalihboxwhite` вынесены из runtime-класса в
    `Audio/BundledFallbackPackProvider.swift`;
  - decision-логика route-change lifecycle (`rebuild graph` / `start after rebuild`) вынесена из
    `ClickSoundEngine` в `Audio/AudioRouteChangeCoordinator.swift`;
  - policy персиста per-device snapshot/boost вынесен в
    `Services/PerDevicePersistenceCoordinator.swift`;
  - policy `startIfNeeded` (engine/player start decisions) вынесен в
    `Audio/AudioStartCoordinator.swift`;
  - preflight policy playback (`canPlay` + `keepEngineRunning`) вынесен в
    `Audio/PlaybackPreflightCoordinator.swift`, логика `_playDown/_playUp` унифицирована;
  - policy нотификации смены velocity-layer вынесен в
    `Audio/VelocityLayerChangeCoordinator.swift`;
  - добавлены unit-тесты:
    - `Tests/KlacAppTests/ProfileSettingsTransferServiceTests.swift`;
    - `Tests/KlacAppTests/ProfileSettingsTransferCoordinatorTests.swift`;
    - `Tests/KlacAppTests/DebugLogExportCoordinatorTests.swift`;
    - `Tests/KlacAppTests/SettingsRepositoryTests.swift`;
    - `Tests/KlacAppTests/OutputDeviceTransitionCoordinatorTests.swift`;
    - `Tests/KlacAppTests/KeyCodeClassifierTests.swift`;
    - `Tests/KlacAppTests/DiagnosticsRuntimeSnapshotFactoryTests.swift`;
    - `Tests/KlacAppTests/KeyboardSoundServiceFacadeTests.swift`;
      (включая фасадный сценарий `system audio poll -> auto output preset`);
      + сценарий инициализации `service <- persisted repository state`;
      + сценарий `resetPrivacyPermissions` с инъекцией bundle id;
      + сценарий `checkForUpdatesInteractive` с DI metadata provider (version/build passthrough);
      + сценарий `runAccessRecoveryWizard` (reset + hint + restart через injected scheduler);
    - `Tests/KlacAppTests/RuntimeSettingsSummaryBuilderTests.swift`;
    - `Tests/KlacAppTests/OutputDeviceRebuildCoordinatorTests.swift`;
    - `Tests/KlacAppTests/UpdateCheckPresentationCoordinatorTests.swift`;
    - `Tests/KlacAppTests/AccessRecoveryCoordinatorTests.swift`;
    - `Tests/KlacAppTests/FailSafeTickCoordinatorTests.swift`;
    - `Tests/KlacAppTests/AutoOutputPresetCoordinatorTests.swift`;
    - `Tests/KlacAppTests/StressProfileTransitionCoordinatorTests.swift`;
    - `Tests/KlacAppTests/SoundStatePatchMapperTests.swift`;
    - `Tests/KlacAppTests/ProfilePresetCoordinatorTests.swift`;
    - `Tests/KlacAppTests/DiagnosticsTimestampProviderTests.swift`;
    - `Tests/KlacAppTests/DeviceSoundStateMapperTests.swift`;
    - `Tests/KlacAppTests/UpdateCheckActionExecutorTests.swift`;
    - `Tests/KlacAppTests/PersistedStateCoordinatorTests.swift`;
    - `Tests/KlacAppTests/AccessRecoveryPlanCoordinatorTests.swift`;
    - `Tests/KlacAppTests/DiagnosticsRuntimeContextMapperTests.swift`;
    - `Tests/KlacAppTests/RuntimeSettingsSummaryMapperTests.swift`;
    - `Tests/KlacAppTests/KeyboardInputEventCoordinatorTests.swift`;
    - `Tests/KlacAppTests/ProfileBankLoadCoordinatorTests.swift`;
    - `Tests/KlacAppTests/CustomPackFallbackCoordinatorTests.swift`;
    - `Tests/KlacAppTests/BundledFallbackPackProviderTests.swift`;
    - `Tests/KlacAppTests/AudioRouteChangeCoordinatorTests.swift`;
    - `Tests/KlacAppTests/PerDevicePersistenceCoordinatorTests.swift`;
    - `Tests/KlacAppTests/AudioStartCoordinatorTests.swift`;
    - `Tests/KlacAppTests/PlaybackPreflightCoordinatorTests.swift`;
    - `Tests/KlacAppTests/VelocityLayerChangeCoordinatorTests.swift`;
    - `Tests/KlacAppTests/CompensationCurveCoordinatorTests.swift`;
    - `Tests/KlacAppTests/DynamicCompensationCoordinatorTests.swift`;
    - `Tests/KlacAppTests/TypingAdaptationCoordinatorTests.swift`;
    - `Tests/KlacAppTests/AudioEngineFailSafeCoordinatorTests.swift`;
    - `Tests/KlacAppTests/UpdateCheckFlowCoordinatorTests.swift`.
- Локальная зачистка без смены поведения:
  - удалены неиспользуемые элементы (`startSystemVolumeMonitoring`, внутренний `debugLogLines`, `lastInputEventAt`);
  - унифицированы простые settings `didSet` через общие helper-методы (`syncSettingFlag`, `syncSettingString`);
  - решение `shouldApplyAutoPreset` делегировано в `SystemAudioPollCoordinator` и покрыто тестом.
  - private runtime-поля `KeyboardSoundService` агрегированы в `RuntimeState`
    (громкость/UID/device flags), при сохранении текущего публичного поведения.

## Stage 2 Status
- Stage 2 refactor завершен: ключевые seam-экстракции сделаны, сборка/тесты проходят, поведение сохранено.

## Остаточные ограничения
- `KeyboardSoundService` всё ещё крупный из-за большого количества `@Published` полей и `didSet` с побочными эффектами.
- `ClickSoundEngine` всё ещё orchestrator-heavy, но основная mix-математика и audio-graph lifecycle уже вынесены.
- Тесты добавлены как `testTarget`, но в текущем окружении раннера может быть недоступен `XCTest`.  
  Файлы тестов обёрнуты в `#if canImport(XCTest)` для совместимости.
- Добавлены unit-тесты на orchestration-логику перехвата:
  - `Tests/KlacAppTests/KeyboardInputMonitorCoordinatorTests.swift`

## Next Backlog (Stage 3, optional)
1. Дальше сжать `KeyboardSoundService`: финально вынести оставшиеся UI/panel workflows в coordinator-и.
2. Углубить декомпозицию `ClickSoundEngine` на playback lifecycle и pack-loading policy.
3. Зафиксировать baseline latency/CPU в полноценном `XCTest`/Xcode раннере и добавить пороговые регресс-тесты.
