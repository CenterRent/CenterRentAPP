import SwiftUI

// MARK: - CRNavigationHeader
/// Reusable navigation header bar for views that don't use NavigationStack titles
struct CRNavigationHeader: View {
    let title: String
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            if let back = onBack {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(CRColor.Text.primary)
                }
            }
            Spacer()
            Text(title)
                .font(.crHeading4)
                .foregroundColor(CRColor.Text.primary)
            Spacer()
            if let trailing = trailing {
                trailing
            } else if onBack != nil {
                // Invisible spacer to center the title
                Image(systemName: "chevron.left").opacity(0)
            }
        }
        .padding(.horizontal, CRSpacing.base)
        .padding(.vertical, CRSpacing.md)
        .background(CRColor.Surface.primary)
        .overlay(Divider(), alignment: .bottom)
    }
}
