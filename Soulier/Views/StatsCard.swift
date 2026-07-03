import SwiftUI

struct StatsCard: View {
    let day: DaySteps
    @Binding var selectedTimeframe: Timeframe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Period", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.title).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 28)

            Text(formattedSteps(day.steps))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: day.id)

            Text("Steps • \(day.subtitle)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.2), value: day.id)

            HStack {
                metric(value: formattedDistance(day.distanceKm), label: "Distance")
                Spacer()
                metric(value: "\(day.calories) kcal", label: "Calories")
                Spacer()
                metric(value: "\(day.floors)", label: "Floors")
            }
            .animation(.easeInOut(duration: 0.2), value: day.id)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 88)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 40,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 40,
                style: .continuous
            )
            .fill(AppTheme.cardBackground)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func formattedSteps(_ steps: Int) -> String {
        Formatters.englishNumber.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    private func formattedDistance(_ km: Double) -> String {
        let value = Formatters.englishDecimal.string(from: NSNumber(value: km)) ?? String(format: "%.2f", km)
        return "\(value) km"
    }
}

#Preview {
    StatsCard(
        day: StepSummary.preview.weeklySteps.last!,
        selectedTimeframe: .constant(.day)
    )
}
