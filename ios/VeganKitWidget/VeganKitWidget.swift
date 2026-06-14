import WidgetKit
import SwiftUI

// MARK: - Model

struct QuoteEntry: TimelineEntry {
    let date: Date
    let text: String
    let category: String

    static let placeholder = QuoteEntry(
        date: .now,
        text: "Every plant-based meal plants a little hope.",
        category: "🌱 Veggie"
    )
}

// MARK: - Provider

struct VeganKitTimelineProvider: TimelineProvider {
    /// Must match HomeWidgetService._appGroupId on the Dart side.
    static let appGroup = "group.io.develooper.vegankit"
    static let queueKey = "quote_queue"

    func placeholder(in context: Context) -> QuoteEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(loadEntries().first ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let entries = loadEntries()
        completion(Timeline(
            entries: entries.isEmpty ? [.placeholder] : entries,
            policy: .atEnd
        ))
    }

    /// Maps the date-indexed queue written by the app into one entry per
    /// local midnight.
    private func loadEntries() -> [QuoteEntry] {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroup),
            let raw = defaults.string(forKey: Self.queueKey),
            let data = raw.data(using: .utf8),
            let queue = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        var calendar = Calendar.current
        calendar.timeZone = .current
        var entries: [QuoteEntry] = []

        for item in queue {
            guard
                let day = item["day"] as? Int,
                let text = item["text"] as? String
            else { continue }
            let emoji = item["emoji"] as? String ?? "🌱"
            let category = item["category"] as? String ?? "Veggie"

            // epoch-day → local midnight of that calendar date
            let utcDate = Date(timeIntervalSince1970: TimeInterval(day) * 86_400)
            var comps = Calendar(identifier: .gregorian)
            comps.timeZone = TimeZone(identifier: "UTC")!
            let ymd = comps.dateComponents([.year, .month, .day], from: utcDate)
            guard let fireDate = calendar.date(from: ymd) else { continue }

            entries.append(QuoteEntry(
                date: fireDate,
                text: text,
                category: "\(emoji) \(category)"
            ))
        }

        // WidgetKit wants ascending, and the first entry should be "now-ish".
        entries.sort { $0.date < $1.date }
        if let todayIndex = entries.lastIndex(where: { $0.date <= .now }) {
            entries[todayIndex] = QuoteEntry(
                date: .now,
                text: entries[todayIndex].text,
                category: entries[todayIndex].category
            )
            entries.removeFirst(todayIndex)
        }
        return entries
    }
}

// MARK: - Views

struct VeganKitWidgetView: View {
    var entry: QuoteEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.category)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(red: 0.36, green: 0.42, blue: 0.38))
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(entry.text)
                .font(.system(
                    size: family == .systemSmall ? 13 : 16,
                    weight: .semibold,
                    design: .serif
                ))
                .foregroundStyle(Color(red: 0.15, green: 0.19, blue: 0.16))
                .minimumScaleFactor(0.7)
                .lineLimit(family == .systemSmall ? 6 : 4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(red: 0.98, green: 0.965, blue: 0.937) // Veggie cream
        }
    }
}

// MARK: - Widget

struct VeganKitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "VeganKitWidget",
            provider: VeganKitTimelineProvider()
        ) { entry in
            VeganKitWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Today's vegan motivation at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
