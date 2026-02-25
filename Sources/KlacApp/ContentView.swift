import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var service: KeyboardSoundService
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showAdvancedPopover = false
    @State private var showAccessHintPopover = false
    private let panelWidth: CGFloat = 266

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

            VStack(alignment: .leading, spacing: 2) {
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
        let releaseFallbackVersion = "1.7.0"
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
        VStack(alignment: .leading, spacing: 3) {
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

            HStack(spacing: 5) {
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
        .padding(6)
        .background(.thinMaterial.opacity(isDarkTheme ? 0.55 : 0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(isDarkTheme ? 0.22 : 0.30), lineWidth: 1)
        }
    }

    private var quickActions: some View {
        HStack(alignment: .bottom, spacing: 5) {
            Button("Проверить") { service.refreshAccessibilityStatus(promptIfNeeded: true) }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .frame(width: 98)
            Button("Восст.") { service.runAccessRecoveryWizard() }
                .buttonStyle(MinimalLiquidActionButtonStyle())
                .frame(width: 84)
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
                        sliderRow(title: "Space/Enter", value: $service.spaceLevel, range: 0.2 ... 1.8)
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
                            sliderRow(title: "Цель @100%", value: $service.autoNormalizeTargetAt100, range: 0.20 ... 1.20)
                            let p30 = Int((service.autoInverseGainPreview(systemVolumePercent: 30) * 100).rounded())
                            let p60 = Int((service.autoInverseGainPreview(systemVolumePercent: 60) * 100).rounded())
                            let p100 = Int((service.autoInverseGainPreview(systemVolumePercent: 100) * 100).rounded())
                            Text("Текущий gain: x\(String(format: "%.2f", service.liveDynamicGain))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("Авто-кривая: Mac 30% → Kbd \(p30)% · 60% → \(p60)% · 100% → \(p100)%")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            LevelCurveEditor(
                                lowX: $service.levelMacLow,
                                lowY: $service.levelKbdLow,
                                midX: $service.levelMacMid,
                                midY: $service.levelKbdMid,
                                highX: $service.levelMacHigh,
                                highY: $service.levelKbdHigh
                            )
                            .frame(height: 208)
                            Text("Ручной режим: 3 точки кривой (как fan curve).")
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

private struct LevelCurveEditor: View {
    @Binding var lowX: Double
    @Binding var lowY: Double
    @Binding var midX: Double
    @Binding var midY: Double
    @Binding var highX: Double
    @Binding var highY: Double

    private let xRange: ClosedRange<Double> = 0.05 ... 1.0
    private let yRange: ClosedRange<Double> = 0.20 ... 4.0
    private let minXGap: Double = 0.03

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let plotInsets = EdgeInsets(top: 12, leading: 34, bottom: 24, trailing: 12)
            let plot = CGRect(
                x: plotInsets.leading,
                y: plotInsets.top,
                width: max(20, width - plotInsets.leading - plotInsets.trailing),
                height: max(20, height - plotInsets.top - plotInsets.bottom)
            )

            let lowPoint = point(x: lowX, y: lowY, in: plot)
            let midPoint = point(x: midX, y: midY, in: plot)
            let highPoint = point(x: highX, y: highY, in: plot)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))

                Path { path in
                    for t in stride(from: 0.0, through: 1.0, by: 0.25) {
                        let y = plot.maxY - CGFloat(t) * plot.height
                        path.move(to: CGPoint(x: plot.minX, y: y))
                        path.addLine(to: CGPoint(x: plot.maxX, y: y))
                    }
                    for t in stride(from: 0.0, through: 1.0, by: 0.25) {
                        let x = plot.minX + CGFloat(t) * plot.width
                        path.move(to: CGPoint(x: x, y: plot.minY))
                        path.addLine(to: CGPoint(x: x, y: plot.maxY))
                    }
                }
                .stroke(Color.primary.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                Path { path in
                    path.move(to: lowPoint)
                    path.addLine(to: midPoint)
                    path.addLine(to: highPoint)
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.95), Color.mint.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )

                pointHandle(
                    title: "L",
                    point: lowPoint,
                    color: Color.cyan,
                    macPercent: Int((lowX * 100).rounded()),
                    kbdPercent: Int((lowY * 100).rounded())
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            lowX = clamp(newX, to: xRange.lowerBound ... (midX - minXGap))
                            lowY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "M",
                    point: midPoint,
                    color: Color.green,
                    macPercent: Int((midX * 100).rounded()),
                    kbdPercent: Int((midY * 100).rounded())
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            midX = clamp(newX, to: (lowX + minXGap) ... (highX - minXGap))
                            midY = clamp(newY, to: yRange)
                        }
                )

                pointHandle(
                    title: "H",
                    point: highPoint,
                    color: Color.blue,
                    macPercent: Int((highX * 100).rounded()),
                    kbdPercent: Int((highY * 100).rounded())
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let newX = valueX(from: drag.location, in: plot)
                            let newY = valueY(from: drag.location, in: plot)
                            highX = clamp(newX, to: (midX + minXGap) ... xRange.upperBound)
                            highY = clamp(newY, to: yRange)
                        }
                )

                axisLabel("Kbd %", x: 8, y: plot.minY - 2, align: .leading)
                axisLabel("Mac %", x: plot.maxX - 2, y: plot.maxY + 8, align: .trailing)
                axisLabel("20", x: 8, y: plot.maxY - 8, align: .leading)
                axisLabel("400", x: 8, y: plot.minY - 8, align: .leading)
                axisLabel("5", x: plot.minX - 2, y: plot.maxY + 8, align: .center)
                axisLabel("100", x: plot.maxX, y: plot.maxY + 8, align: .center)
            }
        }
        .padding(.top, 2)
    }

    private func pointHandle(title: String, point: CGPoint, color: Color, macPercent: Int, kbdPercent: Int) -> some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(color.opacity(0.22))
                .frame(width: 22, height: 22)
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.95), lineWidth: 1.8)
                }
            Text("\(title) \(macPercent)/\(kbdPercent)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8)
                }
                .offset(y: -18)
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
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(fill))
            .overlay {
                Capsule()
                    .strokeBorder(stroke.opacity(1.05), lineWidth: 1.1)
            }
            .shadow(color: isDark ? .black.opacity(0.26) : .clear, radius: isDark ? 2 : 0, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}
