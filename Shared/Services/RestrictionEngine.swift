import Foundation

enum RestrictionEngine {

    // MARK: - Profile Activation

    /// Activates a restriction profile: registers timed windows, applies permanent blocks.
    static func activateProfile(_ profile: PersonalRestrictionProfile) {
        let appState = AppState.shared

        // Save profile
        appState.restrictionProfile = profile
        appState.isRestrictionActive = true

        // Sync timed window states
        appState.timedWindowStates = profile.timedWindowApps

        // Sync content filter presets
        appState.enabledContentFilterPresets = Set(profile.activePresetIDs)

        // Generate and register timed window DeviceActivity schedules
        let slots = TimedWindowService.generateAllSlots(for: profile)
        ScheduleService.registerTimedWindows(slots: slots)

        // Apply permanent blocks
        BlockingService.applyPermanentBlocks(from: profile)
    }

    /// Deactivates all restrictions.
    static func deactivateAll() {
        let appState = AppState.shared
        appState.isRestrictionActive = false
        appState.timedWindowStates = []
        ScheduleService.stopAllSchedules()
        BlockingService.clearAllBlocks()
    }

    /// Re-applies the active profile (e.g., on app launch or scene activation).
    static func reapplyActiveProfile() {
        guard let profile = AppState.shared.restrictionProfile,
              AppState.shared.isRestrictionActive else { return }
        BlockingService.applyPermanentBlocks(from: profile)
    }

    // MARK: - Window Events (called by DeviceActivityMonitor extension)

    /// Called when a timed window opens — unblocks the app temporarily.
    static func onWindowOpen(appID: UUID) {
        AppState.shared.updateTimedWindowState(appID: appID, isInWindow: true, windowStart: Date())
        AppState.shared.incrementTimedWindowsOpened()

        // Find the app token and unblock
        if let app = AppState.shared.timedWindowStates.first(where: { $0.id == appID }),
           let token = app.appToken {
            BlockingService.unblockApp(token: token)
        }
    }

    /// Called when a timed window closes — re-blocks the app.
    static func onWindowClose(appID: UUID) {
        AppState.shared.updateTimedWindowState(appID: appID, isInWindow: false, windowEnd: Date())

        // Find the app token and re-block
        if let app = AppState.shared.timedWindowStates.first(where: { $0.id == appID }),
           let token = app.appToken {
            BlockingService.reblockApp(token: token)
        }
    }

    /// Grants a temporary extension for an app.
    static func grantExtension(appID: UUID, minutes: Int) {
        if let app = AppState.shared.timedWindowStates.first(where: { $0.id == appID }),
           let token = app.appToken {
            BlockingService.unblockApp(token: token)

            // Schedule re-block after extension expires
            let extensionEnd = Date().addingTimeInterval(TimeInterval(minutes * 60))
            AppState.shared.updateTimedWindowState(appID: appID, isInWindow: true, windowStart: Date())

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes * 60)) {
                BlockingService.reblockApp(token: token)
                AppState.shared.updateTimedWindowState(appID: appID, isInWindow: false, windowEnd: extensionEnd)
            }
        }
    }
}
