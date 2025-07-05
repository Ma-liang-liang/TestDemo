//
//  SecondController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/27.
//

import UIKit
import SnapKit
import SwifterSwift
import Combine

class SecondController: SKBaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()


        view.addSubview(jumpBtn)
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }

    }
    
    
    @objc
    func onJumpClick(_ sender:UIButton) {
        let vc = SecondController()
        navigationController?.pushViewController(vc)
    }
    
    lazy var jumpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()

}
