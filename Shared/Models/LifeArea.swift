import Foundation

enum LifeArea: String, Codable, CaseIterable, Identifiable {
    case body
    case mind
    case career
    case creativity
    case relationships
    case peace

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .body: return "figure.run"
        case .mind: return "brain.head.profile"
        case .career: return "briefcase.fill"
        case .creativity: return "paintbrush.fill"
        case .relationships: return "person.2.fill"
        case .peace: return "leaf.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .body: return "#A0B8D0"
        case .mind: return "#A8C5A0"
        case .career: return "#E8DCC8"
        case .creativity: return "#C4B5D4"
        case .relationships: return "#E8B8B8"
        case .peace: return "#8EBAB8"
        }
    }

    var description: String {
        switch self {
        case .body: return "Fitness & health"
        case .mind: return "Learning & growth"
        case .career: return "Work & ambition"
        case .creativity: return "Art & expression"
        case .relationships: return "People & connection"
        case .peace: return "Calm & mindfulness"
        }
    }

    var displayName: String {
        switch self {
        case .body: return "Body"
        case .mind: return "Mind"
        case .career: return "Career"
        case .creativity: return "Creativity"
        case .relationships: return "Relationships"
        case .peace: return "Peace"
        }
    }
}
