//
//  HomeController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/26.
//

import UIKit
import SnapKit
import SwifterSwift

class HomeController: SKBaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(jumpBtn)
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
        addMessageObserver()
        
        // 方法三使用
        let customLabel = GradientSizeLabel(frame: CGRect(x: 50, y: 200, width: 200, height: 50))
        customLabel.text = "CoreText渐变"
        customLabel.startFontSize = 10
        customLabel.endFontSize = 20
        customLabel.textAlignment = .center
        view.addSubview(customLabel)

        UIImage().preparingForDisplay()

        
    }
    
    func addMessageObserver() {
        
        // 监听登录消息
        MessageCenter.shared.addObserver(self, messageType: LoginMessage.self) { [weak self] msg in
            switch msg.status {
            case .success(let user):
                print("HomeController登录成功: \(user)")
            case .failure(let error):
                print("HomeController 登录失败: \(error)")
            case .logout:
                print("HomeController 用户注销")
            }
        }
        
        // 监听网络消息
        MessageCenter.shared.addObserver(self, messageType: NetworkMessage.self) { [weak self] msg in
            let status = msg.status == .connected ? "已连接" : "断开连接"
            print("HomeController 网络status = \(status)")
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
        
        sendMessage()
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

// 登录相关消息
struct LoginMessage: MessageType {
    enum Status {
        case success(user: String)
        case failure(error: Error)
        case logout
    }
    let status: Status
}

// 网络状态消息
struct NetworkMessage: MessageType {
    enum Status {
        case connected
        case disconnected
    }
    let status: Status
}

class GradientSizeLabel: UILabel {
    var startFontSize: CGFloat = 12
    var endFontSize: CGFloat = 24
    
    override func drawText(in rect: CGRect) {
        guard let text = self.text else { return }
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        // 翻转坐标系以匹配CoreText
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let path = CGMutablePath()
        path.addRect(bounds)
        
        let length = text.count
        let attributedString = NSMutableAttributedString(string: text)
        
        for i in 0..<length {
            let size = startFontSize + (endFontSize - startFontSize) * CGFloat(i) / CGFloat(length - 1)
            let range = NSRange(location: i, length: 1)
            attributedString.addAttribute(.font, value: self.font.withSize(size), range: range)
            attributedString.addAttribute(.foregroundColor, value: self.textColor, range: range)
        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)
        
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}
protocol P {
   func foo()
}
extension P {
   func foo() { print("P") }
   func bar() { print("bar") }
}
class C: P {
   func foo() { print("C") }
   func bar() { print("BAR") }
}
