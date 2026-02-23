import SwiftUI
import UIKit

// MARK: - RawDog Design System

enum RawDog {

    // MARK: - Colors

    enum Colors {
        static let background = Color(hex: "000000")
        static let surface = Color(hex: "111111")
        static let surfaceElevated = Color(hex: "1A1A1A")
        static let accent = Color(hex: "E8F4FF")       // ice blue
        static let accentGlow = Color(hex: "A8D4FF")    // brighter ice blue
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "888888")
        static let destructive = Color(hex: "FF3B30")
        static let approved = Color(hex: "34C759")
        static let denied = Color(hex: "FF3B30")
        static let windowOpen = Color(hex: "34C759")
        static let windowClosed = Color(hex: "FF9500")
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 40, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .medium)
    }

    // MARK: - Corner Radius

    enum Radius {
        static let pill: CGFloat = 50
        static let card: CGFloat = 16
        static let small: CGFloat = 8
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
    }
}

// MARK: - Reusable View Components

extension RawDog {

    /// Primary pill button used throughout the app
    struct PillButton: View {
        let title: String
        var style: PillStyle = .primary
        let action: () -> Void

        enum PillStyle {
            case primary, secondary, destructive
        }

        var body: some View {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            } label: {
                Text(title)
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(fillColor)
                    .foregroundStyle(textColor)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: style == .secondary ? 2 : 0)
                    )
            }
            .padding(.horizontal, 32)
        }

        private var fillColor: Color {
            switch style {
            case .primary: Colors.accent
            case .secondary: Color.clear
            case .destructive: Colors.destructive
            }
        }

        private var textColor: Color {
            switch style {
            case .primary: Colors.background
            case .secondary: Colors.accent
            case .destructive: .white
            }
        }

        private var borderColor: Color {
            switch style {
            case .secondary: Colors.accent
            default: Color.clear
            }
        }
    }

    /// Dark card background used for dashboard sections
    struct Card<Content: View>: View {
        @ViewBuilder let content: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        }
    }

    /// Section header label
    struct SectionHeader: View {
        let title: String
        let icon: String

        var body: some View {
            Label(title, systemImage: icon)
                .font(Typography.caption2)
                .foregroundStyle(Colors.textSecondary)
                .textCase(.uppercase)
        }
    }

    /// Status badge (e.g. "Restricted", "Active")
    struct StatusBadge: View {
        let text: String
        let icon: String
        var color: Color = Colors.accent

        var body: some View {
            Label(text, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.15), in: Capsule())
        }
    }

    /// Card with subtle accent border glow
    struct GlowCard<Content: View>: View {
        var accentColor: Color = Colors.accent
        @ViewBuilder let content: () -> Content

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(accentColor.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

// MARK: - Tab Bar Appearance

extension RawDog {
    static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Colors.surface).withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(Colors.textSecondary)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Colors.textSecondary)]
        itemAppearance.selected.iconColor = UIColor(Colors.accent)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Colors.accent)]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
