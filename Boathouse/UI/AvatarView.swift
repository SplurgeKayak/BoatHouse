import SwiftUI

/// Reusable circular avatar with async image loading and deterministic placeholder
struct AvatarView: View {
    let url: URL?
    let initials: String
    let id: String
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(initials) avatar")
    }

    private var placeholderView: some View {
        Circle()
            .fill(backgroundColor)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.32, weight: .semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
            }
    }

    private var backgroundColor: Color {
        let colors: [Color] = [
            .blue, .purple, .green, .orange, .pink, .teal, .indigo
        ]
        // Stable hash: sum of unicode scalar values (deterministic across launches)
        let hash = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return colors[abs(hash) % colors.count]
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(url: nil, initials: "JW", id: "user-001", size: 68)
        AvatarView(url: nil, initials: "SC", id: "user-002", size: 44)
        AvatarView(url: nil, initials: "MJ", id: "user-003", size: 36)
    }
    .padding()
}
