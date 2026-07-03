import SwiftUI

struct ContentView: View {
    @State private var viewModel = StepsViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Steps", systemImage: "shoeprints.fill", value: NavTab.steps) {
                StepsDashboardView(viewModel: viewModel)
            }

            Tab("History", systemImage: "clock", value: NavTab.history) {
                HistoryView()
            }

            Tab("Settings", systemImage: "gearshape", value: NavTab.settings) {
                SettingsView()
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
    @State private var selectedTimeframe: Timeframe = .day

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
                        days: viewModel.summary.weeklySteps,
                        selectedDayID: viewModel.selectedDay.id,
                        onSelectDay: viewModel.selectDay
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: .infinity)

                StatsCard(
                    day: viewModel.selectedDay,
                    selectedTimeframe: $selectedTimeframe
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .lightStatusBar()
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedDay.id)
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
        }
    }

    private var goalBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(formattedGoal(viewModel.summary.dailyGoal))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

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
            Text("\(viewModel.selectedDay.completionPercent(goal: viewModel.summary.dailyGoal))%")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

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
