import Foundation

enum AppMode: String, Codable {
    case detox
    case freedom
}

final class AppState {
    static let shared = AppState()

    private let defaults = Constants.sharedDefaults

    var currentMode: AppMode {
        get {
            guard let raw = defaults.string(forKey: Constants.currentModeKey) else {
                return .detox
            }
            return AppMode(rawValue: raw) ?? .detox
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.currentModeKey)
        }
    }

    var selectedProfile: DetoxProfile {
        get {
            guard let raw = defaults.string(forKey: Constants.selectedProfileKey) else {
                return .fullDetox
            }
            return DetoxProfile(rawValue: raw) ?? .fullDetox
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.selectedProfileKey)
        }
    }

    var freedomWindows: [FreedomWindow] {
        get {
            guard let data = defaults.data(forKey: Constants.freedomWindowsKey),
                  let windows = try? JSONDecoder().decode([FreedomWindow].self, from: data) else {
                return []
            }
            return windows
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Constants.freedomWindowsKey)
            }
        }
    }

    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Constants.onboardingCompletedKey) }
        set { defaults.set(newValue, forKey: Constants.onboardingCompletedKey) }
    }
}
