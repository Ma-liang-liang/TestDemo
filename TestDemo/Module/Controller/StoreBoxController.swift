//
//  StoreBoxController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/16.
//

import UIKit

class StoreBoxController: SKBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var nums: [Int] = []
        
        let dict: [String: Int] = [:]

        dict.sorted(by: { $0.value < $1.value }).forEach { print("\($0.key)") }
    }
    

    

}
