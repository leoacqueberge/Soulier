import SwiftUI

enum RingArcMetrics {
    static let startFraction: CGFloat = 0.10
    static let lengthFraction: CGFloat = 0.80
    static let goalFillFraction: Double = 2.0 / 3.0
    static let rotationDegrees: Double = 90
    private static let knobStartFraction: Double = 0.75

    static var trackEndFraction: CGFloat {
        startFraction + lengthFraction
    }

    static var goalMarkerFraction: CGFloat {
        startFraction + lengthFraction * CGFloat(goalFillFraction)
    }

    static func progressEndFraction(steps: Int, goal: Int) -> CGFloat {
        guard goal > 0 else { return startFraction }

        let ratio = Double(steps) / Double(goal)
        let fillOfArc: Double

        if ratio <= 1 {
            fillOfArc = ratio * goalFillFraction
        } else {
            let overflow = min(ratio - 1, 1)
            fillOfArc = goalFillFraction + overflow * (1 - goalFillFraction)
        }

        return startFraction + lengthFraction * fillOfArc
    }

    static func rotation(forFraction fraction: CGFloat) -> Angle {
        let degrees = Double(fraction) * 360 + rotationDegrees - knobStartFraction * 360
        return .degrees(degrees)
    }

    static func knobRotation(steps: Int, goal: Int) -> Angle {
        rotation(forFraction: progressEndFraction(steps: steps, goal: goal))
    }

    static var goalMarkerRotation: Angle {
        rotation(forFraction: goalMarkerFraction)
    }
}

struct ArcRing: View {
    let steps: Int
    let goal: Int
    let lineWidth: CGFloat
    let size: CGFloat
    var showsKnob: Bool = false
    var showsGoalMarker: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: RingArcMetrics.startFraction, to: RingArcMetrics.trackEndFraction)
                .stroke(AppTheme.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(RingArcMetrics.rotationDegrees))

            Circle()
                .trim(from: RingArcMetrics.startFraction, to: RingArcMetrics.progressEndFraction(steps: steps, goal: goal))
                .stroke(AppTheme.ringProgress, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(RingArcMetrics.rotationDegrees))

            if showsGoalMarker, goal > 0 {
                ringKnob
                    .offset(y: -size / 2)
                    .rotationEffect(RingArcMetrics.goalMarkerRotation)
            }

            if showsKnob, steps > 0 {
                ringKnob
                    .offset(y: -size / 2)
                    .rotationEffect(RingArcMetrics.knobRotation(steps: steps, goal: goal))
            }
        }
        .frame(width: size, height: size)
    }

    private var ringKnob: some View {
        let borderWidth = lineWidth * 0.44

        return ZStack {
            Circle()
                .fill(AppTheme.background)
                .frame(width: lineWidth + borderWidth * 2, height: lineWidth + borderWidth * 2)

            Circle()
                .fill(AppTheme.ringTrack)
                .frame(width: lineWidth, height: lineWidth)
        }
    }
}
