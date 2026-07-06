import Foundation
import HealthKit

struct WidgetStepsData {
    let date: Date
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int

    init(date: Date, steps: Int, distanceKm: Double, calories: Int, floors: Int) {
        self.date = date
        self.steps = steps
        self.distanceKm = distanceKm
        self.calories = calories
        self.floors = floors
    }

    init(snapshot: WidgetStepsSnapshot) {
        date = snapshot.date
        steps = snapshot.steps
        distanceKm = snapshot.distanceKm
        calories = snapshot.calories
        floors = snapshot.floors
    }

    static let preview = WidgetStepsData(
        date: .now,
        steps: 21_583,
        distanceKm: 14.67,
        calories: 669,
        floors: 17
    )

    static let empty = WidgetStepsData(
        date: .now,
        steps: 0,
        distanceKm: 0,
        calories: 0,
        floors: 0
    )
}

enum WidgetHealthKitReader {
    static func fetchToday() async -> WidgetStepsData? {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let floorsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            return nil
        }

        let store = HKHealthStore()
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)

        async let steps = fetchStepCount(type: stepType, from: start, to: now, store: store)
        async let distance = sum(type: distanceType, from: start, to: now, unit: .meter(), store: store)
        async let calories = sum(type: caloriesType, from: start, to: now, unit: .kilocalorie(), store: store)
        async let floors = sum(type: floorsType, from: start, to: now, unit: .count(), store: store)

        return WidgetStepsData(
            date: now,
            steps: Int(await steps),
            distanceKm: await distance / 1000,
            calories: Int(await calories),
            floors: Int(await floors)
        )
    }

    static func resolveToday() async -> WidgetStepsData {
        if let healthKit = await fetchToday(), healthKit.hasActivity {
            WidgetSnapshotStore.save(
                steps: healthKit.steps,
                distanceKm: healthKit.distanceKm,
                calories: healthKit.calories,
                floors: healthKit.floors,
                date: healthKit.date
            )
            return healthKit
        }

        if let cached = WidgetSnapshotStore.loadToday() {
            return WidgetStepsData(snapshot: cached)
        }

        return await fetchToday() ?? .empty
    }

    private static func fetchStepCount(
        type: HKQuantityType,
        from start: Date,
        to end: Date,
        store: HKHealthStore
    ) async -> Int {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            var anchorComponents = calendar.dateComponents([.day, .month, .year], from: start)
            anchorComponents.hour = 0
            guard let anchorDate = calendar.date(from: anchorComponents) else {
                continuation.resume(returning: 0)
                return
            }

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                guard let results else {
                    continuation.resume(returning: 0)
                    return
                }

                var total = 0
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    total += Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                }
                continuation.resume(returning: total)
            }

            store.execute(query)
        }
    }

    private static func sum(
        type: HKQuantityType,
        from start: Date,
        to end: Date,
        unit: HKUnit,
        store: HKHealthStore
    ) async -> Double {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}

private extension WidgetStepsData {
    var hasActivity: Bool {
        steps > 0 || distanceKm > 0 || calories > 0 || floors > 0
    }
}
