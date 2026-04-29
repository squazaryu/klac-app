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
    @EnvironmentObject private var viewModel: MenuBarViewModel
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
            viewModel.start()
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var captureStatusTitle: String {
        viewModel.capturingKeyboard ? "Активно" : "Нет доступа"
    }

    private var isEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isEnabled },
            set: { viewModel.setEnabled($0) }
        )
    }

    private var appVersionCaption: String {
        let releaseFallbackVersion = "2.1.6"
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
            Image(systemName: viewModel.capturingKeyboard ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(viewModel.capturingKeyboard ? Color.green : Color.orange)
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.isEnabled ? "Enable Klac" : "Disable Klac")
                    .font(.system(size: 15, weight: .semibold))
                Text(appVersionCaption)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isEnabledBinding)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(.accentColor)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            Text(captureStatusTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewModel.capturingKeyboard ? .green : .orange)
            Spacer()
            HStack(spacing: 6) {
                statusBadge("AX", ok: viewModel.accessibilityGranted)
                statusBadge("Input", ok: viewModel.inputMonitoringGranted)
                statusBadge("Tap", ok: viewModel.capturingKeyboard)
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
                    Text(viewModel.accessActionHint ?? "Нажми «Проверить». Если не помогло, нажми «Восстановить», выдай доступ и перезапусти приложение.")
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
                    Text(viewModel.selectedProfile.title)
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
                    viewModel.selectProfile(profile)
                    showSwitchesMenu = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.selectedProfile == profile ? "checkmark" : "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(viewModel.selectedProfile == profile ? Color.accentColor : Color.secondary)
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
                viewModel.checkForUpdates()
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
                viewModel.refreshAccess()
            } label: {
                menuRowLabel("Проверить доступы", icon: "checkmark.shield")
            }
            .buttonStyle(.plain)

            Button {
                viewModel.recoverAccess()
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
            viewModel: viewModel.makeAdvancedSettingsViewModel(),
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
