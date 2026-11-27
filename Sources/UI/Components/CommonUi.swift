import SwiftUI

/// The wordmark/logo used on headers and splash (from the asset catalog).
struct BrandTitle: View {
    var height: CGFloat = 40
    var body: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Hot Smarters Player")
    }
}

struct EmptyStateView: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        VStack {
            Text(text).foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A 2:3 poster tile with a name gradient footer; focus/press pops it with a crimson ring.
struct PosterCard: View {
    let item: VodItem
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(url: item.poster, contentMode: .fill) {
                    ZStack {
                        Color.darkSurface2
                        Text(String(item.name.prefix(1)).uppercased())
                            .font(.largeTitle)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .aspectRatio(0.66, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)

                Text(item.name)
                    .lineLimit(2)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.hotRed, lineWidth: pressed ? 3 : 0)
            )
            .scaleEffect(pressed ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

/// Styled search field matching the Android `SearchField`.
struct SearchField: View {
    @Binding var query: String
    var hint: String = "Search"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.textSecondary)
            TextField(hint, text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.dividerColor, lineWidth: 1))
    }
}
