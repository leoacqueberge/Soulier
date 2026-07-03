import Foundation

struct DayStepCount {
    let date: Date
    let steps: Int
}

enum StreakCalculator {
    static func currentStreak(
        daySteps: [DayStepCount],
        goal: Int,
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard goal > 0 else { return 0 }

        let stepsByDay = Dictionary(
            uniqueKeysWithValues: daySteps.map {
                (calendar.startOfDay(for: $0.date), $0.steps)
            }
        )

        let today = calendar.startOfDay(for: reference)
        let checkDate: Date

        if let todaySteps = stepsByDay[today], todaySteps >= goal {
            checkDate = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            checkDate = yesterday
        } else {
            return 0
        }

        var streak = 0
        var cursor = checkDate

        while let steps = stepsByDay[cursor], steps >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    static func currentStreak(
        from days: [DaySteps],
        goal: Int,
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        currentStreak(
            daySteps: days.map { DayStepCount(date: $0.date, steps: $0.steps) },
            goal: goal,
            reference: reference,
            calendar: calendar
        )
    }
}
