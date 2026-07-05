import Foundation

struct WidgetStepsSnapshot: Codable {
    let date: Date
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let floors: Int
    let updatedAt: Date
}

enum WidgetSnapshotStore {
    static let appGroupID = "group.com.leoacqueberge.Soulier"
    private static let snapshotKey = "todayStepsSnapshot"

    static func save(
        steps: Int,
        distanceKm: Double,
        calories: Int,
        floors: Int,
        date: Date = .now
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let snapshot = WidgetStepsSnapshot(
            date: Calendar.current.startOfDay(for: date),
            steps: steps,
            distanceKm: distanceKm,
            calories: calories,
            floors: floors,
            updatedAt: .now
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func loadToday() -> WidgetStepsSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetStepsSnapshot.self, from: data),
              Calendar.current.isDateInToday(snapshot.date) else {
            return nil
        }

        return snapshot
    }
}
