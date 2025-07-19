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
    var enterAnimationDuration: TimeInterval = 0.5
    var hoverDuration: TimeInterval = 3.0
    var exitAnimationDuration: TimeInterval = 0.3
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
    
    // 更新连击数
    func updateCombo(with giftItem: GiftItem) {
        self.giftItem = giftItem
        comboLabel.text = "x\(giftItem.comboCount)"
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

// MARK: - 跑道状态枚举
enum RunwayState {
    case idle           // 空闲
    case entering       // 进入动画中
    case hovering       // 悬停显示中
    case exiting        // 退出动画中
}

// MARK: - 跑道信息
class RunwayInfo {
    let runway: GiftRunwayView
    var state: RunwayState = .idle
    var hoverTimer: Timer?
    
    init(runway: GiftRunwayView) {
        self.runway = runway
    }
    
    func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    deinit {
        cancelHoverTimer()
    }
}

// MARK: - 礼物跑道管理器
class GiftRunwayManager {
    
    private var config: GiftRunwayConfig
    private var parentView: UIView
    private var runwayInfos: [RunwayInfo] = []
    private var giftQueue: [GiftItem] = []
    private var isProcessing = false
    
    init(parentView: UIView, config: GiftRunwayConfig = GiftRunwayConfig()) {
        self.parentView = parentView
        self.config = config
    }
    
    // 添加礼物到队列
    func addGift(_ giftItem: GiftItem) {
        // 检查是否有相同用户的同类型礼物正在显示，如果有就合并连击
        if let existingRunwayInfo = findExistingRunway(for: giftItem) {
            handleComboGift(runwayInfo: existingRunwayInfo, giftItem: giftItem)
            return
        }
        
        giftQueue.append(giftItem)
        processQueue()
    }
    
    // 查找现有跑道
    private func findExistingRunway(for giftItem: GiftItem) -> RunwayInfo? {
        return runwayInfos.first { runwayInfo in
            // 检查所有非空闲状态的跑道（包括退出状态）
            guard runwayInfo.state != .idle,
                  let currentGift = runwayInfo.runway.giftItem else { return false }
            return currentGift.userName == giftItem.userName &&
                   currentGift.giftName == giftItem.giftName
        }
    }
    
    // 处理连击礼物
    private func handleComboGift(runwayInfo: RunwayInfo, giftItem: GiftItem) {
        guard let currentGift = runwayInfo.runway.giftItem else { return }
        
        // 取消之前的悬停计时器
        runwayInfo.cancelHoverTimer()
        
        // 根据当前状态进行不同处理
        switch runwayInfo.state {
        case .entering:
            // 如果正在进入，累加连击数
            let updatedGift = GiftItem(
                userName: currentGift.userName,
                userAvatar: currentGift.userAvatar,
                giftName: currentGift.giftName,
                giftIcon: currentGift.giftIcon,
                giftCount: currentGift.giftCount,
                comboCount: currentGift.comboCount + giftItem.comboCount
            )
            runwayInfo.runway.updateCombo(with: updatedGift)
            runwayInfo.runway.playComboAnimation()
            
        case .hovering:
            // 如果正在悬停，累加连击数并重新开始进入动画
            let updatedGift = GiftItem(
                userName: currentGift.userName,
                userAvatar: currentGift.userAvatar,
                giftName: currentGift.giftName,
                giftIcon: currentGift.giftIcon,
                giftCount: currentGift.giftCount,
                comboCount: currentGift.comboCount + giftItem.comboCount
            )
            restartEnterAnimation(runwayInfo: runwayInfo, giftItem: updatedGift)
            
        case .exiting:
            // 如果正在退出，停止退出动画，重置连击数，重新开始进入动画
            let newGift = GiftItem(
                userName: giftItem.userName,
                userAvatar: giftItem.userAvatar,
                giftName: giftItem.giftName,
                giftIcon: giftItem.giftIcon,
                giftCount: giftItem.giftCount,
                comboCount: giftItem.comboCount // 重置连击数
            )
            
            // 停止当前的退出动画，从当前位置重新开始
            runwayInfo.runway.layer.removeAllAnimations()
            restartFromCurrentPosition(runwayInfo: runwayInfo, giftItem: newGift)
            
        case .idle:
            // 空闲状态，直接开始新动画
            startNewAnimation(runwayInfo: runwayInfo, giftItem: giftItem)
        }
    }
    
    // 重新开始进入动画
    private func restartEnterAnimation(runwayInfo: RunwayInfo, giftItem: GiftItem) {
        let runway = runwayInfo.runway
        
        // 更新礼物信息
        runway.updateCombo(with: giftItem)
        
        // 播放连击动画
        runway.playComboAnimation()
        
        // 重新设置进入动画状态
        runwayInfo.state = .entering
        
        // 从当前位置重新开始进入动画
        UIView.animate(withDuration: config.enterAnimationDuration,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 1.0,
                      options: [.curveEaseOut]) {
            runway.alpha = 1
            runway.transform = .identity
        } completion: { _ in
            runwayInfo.state = .hovering
            self.startHoverTimer(for: runwayInfo)
        }
    }
    
    // 从当前位置重新开始进入动画（用于退出状态被中断时）
    private func restartFromCurrentPosition(runwayInfo: RunwayInfo, giftItem: GiftItem) {
        let runway = runwayInfo.runway
        
        // 配置新的礼物信息
        runway.configure(with: giftItem)
        runway.playComboAnimation()
        
        // 确保视图可见
        runway.isHidden = false
        runwayInfo.state = .entering
        
        // 从当前位置开始进入动画
        UIView.animate(withDuration: config.enterAnimationDuration,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 1.0,
                      options: [.curveEaseOut]) {
            runway.alpha = 1
            runway.transform = .identity
        } completion: { _ in
            runwayInfo.state = .hovering
            self.startHoverTimer(for: runwayInfo)
        }
    }
    
    // 开始新动画（用于空闲状态）
    private func startNewAnimation(runwayInfo: RunwayInfo, giftItem: GiftItem) {
        let runway = runwayInfo.runway
        
        // 配置礼物信息
        runway.configure(with: giftItem)
        runway.isHidden = false
        runwayInfo.state = .entering
        
        // 设置初始位置（从左侧进入）
        runway.transform = CGAffineTransform(translationX: -300, y: 0)
        runway.alpha = 0
        
        // 入场动画
        UIView.animate(withDuration: config.enterAnimationDuration,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 1.0,
                      options: [.curveEaseOut]) {
            runway.alpha = 1
            runway.transform = .identity
        } completion: { _ in
            runwayInfo.state = .hovering
            self.startHoverTimer(for: runwayInfo)
        }
    }
    
    // 处理队列
    private func processQueue() {
        guard !isProcessing, !giftQueue.isEmpty else { return }
        
        isProcessing = true
        
        let giftItem = giftQueue.removeFirst()
        let availableRunwayInfo = findAvailableRunway()
        
        if let runwayInfo = availableRunwayInfo {
            showGift(giftItem, in: runwayInfo)
        } else if runwayInfos.count < config.maxRunways {
            let newRunwayInfo = createNewRunway()
            runwayInfos.append(newRunwayInfo)
            showGift(giftItem, in: newRunwayInfo)
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
    private func findAvailableRunway() -> RunwayInfo? {
        return runwayInfos.first { $0.state == .idle }
    }
    
    // 创建新跑道
    private func createNewRunway() -> RunwayInfo {
        let runway = GiftRunwayView(config: config)
        runway.alpha = 0
        runway.isHidden = true
        runway.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(runway)
        
        let runwayIndex = runwayInfos.count
        let topOffset = CGFloat(runwayIndex) * (config.runwayHeight + config.runwaySpacing)
        
        NSLayoutConstraint.activate([
            runway.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            runway.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 100 + topOffset),
            runway.heightAnchor.constraint(equalToConstant: config.runwayHeight),
            runway.widthAnchor.constraint(equalToConstant: 280)
        ])
        
        let runwayInfo = RunwayInfo(runway: runway)
        return runwayInfo
    }
    
    // 显示礼物动画
    private func showGift(_ giftItem: GiftItem, in runwayInfo: RunwayInfo) {
        let runway = runwayInfo.runway
        
        runway.configure(with: giftItem)
        runway.isHidden = false
        runwayInfo.state = .entering
        
        // 设置初始位置（从左侧进入）
        runway.transform = CGAffineTransform(translationX: -300, y: 0)
        runway.alpha = 0
        
        // 入场动画
        UIView.animate(withDuration: config.enterAnimationDuration,
                      delay: 0,
                      usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 1.0,
                      options: [.curveEaseOut]) {
            runway.alpha = 1
            runway.transform = .identity
        } completion: { _ in
            runwayInfo.state = .hovering
            self.startHoverTimer(for: runwayInfo)
        }
    }
    
    // 开始悬停计时器
    private func startHoverTimer(for runwayInfo: RunwayInfo) {
        runwayInfo.cancelHoverTimer()
        
        runwayInfo.hoverTimer = Timer.scheduledTimer(withTimeInterval: config.hoverDuration, repeats: false) { _ in
            self.hideGift(runwayInfo)
        }
    }
    
    // 隐藏礼物动画（原路返回）
    private func hideGift(_ runwayInfo: RunwayInfo) {
        let runway = runwayInfo.runway
        runwayInfo.state = .exiting
        runwayInfo.cancelHoverTimer()
        
        // 退场动画（原路返回到左侧）
        UIView.animate(withDuration: config.exitAnimationDuration,
                      delay: 0,
                      options: [.curveEaseIn]) {
            runway.alpha = 0
            runway.transform = CGAffineTransform(translationX: -300, y: 0)
        } completion: { _ in
            runway.isHidden = true
            runway.transform = .identity
            runwayInfo.state = .idle
            
            // 继续处理队列
            self.processQueue()
        }
    }
    
    // 清除所有跑道
    func clearAllRunways() {
        runwayInfos.forEach { runwayInfo in
            runwayInfo.cancelHoverTimer()
            runwayInfo.runway.removeFromSuperview()
        }
        runwayInfos.removeAll()
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
        config.enterAnimationDuration = 0.5
        config.hoverDuration = 1.0
        config.exitAnimationDuration = 2
        
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
//        let gift = GiftItem(
//            userName: "用户\(Int.random(in: 1...100))",
//            userAvatar: "",
//            giftName: "玫瑰花",
//            giftIcon: "",
//            comboCount: Int.random(in: 1...5)
//        )
//        giftManager.addGift(gift)
        let gift = GiftItem(
            userName: "用户 12",
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
