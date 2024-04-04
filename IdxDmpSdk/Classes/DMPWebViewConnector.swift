import WebKit

public final class DMPWebViewConnector: NSObject, WKScriptMessageHandler {
    private let handlerName: String = "sendDataToDmpNativeSdk"

    private var monitoring: Monitoring?

    private var errorCounter: Int = 0
    private var userId: String = ""
    private var definitionIds: String = ""

    public init(_ controller: WKUserContentController, _ monitoringLabel: String?) {
        super.init()
        
        self.monitoring = Monitoring(label: monitoringLabel)

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
            errorCounter = errorCounter + 1
            return
        }
        
        userId = data.first(where: { (key: String, value: String) in
            key == "userId"
        })?.value ?? ""

        definitionIds = data.first(where: { (key: String, value: String) in
            key == "definitionIdsAsString"
        })?.value ?? ""
        
        if (userId.isEmpty || definitionIds.isEmpty) {
            errorCounter = errorCounter + 1
        }
        
        if (errorCounter > 9) {
            errorCounter = 0
            monitoring?.complete(EDMPError.webViewDataAlwaysEmpty)
        }
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
