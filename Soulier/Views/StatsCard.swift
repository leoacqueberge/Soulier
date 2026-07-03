import SwiftUI
import UIKit

struct StatsCard: View {
    let period: PeriodStats
    @Binding var selectedTimeframe: Timeframe
    var onTimeframeChange: (Timeframe) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                timeframePicker
            }
            .padding(.bottom, 28)

            Text(formattedSteps(period.displaySteps(for: selectedTimeframe)))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 72, maxHeight: 72, alignment: .leading)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: period.id)
                .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)

            Text("Steps • \(period.subtitle)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28, alignment: .leading)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.2), value: period.id)

            HStack(spacing: 0) {
                metric(value: formattedDistance(period.displayDistanceKm(for: selectedTimeframe)), label: "Distance", alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                metric(value: "\(period.displayCalories(for: selectedTimeframe))kcal", label: "Calories", alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                metric(value: "\(period.displayFloors(for: selectedTimeframe))", label: "Floors", alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .animation(.easeInOut(duration: 0.2), value: period.id)
            .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 95)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
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
        .onChange(of: selectedTimeframe) { _, newValue in
            onTimeframeChange(newValue)
        }
    }

    private func metric(value: String, label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minHeight: 30, maxHeight: 30, alignment: alignment == .center ? .center : (alignment == .trailing ? .trailing : .leading))
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(minHeight: 14, maxHeight: 14, alignment: alignment == .center ? .center : (alignment == .trailing ? .trailing : .leading))
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
        period: StepSummary.preview.weeklySteps.last!.toPeriodStats(),
        selectedTimeframe: .constant(.day),
        onTimeframeChange: { _ in }
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
