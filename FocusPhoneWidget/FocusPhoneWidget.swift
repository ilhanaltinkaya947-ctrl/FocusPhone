import WidgetKit
import SwiftUI

struct FocusPhoneWidgetEntry: TimelineEntry {
    let date: Date
    let mode: String
}

struct FocusPhoneWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusPhoneWidgetEntry {
        FocusPhoneWidgetEntry(date: .now, mode: "Detox")
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusPhoneWidgetEntry) -> Void) {
        let mode = AppState.shared.currentMode == .detox ? "Detox" : "Freedom"
        completion(FocusPhoneWidgetEntry(date: .now, mode: mode))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusPhoneWidgetEntry>) -> Void) {
        let mode = AppState.shared.currentMode == .detox ? "Detox" : "Freedom"
        let entry = FocusPhoneWidgetEntry(date: .now, mode: mode)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct FocusPhoneWidgetEntryView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("FocusPhone")
                .font(.caption2)
                .fontWeight(.semibold)
            Text(entry.mode)
                .font(.headline)
                .foregroundColor(entry.mode == "Detox" ? .red : .green)
        }
        .padding()
    }
}

@main
struct FocusPhoneWidget: Widget {
    let kind = "FocusPhoneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusPhoneWidgetProvider()) { entry in
            FocusPhoneWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusPhone")
        .description("See your current mode at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
