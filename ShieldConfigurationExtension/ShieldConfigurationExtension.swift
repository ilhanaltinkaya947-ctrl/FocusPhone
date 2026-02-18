import ManagedSettingsUI
import ManagedSettings
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appState = AppState.shared
        let modeName: String
        let modeColorHex: String
        let modeIcon: String

        if let activeModeID = appState.activeModeID,
           let activeMode = appState.modes.first(where: { $0.id == activeModeID }) {
            modeName = activeMode.name
            modeColorHex = activeMode.colorHex
            modeIcon = activeMode.icon
        } else {
            modeName = "Focus"
            modeColorHex = "#007AFF"
            modeIcon = "lock.fill"
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor(hex: modeColorHex).withAlphaComponent(0.05),
            icon: UIImage(systemName: modeIcon),
            title: ShieldConfiguration.Label(text: "\(modeName) Mode Active", color: UIColor(hex: modeColorHex)),
            subtitle: ShieldConfiguration.Label(text: "This app is blocked right now. Stay focused!", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Go Back", color: .white),
            primaryButtonBackgroundColor: UIColor(hex: modeColorHex)
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let appState = AppState.shared
        let modeName: String
        let modeColorHex: String

        if let activeModeID = appState.activeModeID,
           let activeMode = appState.modes.first(where: { $0.id == activeModeID }) {
            modeName = activeMode.name
            modeColorHex = activeMode.colorHex
        } else {
            modeName = "Focus"
            modeColorHex = "#007AFF"
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor(hex: modeColorHex).withAlphaComponent(0.05),
            icon: UIImage(systemName: "globe"),
            title: ShieldConfiguration.Label(text: "\(modeName) Mode Active", color: UIColor(hex: modeColorHex)),
            subtitle: ShieldConfiguration.Label(text: "This website is blocked right now. Stay focused!", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Go Back", color: .white),
            primaryButtonBackgroundColor: UIColor(hex: modeColorHex)
        )
    }
}
