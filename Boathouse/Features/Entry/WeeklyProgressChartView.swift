import SwiftUI

/// A custom scatter chart showing weekly best times for a selected distance.
struct WeeklyProgressChartView: View {
    let sessions: [Session]

    @State private var selectedDistance: RaceType = .fastest1km

    private var dataPoints: [(week: Int, timeSeconds: Double)] {
        let calendar = Calendar.current
        var byWeek: [Int: Double] = [:]

        for session in sessions {
            let weekOfYear = calendar.component(.weekOfYear, from: session.startDate)
            let time: TimeInterval?
            switch selectedDistance {
            case .fastest1km:  time = session.fastest1kmTime
            case .fastest5km:  time = session.fastest5kmTime
            case .fastest10km: time = session.fastest10kmTime
            }
            guard let t = time else { continue }
            // Keep the fastest (lowest) time per week
            if let existing = byWeek[weekOfYear] {
                byWeek[weekOfYear] = min(existing, t)
            } else {
                byWeek[weekOfYear] = t
            }
        }
        return byWeek.map { (week: $0.key, timeSeconds: $0.value) }
            .sorted { $0.week < $1.week }
    }

    private let yPadding: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Distance selector
            Picker("Distance", selection: $selectedDistance) {
                ForEach(RaceType.allCases) { type in
                    Text(type.shortName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if dataPoints.isEmpty {
                emptyChartView
            } else {
                chartView
                    .frame(height: 200)

                legendView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chart

    private var chartView: some View {
        GeometryReader { geometry in
            let width  = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 44

            let xRange = xAxisRange
            let yRange = yAxisRange

            let xScale = (xRange.1 == xRange.0) ? width - padding : (width - padding) / Double(xRange.1 - xRange.0)
            let yScale = (yRange.1 == yRange.0) ? height - yPadding : (height - yPadding) / Double(yRange.1 - yRange.0)

            func xPos(_ week: Int) -> CGFloat {
                padding + CGFloat(week - xRange.0) * xScale
            }
            func yPos(_ seconds: Double) -> CGFloat {
                // Invert: faster (lower seconds) = higher on chart
                height - CGFloat(seconds - yRange.0) * yScale
            }

            ZStack(alignment: .topLeading) {
                // Gridlines + Y labels
                ForEach(yTicks, id: \.self) { tick in
                    let y = yPos(tick)
                    Path { p in
                        p.move(to: CGPoint(x: padding, y: y))
                        p.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Text(formatTime(tick))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .position(x: padding / 2, y: y)
                }

                // Connecting line
                if dataPoints.count > 1 {
                    Path { p in
                        for (i, pt) in dataPoints.enumerated() {
                            let x = xPos(pt.week)
                            let y = yPos(pt.timeSeconds)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else       { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                }

                // Dots + X labels
                ForEach(dataPoints, id: \.week) { pt in
                    let x = xPos(pt.week)
                    let y = yPos(pt.timeSeconds)

                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)

                    Text("W\(pt.week)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .position(x: x, y: height)
                }
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                Text("Best Time (\(selectedDistance.shortName))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyChartView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No race data yet for \(selectedDistance.shortName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Axis helpers

    private var xAxisRange: (Int, Int) {
        guard let min = dataPoints.map(\.week).min(),
              let max = dataPoints.map(\.week).max() else { return (0, 52) }
        return (min, max == min ? min + 1 : max)
    }

    private var yAxisRange: (Double, Double) {
        guard let min = dataPoints.map(\.timeSeconds).min(),
              let max = dataPoints.map(\.timeSeconds).max() else { return (0, 600) }
        let padding = (max - min) * 0.15
        return (max(0, min - padding), max + padding)
    }

    private var yTicks: [Double] {
        let (lo, hi) = yAxisRange
        let range = hi - lo
        guard range > 0 else { return [lo] }
        let step = max(10.0, (range / 4.0).rounded(.up))
        var ticks: [Double] = []
        var t = (lo / step).rounded(.up) * step
        while t <= hi {
            ticks.append(t)
            t += step
        }
        return ticks.isEmpty ? [lo, hi] : ticks
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    WeeklyProgressChartView(sessions: MockData.sessions.filter { $0.userId == "andy-001" })
        .padding()
}
