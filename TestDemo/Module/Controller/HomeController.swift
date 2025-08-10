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
        setupUI()
    }
    
    private func setupUI() {
        let buttons = [jumpBtn, jumpBtn1, jumpBtn2]
        
        view.addSubviews {
            jumpBtn
            jumpBtn1
            jumpBtn2
        }
        
        // 使用循环简化约束设置
        for (index, button) in buttons.enumerated() {
            button.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(UIConstants.Spacing.huge)
                make.height.equalTo(UIConstants.ButtonHeight.medium)
                
                if index == 0 {
                    make.top.equalTo(navBar.snp.bottom).offset(UIConstants.Spacing.huge)
                } else {
                    make.top.equalTo(buttons[index - 1].snp.bottom).offset(UIConstants.Spacing.medium)
                }
            }
        }
    }
    
    @objc
    func onJumpClick(_ sender: UIButton) {
        if sender == jumpBtn {
            let vc = UIHostingController(rootView: MainTabBarControllerRepresentable())
            //            vc.modalPresentationStyle = .overFullScreen
            //            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        } else if sender == jumpBtn1 {
            let page = ALSheetPage(onDismiss: {
                
            }, onPinkAreaTap: {
                
            })
            let vc = UIHostingController(rootView: page)
            vc.view.backgroundColor = .clear
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        } else if sender == jumpBtn2 {
            let vc = ALCollectionController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // 使用工厂方法减少重复代码
    private func createJumpButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.App.primary
        button.layer.cornerRadius = UIConstants.CornerRadius.medium
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }
    
    lazy var jumpBtn = createJumpButton(title: "跳转到 SwiftUI TabBar")
    lazy var jumpBtn1 = createJumpButton(title: "显示底部弹窗")
    lazy var jumpBtn2 = createJumpButton(title: "跳转到集合视图")
}
