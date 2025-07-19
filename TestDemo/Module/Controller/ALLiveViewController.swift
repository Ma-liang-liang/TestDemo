//
//  ALLiveViewController.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/19.
//

import UIKit

// MARK: - 礼物数据模型
struct GiftItem {
    let id: String
    let userName: String
    let userAvatar: String
    let giftName: String
    let giftIcon: String
    let giftCount: Int
    let comboCount: Int
    
    init(userName: String, userAvatar: String, giftName: String, giftIcon: String, giftCount: Int = 1, comboCount: Int = 1) {
        self.id = UUID().uuidString
        self.userName = userName
        self.userAvatar = userAvatar
        self.giftName = giftName
        self.giftIcon = giftIcon
        self.giftCount = giftCount
        self.comboCount = comboCount
    }
}

// MARK: - 礼物跑道配置
struct GiftRunwayConfig {
    var maxRunways: Int = 3
    var animationDuration: TimeInterval = 3.0
    var comboAnimationDuration: TimeInterval = 0.8
    var runwayHeight: CGFloat = 60
    var runwaySpacing: CGFloat = 8
    var cornerRadius: CGFloat = 30
    var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.6)
    var textColor: UIColor = .white
    var comboColor: UIColor = .orange
}

// MARK: - 礼物跑道视图
class GiftRunwayView: UIView {
    
    // UI组件
    private let containerView = UIView()
    private let userAvatarImageView = UIImageView()
    private let userNameLabel = UILabel()
    private let giftIconImageView = UIImageView()
    private let giftNameLabel = UILabel()
    private let comboLabel = UILabel()
    
    // 属性
    var giftItem: GiftItem?
    private var config: GiftRunwayConfig
    
    init(config: GiftRunwayConfig = GiftRunwayConfig()) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.config = GiftRunwayConfig()
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 容器视图设置
        containerView.backgroundColor = config.backgroundColor
        containerView.layer.cornerRadius = config.cornerRadius
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // 用户头像设置
        userAvatarImageView.contentMode = .scaleAspectFill
        userAvatarImageView.layer.cornerRadius = 20
        userAvatarImageView.clipsToBounds = true
        userAvatarImageView.backgroundColor = .lightGray
        containerView.addSubview(userAvatarImageView)
        
        // 用户名设置
        userNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        userNameLabel.textColor = config.textColor
        containerView.addSubview(userNameLabel)
        
        // 礼物图标设置
        giftIconImageView.contentMode = .scaleAspectFit
        giftIconImageView.backgroundColor = .clear
        containerView.addSubview(giftIconImageView)
        
        // 礼物名称设置
        giftNameLabel.font = UIFont.systemFont(ofSize: 12)
        giftNameLabel.textColor = config.textColor
        containerView.addSubview(giftNameLabel)
        
        // 连击数设置
        comboLabel.font = UIFont.boldSystemFont(ofSize: 18)
        comboLabel.textColor = config.comboColor
        comboLabel.textAlignment = .center
        containerView.addSubview(comboLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        userAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        giftIconImageView.translatesAutoresizingMaskIntoConstraints = false
        giftNameLabel.translatesAutoresizingMaskIntoConstraints = false
        comboLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 容器约束
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 头像约束
            userAvatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            userAvatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            userAvatarImageView.widthAnchor.constraint(equalToConstant: 40),
            userAvatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // 用户名约束
            userNameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 8),
            userNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            userNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            
            // 礼物名约束
            giftNameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 8),
            giftNameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            giftNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            
            // 礼物图标约束
            giftIconImageView.leadingAnchor.constraint(equalTo: userNameLabel.trailingAnchor, constant: 8),
            giftIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            giftIconImageView.widthAnchor.constraint(equalToConstant: 32),
            giftIconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // 连击数约束
            comboLabel.leadingAnchor.constraint(equalTo: giftIconImageView.trailingAnchor, constant: 8),
            comboLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            comboLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            comboLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    func configure(with giftItem: GiftItem) {
        self.giftItem = giftItem
        
        userNameLabel.text = giftItem.userName
        giftNameLabel.text = giftItem.giftName
        comboLabel.text = "x\(giftItem.comboCount)"
        
        // 设置头像（这里使用占位图）
        userAvatarImageView.backgroundColor = .systemBlue
        
        // 设置礼物图标（这里使用占位图）
        giftIconImageView.backgroundColor = .systemOrange
    }
    
    // 连击动画
    func playComboAnimation() {
        UIView.animate(withDuration: config.comboAnimationDuration * 0.5,
                      delay: 0,
                      usingSpringWithDamping: 0.6,
                      initialSpringVelocity: 0.8,
                      options: [.curveEaseInOut]) {
            self.comboLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        } completion: { _ in
            UIView.animate(withDuration: self.config.comboAnimationDuration * 0.5) {
                self.comboLabel.transform = .identity
            }
        }
    }
}

// MARK: - 礼物跑道管理器
class GiftRunwayManager {
    
    private var config: GiftRunwayConfig
    private var parentView: UIView
    private var runways: [GiftRunwayView] = []
    private var giftQueue: [GiftItem] = []
    private var isProcessing = false
    
    init(parentView: UIView, config: GiftRunwayConfig = GiftRunwayConfig()) {
        self.parentView = parentView
        self.config = config
    }
    
    // 添加礼物到队列
    func addGift(_ giftItem: GiftItem) {
        // 检查是否有相同用户的同类型礼物正在显示，如果有就合并连击
        if let existingRunway = findExistingRunway(for: giftItem) {
            updateCombo(runway: existingRunway, newCombo: giftItem.comboCount)
            return
        }
        
        giftQueue.append(giftItem)
        processQueue()
    }
    
    // 查找现有跑道
    private func findExistingRunway(for giftItem: GiftItem) -> GiftRunwayView? {
        return runways.first { runway in
            guard let currentGift = runway.giftItem else { return false }
            return currentGift.userName == giftItem.userName &&
                   currentGift.giftName == giftItem.giftName
        }
    }
    
    // 更新连击数
    private func updateCombo(runway: GiftRunwayView, newCombo: Int) {
        guard let currentGift = runway.giftItem else { return }
        let updatedGift = GiftItem(
            userName: currentGift.userName,
            userAvatar: currentGift.userAvatar,
            giftName: currentGift.giftName,
            giftIcon: currentGift.giftIcon,
            giftCount: currentGift.giftCount,
            comboCount: currentGift.comboCount + newCombo
        )
        runway.configure(with: updatedGift)
        runway.playComboAnimation()
    }
    
    // 处理队列
    private func processQueue() {
        guard !isProcessing, !giftQueue.isEmpty else { return }
        
        isProcessing = true
        
        let giftItem = giftQueue.removeFirst()
        let availableRunway = findAvailableRunway()
        
        if let runway = availableRunway {
            showGift(giftItem, in: runway)
        } else if runways.count < config.maxRunways {
            let newRunway = createNewRunway()
            runways.append(newRunway)
            showGift(giftItem, in: newRunway)
        } else {
            // 等待跑道空闲
            giftQueue.insert(giftItem, at: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isProcessing = false
                self.processQueue()
            }
            return
        }
        
        isProcessing = false
    }
    
    // 查找可用跑道
    private func findAvailableRunway() -> GiftRunwayView? {
        return runways.first { $0.alpha == 0 || $0.isHidden }
    }
    
    // 创建新跑道
    private func createNewRunway() -> GiftRunwayView {
        let runway = GiftRunwayView(config: config)
        runway.alpha = 0
        runway.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(runway)
        
        let runwayIndex = runways.count
        let topOffset = CGFloat(runwayIndex) * (config.runwayHeight + config.runwaySpacing)
        
        NSLayoutConstraint.activate([
            runway.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            runway.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 100 + topOffset),
            runway.heightAnchor.constraint(equalToConstant: config.runwayHeight),
            runway.widthAnchor.constraint(equalToConstant: 280)
        ])
        
        return runway
    }
    
    // 显示礼物动画
    private func showGift(_ giftItem: GiftItem, in runway: GiftRunwayView) {
        runway.configure(with: giftItem)
        runway.isHidden = false
        
        // 入场动画
        runway.transform = CGAffineTransform(translationX: -300, y: 0)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: [.curveEaseOut]) {
            runway.alpha = 1
            runway.transform = .identity
        } completion: { _ in
            // 显示持续时间后开始退场动画
            DispatchQueue.main.asyncAfter(deadline: .now() + self.config.animationDuration) {
                self.hideGift(runway)
            }
        }
    }
    
    // 隐藏礼物动画
    private func hideGift(_ runway: GiftRunwayView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
            runway.alpha = 0
            runway.transform = CGAffineTransform(translationX: 300, y: 0)
        } completion: { _ in
            runway.isHidden = true
            runway.transform = .identity
            // 继续处理队列
            self.processQueue()
        }
    }
    
    // 清除所有跑道
    func clearAllRunways() {
        runways.forEach { runway in
            runway.removeFromSuperview()
        }
        runways.removeAll()
        giftQueue.removeAll()
        isProcessing = false
    }
    
    // 更新配置
    func updateConfig(_ newConfig: GiftRunwayConfig) {
        self.config = newConfig
        // 可以在这里更新现有跑道的配置
    }
}

// MARK: - 使用示例
class ALLiveViewController: UIViewController {
    
    private var giftManager: GiftRunwayManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // 初始化礼物跑道管理器
        var config = GiftRunwayConfig()
        config.maxRunways = 3
        config.animationDuration = 4.0
        
        giftManager = GiftRunwayManager(parentView: view, config: config)
        
        // 添加测试按钮
        setupTestButtons()
    }
    
    private func setupTestButtons() {
        let button1 = UIButton(type: .system)
        button1.setTitle("送玫瑰", for: .normal)
        button1.backgroundColor = .systemBlue
        button1.setTitleColor(.white, for: .normal)
        button1.layer.cornerRadius = 8
        button1.addTarget(self, action: #selector(sendRose), for: .touchUpInside)
        
        let button2 = UIButton(type: .system)
        button2.setTitle("送跑车", for: .normal)
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
        let gift = GiftItem(
            userName: "用户\(Int.random(in: 1...100))",
            userAvatar: "",
            giftName: "玫瑰花",
            giftIcon: "",
            comboCount: Int.random(in: 1...5)
        )
        giftManager.addGift(gift)
    }
    
    @objc private func sendCar() {
        let gift = GiftItem(
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
