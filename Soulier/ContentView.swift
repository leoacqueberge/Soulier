import SwiftUI

struct ContentView: View {
    @State private var viewModel = StepsViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Steps", systemImage: "shoeprints.fill", value: NavTab.steps) {
                StepsDashboardView(viewModel: viewModel)
            }

            Tab("History", systemImage: "clock", value: NavTab.history) {
                HistoryView(viewModel: viewModel)
            }

            Tab("Settings", systemImage: "gearshape", value: NavTab.settings) {
                SettingsView(viewModel: viewModel)
            }
        }
        .tint(.black)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await viewModel.load()
        }
    }
}

struct StepsDashboardView: View {
    @Bindable var viewModel: StepsViewModel

    var body: some View {
        ZStack {
            AppTheme.blueGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    WeeklyBarChart(
                        periods: viewModel.chartPeriods,
                        selectedPeriodID: viewModel.selectedPeriod.id,
                        onSelectPeriod: viewModel.selectPeriod
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: .infinity)

                StatsCard(
                    period: viewModel.selectedPeriod,
                    selectedTimeframe: $viewModel.selectedTimeframe,
                    onTimeframeChange: { timeframe in
                        Task {
                            await viewModel.setTimeframe(timeframe)
                        }
                    }
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .lightStatusBar()
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPeriod.id)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTimeframe)
        .task {
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
    }

    private var header: some View {
        HStack(spacing: 20) {
            goalBlock
            divider
            completionBlock
            Spacer(minLength: 0)
            streakBlock
        }
    }

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentStreak)

            Text("Streak")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var goalBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(formattedGoal(viewModel.dailyGoal))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: viewModel.dailyGoal)

            Text("Daily goal")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.35))
            .frame(width: 1, height: 24)
    }

    private var completionBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(viewModel.selectedPeriod.completionPercent(goal: viewModel.dailyGoal))%")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: viewModel.dailyGoal)

            Text("Completed")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private func formattedGoal(_ goal: Int) -> String {
        Formatters.englishNumber.string(from: NSNumber(value: goal)) ?? "\(goal)"
    }
}

#Preview {
    ContentView()
}
