import SwiftUI

/// Information screen explaining what Racepace is
struct WhatIsRacepaceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)

                    Text("What is Racepace?")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                // Welcome
                sectionView(title: "Welcome to Racepace") {
                    Text("Racepace is a vibe-code project from Drew, the head developer.")
                    Text("Bear with us as updates may be buggy and may not work on all devices.")
                    Text("We welcome feedback via the TestFlight process.")
                    Text("Race Pace takes inspiration from Zwift in cycling and Royalty Rowing online competitions.")
                    Text("It is built for kayak racers, coaches, and the wider UK paddling community.")
                }

                // Why Racepace
                sectionView(title: "Why Racepace?") {
                    Text("Don't wait for summer championships or winter race series to see how you stack up.")
                    Text("With Racepace, athletes can compare their Garmin-tracked sessions against the best racers and trainers in UK canoe clubs every week. Track your performance over time and enter competitive challenges that turn everyday paddling into meaningful racing.")
                    Text("Racepace isn't just about rankings \u{2014} it enables real competition.")

                    HStack(spacing: 8) {
                        Image(systemName: "sterlingsign.circle.fill")
                            .foregroundStyle(.accent)
                        Text("99% of all race entry fees become prize money.")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)

                    Text("Only 1% is retained by developers to maintain the platform.")
                        .foregroundStyle(.secondary)

                    Text("Train. Compare. Compete. Win.")
                        .font(.headline)
                        .foregroundStyle(.accent)
                        .padding(.top, 4)
                }

                // What is a Spectator?
                sectionView(title: "What is a Spectator?") {
                    Text("Join as a spectator to track your sessions versus others in the Racepace club room.")
                }

                // What is a Racer?
                sectionView(title: "What is a Racer?") {
                    Text("Join as a racer to enter races and compete for prize money.")
                    Text("Track your activities from your Garmin and race against others across the UK.")
                }
            }
            .padding(24)
        }
        .navigationTitle("About Racepace")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        WhatIsRacepaceView()
    }
}
