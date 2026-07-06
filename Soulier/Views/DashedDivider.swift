import SwiftUI

struct DashedDivider: View {
    var color: Color = .white.opacity(0.35)
    var dash: [CGFloat] = [3, 4]
    var lineWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: lineWidth / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: lineWidth / 2))
            }
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, dash: dash)
            )
        }
        .frame(height: lineWidth)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        DashedDivider()
            .padding(.horizontal, 24)
    }
}
