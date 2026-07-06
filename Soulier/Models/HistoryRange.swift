import Foundation

enum HistoryRange: String, CaseIterable, Identifiable, Hashable {
    case week = "W"
    case month = "M"
    case sixMonths = "6M"
    case year = "1Y"
    case threeYears = "3Y"

    var id: String { rawValue }

    var title: String { rawValue }
}

struct HourlySteps: Identifiable, Hashable {
    let hour: Int
    let steps: Int

    var id: Int { hour }

    static let preview: [HourlySteps] = {
        var values = Array(repeating: 0, count: 24)
        values[0] = 4200
        values[1] = 58
        return values.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element) }
    }()
}
