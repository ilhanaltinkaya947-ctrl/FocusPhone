import ManagedSettingsUI
import ManagedSettings
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // RawDog accent color (ice blue)
    private let accentColor = UIColor(red: 232/255, green: 244/255, blue: 255/255, alpha: 1.0)
    private let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)

    // MARK: - App Shielding

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(
            blockedItemIcon: "xmark.app.fill",
            blockedItemLabel: "This app is blocked"
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    // MARK: - Web Domain Shielding

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(
            blockedItemIcon: "globe.badge.chevron.backward",
            blockedItemLabel: "This website is blocked"
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }

    // MARK: - Shared Configuration Builder

    private func makeConfiguration(blockedItemIcon: String, blockedItemLabel: String) -> ShieldConfiguration {
        let appState = AppState.shared
        let profile = appState.restrictionProfile

        let subtitle = buildSubtitle(
            blockedItemLabel: blockedItemLabel,
            windowStates: appState.timedWindowStates,
            profile: profile
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: bgColor,
            icon: UIImage(systemName: "lock.fill")?
                .withTintColor(accentColor, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(
                text: "RawDog says not yet.",
                color: accentColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .black
            ),
            primaryButtonBackgroundColor: accentColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Extension",
                color: accentColor
            )
        )
    }

    // MARK: - Subtitle Builder

    private func buildSubtitle(
        blockedItemLabel: String,
        windowStates: [TimedWindowApp],
        profile: PersonalRestrictionProfile?
    ) -> String {
        var parts: [String] = []
        parts.append(blockedItemLabel)

        if !windowStates.isEmpty {
            let openApps = windowStates.filter { $0.isCurrentlyInWindow }
            if openApps.isEmpty {
                parts.append("Check the dashboard for window times.")
            }
        }

        parts.append(motivationalMessage())

        return parts.joined(separator: "\n")
    }

    private func motivationalMessage() -> String {
        let messages = [
            "Stay present. You chose this.",
            "Small disciplines lead to big results.",
            "You don't need this app right now.",
            "Your future self will thank you.",
            "Be intentional with your time.",
            "This restriction is helping you grow.",
        ]
        let index = Calendar.current.component(.minute, from: Date()) % messages.count
        return messages[index]
    }
}
