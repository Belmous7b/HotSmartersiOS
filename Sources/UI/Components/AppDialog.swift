import SwiftUI

/// A single, polished dialog shell used by every pop-up in the app so they all
/// share the same rounded glass card, title and action-button styling.
/// Mirrors the Android `AppDialog`.
struct AppDialogCard<DialogBody: View>: View {
    let title: String
    var icon: String? = nil
    var confirmText: String? = nil
    var onConfirm: (() -> Void)? = nil
    var confirmEnabled: Bool = true
    var dismissText: String? = "Close"
    var onDismissClick: (() -> Void)? = nil
    let onDismiss: () -> Void
    let content: () -> DialogBody

    init(title: String, icon: String? = nil, confirmText: String? = nil,
         onConfirm: (() -> Void)? = nil, confirmEnabled: Bool = true,
         dismissText: String? = "Close", onDismissClick: (() -> Void)? = nil,
         onDismiss: @escaping () -> Void, @ViewBuilder content: @escaping () -> DialogBody) {
        self.title = title
        self.icon = icon
        self.confirmText = confirmText
        self.onConfirm = onConfirm
        self.confirmEnabled = confirmEnabled
        self.dismissText = dismissText
        self.onDismissClick = onDismissClick
        self.onDismiss = onDismiss
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).foregroundStyle(Color.hotRed) }
                Text(title).font(.title3.bold()).foregroundStyle(.white)
            }
            .padding(.bottom, 14)

            // Hug the content (short dialogs stay small); only scroll when the
            // content would exceed the cap. The `fixedSize` stops the ScrollView
            // from greedily eating vertical space.
            ScrollView {
                VStack(alignment: .leading, spacing: 6) { content() }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 340)
            .fixedSize(horizontal: false, vertical: true)

            if confirmText != nil || dismissText != nil {
                HStack {
                    Spacer()
                    if let dismissText {
                        Button(dismissText) { (onDismissClick ?? onDismiss)() }
                            .foregroundStyle(Color.textSecondary)
                    }
                    if let confirmText, let onConfirm {
                        Button(action: onConfirm) {
                            Text(confirmText).fontWeight(.bold).foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.hotRed.opacity(confirmEnabled ? 1 : 0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(!confirmEnabled)
                        .padding(.leading, 10)
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .glass(cornerRadius: 18, alpha: 0.80)
        .padding(.horizontal, 24)
    }
}

/// A styled single-choice list dialog (label shown, value stored).
struct AppOptionDialog: View {
    let title: String
    let options: [(label: String, value: String)]
    let current: String
    let onDismiss: () -> Void
    let onSelect: (String) -> Void

    var body: some View {
        AppDialogCard(title: title, dismissText: tr("Close"), onDismiss: onDismiss) {
            ForEach(options, id: \.value) { opt in
                AppRadioRow(selected: opt.value == current, label: opt.label) { onSelect(opt.value) }
            }
        }
    }
}

struct AppRadioRow: View {
    let selected: Bool
    let label: String
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Color.hotRed : Color.dividerColor)
                Text(label)
                    .foregroundStyle(selected ? Color.hotRed : .white)
                    .fontWeight(selected ? .semibold : .regular)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 12)
            .background(selected ? Color.hotRed.opacity(0.12) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dialog host overlay modifiers

extension View {
    /// Presents a centered glass dialog over a dimmed, tap-to-dismiss backdrop.
    func appDialog<C: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> C) -> some View {
        overlay {
            if isPresented.wrappedValue {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                        .onTapGesture { isPresented.wrappedValue = false }
                    content()
                }
                .transition(.opacity)
            }
        }
    }

    /// Item-driven variant (dialog shows while the bound optional is non-nil).
    func appDialog<Item, C: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> C) -> some View {
        overlay {
            if let value = item.wrappedValue {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                        .onTapGesture { item.wrappedValue = nil }
                    content(value)
                }
                .transition(.opacity)
            }
        }
    }
}
