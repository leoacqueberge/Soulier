import Foundation
import HealthKit

@MainActor
@Observable
final class HealthKitManager {
    private let store = HKHealthStore()

    var isAuthorized = false
    var authorizationFailed = false

    private var observerQuery: HKObserverQuery?
    private var isObserving = false

    private var stepType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }

    private var distanceType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
    }

    private var caloriesType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    }

    private var floorsType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .flightsClimbed)
    }

    private var walkingSpeedType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .walkingSpeed)
    }

    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, caloriesType, floorsType, walkingSpeedType]
            .compactMap { $0 as HKObjectType? }
            .reduce(into: Set<HKObjectType>()) { $0.insert($1) }
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable, !readTypes.isEmpty else {
            authorizationFailed = true
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            authorizationFailed = true
        }
    }

    func fetchSummary(dailyGoal: Int) async -> StepSummary? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        let now = Date()
        let weekly = await fetchWeeklyDays(
            endingOn: now,
            stepType: stepType,
            distanceType: distanceType,
            caloriesType: caloriesType,
            floorsType: floorsType
        )

        guard !weekly.isEmpty else { return nil }

        return StepSummary(dailyGoal: dailyGoal, weeklySteps: weekly)
    }

    func fetchChartPeriods(for timeframe: Timeframe, reference: Date = .now) async -> [PeriodStats]? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        switch timeframe {
        case .day:
            let days = await fetchWeeklyDays(
                endingOn: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            return days.map { $0.toPeriodStats() }
        case .week:
            return await fetchWeekChartPeriods(
                count: 7,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        case .month:
            return await fetchMonthChartPeriods(
                count: 7,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        }
    }

    func fetchTrend(period: TrendPeriod) async -> TrendSummary? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        let range = period.dateRange()

        async let steps = sumQuantity(type: stepType, from: range.start, to: range.end)
        async let distance = sumQuantity(type: distanceType, from: range.start, to: range.end)
        async let calories = sumQuantity(type: caloriesType, from: range.start, to: range.end)
        async let floors = sumQuantity(type: floorsType, from: range.start, to: range.end)
        async let speedRange = fetchWalkingSpeedRange(from: range.start, to: range.end)

        let speed = await speedRange

        return TrendSummary(
            period: period,
            totalSteps: Int(await steps),
            totalDistanceKm: await distance / 1000,
            totalFloors: Int(await floors),
            totalCalories: await calories,
            walkingSpeedMinKmh: speed.min,
            walkingSpeedMaxKmh: speed.max,
            walkingSpeedAvgKmh: speed.avg,
            dayCount: range.dayCount
        )
    }

    func fetchToday() async -> DaySteps? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)

        return await fetchDay(
            day: startOfToday,
            end: now,
            isToday: true,
            stepType: stepType,
            distanceType: distanceType,
            caloriesType: caloriesType,
            floorsType: floorsType
        )
    }

    func startObservingToday(onUpdate: @escaping @MainActor () -> Void) {
        guard isAvailable, isAuthorized, let stepType, !isObserving else { return }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: nil, options: .strictStartDate)

        let query = HKObserverQuery(sampleType: stepType, predicate: predicate) { _, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    onUpdate()
                }
            }
            completionHandler()
        }

        observerQuery = query
        isObserving = true
        store.execute(query)
    }

    func stopObserving() {
        guard let observerQuery else { return }
        store.stop(observerQuery)
        self.observerQuery = nil
        isObserving = false
    }

    private func fetchWeeklyDays(
        endingOn date: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [DaySteps] {
        let calendar = Calendar.current
        var days: [DaySteps] = []

        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) else {
                continue
            }

            let isToday = calendar.isDateInToday(day)
            let end = isToday ? date : calendar.date(byAdding: .day, value: 1, to: day) ?? day

            let daySteps = await fetchDay(
                day: day,
                end: end,
                isToday: isToday,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            days.append(daySteps)
        }

        return days
    }

    private func fetchWeekChartPeriods(
        count: Int,
        reference: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [PeriodStats] {
        let calendar = Calendar.current
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start else { return [] }

        var periods: [PeriodStats] = []

        for offset in (0..<count).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) else {
                continue
            }

            let isCurrent = offset == 0
            let weekEnd = isCurrent
                ? reference
                : calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? reference
            let dayCount = Self.inclusiveDayCount(from: weekStart, to: weekEnd, calendar: calendar)

            let period = await fetchPeriodStats(
                from: weekStart,
                to: weekEnd,
                label: Self.weekChartLabel(for: weekStart),
                subtitle: isCurrent ? "This Week" : Self.weekSubtitle(for: weekStart),
                isCurrent: isCurrent,
                dayCount: dayCount,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            periods.append(period)
        }

        return periods
    }

    private func fetchMonthChartPeriods(
        count: Int,
        reference: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [PeriodStats] {
        let calendar = Calendar.current
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: reference)?.start else { return [] }

        var periods: [PeriodStats] = []

        for offset in (0..<count).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart) else {
                continue
            }

            let isCurrent = offset == 0
            let monthEnd = isCurrent
                ? reference
                : calendar.date(byAdding: .month, value: 1, to: monthStart) ?? reference
            let dayCount = Self.inclusiveDayCount(from: monthStart, to: monthEnd, calendar: calendar)

            let period = await fetchPeriodStats(
                from: monthStart,
                to: monthEnd,
                label: Self.monthChartLabel(for: monthStart),
                subtitle: isCurrent ? "This Month" : Self.monthSubtitle(for: monthStart),
                isCurrent: isCurrent,
                dayCount: dayCount,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            periods.append(period)
        }

        return periods
    }

    private func fetchPeriodStats(
        from start: Date,
        to end: Date,
        label: String,
        subtitle: String,
        isCurrent: Bool,
        dayCount: Int,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> PeriodStats {
        async let steps = sumQuantity(type: stepType, from: start, to: end)
        async let distance = sumQuantity(type: distanceType, from: start, to: end)
        async let calories = sumQuantity(type: caloriesType, from: start, to: end)
        async let floors = sumQuantity(type: floorsType, from: start, to: end)

        return PeriodStats(
            startDate: start,
            label: label,
            subtitle: subtitle,
            steps: Int(await steps),
            distanceKm: await distance / 1000,
            calories: Int(await calories),
            floors: Int(await floors),
            isCurrent: isCurrent,
            dayCount: dayCount
        )
    }

    private func fetchDay(
        day: Date,
        end: Date,
        isToday: Bool,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> DaySteps {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"

        async let steps = sumQuantity(type: stepType, from: day, to: end)
        async let distance = sumQuantity(type: distanceType, from: day, to: end)
        async let calories = sumQuantity(type: caloriesType, from: day, to: end)
        async let floors = sumQuantity(type: floorsType, from: day, to: end)

        return DaySteps(
            date: day,
            label: formatter.string(from: day),
            steps: Int(await steps),
            distanceKm: await distance / 1000,
            calories: Int(await calories),
            floors: Int(await floors),
            isToday: isToday
        )
    }

    private func fetchWalkingSpeedRange(from start: Date, to end: Date) async -> (min: Double?, max: Double?, avg: Double?) {
        guard let walkingSpeedType else { return (nil, nil, nil) }

        async let minMs = discreteQuantity(type: walkingSpeedType, from: start, to: end, option: .discreteMin)
        async let maxMs = discreteQuantity(type: walkingSpeedType, from: start, to: end, option: .discreteMax)
        async let avgMs = discreteQuantity(type: walkingSpeedType, from: start, to: end, option: .discreteAverage)

        let minKmh = (await minMs).map { $0 * 3.6 }
        let maxKmh = (await maxMs).map { $0 * 3.6 }
        let avgKmh = (await avgMs).map { $0 * 3.6 }

        return (minKmh, maxKmh, avgKmh)
    }

    private func sumQuantity(type: HKQuantityType, from start: Date, to end: Date, unit: HKUnit? = nil) async -> Double {
        let resolvedUnit = unit ?? Self.unit(for: type)
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: resolvedUnit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func discreteQuantity(
        type: HKQuantityType,
        from start: Date,
        to end: Date,
        option: HKStatisticsOptions,
        unit: HKUnit? = nil
    ) async -> Double? {
        let resolvedUnit = unit ?? Self.unit(for: type)
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: option
            ) { _, result, _ in
                guard let quantity = Self.quantity(from: result, option: option) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: quantity.doubleValue(for: resolvedUnit))
            }
            store.execute(query)
        }
    }

    private static func quantity(from result: HKStatistics?, option: HKStatisticsOptions) -> HKQuantity? {
        switch option {
        case .discreteAverage: result?.averageQuantity()
        case .discreteMin: result?.minimumQuantity()
        case .discreteMax: result?.maximumQuantity()
        default: nil
        }
    }

    private static func inclusiveDayCount(from start: Date, to end: Date, calendar: Calendar) -> Int {
        max(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0, 0) + 1
    }

    private static func weekChartLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private static func weekSubtitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "'Week of' MMM d"
        return formatter.string(from: date)
    }

    private static func monthChartLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private static func monthSubtitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func unit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            .count()
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            .meter()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            .kilocalorie()
        case HKQuantityTypeIdentifier.walkingSpeed.rawValue:
            .meter().unitDivided(by: .second())
        default:
            .count()
        }
    }
}
