import SwiftUI

/// Full-screen detail sheet for an external news item.
struct NewsDetailView: View {
    let item: ExternalNewsItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Source badge
                    HStack(spacing: 6) {
                        Image(systemName: item.source.iconName)
                            .font(.caption)
                            .foregroundStyle(item.source.accentColor)

                        Text(item.source.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(item.source.accentColor)

                        Spacer()

                        Text(Self.dateFormatter.string(from: item.publishedAt))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.source.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Full title
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Divider()

                    // Full body / snippet
                    Text(item.snippet)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let url = item.link {
                        Button {
                            openURL(url)
                        } label: {
                            Label(Strings.Feed.readMore, systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle(item.source.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
