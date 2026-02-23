import SwiftUI
import UIKit
import Combine

// MARK: - Device Size Classification

enum DeviceSize {
    case compact   // < 375pt (iPhone SE)
    case regular   // < 430pt (standard iPhones)
    case large     // >= 430pt (Pro Max, Plus)

    init(width: CGFloat) {
        if width < 375 {
            self = .compact
        } else if width < 430 {
            self = .regular
        } else {
            self = .large
        }
    }
}

// MARK: - Responsive Metrics

struct ResponsiveMetrics: Equatable {
    let deviceSize: DeviceSize
    let mascotSize: CGFloat
    let horizontalPadding: CGFloat
    let isKeyboardVisible: Bool
    let safeAreaInsets: EdgeInsets

    init(
        deviceSize: DeviceSize = .regular,
        isKeyboardVisible: Bool = false,
        safeAreaInsets: EdgeInsets = EdgeInsets()
    ) {
        self.deviceSize = deviceSize
        self.isKeyboardVisible = isKeyboardVisible
        self.safeAreaInsets = safeAreaInsets

        switch deviceSize {
        case .compact:
            mascotSize = 80
            horizontalPadding = 16
        case .regular:
            mascotSize = 100
            horizontalPadding = 20
        case .large:
            mascotSize = 120
            horizontalPadding = 24
        }
    }

    func scaled(_ value: CGFloat) -> CGFloat {
        switch deviceSize {
        case .compact: value * 0.85
        case .regular: value
        case .large: value * 1.1
        }
    }
}

// MARK: - Environment Key

private struct ResponsiveMetricsKey: EnvironmentKey {
    static let defaultValue = ResponsiveMetrics()
}

extension EnvironmentValues {
    var responsiveMetrics: ResponsiveMetrics {
        get { self[ResponsiveMetricsKey.self] }
        set { self[ResponsiveMetricsKey.self] = newValue }
    }
}

// MARK: - Root Modifier

private struct ResponsiveRootModifier: ViewModifier {
    @State private var isKeyboardVisible = false

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .environment(
                    \.responsiveMetrics,
                    ResponsiveMetrics(
                        deviceSize: DeviceSize(width: geo.size.width),
                        isKeyboardVisible: isKeyboardVisible,
                        safeAreaInsets: geo.safeAreaInsets
                    )
                )
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            isKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            isKeyboardVisible = false
        }
    }
}

extension View {
    func withResponsiveMetrics() -> some View {
        modifier(ResponsiveRootModifier())
    }
}
