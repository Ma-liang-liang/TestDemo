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

    var numbers: [Int] = [1]
    
    override func viewDidLoad() {
        super.viewDidLoad()


        view.addSubview(jumpBtn)
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
        addMessageObserver()
        
        numbers.publisher.sink { v in
            print("v = \(v)")
        }.store(in: &cancelables)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        MessageCenter.shared.removeObserver(self, messageType: LoginMessage.self)
    }
    
    func addMessageObserver() {
        
        // 监听登录消息
        MessageCenter.shared.addObserver(self, messageType: LoginMessage.self) { [weak self] msg in
            switch msg.status {
            case .success(let user):
                print("SecondController 登录成功: \(user)")
            case .failure(let error):
                print("SecondController 登录失败: \(error)")
            case .logout:
                print("SecondController 用户注销")
            }
        }
        
        // 监听网络消息
        MessageCenter.shared.addObserver(self, messageType: NetworkMessage.self) { [weak self] msg in
            let status = msg.status == .connected ? "已连接" : "断开连接"
            print("SecondController 网络status = \(status)")
        }
    }

    func sendMessage() {
        // 发送登录成功消息
        MessageCenter.shared.send(LoginMessage(status: .success(user: "John")))
        
        // 发送网络断开消息
        let error = NSError(domain: "LoginError", code: 401, userInfo: nil)
        MessageCenter.shared.send(LoginMessage(status: .failure(error: error)))
        
        // 发送网络状态消息
        MessageCenter.shared.send(NetworkMessage(status: .disconnected))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        sendMessage()
        numbers.append(Int(arc4random()) % 100)
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
