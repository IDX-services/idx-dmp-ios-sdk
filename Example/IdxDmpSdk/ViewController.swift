//
//  ViewController.swift
//  IdxDmpSdk
//
//  Created by Brainway LTD on 12/14/2022.
//  Copyright (c) 2022 Brainway LTD. All rights reserved.
//

import UIKit
import IdxDmpSdk

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let dmp = DataManagerProvider()
        print(dmp.getProviderId())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

