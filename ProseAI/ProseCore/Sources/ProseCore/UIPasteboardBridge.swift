import Foundation
import UIKit

/// Lightweight bridge so the core framework can access the shared pasteboard
/// without depending on UIKit outside Apple platforms.
public final class UIPasteboardBridge {
    public static let shared = UIPasteboardBridge()

    private init() {}

    public var string: String? {
        get { UIPasteboard.general.string }
        set { UIPasteboard.general.string = newValue }
    }
}
