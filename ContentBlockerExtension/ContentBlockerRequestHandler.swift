import UIKit
import SafariServices

// Stub for Phase 2 — will provide real blocking rules
class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let attachment = NSItemProvider(
            contentsOf: Bundle.main.url(forResource: "blockerList", withExtension: "json")
        )!

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
