import SwiftUI
import UIKit

struct StatsCard: View {
    let day: DaySteps
    @Binding var selectedTimeframe: Timeframe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(formattedSteps(day.steps))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: day.id)

                Spacer(minLength: 0)

                timeframePicker
            }

            Text("Steps • \(day.subtitle)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.2), value: day.id)

            HStack(spacing: 0) {
                metric(value: formattedDistance(day.distanceKm), label: "Distance", alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                metric(value: "\(day.calories)kcal", label: "Calories", alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                metric(value: "\(day.floors)", label: "Floors", alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .animation(.easeInOut(duration: 0.2), value: day.id)
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

    private var timeframePicker: some View {
        Picker("Period", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .tint(.black)
        .monospacedSegmentedPicker()
        .frame(width: 120)
    }

    private func metric(value: String, label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func formattedSteps(_ steps: Int) -> String {
        Formatters.englishNumber.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    private func formattedDistance(_ km: Double) -> String {
        let value = Formatters.englishDecimal.string(from: NSNumber(value: km)) ?? String(format: "%.2f", km)
        return "\(value)km"
    }
}

#Preview {
    StatsCard(
        day: StepSummary.preview.weeklySteps.last!,
        selectedTimeframe: .constant(.day)
    )
}

private extension View {
    func monospacedSegmentedPicker() -> some View {
        onAppear {
            let font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
            UISegmentedControl.appearance().setTitleTextAttributes([.font: font], for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes([.font: font], for: .selected)
        }
    }
}
