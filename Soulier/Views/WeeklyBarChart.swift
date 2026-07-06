import SwiftUI

struct WeeklyBarChart: View {
    let periods: [PeriodStats]
    let selectedPeriodID: Date
    let onSelectPeriod: (PeriodStats) -> Void

    private let dayLabelHeight: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let chartHeight = max(geo.size.height - dayLabelHeight - 8, 0)

            HStack(alignment: .bottom, spacing: 0) {
                yAxis(height: chartHeight)
                    .frame(width: 32)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(periods) { period in
                        VStack(spacing: 8) {
                            bar(for: period, maxHeight: chartHeight, isSelected: period.id == selectedPeriodID)
                            Text(period.label)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(period.id == selectedPeriodID ? 1 : 0.85))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(height: dayLabelHeight)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectPeriod(period)
                        }
                    }
                }
                .padding(.leading, 4)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }

    private var chartMaxSteps: Double {
        Self.niceCeiling(Double(periods.map(\.steps).max() ?? 0))
    }

    private var yLabels: [String] {
        let maxValue = chartMaxSteps
        return (1...10).reversed().map { index in
            Self.compactLabel(for: maxValue * Double(index) / 10.0)
        }
    }

    private func yAxis(height: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yLabels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(height: height / CGFloat(yLabels.count), alignment: .top)
            }
        }
        .frame(height: height, alignment: .bottom)
    }

    private func bar(for period: PeriodStats, maxHeight: CGFloat, isSelected: Bool) -> some View {
        let ratio = min(Double(period.steps) / chartMaxSteps, 1.0)
        let height = max(maxHeight * ratio, 12)

        return VStack {
            Spacer(minLength: 0)
            Capsule()
                .fill(isSelected ? Color.white : Color.white.opacity(0.28))
                .frame(width: 28, height: height)
        }
        .frame(height: maxHeight)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private static func niceCeiling(_ value: Double) -> Double {
        guard value > 0 else { return 22_000 }

        let thresholds: [Double] = [
            2_000, 4_000, 6_000, 8_000, 11_000, 13_000, 15_000, 17_000, 19_000, 22_000,
            50_000, 75_000, 100_000, 150_000, 200_000, 300_000, 500_000, 750_000, 1_000_000
        ]

        return thresholds.first(where: { $0 >= value }) ?? value
    }

    private static func compactLabel(for value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return millions.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(millions))M"
                : String(format: "%.1fM", millions)
        }

        if value >= 1_000 {
            let thousands = value / 1_000
            return thousands.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(thousands))K"
                : String(format: "%.0fK", thousands)
        }

        return "\(Int(value))"
    }
}

#Preview {
    ZStack {
        AppTheme.background
            .ignoresSafeArea()
        WeeklyBarChart(
            periods: StepSummary.preview.weeklySteps.map { $0.toPeriodStats() },
            selectedPeriodID: StepSummary.preview.weeklySteps.last!.id,
            onSelectPeriod: { _ in }
        )
        .padding()
    }
}
