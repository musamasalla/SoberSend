import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isLocked: false, start: "22:00", end: "07:00")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), isLocked: true, start: "22:00", end: "07:00")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
        let startHour = sharedDefaults?.integer(forKey: "lockStartHour") ?? 22
        let startMinute = sharedDefaults?.integer(forKey: "lockStartMinute") ?? 0
        let endHour = sharedDefaults?.integer(forKey: "lockEndHour") ?? 7
        let endMinute = sharedDefaults?.integer(forKey: "lockEndMinute") ?? 0
        
        // Evaluate locked state
        let now = Date()
        let calendar = Calendar.current
        
        let startHStr = String(format: "%02d", startHour)
        let startMStr = String(format: "%02d", startMinute)
        let endHStr = String(format: "%02d", endHour)
        let endMStr = String(format: "%02d", endMinute)
        
        let startTimeString = "\(startHStr):\(startMStr)"
        let endTimeString = "\(endHStr):\(endMStr)"
        
        var isLocked = false
        if let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
           let endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) {
            
            if startToday > endToday {
                // Crosses midnight
                if now >= startToday || now <= endToday {
                    isLocked = true
                }
            } else {
                if now >= startToday && now <= endToday {
                    isLocked = true
                }
            }
        }
        
        let entry = SimpleEntry(date: now, isLocked: isLocked, start: startTimeString, end: endTimeString)
        
        // Update the widget every hour to check status
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isLocked: Bool
    let start: String
    let end: String
}

struct SoberSendWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 8) {
                Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(entry.isLocked ? .red : .green)
                
                Text(entry.isLocked ? "LOCKED" : "UNLOCKED")
                    .font(.footnote)
                    .bold()
                    .foregroundColor(.white)
                
                Text("\(entry.start) - \(entry.end)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SoberSendWidget: Widget {
    let kind: String = "SoberSendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SoberSendWidgetEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("SoberSend Status")
        .description("Shows your current lockdown status.")
        .supportedFamilies([.systemSmall])
    }
}
