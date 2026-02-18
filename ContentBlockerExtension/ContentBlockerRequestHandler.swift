import UIKit

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let attachment: NSItemProvider

        if let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
            .appendingPathComponent(Constants.contentBlockerRulesFileName),
           FileManager.default.fileExists(atPath: sharedURL.path) {
            attachment = NSItemProvider(contentsOf: sharedURL)!
        } else {
            attachment = NSItemProvider(
                contentsOf: Bundle.main.url(forResource: "blockerList", withExtension: "json")
            )!
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
