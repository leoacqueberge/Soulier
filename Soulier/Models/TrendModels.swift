import Foundation

enum TrendPeriod: String, CaseIterable, Identifiable {
    case thisWeek
    case thisMonth
    case thisYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .thisYear: "This Year"
        }
    }

    func dateRange(reference: Date = .now, calendar: Calendar = .current) -> (start: Date, end: Date, dayCount: Int) {
        let end = reference
        let start: Date

        switch self {
        case .thisWeek:
            start = calendar.dateInterval(of: .weekOfYear, for: reference)?.start
                ?? calendar.startOfDay(for: reference)
        case .thisMonth:
            start = calendar.dateInterval(of: .month, for: reference)?.start
                ?? calendar.startOfDay(for: reference)
        case .thisYear:
            start = calendar.dateInterval(of: .year, for: reference)?.start
                ?? calendar.startOfDay(for: reference)
        }

        let days = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0, 0) + 1
        return (start, end, days)
    }
}

struct TrendSummary {
    let period: TrendPeriod
    let totalSteps: Int
    let totalDistanceKm: Double
    let totalFloors: Int
    let totalCalories: Double
    let walkingSpeedMinKmh: Double?
    let walkingSpeedMaxKmh: Double?
    let walkingSpeedAvgKmh: Double?
    let dayCount: Int

    var averageSteps: Int {
        guard dayCount > 0 else { return 0 }
        return Int((Double(totalSteps) / Double(dayCount)).rounded())
    }

    var averageDistanceKm: Double {
        guard dayCount > 0 else { return 0 }
        return totalDistanceKm / Double(dayCount)
    }

    var averageFloors: Double {
        guard dayCount > 0 else { return 0 }
        return Double(totalFloors) / Double(dayCount)
    }

    var averageCalories: Double {
        guard dayCount > 0 else { return 0 }
        return totalCalories / Double(dayCount)
    }

    static let previewWeek = TrendSummary(
        period: .thisWeek,
        totalSteps: 74_138,
        totalDistanceKm: 55.67,
        totalFloors: 109,
        totalCalories: 2_739.5,
        walkingSpeedMinKmh: 2,
        walkingSpeedMaxKmh: 6,
        walkingSpeedAvgKmh: 4,
        dayCount: 6
    )

    static let previewMonth = TrendSummary(
        period: .thisMonth,
        totalSteps: 312_450,
        totalDistanceKm: 228.4,
        totalFloors: 468,
        totalCalories: 11_842.5,
        walkingSpeedMinKmh: 2,
        walkingSpeedMaxKmh: 7,
        walkingSpeedAvgKmh: 4.2,
        dayCount: 30
    )

    static let previewYear = TrendSummary(
        period: .thisYear,
        totalSteps: 2_845_120,
        totalDistanceKm: 2_104.8,
        totalFloors: 4_892,
        totalCalories: 98_450.5,
        walkingSpeedMinKmh: 2,
        walkingSpeedMaxKmh: 8,
        walkingSpeedAvgKmh: 4.1,
        dayCount: 184
    )
}

struct TrendMetric: Identifiable {
    let id: String
    let icon: String
    let label: String
    let totalValue: String
    let averageValue: String
}

extension TrendSummary {
    var metrics: [TrendMetric] {
        [
            TrendMetric(
                id: "steps",
                icon: "shoeprints.fill",
                label: "Total Steps",
                totalValue: Formatters.trendInteger(totalSteps),
                averageValue: Formatters.trendInteger(averageSteps)
            ),
            TrendMetric(
                id: "distance",
                icon: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
                label: "Total Distance",
                totalValue: Formatters.trendDecimal(totalDistanceKm) + "km",
                averageValue: Formatters.trendDecimal(averageDistanceKm) + "km"
            ),
            TrendMetric(
                id: "floors",
                icon: "figure.stairs",
                label: "Floors Climbed",
                totalValue: Formatters.trendDecimal(Double(totalFloors), fractionDigits: 0),
                averageValue: Formatters.trendDecimal(averageFloors, fractionDigits: 1)
            ),
            TrendMetric(
                id: "energy",
                icon: "flame.fill",
                label: "Active Energy",
                totalValue: Formatters.trendDecimal(totalCalories) + "kcal",
                averageValue: Formatters.trendDecimal(averageCalories) + "kcal"
            ),
            TrendMetric(
                id: "speed",
                icon: "gauge.with.dots.needle.33percent",
                label: "Walking Speed",
                totalValue: Self.formatSpeedRange(min: walkingSpeedMinKmh, max: walkingSpeedMaxKmh),
                averageValue: Self.formatSpeed(walkingSpeedAvgKmh)
            ),
        ]
    }

    private static func formatSpeedRange(min: Double?, max: Double?) -> String {
        guard let min, let max, max > 0 else { return "0KMPH" }
        let minText = Formatters.trendDecimal(min, fractionDigits: 0)
        let maxText = Formatters.trendDecimal(max, fractionDigits: 0)
        return "\(minText) - \(maxText)KMPH"
    }

    private static func formatSpeed(_ value: Double?) -> String {
        guard let value, value > 0 else { return "0KMPH" }
        return Formatters.trendDecimal(value, fractionDigits: 0) + "KMPH"
    }
}
