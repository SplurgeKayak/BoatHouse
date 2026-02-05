import SwiftUI

/// Progress bar showing segments for each story page (like Instagram Stories)
struct StoryProgressBarView: View {
    let totalCount: Int
    let currentIndex: Int
    let progress: Double // 0.0 to 1.0 for current segment

    private let segmentHeight: CGFloat = 3
    private let segmentSpacing: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: segmentSpacing) {
                ForEach(0..<totalCount, id: \.self) { index in
                    segmentView(for: index, totalWidth: geometry.size.width)
                }
            }
        }
        .frame(height: segmentHeight)
    }

    private func segmentView(for index: Int, totalWidth: CGFloat) -> some View {
        let segmentCount = CGFloat(totalCount)
        let totalSpacing = segmentSpacing * (segmentCount - 1)
        let segmentWidth = (totalWidth - totalSpacing) / segmentCount

        return ZStack(alignment: .leading) {
            // Background (empty segment)
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: segmentWidth, height: segmentHeight)

            // Filled portion
            Capsule()
                .fill(Color.white)
                .frame(width: fillWidth(for: index, segmentWidth: segmentWidth), height: segmentHeight)
        }
    }

    private func fillWidth(for index: Int, segmentWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            // Completed segments
            return segmentWidth
        } else if index == currentIndex {
            // Current segment - partially filled based on progress
            return segmentWidth * progress
        } else {
            // Future segments
            return 0
        }
    }
}

#Preview {
    ZStack {
        Color.black

        VStack(spacing: 40) {
            // First page, no progress
            StoryProgressBarView(totalCount: 5, currentIndex: 0, progress: 0.0)
                .padding(.horizontal)

            // First page, half progress
            StoryProgressBarView(totalCount: 5, currentIndex: 0, progress: 0.5)
                .padding(.horizontal)

            // Third page, some progress
            StoryProgressBarView(totalCount: 5, currentIndex: 2, progress: 0.7)
                .padding(.horizontal)

            // Last page, full progress
            StoryProgressBarView(totalCount: 5, currentIndex: 4, progress: 1.0)
                .padding(.horizontal)

            // Single page
            StoryProgressBarView(totalCount: 1, currentIndex: 0, progress: 0.5)
                .padding(.horizontal)
        }
    }
}
