import Foundation

enum DailyGoalStore {
    private static let key = "dailyStepGoal"
    static let defaultValue = 20_000
    static let step = 1_000
    static let range = 1_000...100_000

    static var value: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: key)
            return stored == 0 ? defaultValue : stored
        }
        set {
            UserDefaults.standard.set(clamped(newValue), forKey: key)
        }
    }

    static func clamped(_ goal: Int) -> Int {
        min(max(goal, range.lowerBound), range.upperBound)
    }

    static func adjusted(by delta: Int, from current: Int) -> Int {
        clamped(current + delta)
    }
}
