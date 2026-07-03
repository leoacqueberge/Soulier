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

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable,
              let stepType,
              let distanceType,
              let caloriesType,
              let floorsType else {
            authorizationFailed = true
            return
        }

        let readTypes: Set<HKObjectType> = [stepType, distanceType, caloriesType, floorsType]

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

    private func sumQuantity(type: HKQuantityType, from start: Date, to end: Date) async -> Double {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let unit: HKUnit
                switch type.identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue,
                     HKQuantityTypeIdentifier.flightsClimbed.rawValue:
                    unit = .count()
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    unit = .meter()
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    unit = .kilocalorie()
                default:
                    unit = .count()
                }

                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
