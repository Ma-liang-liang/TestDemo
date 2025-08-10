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
    
    private var buttons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()


        view.addSubview(jumpBtn)
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
        let titles = ["standard", "topEnter", "sendSpecial", "pauseAnimation", "clearAll"]
        let col = 3
        
        var lastBtn = UIButton()
        for idx in 0..<titles.count {
            let title = titles[idx]
            let button = UIButton()
                .cg_setTitle(title)
                .cg_setTitleFont(18.mediumFont)
                .cg_setTitleColor(.red)
                .cg_setTag(idx + 1)
                .cg_setBackgroundColor(.random)
                .cg_addTarget(self, action: #selector(onActionClick))
            
            view.addSubview(button)
            
            let row = idx / 3
            let curCol = idx % 3
            if idx == 0 {
                
                button.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(40)
                    make.top.equalTo(self.navBar.snp.bottom).offset(120)
                    make.width.equalTo(82)
                    make.height.equalTo(36)
                }
            } else if row == 0 {
                button.snp.makeConstraints { make in
                    make.leading.equalTo(lastBtn.snp.trailing).offset(20)
                    make.centerY.equalTo(lastBtn)
                    make.width.height.equalTo(lastBtn)
                }
            } else if row == 1, curCol == 0 {
                if curCol == 0 {
                    
                    button.snp.makeConstraints { make in
                        make.leading.equalToSuperview().offset(40)
                        make.top.equalTo(lastBtn.snp.bottom).offset(20)
                        make.width.height.equalTo(lastBtn)
                    }
                } else {
                    button.snp.makeConstraints { make in
                        make.leading.equalTo(lastBtn.snp.trailing).offset(20)
                        make.centerY.equalTo(lastBtn)
                        make.width.height.equalTo(lastBtn)
                    }
                }
            }
            
            lastBtn = button
        }
        
        setupUI()

    }
  
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加一个按钮来触发动画
        let triggerButton = UIButton(type: .system)
        triggerButton.setTitle("开始动画", for: .normal)
        triggerButton.backgroundColor = .systemBlue
        triggerButton.setTitleColor(.white, for: .normal)
        triggerButton.layer.cornerRadius = 8
        triggerButton.addTarget(self, action: #selector(startAnimationWithKeyframes), for: .touchUpInside)
        
        triggerButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(triggerButton)
        
        NSLayoutConstraint.activate([
            triggerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            triggerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            triggerButton.widthAnchor.constraint(equalToConstant: 100),
            triggerButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func startAnimation() {
        // 创建ViewA
        let viewA = UIView()
        viewA.backgroundColor = .systemBlue
        viewA.layer.cornerRadius = 10
        
        // 设置ViewA的尺寸（指定高度）
        let viewAWidth: CGFloat = 200
        let viewAHeight: CGFloat = 100
        viewA.frame = CGRect(x: -viewAWidth, y: 200, width: viewAWidth, height: viewAHeight)
        
        // 在ViewA上添加一个目标位置的标记（比如一个小圆点）
        let targetMark = UIView()
        targetMark.backgroundColor = .red
        targetMark.layer.cornerRadius = 5
        targetMark.frame = CGRect(x: viewAWidth - 30, y: viewAHeight/2 - 5, width: 10, height: 10)
        viewA.addSubview(targetMark)
        
        view.addSubview(viewA)
        
        // 创建图片B
        let imageB = UIImageView(image: UIImage(systemName: "star.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal))
        imageB.contentMode = .scaleAspectFit
        let imageBSize: CGFloat = 100
        imageB.frame = CGRect(x: view.center.x - imageBSize/2, y: view.center.y - imageBSize/2, width: imageBSize, height: imageBSize)
        imageB.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // 初始较大
        view.addSubview(imageB)
        
        // 执行动画
        performAnimation(viewA: viewA, imageB: imageB, viewAWidth: viewAWidth)
    }
    
    private func performAnimation(viewA: UIView, imageB: UIImageView, viewAWidth: CGFloat) {
        // 动画总时长参数
        let enterDuration: TimeInterval = 0.8  // 进入屏幕时间
        let hoverDuration: TimeInterval = 3.0  // 悬停时间
        let exitDuration: TimeInterval = 0.8   // 退出屏幕时间
        
        // 第一阶段：ViewA从左侧进入屏幕，同时图片B开始缩放和移动
        UIView.animate(withDuration: enterDuration, delay: 0, options: .curveEaseOut) {
            // ViewA进入屏幕
            viewA.frame.origin.x = 20
            
            // 图片B缩放和移动到ViewA的目标位置
            imageB.transform = CGAffineTransform.identity // 缩小到正常大小
            imageB.center = CGPoint(x: 20 + viewAWidth - 25, y: viewA.center.y)
        } completion: { _ in
            // 第二阶段：悬停3秒
            DispatchQueue.main.asyncAfter(deadline: .now() + hoverDuration) {
                // 第三阶段：ViewA退出屏幕，图片B移除
                UIView.animate(withDuration: exitDuration, delay: 0, options: .curveEaseIn) {
                    // ViewA退出屏幕
                    viewA.frame.origin.x = -viewA.frame.width
                    
                    // 图片B可以添加一些退出效果（可选）
                    imageB.alpha = 0
                } completion: { _ in
                    // 动画完成后移除视图
                    viewA.removeFromSuperview()
                    imageB.removeFromSuperview()
                }
            }
        }
    }

 
    // 演示不同类型的动画效果
    
    @objc
    func onActionClick(_ sender: UIButton) {
      
        if sender.tag == 1 {
            sendStandardGift(sender)
        } else if sender.tag == 2 {
            sendTopEnterGift(sender)
        } else if sender.tag == 3 {
            sendSpecialGift(sender)
        } else if sender.tag == 4 {
            togglePauseAnimation(sender)
        } else if sender.tag == 5 {
           clearAllGifts(sender)
        }
        
    }
    
    /// 标准左侧进入动画
    @IBAction func sendStandardGift(_ sender: UIButton) {
      
    }
    
    /// 顶部进入动画
    @IBAction func sendTopEnterGift(_ sender: UIButton) {
       
        
    }
    
    /// 特殊撞击动画
    @IBAction func sendSpecialGift(_ sender: UIButton) {
      
        
    }
    
    /// 暂停/恢复动画
    @IBAction func togglePauseAnimation(_ sender: UIButton) {
      
        
    }
    
    /// 清除所有礼物
    @IBAction func clearAllGifts(_ sender: UIButton) {

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

// 如果你想要更精确的控制，可以使用关键帧动画版本：
extension SecondController {
    @objc private func startAnimationWithKeyframes() {
        // 创建ViewA
        let viewA = UIView()
        viewA.backgroundColor = .systemGreen
        viewA.layer.cornerRadius = 10
        
        let viewAWidth: CGFloat = 200
        let viewAHeight: CGFloat = 100
        viewA.frame = CGRect(x: -viewAWidth, y: 300, width: viewAWidth, height: viewAHeight)
        
        // 添加目标标记
        let targetMark = UIView()
        targetMark.backgroundColor = .red
        targetMark.layer.cornerRadius = 5
        targetMark.frame = CGRect(x: viewAWidth - 30, y: viewAHeight/2 - 5, width: 10, height: 10)
        viewA.addSubview(targetMark)
        
        view.addSubview(viewA)
        
        // 创建图片B
        let imageB = UIImageView(image: UIImage(systemName: "heart.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal))
        imageB.contentMode = .scaleAspectFit
        let imageBSize: CGFloat = 80
        imageB.frame = CGRect(x: view.center.x - imageBSize/2, y: view.center.y - imageBSize/2, width: imageBSize, height: imageBSize)
        imageB.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
        view.addSubview(imageB)
        
        // 使用关键帧动画
        performKeyframeAnimation(viewA: viewA, imageB: imageB, viewAWidth: viewAWidth)
    }
    
    private func performKeyframeAnimation(viewA: UIView, imageB: UIImageView, viewAWidth: CGFloat) {
        let totalDuration: TimeInterval = 5.0 // 总动画时长
        
        UIView.animateKeyframes(withDuration: totalDuration, delay: 0, options: []) {
            // 第一阶段：进入（20%的时间）
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                viewA.frame.origin.x = 20
                imageB.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                imageB.center = CGPoint(x: 100, y: viewA.center.y)
            }
            
            // 第二阶段：继续移动和缩放（60%的时间）
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.6) {
                imageB.transform = CGAffineTransform.identity
                imageB.center = CGPoint(x: 20 + viewAWidth - 25, y: viewA.center.y)
            }
            
            // 第三阶段：退出（20%的时间）
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                viewA.frame.origin.x = -viewA.frame.width
                imageB.alpha = 0
            }
        } completion: { _ in
            viewA.removeFromSuperview()
            imageB.removeFromSuperview()
        }
    }
}
