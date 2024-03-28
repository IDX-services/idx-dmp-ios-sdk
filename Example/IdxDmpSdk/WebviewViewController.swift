//
//  WebviewViewController.swift
//  IdxDmpSdk_Example
//
//  Created by brainway on 21.03.2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

import IdxDmpSdk

class WebviewViewController: UIViewController {
    var connector: DMPWebViewConnector?
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textFieldUrl: UITextField!
    @IBOutlet weak var labelDebugOutput: UILabel!
    
    @IBAction func navigateToHome() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "HomeViewController") as! ViewController
        nextViewController.modalPresentationStyle = .fullScreen
        self.present(nextViewController, animated:true, completion:nil)
    }
    
    @IBAction func handleOpenUrl() {
        let rawUrl = textFieldUrl.text ?? ""
        let myURL = URL(string:rawUrl)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    @IBAction func handleShowDebug() {
        self.labelDebugOutput.text = """
            Custom targeting: \(connector?.getCustomAdTargeting())
        """
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        connector = DMPWebViewConnector(webView.configuration.userContentController)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
