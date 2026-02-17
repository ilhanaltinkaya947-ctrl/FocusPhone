import Foundation
import ManagedSettings

enum DetoxProfile: String, Codable, CaseIterable, Identifiable {
    case fullDetox
    case socialDetox
    case focusMode
    case minimal
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullDetox: return "Full Detox"
        case .socialDetox: return "Social Detox"
        case .focusMode: return "Focus Mode"
        case .minimal: return "Minimal"
        case .custom: return "Custom"
        }
    }

    var description: String {
        switch self {
        case .fullDetox: return "Block all non-essential apps"
        case .socialDetox: return "Block social media only"
        case .focusMode: return "Block entertainment and social media"
        case .minimal: return "Block only the most distracting apps"
        case .custom: return "Choose which apps to block"
        }
    }

    var blockedCategories: Set<ActivityCategoryToken> {
        // ActivityCategoryToken is opaque — actual categories are selected
        // via FamilyActivitySelection picker in the main app.
        // This property is a placeholder; real blocking uses the user's selection.
        return []
    }
}
