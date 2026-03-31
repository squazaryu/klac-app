import SwiftUI
import AppKit

private enum AdvancedSettingsWindowHost {
    static var window: NSWindow?
    static let closeDelegate = AdvancedSettingsWindowCloseDelegate()
}

private final class AdvancedSettingsWindowCloseDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        _ = notification
        AdvancedSettingsWindowHost.window = nil
    }
}

struct ContentView: View {
    @EnvironmentObject private var service: KeyboardSoundService
    @State private var showAccessHintPopover = false
    @State private var showSwitchesMenu = false
    private let outerRadius: CGFloat = 14
    private let innerRadius: CGFloat = 11
    private let outerPadding: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuHeader
            Divider().opacity(0.65)
            statusLine
            Divider().opacity(0.55)
            profileLine
            Divider().opacity(0.55)
            menuActions
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(.thinMaterial.opacity(0.30))
        )
        .padding(outerPadding)
        .background(
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.58))
                .overlay {
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .blendMode(.multiply)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
        .frame(width: 340, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
        .onAppear {
            service.start()
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch service.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var captureStatusTitle: String {
        service.capturingKeyboard ? "Активно" : "Нет доступа"
    }

    private var appVersionCaption: String {
        let releaseFallbackVersion = "2.1.1"
        let short = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let tag = (Bundle.main.object(forInfoDictionaryKey: "KlacBuildTag") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let version = (short?.isEmpty == false) ? short! : releaseFallbackVersion
        let buildPart: String
        if build?.isEmpty == false, tag?.isEmpty == false {
            buildPart = "b\(build!)-\(tag!)"
        } else if build?.isEmpty == false {
            buildPart = "b\(build!)"
        } else {
            buildPart = "bdev"
        }
        return "v\(version) (\(buildPart))"
    }

    private var menuHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: service.capturingKeyboard ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(service.capturingKeyboard ? Color.green : Color.orange)
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(service.isEnabled ? "Enable Klac" : "Disable Klac")
                    .font(.system(size: 15, weight: .semibold))
                Text(appVersionCaption)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $service.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(.accentColor)
                .onChange(of: service.isEnabled) { enabled in
                    enabled ? service.start() : service.stop()
                }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            Text(captureStatusTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(service.capturingKeyboard ? .green : .orange)
            Spacer()
            HStack(spacing: 6) {
                statusBadge("AX", ok: service.accessibilityGranted)
                statusBadge("Input", ok: service.inputMonitoringGranted)
                statusBadge("Tap", ok: service.capturingKeyboard)
            }
            Button {
                showAccessHintPopover.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .popover(isPresented: $showAccessHintPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Подсказка")
                        .font(.headline)
                    Text(service.accessActionHint ?? "Нажми «Проверить». Если не помогло, нажми «Восстановить», выдай доступ и перезапусти приложение.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(width: 320)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(.thinMaterial.opacity(0.42), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var profileLine: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Switches")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Button {
                showSwitchesMenu.toggle()
            } label: {
                HStack(spacing: 8) {
                    Text(service.selectedProfile.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.thinMaterial.opacity(0.48), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.9)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSwitchesMenu, arrowEdge: .trailing) {
                switchesMenu
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(.thinMaterial.opacity(0.36), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var switchesMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Switches")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 4)

            ForEach(SoundProfile.allCases) { profile in
                Button {
                    service.selectedProfile = profile
                    showSwitchesMenu = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: service.selectedProfile == profile ? "checkmark" : "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(service.selectedProfile == profile ? Color.accentColor : Color.secondary)
                            .frame(width: 14)
                        Text(profile.title)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                if profile != SoundProfile.allCases.last {
                    Divider().opacity(0.25).padding(.leading, 34)
                }
            }
        }
        .frame(width: 320)
        .background(.ultraThinMaterial.opacity(0.92))
    }

    private var menuActions: some View {
        VStack(spacing: 4) {
            Button {
                service.checkForUpdatesInteractive()
            } label: {
                menuRowLabel("Проверить обновления", icon: "arrow.down.circle")
            }
            .buttonStyle(.plain)

            Button {
                openAdvancedSettingsWindow()
            } label: {
                menuRowLabel("Settings...", icon: "gearshape")
            }
            .buttonStyle(.plain)

            Button {
                service.refreshAccessibilityStatus(promptIfNeeded: true)
            } label: {
                menuRowLabel("Проверить доступы", icon: "checkmark.shield")
            }
            .buttonStyle(.plain)

            Button {
                service.runAccessRecoveryWizard()
            } label: {
                menuRowLabel("Восстановить доступы", icon: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Divider().opacity(0.55)
                .padding(.vertical, 2)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                menuRowLabel("Quit", icon: "power")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(.thinMaterial.opacity(0.30), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func openAdvancedSettingsWindow() {
        if let window = AdvancedSettingsWindowHost.window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let root = AdvancedSettingsView(
            service: service,
            onClose: {
                AdvancedSettingsWindowHost.window?.close()
            }
        )
        let host = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: host)
        window.title = "Klac — Настройки"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setFrame(NSRect(x: 0, y: 0, width: 560, height: 680), display: false)
        window.minSize = NSSize(width: 520, height: 560)
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Klac.AdvancedSettingsWindow")
        window.delegate = AdvancedSettingsWindowHost.closeDelegate
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        AdvancedSettingsWindowHost.window = window
    }

    private func statusBadge(_ title: String, ok: Bool) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(ok ? Color.green : Color.orange)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }

    private func menuRowLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.0001))
        )
    }
}

private struct GlassCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct AdvancedSettingsView: View {
    @ObservedObject var service: KeyboardSoundService
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss
    var onClose: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Дополнительные настройки")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                GlassCard(title: "Звук") {
                    VStack(alignment: .leading, spacing: 10) {
                        sliderRow(title: "Громкость", value: $service.volume)
                        sliderRow(title: "Вариативность", value: $service.variation)
                        sliderRow(title: "Pitch var", value: $service.pitchVariation, range: 0.0 ... 0.6)
                        sliderRow(title: "Нажатие", value: $service.pressLevel, range: 0.2 ... 1.6)
                        sliderRow(title: "Отпускание", value: $service.releaseLevel, range: 0.1 ... 1.4)
                        sliderRow(title: "Space/Enter", value: $service.spaceLevel, range: 0.2 ... 1.8)
                        Toggle("Автоподстройка под выбранный пак", isOn: $service.autoProfileTuningEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Text("Пак-пресет: \(service.profilePresetLastApplied)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Toggle("Звук отпускания клавиши", isOn: $service.playKeyUp)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Toggle("Автокомпенсация по системной громкости", isOn: $service.dynamicCompensationEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        sliderRow(title: "Сила компенсации", value: $service.compensationStrength, range: 0.0 ... 2.0)
                            .opacity(service.dynamicCompensationEnabled ? 1.0 : 0.45)
                        Text("Текущая компенсация: x\(String(format: "%.2f", service.liveDynamicGain))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Toggle("Адаптация к скорости печати", isOn: $service.typingAdaptiveEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Text("Адаптация авто: x\(String(format: "%.2f", service.liveTypingGain)) · \(String(format: "%.1f", service.typingCPS)) CPS")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Toggle("Stack-режим", isOn: $service.stackModeEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        sliderRow(title: "Плотность стака", value: $service.stackDensity, range: 0.0 ... 1.0)
                            .opacity(service.stackModeEnabled ? 1.0 : 0.45)
                        Toggle("Лимитер пиков", isOn: $service.limiterEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        sliderRow(title: "Драйв лимитера", value: $service.limiterDrive, range: 0.6 ... 2.0)
                            .opacity(service.limiterEnabled ? 1.0 : 0.45)
                        HStack(spacing: 8) {
                            Picker("A/B", selection: $service.abFeature) {
                                ForEach(KeyboardSoundService.ABFeature.allCases) { feature in
                                    Text(feature.title).tag(feature)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                            Button(service.isABPlaying ? "Сравнение..." : "Сравнить OFF/ON") {
                                service.playABComparison()
                            }
                            .buttonStyle(PrimaryGlassButtonStyle())
                            .disabled(service.isABPlaying)
                        }
                        Text("Проигрывает два теста подряд: сначала OFF, затем ON.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Пресет: Наушники") { service.applyHeadphonesPreset() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                            Button("Пресет: Динамики") { service.applySpeakersPreset() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                        }
                    }
                }

                GlassCard(title: "Layers") {
                    VStack(alignment: .leading, spacing: 10) {
                        layerSliderRow(title: "Slam", value: $service.layerThresholdSlam, range: 0.010 ... 0.120)
                        layerSliderRow(title: "Hard", value: $service.layerThresholdHard, range: 0.025 ... 0.180)
                        layerSliderRow(title: "Medium", value: $service.layerThresholdMedium, range: 0.040 ... 0.260)
                        sliderRow(title: "Min gap", value: $service.minInterKeyGapMs, range: 0 ... 45, suffix: " ms", width: 64)
                        sliderRow(title: "Duck release", value: $service.releaseDuckingStrength, range: 0 ... 1)
                        sliderRow(title: "Duck window", value: $service.releaseDuckingWindowMs, range: 20 ... 180, suffix: " ms", width: 64)
                        sliderRow(title: "Tail tight", value: $service.releaseTailTightness, range: 0 ... 1)
                        Text("Live слой: \(service.liveVelocityLayer)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassCard(title: "Пак звуков") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(service.manifestValidationSummary)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(service.manifestValidationIssues.isEmpty ? Color.green : Color.orange)
                        if !service.manifestValidationIssues.isEmpty {
                            ForEach(Array(service.manifestValidationIssues.prefix(4)), id: \.self) { issue in
                                Text("• \(issue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                GlassCard(title: "Уровни") {
                    VStack(alignment: .leading, spacing: 10) {
                        let systemVolumeCaption = service.detectedSystemVolumeAvailable
                            ? "\(Int(service.detectedSystemVolumePercent.rounded()))%"
                            : "нет данных"
                        Text("Системная громкость: \(systemVolumeCaption)")
                            .font(.footnote)
                            .foregroundStyle(service.detectedSystemVolumeAvailable ? Color.secondary : Color.orange)
                        Toggle("Авто-нормализация (inverse-кривая)", isOn: $service.strictVolumeNormalizationEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        if service.strictVolumeNormalizationEnabled {
                            Picker("Режим", selection: $service.levelTuningMode) {
                                ForEach(KeyboardSoundService.LevelTuningMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            sliderRow(title: "Цель @100%", value: $service.autoNormalizeTargetAt100, range: 0.20 ... 1.20)
                            if service.levelTuningMode == .curve {
                                LevelCurveEditor(
                                    lowX: $service.levelMacLow,
                                    lowY: $service.levelKbdLow,
                                    lowMidX: $service.levelMacLowMid,
                                    lowMidY: $service.levelKbdLowMid,
                                    midX: $service.levelMacMid,
                                    midY: $service.levelKbdMid,
                                    highMidX: $service.levelMacHighMid,
                                    highMidY: $service.levelKbdHighMid,
                                    highX: $service.levelMacHigh,
                                    highY: $service.levelKbdHigh
                                )
                                .frame(height: 196)
                                Text("Точки: L \(Int((service.levelMacLow * 100).rounded()))/\(Int((service.levelKbdLow * 100).rounded())) · LM \(Int((service.levelMacLowMid * 100).rounded()))/\(Int((service.levelKbdLowMid * 100).rounded())) · M \(Int((service.levelMacMid * 100).rounded()))/\(Int((service.levelKbdMid * 100).rounded())) · HM \(Int((service.levelMacHighMid * 100).rounded()))/\(Int((service.levelKbdHighMid * 100).rounded())) · H \(Int((service.levelMacHigh * 100).rounded()))/\(Int((service.levelKbdHigh * 100).rounded()))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Простой режим: только целевая громкость на 100% системной громкости.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Авто-нормализация выключена. Используется ручная кривая уровней.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            LevelCurveEditor(
                                lowX: $service.levelMacLow,
                                lowY: $service.levelKbdLow,
                                lowMidX: $service.levelMacLowMid,
                                lowMidY: $service.levelKbdLowMid,
                                midX: $service.levelMacMid,
                                midY: $service.levelKbdMid,
                                highMidX: $service.levelMacHighMid,
                                highMidY: $service.levelKbdHighMid,
                                highX: $service.levelMacHigh,
                                highY: $service.levelKbdHigh
                            )
                            .frame(height: 196)
                        }
                        let p30 = Int((service.autoInverseGainPreview(systemVolumePercent: 30) * 100).rounded())
                        let p60 = Int((service.autoInverseGainPreview(systemVolumePercent: 60) * 100).rounded())
                        let p100 = Int((service.autoInverseGainPreview(systemVolumePercent: 100) * 100).rounded())
                        Text("Текущий gain: x\(String(format: "%.2f", service.liveDynamicGain))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Preview: Mac 30% → Kbd \(p30)% · 60% → \(p60)% · 100% → \(p100)%")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassCard(title: "Устройство вывода") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(service.currentOutputDeviceName)
                            .foregroundStyle(.primary)
                        Toggle("Персональные настройки устройства", isOn: $service.perDeviceSoundProfileEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Toggle("Автопресет по устройству", isOn: $service.autoOutputPresetEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Picker("Профиль устройства", selection: $service.currentOutputPresetMode) {
                            ForEach(KeyboardSoundService.OutputPresetMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Последний автопресет: \(service.autoOutputPresetLastApplied)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        sliderRow(title: "Калибровка", value: $service.currentOutputDeviceBoost, range: 0.5 ... 2.0)
                        Text("Отдельно сохраняется для каждого аудиоустройства.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassCard(title: "Инфографика") {
                    HStack(spacing: 12) {
                        metricBox(title: "CPS", value: String(format: "%.1f", service.typingCPS))
                        metricBox(title: "WPM", value: String(format: "%.0f", service.typingWPM))
                    }
                }

                GlassCard(title: "Система") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Автозапуск при входе в систему", isOn: $service.launchAtLogin)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        Picker("Тема", selection: $service.appearanceMode) {
                            ForEach(KeyboardSoundService.AppearanceMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            Button("Проверить доступы") { service.refreshAccessibilityStatus(promptIfNeeded: true) }
                                .buttonStyle(PrimaryGlassButtonStyle())
                            Button("Мастер восстановления") { service.runAccessRecoveryWizard() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                        }
                        HStack {
                            Button("Экспорт профиля") { service.exportSettings() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                            Button("Импорт профиля") { service.importSettings() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Закрыть") {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    }
                        .buttonStyle(PrimaryGlassButtonStyle())
                }
            }
            .padding(16)
        }
        .frame(minWidth: 520, idealWidth: 640, maxWidth: .infinity, minHeight: 560, idealHeight: 760, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: isDarkTheme
                ? [Color(red: 0.10, green: 0.16, blue: 0.26), Color(red: 0.06, green: 0.08, blue: 0.14)]
                : [Color(red: 0.93, green: 0.96, blue: 0.99), Color(red: 0.85, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch service.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var isDarkTheme: Bool {
        switch service.appearanceMode {
        case .system: return systemColorScheme == .dark
        case .light: return false
        case .dark: return true
        }
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0.0 ... 1.0,
        suffix: String = "%",
        width: CGFloat = 52
    ) -> some View {
        let display = suffix == "%" ? Int(value.wrappedValue * 100) : Int(value.wrappedValue.rounded())
        return HStack {
            Text(title)
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.cyan)
            Text("\(display)\(suffix)")
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: width, alignment: .trailing)
        }
    }

    private func layerSliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.cyan)
            Text("\(Int((value.wrappedValue * 1000).rounded())) ms")
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func metricBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LevelCurveEditor: View {
    @Binding var lowX: Double
    @Binding var lowY: Double
    @Binding var lowMidX: Double
    @Binding var lowMidY: Double
    @Binding var midX: Double
    @Binding var midY: Double
    @Binding var highMidX: Double
    @Binding var highMidY: Double
    @Binding var highX: Double
    @Binding var highY: Double

    private let xRange: ClosedRange<Double> = 0.05 ... 1.0
    private let yRange: ClosedRange<Double> = 0.20 ... 4.0
    private let minXGap: Double = 0.02

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let plotInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            let plot = CGRect(
                x: plotInsets.leading,
                y: plotInsets.top,
                width: max(20, width - plotInsets.leading - plotInsets.trailing),
                height: max(20, height - plotInsets.top - plotInsets.bottom)
            )

            let lowPoint = point(x: lowX, y: lowY, in: plot)
            let lowMidPoint = point(x: lowMidX, y: lowMidY, in: plot)
            let midPoint = point(x: midX, y: midY, in: plot)
            let highMidPoint = point(x: highMidX, y: highMidY, in: plot)
            let highPoint = point(x: highX, y: highY, in: plot)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.9)
                    }

                Path { path in
                    for t in stride(from: 0.25, through: 0.75, by: 0.25) {
                        let y = plot.maxY - CGFloat(t) * plot.height
                        path.move(to: CGPoint(x: plot.minX, y: y))
                        path.addLine(to: CGPoint(x: plot.maxX, y: y))
                    }
                    for t in stride(from: 0.25, through: 0.75, by: 0.25) {
                        let x = plot.minX + CGFloat(t) * plot.width
                        path.move(to: CGPoint(x: x, y: plot.minY))
                        path.addLine(to: CGPoint(x: x, y: plot.maxY))
                    }
                }
                .stroke(Color.primary.opacity(0.10), style: StrokeStyle(lineWidth: 0.8))

                Path { path in
                    path.move(to: lowPoint)
                    path.addLine(to: lowMidPoint)
                    path.addLine(to: midPoint)
                    path.addLine(to: highMidPoint)
                    path.addLine(to: highPoint)
                    path.addLine(to: CGPoint(x: highPoint.x, y: plot.maxY))
                    path.addLine(to: CGPoint(x: lowPoint.x, y: plot.maxY))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.16), Color.cyan.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    path.move(to: lowPoint)
                    path.addLine(to: lowMidPoint)
                    path.addLine(to: midPoint)
                    path.addLine(to: highMidPoint)
                    path.addLine(to: highPoint)
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.95), Color.mint.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                )

                pointHandle(
                    title: "L",
                    point: lowPoint,
                    color: Color.cyan
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            lowX = clamp(newX, to: orderedRange(xRange.lowerBound, lowMidX - minXGap))
                            lowY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "LM",
                    point: lowMidPoint,
                    color: Color.teal
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            lowMidX = clamp(newX, to: orderedRange(lowX + minXGap, midX - minXGap))
                            lowMidY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "M",
                    point: midPoint,
                    color: Color.green
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            midX = clamp(newX, to: orderedRange(lowMidX + minXGap, highMidX - minXGap))
                            midY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "HM",
                    point: highMidPoint,
                    color: Color.blue.opacity(0.85)
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            highMidX = clamp(newX, to: orderedRange(midX + minXGap, highX - minXGap))
                            highMidY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "H",
                    point: highPoint,
                    color: Color.blue
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            highX = clamp(newX, to: orderedRange(highMidX + minXGap, xRange.upperBound))
                            highY = clamp(newY, to: yRange)
                        }
                )

                axisLabel("Kbd gain", x: plot.minX + 4, y: plot.minY + 6, align: .topLeading)
                axisLabel("Mac volume", x: plot.maxX - 4, y: plot.maxY - 6, align: .bottomTrailing)
            }
        }
        .padding(.top, 2)
    }

    private func pointHandle(title: String, point: CGPoint, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.95), lineWidth: 1.6)
                }
            Text(title)
                .font(.system(size: 7, weight: .semibold, design: .rounded))
                .foregroundStyle(color.opacity(0.95))
                .offset(y: -13)
        }
        .position(point)
    }

    private func axisLabel(_ text: String, x: CGFloat, y: CGFloat, align: Alignment) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: align)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }

    private func point(x: Double, y: Double, in rect: CGRect) -> CGPoint {
        let tx = CGFloat((x - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound))
        let ty = CGFloat((y - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound))
        return CGPoint(
            x: rect.minX + tx * rect.width,
            y: rect.maxY - ty * rect.height
        )
    }

    private func valueX(from location: CGPoint, in rect: CGRect) -> Double {
        let normalized = (location.x - rect.minX) / max(1, rect.width)
        return xRange.lowerBound + Double(normalized) * (xRange.upperBound - xRange.lowerBound)
    }

    private func valueY(from location: CGPoint, in rect: CGRect) -> Double {
        let normalized = (rect.maxY - location.y) / max(1, rect.height)
        return yRange.lowerBound + Double(normalized) * (yRange.upperBound - yRange.lowerBound)
    }

    private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func orderedRange(_ a: Double, _ b: Double) -> ClosedRange<Double> {
        min(a, b) ... max(a, b)
    }
}

private struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.20) : Color.primary.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.primary.opacity(configuration.isPressed ? 0.36 : 0.42), lineWidth: 1)
            )
    }
}

private struct MinimalLiquidActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let isDark = colorScheme == .dark
        let foreground = isDark
            ? Color.white.opacity(configuration.isPressed ? 0.86 : 0.96)
            : Color(red: 0.18, green: 0.23, blue: 0.30).opacity(configuration.isPressed ? 0.88 : 0.98)
        let fill = isDark
            ? Color.white.opacity(configuration.isPressed ? 0.18 : 0.14)
            : Color.white.opacity(configuration.isPressed ? 0.36 : 0.28)
        let stroke = isDark
            ? Color.white.opacity(configuration.isPressed ? 0.55 : 0.46)
            : Color.white.opacity(configuration.isPressed ? 0.26 : 0.30)

        configuration.label
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(fill))
            .overlay {
                Capsule()
                    .strokeBorder(stroke.opacity(1.05), lineWidth: 1.1)
            }
            .shadow(color: isDark ? .black.opacity(0.26) : .clear, radius: isDark ? 2 : 0, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}
