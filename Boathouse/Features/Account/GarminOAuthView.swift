import SwiftUI

struct GarminOAuthView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)

                Text("Connect Garmin")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Garmin integration coming soon. Your canoe and kayak sessions will be automatically imported once connected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Garmin Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
