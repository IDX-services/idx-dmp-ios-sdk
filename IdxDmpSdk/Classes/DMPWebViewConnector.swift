import WebKit

public final class DMPWebViewConnector: NSObject, WKScriptMessageHandler {
    private let jsNameSendDataToDmpNativeSdk: String = "sendDataToDmpNativeSdk"

    private var monitoring: Monitoring?

    private var errorCounter: Int = 0
    private var userId: String = ""
    private var definitionIds: String = ""
    
    private func sdkMetaDataToJson(_ sdkMetaData: SdkMetaDataStruct) -> String {
        do {
            let data = try JSONEncoder().encode(sdkMetaData)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    public init(_ controller: WKUserContentController, _ appName: String, _ appVersion: String) {
        super.init()
        
        self.monitoring = Monitoring(label: appName)

        controller.add(self, name: jsNameSendDataToDmpNativeSdk)
        
        let sdkMetaData = SdkMetaDataStruct(
            sdkName: "iOS DMP WEB CONNECTOR SDK",
            sdkVer: monitoring?.getBuildNumber() ?? "Unknown version",
            appName: appName,
            appVer: appVersion
        )

        let javaScriptSource = "window.dmpsdk = { properties: { sdkMetaData: \(sdkMetaDataToJson(sdkMetaData)) } }"
        let sdkMetaDataScript = WKUserScript(
            source: javaScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        controller.addUserScript(sdkMetaDataScript)
    }
    
    private func handleSendDataToDmpNativeSdk (message: WKScriptMessage) {
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
    
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case jsNameSendDataToDmpNativeSdk:
            return handleSendDataToDmpNativeSdk(message: message)
        default:
            return
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
