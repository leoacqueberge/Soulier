import WidgetKit
import SwiftUI

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int

    init(date: Date, data: WidgetStepsData) {
        self.date = date
        steps = data.steps
        distanceKm = data.distanceKm
        calories = data.calories
        floors = data.floors
    }

    static let preview = StepsEntry(date: .now, data: .preview)
}

struct SoulierWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview {
            completion(.preview)
            return
        }

        Task {
            let data = await WidgetHealthKitReader.fetchToday() ?? .preview
            completion(StepsEntry(date: .now, data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        if context.isPreview {
            completion(Timeline(entries: [.preview], policy: .never))
            return
        }

        Task {
            let data = await WidgetHealthKitReader.fetchToday() ?? WidgetStepsData(
                date: .now,
                steps: 0,
                distanceKm: 0,
                calories: 0,
                floors: 0
            )
            let entry = StepsEntry(date: .now, data: data)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }
}

struct SoulierWidget: Widget {
    let kind = "SoulierWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SoulierWidgetProvider()) { entry in
            SoulierWidgetView(entry: entry)
        }
        .configurationDisplayName("Steps")
        .description("Today's steps, distance, calories and floors.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct SoulierWidgetView: View {
    let entry: StepsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(formattedSteps)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(WidgetTheme.steps)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Steps walked")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(WidgetTheme.stepsWalked)
                .padding(.top, 1)
                .padding(.bottom, 5)

            statLine(formattedDistance, color: WidgetTheme.distance)
            statLine("\(entry.calories)kcal", color: WidgetTheme.calories)
            statLine("\(entry.floors) floors", color: WidgetTheme.floors)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .containerBackground(for: .widget) {
            WidgetTheme.background
        }
    }

    private func statLine(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.bottom, 3)
    }

    private var formattedSteps: String {
        WidgetFormatters.steps(entry.steps)
    }

    private var formattedDistance: String {
        "\(WidgetFormatters.decimal(entry.distanceKm))km"
    }
}

#Preview(as: .systemSmall) {
    SoulierWidget()
} timeline: {
    StepsEntry.preview
}
