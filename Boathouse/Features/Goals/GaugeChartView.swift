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
            ArcShape(
                startAngle: startAngle,
                endAngle: endAngle,
                lineWidth: lineWidth
            )
            .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress fill
            ArcShape(
                startAngle: startAngle,
                endAngle: progressEndAngle,
                lineWidth: lineWidth
            )
            .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Average marker (small dot on arc)
            if let avg = averageFraction, avg > 0 {
                averageMarker(fraction: min(avg, 1.0))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var progressEndAngle: Angle {
        let sweep: Double = endAngle.degrees - startAngle.degrees
        let clamped: Double = min(progressFraction, 1.0)
        return Angle(degrees: startAngle.degrees + sweep * clamped)
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

    private func averageMarker(fraction: Double) -> some View {
        GeometryReader { geo in
            let size: CGFloat = min(geo.size.width, geo.size.height)
            let cx: CGFloat = size / 2
            let cy: CGFloat = size / 2
            let r: CGFloat = (size / 2) - lineWidth / 2
            let sweep: Double = endAngle.degrees - startAngle.degrees
            let a: Double = (startAngle.degrees + sweep * fraction) * .pi / 180
            let x: CGFloat = cx + r * CGFloat(cos(a))
            let y: CGFloat = cy + r * CGFloat(sin(a))

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.3), radius: 2)
                .position(x: x, y: y)
        }
    }
}

// MARK: - Arc Shape

/// Draws a single arc stroke-path directly in its layout rect.
/// Replaces the old approach of building a Path in unit coords then chaining transforms.
private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) / 2 - lineWidth / 2

        var p = Path()
        p.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return p
    }
}
