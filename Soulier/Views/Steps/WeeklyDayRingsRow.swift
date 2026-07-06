import SwiftUI

struct WeeklyDayRingsRow: View {
    let days: [DaySteps]
    let goal: Int
    let selectedDayID: Date?
    let onSelectDay: (DaySteps) -> Void

    private let ringSize: CGFloat = 34
    private let ringLineWidth: CGFloat = 6

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                dayColumn(day)
                    .frame(maxWidth: .infinity)
                    .onTapGesture { onSelectDay(day) }
            }
        }
    }

    private func dayColumn(_ day: DaySteps) -> some View {
        let isSelected = isDaySelected(day)

        return VStack(spacing: 8) {
            Text(day.dayInitial)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.background : AppTheme.primaryText)
                .frame(width: 28, height: 28)
                .background(Circle().fill(isSelected ? AppTheme.primaryText : .clear))

            ZStack {
                ArcRing(
                    steps: day.steps,
                    goal: goal,
                    lineWidth: ringLineWidth,
                    size: ringSize,
                    showsGoalMarker: goal > 0
                )

                if day.steps > 0 {
                    Text(Formatters.compactSteps(day.steps))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                }
            }
            .frame(width: ringSize, height: ringSize)
        }
    }

    private func isDaySelected(_ day: DaySteps) -> Bool {
        if let selectedDayID {
            return Calendar.current.isDate(selectedDayID, inSameDayAs: day.date)
        }
        return day.isToday
    }
}

struct WeekDaysPager: View {
    let weeks: [[DaySteps]]
    let goal: Int
    let selectedDayID: Date?
    let onSelectDay: (DaySteps) -> Void

    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                WeeklyDayRingsRow(
                    days: week,
                    goal: goal,
                    selectedDayID: selectedDayID,
                    onSelectDay: onSelectDay
                )
                .padding(.horizontal, 20)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 76)
        .onAppear {
            currentPage = max(weeks.count - 1, 0)
        }
        .onChange(of: weeks.count) { _, count in
            currentPage = max(count - 1, 0)
        }
    }
}

#Preview {
    WeekDaysPager(
        weeks: [StepSummary.preview.weeklySteps],
        goal: 20_000,
        selectedDayID: nil,
        onSelectDay: { _ in }
    )
    .padding()
    .background(AppTheme.background)
}
