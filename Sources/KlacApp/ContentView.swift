import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var service: KeyboardSoundService
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showAdvancedPopover = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Circle()
                    .fill(accentBlobColor)
                    .frame(width: 200, height: 200)
                    .blur(radius: 26)
                    .offset(x: 90, y: -100)
            }

            VStack(alignment: .leading, spacing: 12) {
                header
                permissionsCard
                quickSoundCard
                footer
            }
            .padding(14)
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

    private var header: some View {
        HStack {
            Text("Klac")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                showAdvancedPopover.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            .popover(isPresented: $showAdvancedPopover, arrowEdge: .top) {
                AdvancedSettingsView(service: service)
            }

            Toggle("Вкл", isOn: $service.isEnabled)
                .toggleStyle(.switch)
                .tint(.cyan)
                .foregroundStyle(.primary)
                .onChange(of: service.isEnabled) { enabled in
                    enabled ? service.start() : service.stop()
                }
        }
    }

    private var permissionsCard: some View {
        GlassCard(title: "Права доступа") {
            VStack(alignment: .leading, spacing: 8) {
                Text(service.capturingKeyboard ? "Перехват клавиш активен." : "Нужны Accessibility + Input Monitoring.")
                    .foregroundStyle(.primary)

                Text(service.capturingKeyboard
                     ? "Все разрешения выданы."
                     : "Если включено, но не работает: нажми восстановление и выдай доступы заново.")
                    .foregroundStyle(service.capturingKeyboard ? .green : .orange)
                    .font(.footnote)

                HStack {
                    Button("Проверить") {
                        service.refreshAccessibilityStatus(promptIfNeeded: true)
                    }
                    .buttonStyle(PrimaryGlassButtonStyle())

                    Button("Восстановить") {
                        service.runAccessRecoveryWizard()
                    }
                    .buttonStyle(PrimaryGlassButtonStyle())
                }

                if let hint = service.accessActionHint {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickSoundCard: some View {
        GlassCard(title: "Свитчи") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Профиль", selection: $service.selectedProfile) {
                    ForEach(SoundProfile.allCases) { profile in
                        Text(profile.title).tag(profile)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                Button("Тест звука") {
                    service.playTestSound()
                }
                .buttonStyle(PrimaryGlassButtonStyle())
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Работает в фоне.")
                .foregroundStyle(.secondary)
                .font(.footnote)
            Spacer()
            Button("Выход") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(PrimaryGlassButtonStyle())
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
                        Toggle("Адаптация к скорости печати", isOn: $service.typingAdaptiveEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        sliderRow(title: "Сила адаптации", value: $service.typingAdaptiveStrength, range: 0.0 ... 1.5)
                            .opacity(service.typingAdaptiveEnabled ? 1.0 : 0.45)
                        Toggle("Лимитер пиков", isOn: $service.limiterEnabled)
                            .tint(.cyan)
                            .foregroundStyle(.primary)
                        sliderRow(title: "Драйв лимитера", value: $service.limiterDrive, range: 0.6 ... 2.0)
                            .opacity(service.limiterEnabled ? 1.0 : 0.45)
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
