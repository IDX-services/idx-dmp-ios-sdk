# IdxDmpSdk

[![Version](https://img.shields.io/cocoapods/v/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)
[![License](https://img.shields.io/cocoapods/l/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)
[![Platform](https://img.shields.io/cocoapods/p/IdxDmpSdk.svg?style=flat)](https://cocoapods.org/pods/IdxDmpSdk)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

IdxDmpSdk is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IdxDmpSdk'
```

## Integration example

```swift
class ViewController: UIViewController {
    var dmp: DataManagerProvider?
    
    ...

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dmp = DataManagerProvider(providerId: providerId, monitoringLabel: "My app name") {_ in
          // Success callback
        }
    }

    ...
    
    @IBAction func handleShowAd() {
        guard let dmp = self.dmp else {
            return
        }

        let adRequest: GAMRequest = GAMRequest()

        adRequest.customTargeting = ["dxseg": dmp.getDefinitionIds()]
    }

    ...
}
```

## Author

Brainway LTD, https://brainway.co.il/

## License

IdxDmpSdk is available under the MIT license. See the LICENSE file for more info.
