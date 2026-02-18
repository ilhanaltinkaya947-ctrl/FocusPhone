import UIKit

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let attachment: NSItemProvider

        if let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
            .appendingPathComponent(Constants.contentBlockerRulesFileName),
           FileManager.default.fileExists(atPath: sharedURL.path),
           let provider = NSItemProvider(contentsOf: sharedURL) {
            attachment = provider
        } else if let bundleURL = Bundle.main.url(forResource: "blockerList", withExtension: "json"),
                  let provider = NSItemProvider(contentsOf: bundleURL) {
            attachment = provider
        } else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
