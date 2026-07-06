import SwiftUI

struct TodayHourlyChart: View {
    let hourlySteps: [HourlySteps]
    let date: Date

    private let axisHours = [3, 6, 9, 12, 15, 18, 21]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(Formatters.todayTitle(date))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.cardTitle)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.cardSecondary)
            }

            chart
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardBackground)
        }
    }

    private var chart: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - 28
            let chartWidth = geo.size.width - 36
            let maxSteps = max(Double(hourlySteps.map(\.steps).max() ?? 0), 5000)
            let currentHour = Calendar.current.component(.hour, from: .now)
            let currentX = chartWidth * CGFloat(currentHour) / 24

            ZStack(alignment: .bottomLeading) {
                ForEach(0..<5, id: \.self) { index in
                    let y = chartHeight * CGFloat(index) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: chartWidth, y: y))
                    }
                    .stroke(AppTheme.chartGrid, lineWidth: 1)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        let steps = hourlySteps.first(where: { $0.hour == hour })?.steps ?? 0
                        let ratio = CGFloat(steps) / CGFloat(maxSteps)
                        let barWidth = max(chartWidth / 24 - 1, 1)

                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(AppTheme.chartBar)
                            .frame(width: barWidth, height: max(ratio * chartHeight, steps > 0 ? 4 : 0))
                            .frame(width: chartWidth / 24, alignment: .center)
                    }
                }

                if Calendar.current.isDateInToday(date) {
                    Path { path in
                        path.move(to: CGPoint(x: currentX, y: 0))
                        path.addLine(to: CGPoint(x: currentX, y: chartHeight))
                    }
                    .stroke(AppTheme.currentIndicator, lineWidth: 1.5)

                    Circle()
                        .fill(AppTheme.currentIndicator)
                        .frame(width: 6, height: 6)
                        .offset(x: currentX - 3, y: chartHeight)
                }

                HStack(spacing: 0) {
                    ForEach(axisHours, id: \.self) { hour in
                        axisLabel(for: hour)
                            .frame(width: chartWidth / CGFloat(axisHours.count), alignment: .center)
                    }
                }
                .offset(y: chartHeight + 8)

                VStack(alignment: .trailing, spacing: 0) {
                    ForEach((0...4).reversed(), id: \.self) { index in
                        Text("\(Int(maxSteps * Double(index) / 4))")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.cardSecondary)
                            .frame(height: chartHeight / 4, alignment: .top)
                    }
                }
                .frame(width: 32)
                .offset(x: chartWidth + 4)
            }
        }
        .frame(height: 144)
    }

    @ViewBuilder
    private func axisLabel(for hour: Int) -> some View {
        if hour == 12 {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.cardSecondary)
        } else {
            Text("\(hour)")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.cardSecondary)
        }
    }
}

#Preview {
    TodayHourlyChart(hourlySteps: HourlySteps.preview, date: .now)
        .padding()
        .background(AppTheme.background)
}
