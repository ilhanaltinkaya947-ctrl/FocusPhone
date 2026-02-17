import ManagedSettingsUI
import ManagedSettings
import UIKit

// Stub for Phase 3 — will customize the shield appearance
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            title: ShieldConfiguration.Label(text: "App Blocked", color: .label),
            subtitle: ShieldConfiguration.Label(text: "This app is blocked during Detox Mode.", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .white),
            primaryButtonBackgroundColor: .systemBlue
        )
    }
}
