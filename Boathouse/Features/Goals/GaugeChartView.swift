import SwiftUI

/// Semi-circular gauge chart for goal progress.
/// Shows target time as the full arc, current best as the filled portion,
/// and 30-day average as a secondary marker.
struct GaugeChartView: View {
    let progressFraction: Double  // 0..1 (best vs target)
    let averageFraction: Double?  // 0..1 (avg vs target), optional
    let isGoalMet: Bool

    private let startAngle: Angle = .degrees(135)
    private let endAngle: Angle = .degrees(405)
    private let lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Track (background arc)
            arcPath(fraction: 1.0)
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress fill
            arcPath(fraction: min(progressFraction, 1.0))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Average marker (small dot on arc)
            if let avg = averageFraction, avg > 0 {
                averageMarker(fraction: min(avg, 1.0))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var progressColor: Color {
        if isGoalMet {
            return .green
        } else if progressFraction > 0.8 {
            return AppColors.accent
        } else if progressFraction > 0.5 {
            return .yellow
        } else {
            return Color(.systemGray3)
        }
    }

    private func arcPath(fraction: Double) -> Path {
        let sweep = endAngle.degrees - startAngle.degrees
        let end = Angle(degrees: startAngle.degrees + sweep * fraction)

        return Path { path in
            path.addArc(
                center: CGPoint(x: 0.5, y: 0.5),
                radius: 0.5 - lineWidth / 200,
                startAngle: startAngle,
                endAngle: end,
                clockwise: false
            )
        }
        .applying(CGAffineTransform(scaleX: 200, y: 200))
        .applying(CGAffineTransform(translationX: -100 + lineWidth / 2, y: -100 + lineWidth / 2))
        .offsetBy(dx: 100 - lineWidth / 2, dy: 100 - lineWidth / 2)
    }

    private func averageMarker(fraction: Double) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size / 2) - lineWidth / 2
            let sweep = endAngle.degrees - startAngle.degrees
            let angle = Angle(degrees: startAngle.degrees + sweep * fraction)
            let x = center.x + radius * cos(CGFloat(angle.radians))
            let y = center.y + radius * sin(CGFloat(angle.radians))

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.3), radius: 2)
                .position(x: x, y: y)
        }
    }
}

// Helper for Path offset
private extension Path {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> Path {
        applying(CGAffineTransform(translationX: dx, dy: dy))
    }
}
