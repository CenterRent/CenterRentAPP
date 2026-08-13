import SwiftUI

// MARK: - CRAvatar
public struct CRAvatar: View {
    let imageURL: String?
    let name: String
    let size: CGFloat
    let showStatus: Bool
    let status: CRStatusIndicator.Status

    public init(
        imageURL: String? = nil,
        name: String,
        size: CGFloat = CRSize.avatarMD,
        showStatus: Bool = false,
        status: CRStatusIndicator.Status = .offline
    ) {
        self.imageURL = imageURL; self.name = name; self.size = size
        self.showStatus = showStatus; self.status = status
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let urlString = imageURL, !urlString.isEmpty {
                    CRAvatarImage(urlString: urlString) { initialsView }
                } else {
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            if showStatus {
                CRStatusIndicator(status: status)
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(CRColor.Secondary.lighter)
                .overlay(Circle().stroke(CRColor.Secondary.default, lineWidth: 1.5))
            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundColor(CRColor.Secondary.darker)
        }
    }
}

// MARK: - Avatar Group (multiple avatars overlapping)
public struct CRAvatarGroup: View {
    let users: [(name: String, imageURL: String?)]
    let maxVisible: Int
    let size: CGFloat

    public init(
        users: [(name: String, imageURL: String?)],
        maxVisible: Int = 3,
        size: CGFloat = CRSize.avatarSM
    ) {
        self.users = users; self.maxVisible = maxVisible; self.size = size
    }

    public var body: some View {
        HStack(spacing: -(size * 0.3)) {
            ForEach(users.prefix(maxVisible).indices, id: \.self) { i in
                CRAvatar(imageURL: users[i].imageURL, name: users[i].name, size: size)
                    .overlay(Circle().stroke(CRColor.Surface.primary, lineWidth: 2))
                    .zIndex(Double(maxVisible - i))
            }
            if users.count > maxVisible {
                ZStack {
                    Circle()
                        .fill(CRColor.Neutral.n200)
                        .frame(width: size, height: size)
                        .overlay(Circle().stroke(CRColor.Surface.primary, lineWidth: 2))
                    Text("+\(users.count - maxVisible)")
                        .font(.system(size: size * 0.3, weight: .semibold))
                        .foregroundColor(CRColor.Text.secondary)
                }
            }
        }
    }
}
