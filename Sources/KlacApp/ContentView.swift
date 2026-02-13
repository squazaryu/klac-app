import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var service: KeyboardSoundService
    @State private var showAdvanced = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.16, blue: 0.26),
                    Color(red: 0.07, green: 0.11, blue: 0.19),
                    Color(red: 0.06, green: 0.08, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .blur(radius: 30)
                    .offset(x: 110, y: -120)
            }

            VStack(alignment: .leading, spacing: 14) {
                header
                permissionsCard
                soundCard
                systemCard
                footer
            }
            .padding(16)
        }
        .sheet(isPresented: $showAdvanced) {
            AdvancedSettingsView(service: service)
        }
        .onAppear {
            service.start()
        }
    }

    private var header: some View {
        HStack {
            Text("Klac")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Toggle("Включено", isOn: $service.isEnabled)
                .toggleStyle(.switch)
                .tint(.cyan)
                .foregroundStyle(.white)
                .onChange(of: service.isEnabled) { enabled in
                    enabled ? service.start() : service.stop()
                }
        }
    }

    private var permissionsCard: some View {
        GlassCard(title: "Права доступа") {
            VStack(alignment: .leading, spacing: 8) {
                Text(service.accessibilityGranted
                     ? "Доступ к Accessibility выдан."
                     : "Нужно разрешение Accessibility для глобального перехвата клавиш.")
                    .foregroundStyle(.white)

                Text(service.capturingKeyboard
                     ? "Перехват клавиш активен."
                     : "Перехват клавиш не активен. Добавьте приложение в Input Monitoring.")
                    .foregroundStyle(service.capturingKeyboard ? .green : .orange)
                    .font(.footnote)

                HStack {
                    Button("Проверить доступ") {
                        service.refreshAccessibilityStatus(promptIfNeeded: true)
                    }
                    if !service.accessibilityGranted {
                        Button("Открыть настройки") {
                            service.openAccessibilitySettings()
                        }
                    }
                }
            }
        }
    }

    private var soundCard: some View {
        GlassCard(title: "Звук") {
            VStack(alignment: .leading, spacing: 11) {
                Picker("Профиль", selection: $service.selectedProfile) {
                    ForEach(SoundProfile.allCases) { profile in
                        Text(profile.title).tag(profile)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)

                sliderRow(title: "Громкость", value: $service.volume)
                sliderRow(title: "Вариативность", value: $service.variation)
                sliderRow(title: "Нажатие", value: $service.pressLevel, range: 0.2 ... 1.6)
                sliderRow(title: "Отпускание", value: $service.releaseLevel, range: 0.1 ... 1.4)
                sliderRow(title: "Space/Enter", value: $service.spaceLevel, range: 0.5 ... 1.8)

                Toggle("Звук отпускания клавиши", isOn: $service.playKeyUp)
                    .tint(.cyan)
                    .foregroundStyle(.white)

                Button("Тест звука") {
                    service.playTestSound()
                }
            }
        }
    }

    private var systemCard: some View {
        GlassCard(title: "Система") {
            Toggle("Автозапуск при входе в систему", isOn: $service.launchAtLogin)
                .tint(.cyan)
                .foregroundStyle(.white)
        }
    }

    private var footer: some View {
        HStack {
            Text("Работает в фоне.")
                .foregroundStyle(.white.opacity(0.75))
                .font(.footnote)
            Spacer()
            Button("Дополнительно") {
                showAdvanced = true
            }
            Button("Выход") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double> = 0.0 ... 1.0) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
                .frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
                .tint(.cyan)
            Text("\(Int(value.wrappedValue * 100))%")
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 48, alignment: .trailing)
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
                .foregroundStyle(.white.opacity(0.92))
            content
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct AdvancedSettingsView: View {
    @ObservedObject var service: KeyboardSoundService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Дополнительные настройки")
                .font(.title3.bold())

            Text("Импорт и экспорт профилей вынесен сюда, чтобы не перегружать основную страницу.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Экспорт профиля") {
                    service.exportSettings()
                }
                Button("Импорт профиля") {
                    service.importSettings()
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
        .padding(20)
        .frame(width: 430, height: 220)
    }
}
