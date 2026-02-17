import SwiftUI
import FamilyControls

struct DashboardView: View {
    @ObservedObject var blockingVM: AppBlockingViewModel
    @StateObject private var scheduleVM = ScheduleViewModel()
    @State private var showingScheduleSetup = false
    @State private var showingAppPicker = false

    private var currentMode: AppMode {
        AppState.shared.currentMode
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mode Status Card
                    modeStatusCard

                    // App Selection
                    appSelectionSection

                    // Quick Actions
                    quickActionsSection

                    // Freedom Windows
                    freedomWindowsSection
                }
                .padding()
            }
            .navigationTitle("FocusPhone")
            .sheet(isPresented: $showingScheduleSetup) {
                ScheduleSetupView(viewModel: scheduleVM)
            }
            .familyActivityPicker(
                isPresented: $showingAppPicker,
                selection: $blockingVM.activitySelection
            )
            .onChange(of: blockingVM.activitySelection) { _ in
                blockingVM.saveSelection()
            }
        }
    }

    private var modeStatusCard: some View {
        VStack(spacing: 12) {
            Text(currentMode == .detox ? "Detox Mode" : "Freedom Mode")
                .font(.title2)
                .fontWeight(.bold)

            Text(currentMode == .detox
                 ? "Apps are blocked. Stay focused."
                 : "Enjoy your freedom window!")
                .foregroundStyle(.secondary)

            Circle()
                .fill(currentMode == .detox ? Color.red : Color.green)
                .frame(width: 16, height: 16)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blocked Apps")
                .font(.headline)

            Button {
                showingAppPicker = true
            } label: {
                HStack {
                    Text("Select Apps & Categories")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    blockingVM.activateDetoxMode()
                } label: {
                    Text("Start Detox")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    blockingVM.deactivateDetoxMode()
                } label: {
                    Text("Stop Detox")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var freedomWindowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Freedom Windows")
                    .font(.headline)
                Spacer()
                Button {
                    showingScheduleSetup = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            if scheduleVM.freedomWindows.isEmpty {
                Text("No freedom windows scheduled.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(scheduleVM.freedomWindows) { window in
                    freedomWindowRow(window)
                }
            }
        }
    }

    private func freedomWindowRow(_ window: FreedomWindow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(window.label)
                    .fontWeight(.medium)
                Text("\(window.startTimeString) – \(window.endTimeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(window.days.sorted().map(\.shortName).joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(window.isEnabled ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
