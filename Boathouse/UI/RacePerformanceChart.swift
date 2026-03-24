import SwiftUI

// MARK: - RacePerformanceChart

/// A fully-featured race performance chart replicating Strava's "Matched Runs" style.
/// - Background: dark navy (Color.darkBackground)
/// - Main line/dots: Strava orange (Color.darkTitleText)
/// - Trend line: white 60% opacity, dashed
/// - Goal line: green 80% opacity, dashed
/// - Benchmark line: cyan 80% opacity, dashed
struct RacePerformanceChart: View {
    let distanceLabel: String
    let dataPoints: [RacePerformanceDataPoint]   // sorted oldest → newest
    let goalPace: TimeInterval?
    let categoryBenchmark: CategoryBenchmark?

    // Tap state
    @State private var selectedIndex: Int? = nil
    @State private var tooltipOffset: CGFloat = 0

    // Layout constants
    private let yAxisWidth: CGFloat = 52
    private let xAxisHeight: CGFloat = 20
    private let padding: Double = 0.08   // 8% buffer above/below

    var body: some View {
        ZStack {
            Color.darkBackground
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if dataPoints.isEmpty {
                Text("No sessions for \(distanceLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let plotW = geo.size.width - yAxisWidth
                        let plotH = geo.size.height - xAxisHeight
                        let yRange = computeYRange()
                        let minY = yRange.min
                        let maxY = yRange.max

                        ZStack(alignment: .topLeading) {
                            // Y-axis labels
                            yAxisLabels(plotH: plotH, minY: minY, maxY: maxY)
                                .frame(width: yAxisWidth)

                            // Plot area (shifted right of y-axis)
                            ZStack {
                                // Grid lines
                                gridLines(plotW: plotW, plotH: plotH)

                                // Goal line
                                if let gp = goalPace {
                                    overlayLine(
                                        pace: gp,
                                        color: Color.green.opacity(0.8),
                                        dash: [8, 4],
                                        plotW: plotW,
                                        plotH: plotH,
                                        minY: minY,
                                        maxY: maxY
                                    )
                                }

                                // Benchmark line
                                if let bm = categoryBenchmark {
                                    overlayLine(
                                        pace: bm.averagePacePerKm,
                                        color: Color.cyan.opacity(0.8),
                                        dash: [4, 4],
                                        plotW: plotW,
                                        plotH: plotH,
                                        minY: minY,
                                        maxY: maxY
                                    )
                                }

                                // Trend line
                                trendLine(plotW: plotW, plotH: plotH, minY: minY, maxY: maxY)

                                // Main session line
                                if dataPoints.count > 1 {
                                    mainLine(plotW: plotW, plotH: plotH, minY: minY, maxY: maxY)
                                }

                                // Session dots
                                sessionDots(plotW: plotW, plotH: plotH, minY: minY, maxY: maxY)

                                // Tooltip
                                if let idx = selectedIndex {
                                    tooltip(
                                        index: idx,
                                        plotW: plotW,
                                        plotH: plotH,
                                        minY: minY,
                                        maxY: maxY
                                    )
                                }
                            }
                            .offset(x: yAxisWidth)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        selectedIndex = nearestIndex(x: x, plotW: plotW)
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            selectedIndex = nil
                                        }
                                    }
                            )

                            // X-axis labels (beneath plot area)
                            xAxisLabels(plotW: plotW, plotH: plotH)
                                .offset(x: yAxisWidth)
                        }
                    }
                    .padding(.vertical, 8)

                    // Legend
                    legendRow
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                }
            }
        }
    }

    // MARK: - Y Range

    private func computeYRange() -> (min: Double, max: Double) {
        var allPaces = dataPoints.map(\.pacePerKm)
        if let gp = goalPace { allPaces.append(gp) }
        if let bm = categoryBenchmark { allPaces.append(bm.averagePacePerKm) }

        let rawMin = allPaces.min() ?? 0
        let rawMax = allPaces.max() ?? 1
        let span = rawMax - rawMin
        let buf = span * padding
        return (min: rawMin - buf, max: rawMax + buf)
    }

    // MARK: - Y / X Position Helpers

    private func yPos(pace: Double, minY: Double, maxY: Double, height: CGFloat) -> CGFloat {
        guard maxY > minY else { return height / 2 }
        // Fastest (lowest pace) → top (small y). Slowest → bottom (large y).
        let ratio = CGFloat((pace - minY) / (maxY - minY))
        return height * ratio
    }

    private func xPos(index: Int, plotW: CGFloat) -> CGFloat {
        let count = dataPoints.count
        guard count > 1 else { return plotW / 2 }
        return plotW * CGFloat(index) / CGFloat(count - 1)
    }

    // MARK: - Grid Lines

    private func gridLines(plotW: CGFloat, plotH: CGFloat) -> some View {
        let lineCount = 4
        return ZStack {
            ForEach(0..<lineCount, id: \.self) { i in
                let y = plotH * CGFloat(i) / CGFloat(lineCount - 1)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: plotW, y: y))
                }
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
        }
    }

    // MARK: - Overlay Lines (goal, benchmark)

    private func overlayLine(
        pace: Double,
        color: Color,
        dash: [CGFloat],
        plotW: CGFloat,
        plotH: CGFloat,
        minY: Double,
        maxY: Double
    ) -> some View {
        let y = yPos(pace: pace, minY: minY, maxY: maxY, height: plotH)
        return Path { p in
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: plotW, y: y))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: dash))
    }

    // MARK: - Trend Line

    @ViewBuilder
    private func trendLine(plotW: CGFloat, plotH: CGFloat, minY: Double, maxY: Double) -> some View {
        if let reg = GoalProgressCalculator.linearRegression(points: dataPoints) {
            let y0 = yPos(
                pace: reg.slope * 0 + reg.intercept,
                minY: minY, maxY: maxY, height: plotH
            )
            let y1 = yPos(
                pace: reg.slope * Double(dataPoints.count - 1) + reg.intercept,
                minY: minY, maxY: maxY, height: plotH
            )
            Path { p in
                p.move(to: CGPoint(x: 0, y: y0))
                p.addLine(to: CGPoint(x: plotW, y: y1))
            }
            .stroke(
                Color.white.opacity(0.6),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
        } else if dataPoints.count == 1 {
            // Single point: flat horizontal trend at that value
            let y = yPos(pace: dataPoints[0].pacePerKm, minY: minY, maxY: maxY, height: plotH)
            Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: plotW, y: y))
            }
            .stroke(
                Color.white.opacity(0.6),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
        }
    }

    // MARK: - Main Session Line

    private func mainLine(plotW: CGFloat, plotH: CGFloat, minY: Double, maxY: Double) -> some View {
        Path { p in
            for (i, pt) in dataPoints.enumerated() {
                let x = xPos(index: i, plotW: plotW)
                let y = yPos(pace: pt.pacePerKm, minY: minY, maxY: maxY, height: plotH)
                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                else { p.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
        .stroke(Color.darkTitleText.opacity(0.7), lineWidth: 2)
    }

    // MARK: - Session Dots

    private func sessionDots(plotW: CGFloat, plotH: CGFloat, minY: Double, maxY: Double) -> some View {
        ZStack {
            ForEach(Array(dataPoints.enumerated()), id: \.element.id) { idx, pt in
                let x = xPos(index: idx, plotW: plotW)
                let y = yPos(pace: pt.pacePerKm, minY: minY, maxY: maxY, height: plotH)
                let isSelected = selectedIndex == idx
                Circle()
                    .fill(Color.darkTitleText)
                    .frame(width: isSelected ? 10 : 6, height: isSelected ? 10 : 6)
                    .position(x: x, y: y)
            }
        }
    }

    // MARK: - Y-Axis Labels

    private func yAxisLabels(plotH: CGFloat, minY: Double, maxY: Double) -> some View {
        let labelCount = 4
        return ZStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let ratio = Double(i) / Double(labelCount - 1)
                // ratio 0 = top (fastest), 1 = bottom (slowest)
                let pace = minY + ratio * (maxY - minY)
                let y = plotH * CGFloat(ratio)
                Text(formatPace(pace))
                    .font(.system(size: 9))
                    .foregroundStyle(Color.darkBodyText.opacity(0.7))
                    .frame(width: yAxisWidth - 4, alignment: .trailing)
                    .position(x: (yAxisWidth - 4) / 2, y: y)
            }
        }
    }

    // MARK: - X-Axis Labels

    private func xAxisLabels(plotW: CGFloat, plotH: CGFloat) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        let maxLabels = 5
        let step = max(1, dataPoints.count / maxLabels)
        let indices = stride(from: 0, to: dataPoints.count, by: step).map { $0 }

        return ZStack {
            ForEach(indices, id: \.self) { i in
                let x = xPos(index: i, plotW: plotW)
                Text(formatter.string(from: dataPoints[i].date))
                    .font(.system(size: 9))
                    .foregroundStyle(Color.darkBodyText.opacity(0.7))
                    .position(x: x, y: plotH + xAxisHeight / 2)
            }
        }
    }

    // MARK: - Tooltip

    private func tooltip(index: Int, plotW: CGFloat, plotH: CGFloat, minY: Double, maxY: Double) -> some View {
        let pt = dataPoints[index]
        let x = xPos(index: index, plotW: plotW)
        let y = yPos(pace: pt.pacePerKm, minY: minY, maxY: maxY, height: plotH)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"

        let bestPace = dataPoints.map(\.pacePerKm).min() ?? pt.pacePerKm
        let pbDelta = pt.pacePerKm - bestPace

        var lines: [String] = [
            dateFormatter.string(from: pt.date),
            "\(formatPace(pt.pacePerKm)) /km"
        ]

        if let gp = goalPace {
            let diff = pt.pacePerKm - gp
            if diff < 0 {
                lines.append("\(formatSeconds(-diff)) faster than goal")
            } else {
                lines.append("\(formatSeconds(diff)) behind goal")
            }
        }

        if pbDelta > 0 {
            lines.append("\(formatSeconds(pbDelta)) behind PB")
        } else {
            lines.append("Personal best!")
        }

        let tooltipWidth: CGFloat = 160
        let clampedX = min(max(x, tooltipWidth / 2), plotW - tooltipWidth / 2)
        let tooltipY = y > plotH / 2 ? y - 80 : y + 20

        return VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.darkBodyText)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.3))
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        )
        .frame(width: tooltipWidth, alignment: .leading)
        .position(x: clampedX, y: tooltipY)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 14) {
            LegendItem(color: Color.darkTitleText, label: "Sessions", dashed: false)
            LegendItem(color: Color.white.opacity(0.6), label: "Trend", dashed: true)
            if goalPace != nil {
                LegendItem(color: Color.green.opacity(0.8), label: "Goal", dashed: true)
            }
            if let bm = categoryBenchmark {
                LegendItem(color: Color.cyan.opacity(0.8), label: bm.categoryName, dashed: true)
            }
            Spacer()
        }
    }

    // MARK: - Tap Handling

    private func nearestIndex(x: CGFloat, plotW: CGFloat) -> Int {
        let count = dataPoints.count
        guard count > 1 else { return 0 }
        let step = plotW / CGFloat(count - 1)
        let raw = Int((x / step).rounded())
        return min(max(raw, 0), count - 1)
    }

    // MARK: - Formatters

    private func formatPace(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func formatSeconds(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded()))
        if s >= 60 {
            return String(format: "%dm %02ds", s / 60, s % 60)
        }
        return "\(s)s"
    }
}

// MARK: - LegendItem

private struct LegendItem: View {
    let color: Color
    let label: String
    let dashed: Bool

    var body: some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 6, height: 2)
                    }
                }
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.darkBodyText.opacity(0.8))
        }
    }
}

#Preview {
    let now = Date()
    let points = (0..<10).map { i -> RacePerformanceDataPoint in
        let date = Calendar.current.date(byAdding: .day, value: -((9 - i) * 7), to: now)!
        let pace = 280.0 - Double(i) * 3 + Double.random(in: -5...5)
        return RacePerformanceDataPoint(id: "s-\(i)", date: date, pacePerKm: pace)
    }
    RacePerformanceChart(
        distanceLabel: "1 km",
        dataPoints: points,
        goalPace: 270,
        categoryBenchmark: CategoryBenchmark(categoryName: "Senior Men", averagePacePerKm: 290)
    )
    .frame(height: 260)
    .padding()
    .background(Color.darkBackground)
}
