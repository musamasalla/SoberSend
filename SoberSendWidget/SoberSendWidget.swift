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
        let isManuallyActive = sharedDefaults?.bool(forKey: "isManuallyActive") ?? false
        
        let now = Date()
        let calendar = Calendar.current
        
        let startHStr = String(format: "%02d", startHour)
        let startMStr = String(format: "%02d", startMinute)
        let endHStr = String(format: "%02d", endHour)
        let endMStr = String(format: "%02d", endMinute)
        
        let startTimeString = "\(startHStr):\(startMStr)"
        let endTimeString = "\(endHStr):\(endMStr)"
        
        var isLocked = isManuallyActive
        if !isLocked, let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
           let endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) {
            if startToday > endToday {
                if now >= startToday || now <= endToday { isLocked = true }
            } else {
                if now >= startToday && now <= endToday { isLocked = true }
            }
        }
        
        let entry = SimpleEntry(date: now, isLocked: isLocked, start: startTimeString, end: endTimeString)
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

// MARK: - Adaptive Widget Colors (matches app theme, auto light/dark)
private enum WidgetTheme {
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    
    static let background = adaptive(
        light: UIColor(red: 0.92, green: 0.96, blue: 0.98, alpha: 1),
        dark:  UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
    )
    static let card = adaptive(light: .white, dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1))
    static let mintCard = adaptive(
        light: UIColor(red: 0.83, green: 0.96, blue: 0.91, alpha: 1),
        dark:  UIColor(red: 0.12, green: 0.24, blue: 0.18, alpha: 1)
    )
    static let mintText = adaptive(
        light: UIColor(red: 0.18, green: 0.55, blue: 0.38, alpha: 1),
        dark:  UIColor(red: 0.40, green: 0.80, blue: 0.58, alpha: 1)
    )
    static let peachCard = adaptive(
        light: UIColor(red: 1.00, green: 0.88, blue: 0.86, alpha: 1),
        dark:  UIColor(red: 0.30, green: 0.14, blue: 0.12, alpha: 1)
    )
    static let peachText = adaptive(
        light: UIColor(red: 0.70, green: 0.30, blue: 0.25, alpha: 1),
        dark:  UIColor(red: 0.92, green: 0.50, blue: 0.42, alpha: 1)
    )
    static let textPrimary = adaptive(
        light: UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
        dark:  UIColor(white: 0.95, alpha: 1)
    )
    static let textSecondary = adaptive(
        light: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1),
        dark:  UIColor(white: 0.55, alpha: 1)
    )
}

struct SoberSendWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(entry.isLocked ? WidgetTheme.mintCard : WidgetTheme.peachCard)
                    .frame(width: 44, height: 44)
                Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(entry.isLocked ? WidgetTheme.mintText : WidgetTheme.peachText)
            }
            
            Text(entry.isLocked ? "Protected" : "Unprotected")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTheme.textPrimary)
            
            Text("\(entry.start) – \(entry.end)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SoberSendWidget: Widget {
    let kind: String = "SoberSendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SoberSendWidgetEntryView(entry: entry)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("SoberSend Status")
        .description("Shows your current lockdown status.")
        .supportedFamilies([.systemSmall])
    }
}
