//
//  ViewController.swift
//  IdxDmpSdk
//
//  Created by Brainway LTD on 12/14/2022.
//  Copyright (c) 2022 Brainway LTD. All rights reserved.
//

import UIKit
import IdxDmpSdk
import GoogleMobileAds

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class ViewController: UIViewController {
    var dmp: DataManagerProvider?
    var bannerView: GADBannerView!
    
    @IBOutlet weak var textFieldProvider: UITextField!
    @IBOutlet weak var textFieldUrl: UITextField!
    @IBOutlet weak var textFieldTitle: UITextField!
    @IBOutlet weak var textFieldDomain: UITextField!
    @IBOutlet weak var textFieldAuthor: UITextField!
    @IBOutlet weak var textFieldCategory: UITextField!
    @IBOutlet weak var textFieldDescription: UITextField!
    @IBOutlet weak var textFieldTags: UITextField!
    
    @IBOutlet weak var labelDebugOutput: UILabel!
    
    @IBAction func handleSendEvent() {
        labelDebugOutput.text = ""

        guard let providerId = textFieldProvider.text else {
            self.showToast("Provider id is empty!")
            return
        }

        self.dmp = DataManagerProvider(providerId: providerId) {
//            self.showToast("Provider id has been init")
        }
        
        let requestProps = EventRequestPropertiesStruct(
            url: textFieldUrl.text ?? "",
            title: textFieldTitle.text ?? "",
            domain: textFieldDomain.text ?? "",
            author: textFieldAuthor.text ?? "",
            category: textFieldCategory.text ?? "",
            description: textFieldDescription.text ?? "",
            tags: textFieldTags.text?.components(separatedBy: ",") ?? []
        )

        self.dmp!.sendEvent(properties: requestProps) {
            self.labelDebugOutput.text = """
                Success PAGE VIEW with params:
                URL: \(requestProps.url)
                Title: \(requestProps.title)
                Domain: \(requestProps.domain)
                Author: \(requestProps.author)
                Category: \(requestProps.category)
                Desc: \(requestProps.description)
                Tags: \(requestProps.tags)
                UserId: \(String(describing: self.dmp!.getUserId()))
                Timestamp: \(String(describing: self.dmp!.getTimestamp()))
                OS Version: \(UIDevice.current.systemVersion)
                Device Id: \(String(describing: UIDevice.current.identifierForVendor))
                Model: \(UIDevice.current.model)
            """
        }
    }
    
    @IBAction func handleShowAd() {
        guard let dmp = self.dmp else {
            self.showToast("DMP is not init!")
            return
        }

        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self

        addBannerViewToView(bannerView)

        let adRequest: GAMRequest = GAMRequest()

        adRequest.customTargeting = ["dxseg": dmp.getDefinitionIds()]
        
        labelDebugOutput.text = "Success Ad Request with CUSTOM GOOGLE PARAMS:\n\n\(String(describing: adRequest.customTargeting))"

        bannerView.load(adRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .top,
                              relatedBy: .equal,
                              toItem: view.safeAreaLayoutGuide,
                              attribute: .top,
                              multiplier: 1,
                              constant: 0),
           NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: view,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
          ]
        )
    }
    
    func showToast(_ message : String, font: UIFont = .systemFont(ofSize: 12.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

