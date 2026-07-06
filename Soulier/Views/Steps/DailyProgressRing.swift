import SwiftUI

struct DailyProgressRing: View {
    let steps: Int
    let goal: Int

    private let ringSize: CGFloat = 220
    private let lineWidth: CGFloat = 24 * 1.05

    private var percent: Int {
        guard goal > 0 else { return 0 }
        return Int((Double(steps) / Double(goal)) * 100)
    }

    private var gapLabelOffsetY: CGFloat {
        ringSize / 2 - lineWidth * 0.65
    }

    var body: some View {
        ZStack {
            ArcRing(
                steps: steps,
                goal: goal,
                lineWidth: lineWidth,
                size: ringSize,
                showsGoalMarker: true
            )

            Text(Formatters.steps(steps))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 28)

            Text("\(percent)% / \(Formatters.compactSteps(goal))")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .offset(y: gapLabelOffsetY)
        }
        .frame(width: ringSize, height: 200)
    }
}

#Preview {
    DailyProgressRing(steps: 4258, goal: 20_000)
        .padding()
        .background(AppTheme.background)
}
