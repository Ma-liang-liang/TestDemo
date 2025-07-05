//
//  HomeController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/26.
//

import UIKit
import SnapKit
import SwifterSwift
import SwiftUI

class HomeController: SKBaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(jumpBtn)
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
     
        
    }
   
    @objc
    func onJumpClick(_ sender:UIButton) {
        let vc = UIHostingController(rootView: MainTabBarControllerRepresentable())
        present(vc, animated: true)
    }
    
    lazy var jumpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
}
