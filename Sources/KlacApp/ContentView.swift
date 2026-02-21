import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var service: KeyboardSoundService
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showAdvancedPopover = false
    @State private var showAccessHintPopover = false
    private let panelWidth: CGFloat = 282

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                ZStack {
                    Circle()
                        .fill(accentBlobColor)
                        .frame(width: 220, height: 220)
                        .blur(radius: 28)
                        .offset(x: 96, y: -118)
                    Circle()
                        .fill(secondaryBlobColor)
                        .frame(width: 160, height: 160)
                        .blur(radius: 24)
                        .offset(x: -84, y: 108)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                header
                compactMainCard
                quickActions
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 0)
            .frame(width: panelWidth, alignment: .leading)
        }
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

    private var isDarkTheme: Bool {
        switch service.appearanceMode {
        case .system: return systemColorScheme == .dark
        case .light: return false
        case .dark: return true
        }
    }

    private var backgroundGradient: [Color] {
        if isDarkTheme {
            return [
                Color(red: 0.10, green: 0.16, blue: 0.26),
                Color(red: 0.07, green: 0.11, blue: 0.19),
                Color(red: 0.06, green: 0.08, blue: 0.14)
            ]
        }
        return [
            Color(red: 0.92, green: 0.95, blue: 0.99),
            Color(red: 0.87, green: 0.92, blue: 0.98),
            Color(red: 0.82, green: 0.89, blue: 0.97)
        ]
    }

    private var accentBlobColor: Color {
        isDarkTheme ? Color.cyan.opacity(0.18) : Color.blue.opacity(0.16)
    }

    private var secondaryBlobColor: Color {
        isDarkTheme ? Color.mint.opacity(0.14) : Color.white.opacity(0.42)
    }

    private var captureStatusTitle: String {
        service.capturingKeyboard ? "Активно" : "Нет доступа"
    }

    private var captureStatusDetail: String {
        service.capturingKeyboard ? "Глобальный перехват клавиш включён" : "Нужны Accessibility + Input Monitoring"
    }

    private var appVersionCaption: String {
        let releaseFallbackVersion = "1.5.0"
        let short = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let version = (short?.isEmpty == false) ? short! : releaseFallbackVersion
        let buildPart = (build?.isEmpty == false) ? "b\(build!)" : "bdev"
        return "v\(version) (\(buildPart))"
    }

    private var header: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Klac")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Text(appVersionCaption)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    showAdvancedPopover.toggle()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .popover(isPresented: $showAdvancedPopover, arrowEdge: .top) {
                    AdvancedSettingsView(service: service)
                }

                Toggle("", isOn: $service.isEnabled)
                    .toggleStyle(.switch)
                    .tint(.cyan)
                    .foregroundStyle(primaryTextColor)
                    .onChange(of: service.isEnabled) { enabled in
                        enabled ? service.start() : service.stop()
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactMainCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(captureStatusTitle)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(service.capturingKeyboard ? .green : .orange)
                Spacer()
                Button {
                    showAccessHintPopover.toggle()
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .frame(width: 34, height: 28)
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

            HStack(spacing: 6) {
                statusPill(title: "AX", enabled: service.accessibilityGranted)
                statusPill(title: "Input", enabled: service.inputMonitoringGranted)
                statusPill(title: "Tap", enabled: service.capturingKeyboard)
            }

            VStack(alignment: .leading, spacing: 6) {
                Picker("Профиль", selection: $service.selectedProfile) {
                    ForEach(SoundProfile.allCases) { profile in
                        Text(profile.title).tag(profile)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(isDarkTheme ? 0.14 : 0.28), lineWidth: 1)
        }
    }

    private var quickActions: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Button("Проверить") { service.refreshAccessibilityStatus(promptIfNeeded: true) }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .frame(width: 106)
            Button("Восст.") { service.runAccessRecoveryWizard() }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .frame(width: 96)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .help("Выход")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryTextColor: Color {
        isDarkTheme ? .white.opacity(0.96) : Color(red: 0.17, green: 0.21, blue: 0.27)
    }

    private var secondaryTextColor: Color {
        isDarkTheme ? .white.opacity(0.72) : Color(red: 0.34, green: 0.40, blue: 0.50)
    }

    private func statusPill(title: String, enabled: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(enabled ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder((enabled ? Color.green : Color.orange).opacity(0.35), lineWidth: 1)
            }
    }
}

private struct GlassCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct AdvancedSettingsView: View {
    @ObservedObject var service: KeyboardSoundService
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

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
                        sliderRow(title: "Нажатие", value: $service.pressLevel, range: 0.2 ... 1.6)
                        sliderRow(title: "Отпускание", value: $service.releaseLevel, range: 0.1 ... 1.4)
                        sliderRow(title: "Space/Enter", value: $service.spaceLevel, range: 0.5 ... 1.8)
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
                            Button("Импорт Sound Pack") { service.importSoundPack() }
                                .buttonStyle(PrimaryGlassButtonStyle())
                            Text("Профиль: Custom Pack")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if let status = service.soundPackStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                GlassCard(title: "Устройство вывода") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(service.currentOutputDeviceName)
                            .foregroundStyle(.primary)
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
                    Button("Закрыть") { dismiss() }
                        .buttonStyle(PrimaryGlassButtonStyle())
                }
            }
            .padding(16)
        }
        .frame(width: 520, height: 560)
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

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double> = 0.0 ... 1.0) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.cyan)
            Text("\(Int(value.wrappedValue * 100))%")
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 52, alignment: .trailing)
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

private struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.18) : Color.primary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(configuration.isPressed ? 0.30 : 0.38), lineWidth: 1)
            )
    }
}

private struct MinimalLiquidActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.18, green: 0.23, blue: 0.30).opacity(configuration.isPressed ? 0.88 : 0.98))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.18 : 0.30), lineWidth: 0.9)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}
