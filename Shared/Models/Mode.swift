import Foundation
import FamilyControls

struct Mode: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var icon: String              // SF Symbol name
    var colorHex: String          // e.g. "#4A90D9"
    var blockedCategories: Data?  // Encoded FamilyActivitySelection
    var blockAppStore: Bool
    var blockAppDeletion: Bool
    var isSystem: Bool
    var blockedWebsites: [String] // Domain list e.g. ["twitter.com", "reddit.com"]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        blockedCategories: Data? = nil,
        blockAppStore: Bool = true,
        blockAppDeletion: Bool = true,
        isSystem: Bool = false,
        blockedWebsites: [String] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.blockedCategories = blockedCategories
        self.blockAppStore = blockAppStore
        self.blockAppDeletion = blockAppDeletion
        self.isSystem = isSystem
        self.blockedWebsites = blockedWebsites
    }

    // Backward-compatible decoder: old persisted modes without blockedWebsites decode with []
    enum CodingKeys: String, CodingKey {
        case id, name, icon, colorHex, blockedCategories
        case blockAppStore, blockAppDeletion, isSystem, blockedWebsites
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        blockedCategories = try container.decodeIfPresent(Data.self, forKey: .blockedCategories)
        blockAppStore = try container.decode(Bool.self, forKey: .blockAppStore)
        blockAppDeletion = try container.decode(Bool.self, forKey: .blockAppDeletion)
        isSystem = try container.decode(Bool.self, forKey: .isSystem)
        blockedWebsites = try container.decodeIfPresent([String].self, forKey: .blockedWebsites) ?? []
    }

    var familyActivitySelection: FamilyActivitySelection? {
        guard let data = blockedCategories else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    mutating func setFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        blockedCategories = try? JSONEncoder().encode(selection)
    }
}
