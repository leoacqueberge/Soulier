import Foundation

enum Timeframe: String, CaseIterable {
    case day
    case week
    case month

    var title: String {
        switch self {
        case .day: "D"
        case .week: "W"
        case .month: "M"
        }
    }
}

enum NavTab: Hashable {
    case steps
    case history
    case settings
}

struct DaySteps: Identifiable, Hashable {
    let date: Date
    let label: String
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int
    let isToday: Bool

    var id: Date { date }

    var subtitle: String {
        isToday ? "Today" : label
    }

    func completionPercent(goal: Int) -> Int {
        guard goal > 0 else { return 0 }
        return Int((Double(steps) / Double(goal)) * 100)
    }
}

struct StepSummary {
    var dailyGoal: Int
    var weeklySteps: [DaySteps]

    var today: DaySteps? {
        weeklySteps.first(where: \.isToday)
    }

    static let preview = StepSummary(
        dailyGoal: 20_000,
        weeklySteps: [
            DaySteps(date: .preview(daysAgo: 6), label: "Sat", steps: 10_200, distanceKm: 6.94, calories: 316, floors: 8, isToday: false),
            DaySteps(date: .preview(daysAgo: 5), label: "Sun", steps: 13_400, distanceKm: 9.12, calories: 415, floors: 11, isToday: false),
            DaySteps(date: .preview(daysAgo: 4), label: "Mon", steps: 17_100, distanceKm: 11.63, calories: 530, floors: 14, isToday: false),
            DaySteps(date: .preview(daysAgo: 3), label: "Tue", steps: 13_200, distanceKm: 8.98, calories: 409, floors: 10, isToday: false),
            DaySteps(date: .preview(daysAgo: 2), label: "Wed", steps: 16_300, distanceKm: 11.09, calories: 505, floors: 13, isToday: false),
            DaySteps(date: .preview(daysAgo: 1), label: "Thu", steps: 19_400, distanceKm: 13.20, calories: 601, floors: 15, isToday: false),
            DaySteps(date: .preview(daysAgo: 0), label: "Fri", steps: 21_583, distanceKm: 14.67, calories: 669, floors: 17, isToday: true),
        ]
    )
}

private extension Date {
    static func preview(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }
}
