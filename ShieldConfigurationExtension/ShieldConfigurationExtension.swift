import ManagedSettingsUI
import ManagedSettings
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

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

        let modeName: String
        let modeColorHex: String
        let modeIcon: String

        if let activeMode = appState.activeMode {
            modeName = activeMode.name
            modeColorHex = activeMode.colorHex
            modeIcon = activeMode.icon
        } else {
            modeName = "Focus"
            modeColorHex = "#007AFF"
            modeIcon = "lock.fill"
        }

        let modeColor = UIColor(hex: modeColorHex)
        let subtitle = buildSubtitle(modeName: modeName, blockedItemLabel: blockedItemLabel, appState: appState)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: modeColor.withAlphaComponent(0.15),
            icon: UIImage(systemName: modeIcon)?
                .withTintColor(modeColor, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(
                text: modeName,
                color: modeColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: modeColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Open FocusPhone",
                color: modeColor
            )
        )
    }

    // MARK: - Subtitle Builder

    private func buildSubtitle(modeName: String, blockedItemLabel: String, appState: AppState) -> String {
        var parts: [String] = []

        // What's blocked
        parts.append(blockedItemLabel)

        // Time remaining
        if let endTime = appState.activeBlockEndTime {
            let remaining = Int(endTime.timeIntervalSince(Date()) / 60)
            if remaining > 0 {
                if remaining < 60 {
                    parts.append("Back in \(remaining) min")
                } else {
                    let hours = remaining / 60
                    let mins = remaining % 60
                    if mins == 0 {
                        parts.append("Back in \(hours)h")
                    } else {
                        parts.append("Back in \(hours)h \(mins)m")
                    }
                }
            }
        }

        // Motivational nudge
        parts.append(motivationalMessage(for: modeName))

        return parts.joined(separator: "\n")
    }

    private func motivationalMessage(for modeName: String) -> String {
        let name = modeName.lowercased()

        if name.contains("deep work") || name.contains("work") || name.contains("study") {
            return "Deep focus builds great things."
        } else if name.contains("morning") || name.contains("routine") {
            return "Win the morning, win the day."
        } else if name.contains("exercise") || name.contains("gym") || name.contains("workout") {
            return "Your body will thank you."
        } else if name.contains("sleep") || name.contains("bedtime") {
            return "Rest well. Tomorrow starts fresh."
        } else if name.contains("wind down") || name.contains("evening") {
            return "Let your mind slow down."
        } else if name.contains("commute") || name.contains("drive") {
            return "Eyes up, phone down."
        } else if name.contains("family") || name.contains("dinner") {
            return "Be present with the people who matter."
        } else if name.contains("read") || name.contains("learn") {
            return "Knowledge compounds. Keep going."
        } else {
            // Rotate through generic messages based on time
            let messages = [
                "Stay present. You chose this.",
                "Small disciplines lead to big results.",
                "You don't need this app right now.",
                "Your future self will thank you.",
            ]
            let index = Calendar.current.component(.minute, from: Date()) % messages.count
            return messages[index]
        }
    }
}
