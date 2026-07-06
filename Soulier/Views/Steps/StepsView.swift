import SwiftUI

struct StepsView: View {
    @Bindable var viewModel: StepsViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 60) {
                weeklySection
                ringSection
                MetricsRow(
                    distanceKm: viewModel.displayedDay.distanceKm,
                    floors: viewModel.displayedDay.floors,
                    activeMinutes: viewModel.displayedDay.activeMinutes
                )
                .padding(.horizontal, 24)

                TodayHourlyChart(
                    hourlySteps: viewModel.hourlySteps,
                    date: viewModel.displayedDay.date
                )
                .padding(.horizontal, 16)

                StepHistoryCard(
                    periods: viewModel.historyPeriods,
                    goal: viewModel.dailyGoal,
                    selectedRange: $viewModel.historyRange,
                    onRangeChange: { range in
                        Task { await viewModel.setHistoryRange(range) }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.displayedDay.id)
        .animation(.easeInOut(duration: 0.2), value: viewModel.historyRange)
    }

    private var weeklySection: some View {
        WeekDaysPager(
            weeks: viewModel.weekPages,
            goal: viewModel.dailyGoal,
            selectedDayID: viewModel.selectedDayID,
            onSelectDay: viewModel.selectDay
        )
    }

    private var ringSection: some View {
        DailyProgressRing(
            steps: viewModel.displayedDay.steps,
            goal: viewModel.dailyGoal
        )
    }
}

#Preview {
    StepsView(viewModel: StepsViewModel())
}
