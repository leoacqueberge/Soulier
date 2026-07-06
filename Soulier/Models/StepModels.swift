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

struct DaySteps: Identifiable, Hashable {
    let date: Date
    let label: String
    let dayInitial: String
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int
    let activeMinutes: Int
    let isToday: Bool

    var id: Date { date }

    var subtitle: String {
        isToday ? "Today" : label
    }

    func completionPercent(goal: Int) -> Int {
        guard goal > 0 else { return 0 }
        return Int((Double(steps) / Double(goal)) * 100)
    }

    func progress(goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1)
    }

    func toPeriodStats() -> PeriodStats {
        PeriodStats(
            startDate: date,
            label: label,
            subtitle: subtitle,
            steps: steps,
            distanceKm: distanceKm,
            calories: calories,
            floors: floors,
            isCurrent: isToday,
            dayCount: 1
        )
    }

    func withSteps(_ steps: Int) -> DaySteps {
        DaySteps(
            date: date,
            label: label,
            dayInitial: dayInitial,
            steps: steps,
            distanceKm: distanceKm,
            calories: calories,
            floors: floors,
            activeMinutes: activeMinutes,
            isToday: isToday
        )
    }
}

struct PeriodStats: Identifiable, Hashable {
    let startDate: Date
    let label: String
    let subtitle: String
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int
    let isCurrent: Bool
    let dayCount: Int

    var id: Date { startDate }

    func completionPercent(goal: Int) -> Int {
        guard goal > 0, dayCount > 0 else { return 0 }
        return Int((Double(steps) / Double(goal * dayCount)) * 100)
    }

    var averageSteps: Int {
        guard dayCount > 0 else { return 0 }
        return Int((Double(steps) / Double(dayCount)).rounded())
    }

    var averageDistanceKm: Double {
        guard dayCount > 0 else { return 0 }
        return distanceKm / Double(dayCount)
    }

    var averageCalories: Int {
        guard dayCount > 0 else { return 0 }
        return Int((Double(calories) / Double(dayCount)).rounded())
    }

    var averageFloors: Int {
        guard dayCount > 0 else { return 0 }
        return Int((Double(floors) / Double(dayCount)).rounded())
    }

    func displaySteps(for timeframe: Timeframe) -> Int {
        switch timeframe {
        case .day: steps
        case .week, .month: averageSteps
        }
    }

    func displayDistanceKm(for timeframe: Timeframe) -> Double {
        switch timeframe {
        case .day: distanceKm
        case .week, .month: averageDistanceKm
        }
    }

    func displayCalories(for timeframe: Timeframe) -> Int {
        switch timeframe {
        case .day: calories
        case .week, .month: averageCalories
        }
    }

    func displayFloors(for timeframe: Timeframe) -> Int {
        switch timeframe {
        case .day: floors
        case .week, .month: averageFloors
        }
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
            DaySteps(date: .preview(daysAgo: 6), label: "Sat", dayInitial: "S", steps: 4_300, distanceKm: 2.93, calories: 158, floors: 4, activeMinutes: 22, isToday: false),
            DaySteps(date: .preview(daysAgo: 5), label: "Sun", dayInitial: "S", steps: 8_100, distanceKm: 5.52, calories: 251, floors: 7, activeMinutes: 31, isToday: false),
            DaySteps(date: .preview(daysAgo: 4), label: "Mon", dayInitial: "M", steps: 12_400, distanceKm: 8.44, calories: 385, floors: 10, activeMinutes: 45, isToday: false),
            DaySteps(date: .preview(daysAgo: 3), label: "Tue", dayInitial: "T", steps: 9_800, distanceKm: 6.67, calories: 304, floors: 8, activeMinutes: 36, isToday: false),
            DaySteps(date: .preview(daysAgo: 2), label: "Wed", dayInitial: "W", steps: 15_200, distanceKm: 10.34, calories: 472, floors: 12, activeMinutes: 52, isToday: false),
            DaySteps(date: .preview(daysAgo: 1), label: "Thu", dayInitial: "T", steps: 18_900, distanceKm: 12.86, calories: 587, floors: 14, activeMinutes: 61, isToday: false),
            DaySteps(date: .preview(daysAgo: 0), label: "Fri", dayInitial: "F", steps: 4_258, distanceKm: 2.93, calories: 132, floors: 9, activeMinutes: 39, isToday: true),
        ]
    )

    static let previewWeeks: [PeriodStats] = [
        PeriodStats(startDate: .preview(weeksAgo: 6), label: "18 May", subtitle: "Week of May 18", steps: 98_400, distanceKm: 72.1, calories: 3_842, floors: 62, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 5), label: "25 May", subtitle: "Week of May 25", steps: 112_300, distanceKm: 81.4, calories: 4_210, floors: 71, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 4), label: "1 Jun", subtitle: "Week of Jun 1", steps: 105_800, distanceKm: 76.9, calories: 3_980, floors: 68, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 3), label: "8 Jun", subtitle: "Week of Jun 8", steps: 118_600, distanceKm: 86.2, calories: 4_450, floors: 74, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 2), label: "15 Jun", subtitle: "Week of Jun 15", steps: 94_200, distanceKm: 68.5, calories: 3_620, floors: 59, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 1), label: "22 Jun", subtitle: "Week of Jun 22", steps: 121_900, distanceKm: 88.7, calories: 4_580, floors: 78, isCurrent: false, dayCount: 7),
        PeriodStats(startDate: .preview(weeksAgo: 0), label: "29 Jun", subtitle: "This Week", steps: 74_138, distanceKm: 55.67, calories: 2_739, floors: 109, isCurrent: true, dayCount: 6),
    ]

    static let previewMonths: [PeriodStats] = [
        PeriodStats(startDate: .preview(monthsAgo: 6), label: "Jan", subtitle: "January 2026", steps: 412_800, distanceKm: 298.4, calories: 15_820, floors: 312, isCurrent: false, dayCount: 31),
        PeriodStats(startDate: .preview(monthsAgo: 5), label: "Feb", subtitle: "February 2026", steps: 385_200, distanceKm: 278.1, calories: 14_760, floors: 289, isCurrent: false, dayCount: 28),
        PeriodStats(startDate: .preview(monthsAgo: 4), label: "Mar", subtitle: "March 2026", steps: 428_600, distanceKm: 309.5, calories: 16_420, floors: 324, isCurrent: false, dayCount: 31),
        PeriodStats(startDate: .preview(monthsAgo: 3), label: "Apr", subtitle: "April 2026", steps: 396_400, distanceKm: 286.2, calories: 15_180, floors: 298, isCurrent: false, dayCount: 30),
        PeriodStats(startDate: .preview(monthsAgo: 2), label: "May", subtitle: "May 2026", steps: 445_100, distanceKm: 321.8, calories: 17_050, floors: 336, isCurrent: false, dayCount: 31),
        PeriodStats(startDate: .preview(monthsAgo: 1), label: "Jun", subtitle: "June 2026", steps: 318_900, distanceKm: 230.4, calories: 12_210, floors: 241, isCurrent: false, dayCount: 30),
        PeriodStats(startDate: .preview(monthsAgo: 0), label: "Jul", subtitle: "This Month", steps: 74_138, distanceKm: 55.67, calories: 2_739, floors: 109, isCurrent: true, dayCount: 4),
    ]
}

private extension Date {
    static func preview(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    static func preview(weeksAgo: Int) -> Date {
        let calendar = Calendar.current
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: currentWeekStart) ?? currentWeekStart
    }

    static func preview(monthsAgo: Int) -> Date {
        let calendar = Calendar.current
        let currentMonthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .month, value: -monthsAgo, to: currentMonthStart) ?? currentMonthStart
    }
}
