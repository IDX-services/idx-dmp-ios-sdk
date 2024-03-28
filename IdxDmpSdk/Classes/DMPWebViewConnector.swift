import WebKit

public final class DMPWebViewConnector: NSObject, WKScriptMessageHandler {
    private let handlerName: String = "sendDataToDmpNativeSdk"

    private var userId: String = ""
    private var definitionIds: String = ""

    public init(_ controller: WKUserContentController) {
        super.init()

        controller.add(self, name: handlerName)
    }

    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if (message.name != handlerName) {
            return
        }

        guard let data = message.body as? [String : String] else {
            return
        }
        
        userId = data.first(where: { (key: String, value: String) in
            key == "userId"
        })?.value ?? ""

        definitionIds = data.first(where: { (key: String, value: String) in
            key == "definitionIdsAsString"
        })?.value ?? ""
    }
    
    public func getUserId() -> String {
        return userId
    }
    
    public func getDefinitionIds() -> String {
        return definitionIds
    }
    
    public func getCustomAdTargeting() -> [String: String] {
        return ["dxseg": definitionIds, "dxu": userId, "permutive": userId]
    }
}
