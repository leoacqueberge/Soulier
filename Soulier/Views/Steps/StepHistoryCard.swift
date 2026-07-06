import SwiftUI

struct StepHistoryCard: View {
    let periods: [PeriodStats]
    let goal: Int
    @Binding var selectedRange: HistoryRange
    let onRangeChange: (HistoryRange) -> Void

    private var displaySteps: [Int] {
        periods.map(\.steps)
    }

    private var averageSteps: Int {
        guard !displaySteps.isEmpty else { return 0 }
        return displaySteps.reduce(0, +) / displaySteps.count
    }

    private var minSteps: Int { displaySteps.min() ?? 0 }
    private var maxSteps: Int { displaySteps.max() ?? 0 }

    private var chartMax: Double {
        HistoryChartScale.niceCeiling(max(Double(maxSteps), Double(goal)))
    }

    private var goalLineValue: Double {
        switch selectedRange {
        case .week, .month:
            Double(goal)
        case .sixMonths, .year, .threeYears:
            Double(goal * 7)
        }
    }

    private var dateRangeText: String {
        guard let first = periods.first?.startDate, let last = periods.last?.startDate else { return "" }
        return Formatters.dateRange(from: first, to: last)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Step History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $selectedRange) {
                    ForEach(HistoryRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedRange) { _, newValue in
                    onRangeChange(newValue)
                }

                HStack {
                    Text(dateRangeText)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.cardSecondary)
                    Spacer()
                    Text("\(Formatters.compactSteps(minSteps)) – \(Formatters.compactSteps(maxSteps))")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.cardSecondary)
                }

                historyChart

                HStack(spacing: 20) {
                    legendItem(color: AppTheme.averageLine, title: "Average")
                    legendItem(color: AppTheme.goalLine, title: "Daily Goal")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.cardBackground)
            }
        }
    }

    private var historyChart: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - 24
            let chartWidth = geo.size.width - 36
            let barCount = max(periods.count, 1)
            let slotWidth = chartWidth / CGFloat(barCount)
            let barWidth = barWidth(for: slotWidth, barCount: barCount)
            let averageY = yPosition(for: Double(averageSteps), chartHeight: chartHeight)
            let goalY = yPosition(for: goalLineValue, chartHeight: chartHeight)

            ZStack(alignment: .bottomLeading) {
                ForEach(0..<5, id: \.self) { index in
                    let y = chartHeight * CGFloat(index) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: chartWidth, y: y))
                    }
                    .stroke(AppTheme.chartGrid, lineWidth: 1)
                }

                referenceLine(at: averageY, width: chartWidth, color: AppTheme.averageLine)
                referenceLine(at: goalY, width: chartWidth, color: AppTheme.goalLine)

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(periods) { period in
                        let ratio = CGFloat(period.steps) / CGFloat(chartMax)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppTheme.chartBar)
                            .frame(
                                width: barWidth,
                                height: max(ratio * chartHeight, period.steps > 0 ? 4 : 0)
                            )
                            .frame(width: slotWidth)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(periods) { period in
                        Text(period.label)
                            .font(.system(size: labelFontSize, weight: period.isCurrent ? .semibold : .regular))
                            .foregroundStyle(period.isCurrent ? AppTheme.todayHighlight : AppTheme.cardSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .frame(width: slotWidth)
                    }
                }
                .offset(y: chartHeight + 8)

                VStack(alignment: .trailing, spacing: 0) {
                    ForEach((0...4).reversed(), id: \.self) { index in
                        Text(HistoryChartScale.compactLabel(chartMax * Double(index) / 4))
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.cardSecondary)
                            .frame(height: chartHeight / 4, alignment: .top)
                    }
                }
                .frame(width: 32)
                .offset(x: chartWidth + 4)
            }
        }
        .frame(height: 200)
    }

    private var labelFontSize: CGFloat {
        switch selectedRange {
        case .week: 13
        case .month: 11
        default: 12
        }
    }

    private func barWidth(for slotWidth: CGFloat, barCount: Int) -> CGFloat {
        let density: CGFloat = switch selectedRange {
        case .week: 5.5
        case .month: 8.5
        case .sixMonths: 6.5
        case .year, .threeYears: 6.0
        }
        return max(slotWidth / density, barCount > 20 ? 1.5 : 2)
    }

    private func yPosition(for value: Double, chartHeight: CGFloat) -> CGFloat {
        let ratio = min(max(value / chartMax, 0), 1)
        return chartHeight * (1 - CGFloat(ratio))
    }

    private func referenceLine(at y: CGFloat, width: CGFloat, color: Color) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 16, height: 2)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.cardSecondary)
        }
    }
}

private enum HistoryChartScale {
    static func niceCeiling(_ value: Double) -> Double {
        guard value > 0 else { return 22_000 }

        let thresholds: [Double] = [
            2_000, 4_000, 6_000, 8_000, 11_000, 13_000, 15_000, 17_000, 19_000, 22_000,
            50_000, 75_000, 100_000, 150_000, 200_000, 300_000, 500_000, 750_000, 1_000_000
        ]

        return thresholds.first(where: { $0 >= value }) ?? value
    }

    static func compactLabel(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return millions.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(millions))M"
                : String(format: "%.1fM", millions)
        }

        if value >= 1_000 {
            let thousands = value / 1_000
            return thousands.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(thousands))k"
                : String(format: "%.0fk", thousands)
        }

        return "\(Int(value))"
    }
}

#Preview {
    StepHistoryCard(
        periods: StepSummary.preview.weeklySteps.map { $0.toPeriodStats() },
        goal: 20_000,
        selectedRange: .constant(.week),
        onRangeChange: { _ in }
    )
    .padding()
    .background(AppTheme.background)
}
