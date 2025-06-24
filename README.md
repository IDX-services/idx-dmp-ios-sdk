# IDX Data Manager Provider iOS SDK

This guide provides detailed instructions for integrating and using the IDX Data Manager Provider SDK in your iOS applications.

[![Version](https://img.shields.io/cocoapods/v/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)
[![License](https://img.shields.io/cocoapods/l/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)
[![Platform](https://img.shields.io/cocoapods/p/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [App configuration](#app-configuration)
- [Integration with DataManagerProvider](#integration-with-datamanager-provider)
- [Integration with DMPWebViewConnector](#integration-with-dmpwebviewconnector)
- [Author](#author)
- [Support](#support)
- [License](#license)

## Requirements

To integrate this SDK into your project, you need:

- Swift 5.7+
- iOS 12.0+
- Valid ProviderId from IDX

## Installation

IdxDmpSdk is available through [CocoaPods](https://cocoapods.org). Add the following line to your Podfile:

```ruby
pod 'IdxDmpSdk'
```

## App configuration

Add these keys to your Info.plist file:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>It makes our adwords more compatibility with your interests</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>It makes our adwords more compatibility with your location</string>
```

## Integration with DataManagerProvider

To use the SDK in your native app, create a `DataManagerProvider` instance with your `ProviderId` (obtained from `IDX`). You must also specify your app name and version.

The SDK initializes asynchronously. While you can wait for the completion callback, you can immediately use other SDK methods. In this case, audience calculations will be based on previous data.

Audiences are calculated based on Page View events, which you can send when needed (e.g., when a user opens a new article). You control what data to include in each event.

The SDK returns an object containing the generated userId and collected audiences. To get targeted ads based on this data, set these parameters in your Google ad request.

For integration testing:

- Handle errors in SDK initialization and event callbacks
- The object returned by `getCustomAdTargeting` should always contain data
- The dxseg key may be empty if no audiences matched, but `userId` will always be populated

```swift
class ViewController: UIViewController {
    var dmp: DataManagerProvider?
    
    ...

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dmp = DataManagerProvider(providerId: "Your Provider ID goes here", appName: "My app name", appVersion: "1.0.0") {error in
          // Complete callback
        }
    }

    ...

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let requestProps = EventRequestPropertiesStruct(
            url: ("/examplePage"); // Replace with the specific page URL or identifier
            title: ("Example Page Title"); // Replace with the specific page title
            domain: ("your-domain.com"); // Replace with your domain
            author: ("author"); // Replace with the author of the page
            category: ("category"); // Replace with the category of the page
            description: ("This is an example page."); // Replace with the description of the page
            tags: ["tag1", "tag2", "tag3"] // Replace with the tags related to the page
        )

        self.dmp?.sendEvent(properties: requestProps) { error in
            // Complete callback
        }
    }

    ...
    
    @IBAction func handleShowAd() {
        guard let dmp = self.dmp else {
            return
        }

        let adRequest: GAMRequest = GAMRequest()
        adRequest.customTargeting = dmp.getCustomAdTargeting()
    }

    ...
}
```

## Integration with DMPWebViewConnector

If your app uses `WebView` to display content but you want to request ads natively, use `DMPWebViewConnector`. Initialize it with:

- The userContentController from your `WKWebView` (which must have our web SDK installed)
- Your app name and version

The connector automatically listens to events from the web page and provides access to audiences calculated by the web SDK. Subsequent integration is identical to DataManagerProvider.

If you have multiple webviews, you need to create a separate DMPWebViewConnector for each of them. DMPWebViewConnector is just a small bridge, so it has practically no overhead.

```swift
class ViewController: UIViewController {
    var dmpWebViewConnector1: DMPWebViewConnector?
    var dmpWebViewConnector2: DMPWebViewConnector?
    
    ...

    override func viewDidLoad() {
        super.viewDidLoad()
        // You have to set your WKWebView instance
        dmpWebViewConnector1 = DMPWebViewConnector(yourWebView1.configuration.userContentController, "My app name", "1.0.0")
        dmpWebViewConnector2 = DMPWebViewConnector(yourWebView2.configuration.userContentController, "My app name", "1.0.0")
    }

    ...
    
    @IBAction func handleShowAd() {
        guard let connector1 = self.dmpWebViewConnector1 else {
            return
        }

        let adRequest: GAMRequest = GAMRequest()
        adRequest.customTargeting = connector1.getCustomAdTargeting()

        guard let connector2 = self.dmpWebViewConnector2 else {
            return
        }

        let adRequest: GAMRequest = GAMRequest()
        adRequest.customTargeting = connector2.getCustomAdTargeting()
    }

    ...
}
```

## Author

IDX LTD, https://www.id-x.co.il/

## Support

For support, report issues in the issue tracker or reach out through our designated support channels

## License

IdxDmpSdk is available under the MIT license. See the LICENSE file for more info.
