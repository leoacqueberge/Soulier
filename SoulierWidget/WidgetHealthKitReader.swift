import Foundation
import HealthKit

struct WidgetStepsData {
    let date: Date
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int

    static let preview = WidgetStepsData(
        date: .now,
        steps: 21_583,
        distanceKm: 14.67,
        calories: 669,
        floors: 17
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

        async let steps = sum(type: stepType, from: start, to: now, unit: .count(), store: store)
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
