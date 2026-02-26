import WidgetKit
import SwiftUI

// NOTE: To use this widget, you must create a new Widget Extension target in Xcode:
// File -> New -> Target -> Widget Extension.
// Name it "SoberSendWidget" and ensure this file is included in that target.
// You will also need to set up an App Group (e.g., group.com.yourcompany.SoberSend)
// to share UserDefaults between the main app and the widget extension.

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isLocked: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), isLocked: checkLockStatus())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, isLocked: checkLockStatus())
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func checkLockStatus() -> Bool {
        // In a real implementation using App Groups, we would read the shared UserDefaults here.
        // For example:
        // let defaults = UserDefaults(suiteName: "group.com.yourcompany.SoberSend")
        // let startHour = defaults?.integer(forKey: "lockStartHour") ?? 22
        // ... evaluate time ...
        return false // Defaulting to false for template
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isLocked: Bool
}

struct SoberSendWidgetEntryView : View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.isLocked ? "lock.shield.fill" : "lock.shield")
                    .font(.title)
                    .widgetAccentable()
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: entry.isLocked ? "lock.shield.fill" : "lock.shield")
                    Text("SoberSend")
                        .font(.headline)
                }
                Text(entry.isLocked ? "Lockdown Active" : "Unrestricted")
                    .font(.caption)
            }
        default:
            VStack {
                Image(systemName: entry.isLocked ? "lock.shield.fill" : "lock.shield")
                    .font(.largeTitle)
                    .foregroundColor(entry.isLocked ? .red : .green)
                Text(entry.isLocked ? "Locked" : "Unlocked")
                    .font(.headline)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct SoberSendWidget: Widget {
    let kind: String = "SoberSendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SoberSendWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lock Status")
        .description("See if SoberSend lockdown is currently active.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    SoberSendWidget()
} timeline: {
    SimpleEntry(date: .now, isLocked: true)
    SimpleEntry(date: .now, isLocked: false)
}
