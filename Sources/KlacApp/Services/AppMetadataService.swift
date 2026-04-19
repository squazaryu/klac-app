import Foundation

protocol AppMetadataProviding {
    func currentAppVersion() -> String
    func currentAppBuildNumber() -> Int
    func resolveBundleIdentifier() -> String?
}

struct SystemAppMetadataProvider: AppMetadataProviding {
    func currentAppVersion() -> String {
        AppMetadataService.currentAppVersion()
    }

    func currentAppBuildNumber() -> Int {
        AppMetadataService.currentAppBuildNumber()
    }

    func resolveBundleIdentifier() -> String? {
        AppMetadataService.resolveBundleIdentifier()
    }
}

enum AppMetadataService {
    static func currentAppVersion(bundle: Bundle = .main) -> String {
        if let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !short.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return short
        }
        return "0.0.0"
    }

    static func currentAppBuildNumber(bundle: Bundle = .main) -> Int {
        if let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return Int(build.filter(\.isNumber)) ?? 0
        }
        return 0
    }

    static func resolveBundleIdentifier(bundle: Bundle = .main) -> String? {
        if let id = bundle.bundleIdentifier, !id.isEmpty {
            return id
        }
        if let id = bundle.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String,
           !id.isEmpty {
            return id
        }
        if let appURL = resolveAppBundleURL(bundle: bundle),
           let appBundle = Bundle(url: appURL),
           let id = appBundle.bundleIdentifier,
           !id.isEmpty {
            return id
        }
        return "com.klacapp.klac"
    }

    static func resolveAppBundleURL(bundle: Bundle = .main) -> URL? {
        let mainURL = bundle.bundleURL
        if mainURL.pathExtension == "app" {
            return mainURL
        }

        if let executableURL = bundle.executableURL {
            var cursor = executableURL
            for _ in 0 ..< 6 {
                let parent = cursor.deletingLastPathComponent()
                if parent.pathExtension == "app" {
                    return parent
                }
                if parent.path == cursor.path { break }
                cursor = parent
            }
        }

        return nil
    }
}
