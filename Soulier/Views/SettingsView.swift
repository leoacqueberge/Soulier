import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: StepsViewModel

    var body: some View {
        ZStack {
            AppTheme.blueGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                Spacer(minLength: 0)

                settingsCard
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .lightStatusBar()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Settings")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text("Preferences")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            section(title: "Goals") {
                dailyGoalRow
            }

            section(title: "Health") {
                settingRow(label: "Data source", value: "Apple Health")
            }

            section(title: "About") {
                settingRow(label: "Version", value: "1.0")
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 95)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(AppTheme.cardBackground)
        }
    }

    private var dailyGoalRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily step goal")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)

                Spacer(minLength: 16)

                HStack(spacing: 12) {
                    goalAdjustButton(systemName: "minus", isEnabled: viewModel.dailyGoal > DailyGoalStore.range.lowerBound) {
                        viewModel.adjustDailyGoal(by: -DailyGoalStore.step)
                    }

                    Text(formattedGoal(viewModel.dailyGoal))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .frame(minWidth: 72)
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: viewModel.dailyGoal)

                    goalAdjustButton(systemName: "plus", isEnabled: viewModel.dailyGoal < DailyGoalStore.range.upperBound) {
                        viewModel.adjustDailyGoal(by: DailyGoalStore.step)
                    }
                }
            }

            Text("Adjust in 1,000 step increments.")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)

            content()
        }
    }

    private func settingRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black)

            Spacer(minLength: 16)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .multilineTextAlignment(.trailing)
        }
    }

    private func goalAdjustButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(isEnabled ? .black : AppTheme.secondaryText)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(red: 0.94, green: 0.94, blue: 0.96))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func formattedGoal(_ goal: Int) -> String {
        Formatters.englishNumber.string(from: NSNumber(value: goal)) ?? "\(goal)"
    }
}

#Preview {
    SettingsView(viewModel: StepsViewModel())
}
