//
//  ALLiveViewController.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/19.
//
import UIKit

// MARK: - 使用示例
class ALLiveViewController: UIViewController {
    private var giftManager: ALGiftRunwayManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        // 初始化礼物跑道管理器
        var config = ALGiftRunwayConfig()
        config.maxRunways = 3
        config.enterAnimationDuration = 0.5
        config.hoverDuration = 1.0 // 缩短悬停时间以便测试
        config.exitAnimationDuration = 0.5 // 加长退场时间，更容易观察到中断效果
        
        giftManager = ALGiftRunwayManager(parentView: view, config: config)
        setupTestButtons()
    }
    
    private func setupTestButtons() {
        let button1 = UIButton(type: .system)
        button1.setTitle("送玫瑰 (用户12)", for: .normal)
        button1.backgroundColor = .systemBlue
        button1.setTitleColor(.white, for: .normal)
        button1.layer.cornerRadius = 8
        button1.addTarget(self, action: #selector(sendRose), for: .touchUpInside)
        
        let button2 = UIButton(type: .system)
        button2.setTitle("送跑车 (随机土豪)", for: .normal)
        button2.backgroundColor = .systemRed
        button2.setTitleColor(.white, for: .normal)
        button2.layer.cornerRadius = 8
        button2.addTarget(self, action: #selector(sendCar), for: .touchUpInside)
        
        let button3 = UIButton(type: .system)
        button3.setTitle("清空", for: .normal)
        button3.backgroundColor = .systemGray
        button3.setTitleColor(.white, for: .normal)
        button3.layer.cornerRadius = 8
        button3.addTarget(self, action: #selector(clearGifts), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [button1, button2, button3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func sendRose() {
        //        let gift = GiftItem(
        //            userName: "用户\(Int.random(in: 1...100))",
        //            userAvatar: "",
        //            giftName: "玫瑰花",
        //            giftIcon: "",
        //            comboCount: Int.random(in: 1...5)
        //        )
        //        giftManager.addGift(gift)
        let gift = ALGiftItem(
            userName: "用户 12",
            userAvatar: "",
            giftName: "玫瑰花",
            giftIcon: "",
            comboCount: Int.random(in: 1...5)
        )
        giftManager.addGift(gift)
    }
    
    @objc private func sendCar() {
        let gift = ALGiftItem(
            userName: "土豪\(Int.random(in: 1...50))",
            userAvatar: "",
            giftName: "跑车",
            giftIcon: "",
            comboCount: Int.random(in: 1...3)
        )
        giftManager.addGift(gift)
    }
    
    @objc private func clearGifts() {
        giftManager.clearAllRunways()
    }
}
