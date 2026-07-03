import SwiftUI

struct WeeklyBarChart: View {
    let days: [DaySteps]
    let selectedDayID: Date
    let onSelectDay: (DaySteps) -> Void

    private let yLabels = ["22K", "19K", "17K", "15K", "13K", "11K", "8K", "6K", "4K", "2K"]
    private let maxSteps = 22_000.0
    private let dayLabelHeight: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let chartHeight = max(geo.size.height - dayLabelHeight - 8, 0)

            HStack(alignment: .bottom, spacing: 0) {
                yAxis(height: chartHeight)
                    .frame(width: 32)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(days) { day in
                        VStack(spacing: 8) {
                            bar(for: day, maxHeight: chartHeight, isSelected: day.id == selectedDayID)
                            Text(day.label)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(day.id == selectedDayID ? 1 : 0.85))
                                .frame(height: dayLabelHeight)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectDay(day)
                        }
                    }
                }
                .padding(.leading, 4)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
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

    private func bar(for day: DaySteps, maxHeight: CGFloat, isSelected: Bool) -> some View {
        let ratio = min(Double(day.steps) / maxSteps, 1.0)
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
}

#Preview {
    ZStack {
        AppTheme.blueGradient
            .ignoresSafeArea()
        WeeklyBarChart(
            days: StepSummary.preview.weeklySteps,
            selectedDayID: StepSummary.preview.weeklySteps.last!.id,
            onSelectDay: { _ in }
        )
        .padding()
    }
}
