// ExpenseFlow home-screen widget (iOS / WidgetKit).
//
// Not yet part of the Xcode project: add it as a Widget Extension target
// named "SafeToSpendWidget" (see docs/HOME_WIDGETS.md), enable the App Group
// `group.com.nextgen.expenseflowapp` on both Runner and the extension, and use
// this file as the extension's source.

import SwiftUI
import WidgetKit

private let appGroup = "group.com.nextgen.expenseflowapp"

struct SafeToSpendEntry: TimelineEntry {
    let date: Date
    let fresh: Bool
    let hidden: Bool
    let safe: String
    let spent: String
    let over: Bool
}

struct SafeToSpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SafeToSpendEntry {
        SafeToSpendEntry(date: Date(), fresh: true, hidden: false,
                         safe: "₹840", spent: "₹260", over: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SafeToSpendEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SafeToSpendEntry>) -> Void) {
        // Redraw just after midnight so yesterday's numbers aren't shown.
        let midnight = Calendar.current.startOfDay(
            for: Date().addingTimeInterval(24 * 60 * 60))
        completion(Timeline(entries: [read()], policy: .after(midnight)))
    }

    private func read() -> SafeToSpendEntry {
        let data = UserDefaults(suiteName: appGroup)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return SafeToSpendEntry(
            date: Date(),
            fresh: data?.string(forKey: "date") == formatter.string(from: Date()),
            hidden: data?.bool(forKey: "hidden") ?? false,
            safe: data?.string(forKey: "safe") ?? "",
            spent: data?.string(forKey: "spent") ?? "",
            over: data?.bool(forKey: "over") ?? false
        )
    }
}

struct SafeToSpendWidgetView: View {
    let entry: SafeToSpendEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if entry.hidden {
                    Text("ExpenseFlow is locked").font(.caption).foregroundColor(.secondary)
                    Text("🔒").font(.title2)
                } else if !entry.fresh {
                    Text("Safe to spend today").font(.caption).foregroundColor(.secondary)
                    Text("—").font(.title2).bold()
                    Text("Open ExpenseFlow to refresh").font(.caption2).foregroundColor(.secondary)
                } else if entry.safe.isEmpty {
                    Text("Spent today").font(.caption).foregroundColor(.secondary)
                    Text(entry.spent).font(.title2).bold()
                } else {
                    Text("Safe to spend today").font(.caption).foregroundColor(.secondary)
                    Text(entry.safe).font(.title2).bold()
                        .foregroundColor(entry.over ? .red : .primary)
                    Text("Spent today: \(entry.spent)").font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            Link(destination: URL(string: "expenseflow://add-expense?homeWidget")!) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.91, green: 0.45, blue: 0.17))
            }
        }
        .padding()
        .widgetURL(URL(string: "expenseflow://open?homeWidget"))
    }
}

@main
struct SafeToSpendWidget: Widget {
    let kind = "SafeToSpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SafeToSpendProvider()) { entry in
            if #available(iOS 17.0, *) {
                SafeToSpendWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SafeToSpendWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Safe to spend")
        .description("What you can spend today, with quick add.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
