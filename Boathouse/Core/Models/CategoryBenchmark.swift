import Foundation

/// Represents a category-average pace benchmark used as the ranking line on the chart.
struct CategoryBenchmark {
    let categoryName: String       // e.g. "Senior Men"
    let averagePacePerKm: TimeInterval  // seconds/km
}
