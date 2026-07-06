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

    private var exerciseTimeType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
    }

    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, caloriesType, floorsType, walkingSpeedType, exerciseTimeType]
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

    func fetchWeekPages(weekCount: Int = 5, reference: Date = .now) async -> [[DaySteps]]? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        let calendar = Calendar.current
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start else { return nil }

        var pages: [[DaySteps]] = []

        for offset in (0..<weekCount).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) else {
                continue
            }

            let isCurrentWeek = offset == 0
            let latestDay = isCurrentWeek
                ? calendar.startOfDay(for: reference)
                : calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

            let days = await fetchCalendarWeekDays(
                weekStart: weekStart,
                latestDay: latestDay,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            pages.append(days)
        }

        guard !pages.isEmpty else { return nil }

        return pages
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

        async let steps = fetchStepCount(from: range.start, to: range.end, stepType: stepType)
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

    func fetchStreak(goal: Int, maxDays: Int = 365) async -> Int? {
        guard isAvailable, let stepType else { return nil }

        let calendar = Calendar.current
        let end = Date()
        guard let start = calendar.date(byAdding: .day, value: -(maxDays - 1), to: calendar.startOfDay(for: end)) else {
            return nil
        }

        let daySteps = await fetchDailyStepCounts(from: start, to: end, stepType: stepType)
        guard !daySteps.isEmpty else { return nil }

        return StreakCalculator.currentStreak(daySteps: daySteps, goal: goal, reference: end)
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

    func fetchHourlySteps(for day: Date) async -> [HourlySteps]? {
        guard isAvailable, let stepType else { return nil }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.isDateInToday(day) ? Date() : calendar.date(byAdding: .day, value: 1, to: start) ?? start

        return await withCheckedContinuation { continuation in
            var anchorComponents = calendar.dateComponents([.day, .month, .year], from: start)
            anchorComponents.hour = 0
            guard let anchorDate = calendar.date(from: anchorComponents) else {
                continuation.resume(returning: [])
                return
            }

            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(hour: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var hourly: [HourlySteps] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let hour = calendar.component(.hour, from: statistics.startDate)
                    let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    hourly.append(HourlySteps(hour: hour, steps: steps))
                }
                continuation.resume(returning: hourly.sorted { $0.hour < $1.hour })
            }

            store.execute(query)
        }
    }

    func fetchHistoryPeriods(for range: HistoryRange, reference: Date = .now) async -> [PeriodStats]? {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else { return nil }

        switch range {
        case .week:
            let days = await fetchWeeklyDays(
                endingOn: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            return days.map { $0.toPeriodStats() }
        case .month:
            return await fetchDailyChartPeriods(
                count: 30,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        case .sixMonths:
            return await fetchWeekChartPeriods(
                count: 26,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        case .year:
            return await fetchMonthChartPeriods(
                count: 12,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        case .threeYears:
            return await fetchMonthChartPeriods(
                count: 36,
                reference: reference,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
        }
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

    private func fetchDailyStepCounts(
        from start: Date,
        to end: Date,
        stepType: HKQuantityType
    ) async -> [DayStepCount] {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            var anchorComponents = calendar.dateComponents([.day, .month, .year], from: start)
            anchorComponents.hour = 0
            guard let anchorDate = calendar.date(from: anchorComponents) else {
                continuation.resume(returning: [])
                return
            }

            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var daySteps: [DayStepCount] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    daySteps.append(DayStepCount(date: statistics.startDate, steps: steps))
                }
                continuation.resume(returning: daySteps)
            }

            store.execute(query)
        }
    }

    private func fetchStepCount(from start: Date, to end: Date, stepType: HKQuantityType) async -> Int {
        let counts = await fetchDailyStepCounts(from: start, to: end, stepType: stepType)
        return counts.reduce(0) { $0 + $1.steps }
    }

    private func fetchWeeklyDays(
        endingOn date: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [DaySteps] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }

        return await fetchCalendarWeekDays(
            weekStart: weekStart,
            latestDay: calendar.startOfDay(for: date),
            reference: date,
            stepType: stepType,
            distanceType: distanceType,
            caloriesType: caloriesType,
            floorsType: floorsType
        )
    }

    private func fetchCalendarWeekDays(
        weekStart: Date,
        latestDay: Date,
        reference: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [DaySteps] {
        let calendar = Calendar.current
        let latestDayStart = calendar.startOfDay(for: latestDay)
        var days: [DaySteps] = []

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: day)
            if dayStart > latestDayStart {
                days.append(emptyDay(for: day))
                continue
            }

            let isToday = calendar.isDateInToday(day)
            let end = isToday ? reference : calendar.date(byAdding: .day, value: 1, to: day) ?? day

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

    private func emptyDay(for day: Date) -> DaySteps {
        let labelFormatter = DateFormatter()
        labelFormatter.locale = Locale(identifier: "en_US_POSIX")
        labelFormatter.dateFormat = "EEE"

        let initialFormatter = DateFormatter()
        initialFormatter.locale = Locale(identifier: "en_US_POSIX")
        initialFormatter.dateFormat = "EEEEE"

        return DaySteps(
            date: day,
            label: labelFormatter.string(from: day),
            dayInitial: initialFormatter.string(from: day),
            steps: 0,
            distanceKm: 0,
            calories: 0,
            floors: 0,
            activeMinutes: 0,
            isToday: false
        )
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
        async let steps = fetchStepCount(from: start, to: end, stepType: stepType)
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

    private func fetchDailyChartPeriods(
        count: Int,
        reference: Date,
        stepType: HKQuantityType,
        distanceType: HKQuantityType,
        caloriesType: HKQuantityType,
        floorsType: HKQuantityType
    ) async -> [PeriodStats] {
        let calendar = Calendar.current
        var periods: [PeriodStats] = []

        for offset in (0..<count).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: reference)) else {
                continue
            }

            let isCurrent = offset == 0
            let end = isCurrent ? reference : calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let daySteps = await fetchDay(
                day: day,
                end: end,
                isToday: isCurrent,
                stepType: stepType,
                distanceType: distanceType,
                caloriesType: caloriesType,
                floorsType: floorsType
            )
            periods.append(daySteps.toPeriodStats())
        }

        return periods
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
        let labelFormatter = DateFormatter()
        labelFormatter.locale = Locale(identifier: "en_US_POSIX")
        labelFormatter.dateFormat = "EEE"

        let initialFormatter = DateFormatter()
        initialFormatter.locale = Locale(identifier: "en_US_POSIX")
        initialFormatter.dateFormat = "EEEEE"

        async let steps = fetchStepCount(from: day, to: end, stepType: stepType)
        async let distance = sumQuantity(type: distanceType, from: day, to: end)
        async let calories = sumQuantity(type: caloriesType, from: day, to: end)
        async let floors = sumQuantity(type: floorsType, from: day, to: end)
        async let activeMinutes = fetchActiveMinutes(from: day, to: end)

        return DaySteps(
            date: day,
            label: labelFormatter.string(from: day),
            dayInitial: initialFormatter.string(from: day),
            steps: Int(await steps),
            distanceKm: await distance / 1000,
            calories: Int(await calories),
            floors: Int(await floors),
            activeMinutes: await activeMinutes,
            isToday: isToday
        )
    }

    private func fetchActiveMinutes(from start: Date, to end: Date) async -> Int {
        guard let exerciseTimeType else { return 0 }
        let seconds = await sumQuantity(type: exerciseTimeType, from: start, to: end, unit: .second())
        return Int((seconds / 60).rounded())
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

    nonisolated private static func quantity(from result: HKStatistics?, option: HKStatisticsOptions) -> HKQuantity? {
        switch option {
        case .discreteAverage: result?.averageQuantity()
        case .discreteMin: result?.minimumQuantity()
        case .discreteMax: result?.maximumQuantity()
        default: nil
        }
    }

    nonisolated private static func inclusiveDayCount(from start: Date, to end: Date, calendar: Calendar) -> Int {
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

    nonisolated private static func unit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            .count()
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            .meter()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            .kilocalorie()
        case HKQuantityTypeIdentifier.appleExerciseTime.rawValue:
            .second()
        case HKQuantityTypeIdentifier.walkingSpeed.rawValue:
            .meter().unitDivided(by: .second())
        default:
            .count()
        }
    }
}
