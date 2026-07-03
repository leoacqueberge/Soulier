import Foundation

@MainActor
@Observable
final class StepsViewModel {
    var summary = StepSummary.preview
    var selectedDayID: Date?
    var selectedTab: NavTab = .steps
    var isLoading = false

    private let healthKit = HealthKitManager()
    private let dailyGoal = 20_000
    private let debounceInterval: Duration = .seconds(1.5)

    private var refreshTask: Task<Void, Never>?

    var selectedDay: DaySteps {
        if let selectedDayID,
           let day = summary.weeklySteps.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDayID) }) {
            return day
        }
        return summary.today ?? summary.weeklySteps.last!
    }

    func selectDay(_ day: DaySteps) {
        selectedDayID = day.date
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard healthKit.isAvailable else { return }

        if !healthKit.isAuthorized {
            await healthKit.requestAuthorization()
        }

        if let liveSummary = await healthKit.fetchSummary(dailyGoal: dailyGoal),
           liveSummary.today != nil || healthKit.isAuthorized {
            summary = liveSummary
            if let selectedDayID,
               !summary.weeklySteps.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDayID) }) {
                self.selectedDayID = nil
            }
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

    private func scheduleTodayRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await refreshToday()
        }
    }

    private func refreshToday() async {
        guard let today = await healthKit.fetchToday(),
              let index = summary.weeklySteps.firstIndex(where: \.isToday) else { return }

        summary.weeklySteps[index] = today
    }
}
