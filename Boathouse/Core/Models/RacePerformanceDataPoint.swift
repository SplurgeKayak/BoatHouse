import Foundation

/// A single plot point for RacePerformanceChart.
struct RacePerformanceDataPoint: Identifiable {
    let id: String          // session id
    let date: Date
    let pacePerKm: TimeInterval   // seconds per km — lower = faster
}
