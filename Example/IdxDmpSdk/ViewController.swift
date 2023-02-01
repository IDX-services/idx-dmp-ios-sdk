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
        let dmp = DataManagerProvider(providerId: "45c531d8-d959-4240-bb6b-3e7372326a58")
        dmp.getState() {
            dmp.sendEvent(properties: EventRequestPropertiesStruct(
                url: "https://www.ice.co.il/",
                title: "ice (אייס) - חדשות מידע תקשורת וכלכלה",
                domain: "https://www.ice.co.il",
                author: "",
                category: "",
                description: "ice אייס הוא אתר חדשות, מידע ותקשורת, המנגיש את סדר היום הציבורי והכלכלי של ישראל, בגובה העיניים וללא אג'נדות. ice מציע חדשות, מבזקים, דיונים, ניתוחים, דירוגים מחקרים והמלצות 24/7 בנושאי תקשורת, כלכלה, עסקים, בורסה, פיננסים, השקעות, נדל\"ן, טכנולוגיה, דיגיטל וטק, צרכנות, צרכנות פיננסית, מדיה, פרסום ושיווק, משפט ועוד מגוון תכנים מהארץ ומרחבי העולם.",
                tags: []
            )) {
                print(dmp.getDefinitionIds())
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

