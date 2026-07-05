import Foundation
import WidgetKit

@MainActor
@Observable
final class StepsViewModel {
    var summary = StepSummary.preview
    var selectedPeriodID: Date?
    var selectedTimeframe: Timeframe = .day
    var chartPeriods: [PeriodStats] = StepSummary.preview.weeklySteps.map { $0.toPeriodStats() }
    var selectedTab: NavTab = .steps
    var isLoading = false
    var dailyGoal: Int = DailyGoalStore.value {
        didSet {
            let clamped = DailyGoalStore.clamped(dailyGoal)
            guard clamped == dailyGoal else {
                dailyGoal = clamped
                return
            }
            DailyGoalStore.value = dailyGoal
            summary.dailyGoal = dailyGoal
            Task { await loadStreak() }
        }
    }

    var trendPeriod: TrendPeriod = .thisWeek
    var trend = TrendSummary.previewWeek
    var currentStreak: Int = 0

    private let healthKit = HealthKitManager()
    private let debounceInterval: Duration = .seconds(1.5)
    private let dayPreviewDuration: Duration = .seconds(2)

    private var refreshTask: Task<Void, Never>?
    private var periodPreviewResetTask: Task<Void, Never>?

    init() {
        summary.dailyGoal = dailyGoal
    }

    var selectedPeriod: PeriodStats {
        if let selectedPeriodID,
           let period = chartPeriods.first(where: { Calendar.current.isDate($0.startDate, inSameDayAs: selectedPeriodID) }) {
            return period
        }
        return chartPeriods.last ?? StepSummary.preview.weeklySteps.last!.toPeriodStats()
    }

    func selectPeriod(_ period: PeriodStats) {
        periodPreviewResetTask?.cancel()
        periodPreviewResetTask = nil

        if period.isCurrent {
            selectedPeriodID = nil
            return
        }

        selectedPeriodID = period.startDate

        periodPreviewResetTask = Task {
            try? await Task.sleep(for: dayPreviewDuration)
            guard !Task.isCancelled else { return }
            selectedPeriodID = nil
        }
    }

    func setTimeframe(_ timeframe: Timeframe) async {
        periodPreviewResetTask?.cancel()
        periodPreviewResetTask = nil
        selectedPeriodID = nil
        selectedTimeframe = timeframe
        await loadChartPeriods()
    }

    func adjustDailyGoal(by delta: Int) {
        dailyGoal = DailyGoalStore.adjusted(by: delta, from: dailyGoal)
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

    func load() async {
        isLoading = true
        defer { isLoading = false }

        summary.dailyGoal = dailyGoal

        guard healthKit.isAvailable else { return }

        if !healthKit.isAuthorized {
            await healthKit.requestAuthorization()
        }

        if let liveSummary = await healthKit.fetchSummary(dailyGoal: dailyGoal),
           liveSummary.today != nil || healthKit.isAuthorized {
            summary = liveSummary
            summary.dailyGoal = dailyGoal
        }

        await loadChartPeriods()
        await loadStreak()
        syncWidgetSnapshotIfNeeded()
    }

    func loadStreak() async {
        if let streak = await healthKit.fetchStreak(goal: dailyGoal) {
            currentStreak = streak
        } else {
            currentStreak = StreakCalculator.currentStreak(from: summary.weeklySteps, goal: dailyGoal)
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
        periodPreviewResetTask?.cancel()
        periodPreviewResetTask = nil
        healthKit.stopObserving()
    }

    private func loadChartPeriods() async {
        if let livePeriods = await healthKit.fetchChartPeriods(for: selectedTimeframe),
           healthKit.isAuthorized || livePeriods.contains(where: { $0.steps > 0 }) {
            chartPeriods = livePeriods
        } else {
            chartPeriods = previewChartPeriods(for: selectedTimeframe)
        }

        if let selectedPeriodID,
           !chartPeriods.contains(where: { Calendar.current.isDate($0.startDate, inSameDayAs: selectedPeriodID) }) {
            self.selectedPeriodID = nil
        }
    }

    private func previewChartPeriods(for timeframe: Timeframe) -> [PeriodStats] {
        switch timeframe {
        case .day:
            return StepSummary.preview.weeklySteps.map { $0.toPeriodStats() }
        case .week:
            return StepSummary.previewWeeks
        case .month:
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
        guard selectedTimeframe == .day else { return }

        guard let today = await healthKit.fetchToday(),
              let index = summary.weeklySteps.firstIndex(where: \.isToday) else { return }

        summary.weeklySteps[index] = today
        chartPeriods = summary.weeklySteps.map { $0.toPeriodStats() }
        await loadStreak()
        syncWidgetSnapshot(from: today)
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
