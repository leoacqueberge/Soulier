import Foundation
import WidgetKit

@MainActor
@Observable
final class StepsViewModel {
    var summary = StepSummary.preview
    var weekPages: [[DaySteps]] = [StepSummary.preview.weeklySteps]
    var selectedDayID: Date?
    var hourlySteps: [HourlySteps] = HourlySteps.preview
    var historyRange: HistoryRange = .week
    var historyPeriods: [PeriodStats] = StepSummary.preview.weeklySteps.map { $0.toPeriodStats() }
    var isLoading = false
    let dailyGoal = DailyGoalStore.defaultValue

    var trendPeriod: TrendPeriod = .thisWeek
    var trend = TrendSummary.previewWeek
    var currentStreak: Int = 0

    private let healthKit = HealthKitManager()
    private let debounceInterval: Duration = .seconds(1.5)

    private var refreshTask: Task<Void, Never>?

    init() {
        summary.dailyGoal = dailyGoal
    }

    var allWeekDays: [DaySteps] {
        weekPages.flatMap { $0 }
    }

    var selectedDay: DaySteps {
        if let selectedDayID,
           let day = allWeekDays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDayID) }) {
            return day
        }
        return allWeekDays.first(where: \.isToday) ?? allWeekDays.last ?? StepSummary.preview.today!
    }

    var displayedDay: DaySteps {
        selectedDay.isToday ? (summary.today ?? selectedDay) : selectedDay
    }

    func selectDay(_ day: DaySteps) {
        selectedDayID = day.isToday ? nil : day.date
        Task { await loadHourlySteps(for: day.date) }
    }

    func setHistoryRange(_ range: HistoryRange) async {
        historyRange = range
        await loadHistoryPeriods()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        summary.dailyGoal = dailyGoal

        guard healthKit.isAvailable else { return }

        if !healthKit.isAuthorized {
            await healthKit.requestAuthorization()
        }

        if let pages = await healthKit.fetchWeekPages(weekCount: 5),
           healthKit.isAuthorized || pages.flatMap({ $0 }).contains(where: { $0.steps > 0 }) {
            weekPages = pages
        } else {
            weekPages = [StepSummary.preview.weeklySteps]
        }

        if let liveSummary = await healthKit.fetchSummary(dailyGoal: dailyGoal),
           liveSummary.today != nil || healthKit.isAuthorized {
            summary = liveSummary
            summary.dailyGoal = dailyGoal
        }

        await loadHourlySteps(for: displayedDay.date)
        await loadHistoryPeriods()
        await loadStreak()
        syncWidgetSnapshotIfNeeded()
    }

    func loadTrend() async {
        guard healthKit.isAvailable else { return }

        if !healthKit.isAuthorized {
            await healthKit.requestAuthorization()
        }

        if let liveTrend = await healthKit.fetchTrend(period: trendPeriod),
           healthKit.isAuthorized || liveTrend.totalSteps > 0 {
            trend = liveTrend
        } else {
            trend = switch trendPeriod {
            case .thisWeek: .previewWeek
            case .thisMonth: .previewMonth
            case .thisYear: .previewYear
            }
        }
    }

    func setTrendPeriod(_ period: TrendPeriod) async {
        trendPeriod = period
        await loadTrend()
    }

    func loadStreak() async {
        if let streak = await healthKit.fetchStreak(goal: dailyGoal) {
            currentStreak = streak
        } else {
            currentStreak = StreakCalculator.currentStreak(from: allWeekDays, goal: dailyGoal)
        }
    }

    func startLiveUpdates() {
        guard healthKit.isAvailable, healthKit.isAuthorized else { return }

        healthKit.startObservingToday { [weak self] in
            self?.scheduleTodayRefresh()
        }
    }

    func stopLiveUpdates() {
        refreshTask?.cancel()
        refreshTask = nil
        healthKit.stopObserving()
    }

    private func loadHistoryPeriods() async {
        if let livePeriods = await healthKit.fetchHistoryPeriods(for: historyRange),
           healthKit.isAuthorized || livePeriods.contains(where: { $0.steps > 0 }) {
            historyPeriods = livePeriods
        } else {
            historyPeriods = previewHistoryPeriods(for: historyRange)
        }
    }

    private func loadHourlySteps(for day: Date) async {
        if let liveHourly = await healthKit.fetchHourlySteps(for: day),
           healthKit.isAuthorized || liveHourly.contains(where: { $0.steps > 0 }) {
            hourlySteps = liveHourly
        } else {
            hourlySteps = HourlySteps.preview
        }
    }

    private func previewHistoryPeriods(for range: HistoryRange) -> [PeriodStats] {
        switch range {
        case .week:
            return StepSummary.preview.weeklySteps.map { $0.toPeriodStats() }
        case .month:
            return StepSummary.preview.weeklySteps.map { $0.toPeriodStats() }
        case .sixMonths:
            return StepSummary.previewWeeks
        case .year, .threeYears:
            return StepSummary.previewMonths
        }
    }

    private func scheduleTodayRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await refreshToday()
        }
    }

    private func refreshToday() async {
        guard let today = await healthKit.fetchToday() else { return }

        if let index = summary.weeklySteps.firstIndex(where: \.isToday) {
            summary.weeklySteps[index] = today
        }

        updateDayInWeekPages(today)

        if displayedDay.isToday {
            await loadHourlySteps(for: today.date)
        }

        if historyRange == .week {
            await loadHistoryPeriods()
        }

        await loadStreak()
        syncWidgetSnapshot(from: today)
    }

    private func updateDayInWeekPages(_ day: DaySteps) {
        for weekIndex in weekPages.indices {
            if let dayIndex = weekPages[weekIndex].firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day.date) }) {
                weekPages[weekIndex][dayIndex] = day
                return
            }
        }
    }

    private func syncWidgetSnapshotIfNeeded() {
        guard let today = summary.today else { return }
        syncWidgetSnapshot(from: today)
    }

    private func syncWidgetSnapshot(from day: DaySteps) {
        WidgetSnapshotStore.save(
            steps: day.steps,
            distanceKm: day.distanceKm,
            calories: day.calories,
            floors: day.floors,
            date: day.date
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}
