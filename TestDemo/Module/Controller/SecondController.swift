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

// MARK: - 用户模型
struct LiveUser {
    let id: String
    let nickname: String
    let avatar: String // SF Symbol name
    let level: Int
}

// MARK: - 礼物数据模型
struct GiftModel {
    let id: String
    let name: String
    let iconName: String
    let value: Int
    let isSpecial: Bool
    let giftType: GiftType
    let comboEnabled: Bool
    let fullScreenEffect: Bool
    
    enum GiftType {
        case normal      // 普通礼物
        case luxury      // 豪华礼物  
        case superb      // 超级礼物
        case exclusive   // 专属礼物
    }
    
    static let sampleGifts: [GiftModel] = [
        GiftModel(id: "1", name: "玫瑰", iconName: "leaf.fill", value: 1, isSpecial: false, giftType: .normal, comboEnabled: true, fullScreenEffect: false),
        GiftModel(id: "2", name: "比心", iconName: "heart.fill", value: 5, isSpecial: false, giftType: .normal, comboEnabled: true, fullScreenEffect: false),
        GiftModel(id: "3", name: "跑车", iconName: "car.fill", value: 188, isSpecial: true, giftType: .luxury, comboEnabled: false, fullScreenEffect: true),
        GiftModel(id: "4", name: "游艇", iconName: "sailboat.fill", value: 520, isSpecial: true, giftType: .superb, comboEnabled: false, fullScreenEffect: true),
        GiftModel(id: "5", name: "火箭", iconName: "airplane", value: 1314, isSpecial: true, giftType: .exclusive, comboEnabled: false, fullScreenEffect: true)
    ]
}

// MARK: - 直播礼物跑道视图
class LiveGiftRunwayView: UIView {
    private var giftQueue: [GiftAnimationItem] = []
    private var activeAnimations: [String: GiftAnimationItem] = [:] // giftId: item
    private var comboTimers: [String: Timer] = [:]
    private var isPaused = false
    
    struct GiftAnimationItem {
        let id: String
        let gift: GiftModel
        let user: LiveUser
        var comboCount: Int
        let view: UIView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRunway()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRunway()
    }
    
    private func setupRunway() {
        backgroundColor = .clear
    }
    
    func sendGift(_ gift: GiftModel, from user: LiveUser) {
        if gift.comboEnabled, activeAnimations[gift.id] != nil {
            // 连击逻辑
            updateCombo(for: gift.id, gift: gift, user: user)
        } else {
            // 新礼物
            createNewGiftAnimation(gift: gift, user: user)
        }
    }
    
    private func createNewGiftAnimation(gift: GiftModel, user: LiveUser) {
        let giftView = createRealisticGiftView(gift: gift, user: user)
        let item = GiftAnimationItem(id: gift.id, gift: gift, user: user, comboCount: 1, view: giftView)
        
        addSubview(giftView)
        activeAnimations[gift.id] = item
        
        // 从右侧飞入动画
        animateGiftEntry(item)
        
        // 设置定时器，礼物停留时间后移除
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.removeGiftAnimation(gift.id)
        }
        comboTimers[gift.id] = timer
    }
    
    private func createRealisticGiftView(gift: GiftModel, user: LiveUser) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 2
        
        // 根据礼物类型设置边框颜色
        switch gift.giftType {
        case .normal:
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
        case .luxury:
            containerView.layer.borderColor = UIColor.systemPurple.cgColor
        case .superb:
            containerView.layer.borderColor = UIColor.systemOrange.cgColor
        case .exclusive:
            containerView.layer.borderColor = UIColor.systemPink.cgColor
        }
        
        // 用户头像
        let avatarView = UIImageView()
        avatarView.image = UIImage(systemName: user.avatar)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        avatarView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        avatarView.layer.cornerRadius = 15
        avatarView.contentMode = .scaleAspectFit
        containerView.addSubview(avatarView)
        
        // 用户名
        let nicknameLabel = UILabel()
        nicknameLabel.text = user.nickname
        nicknameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nicknameLabel.textColor = .white
        containerView.addSubview(nicknameLabel)
        
        // 等级徽章
        let levelLabel = UILabel()
        levelLabel.text = "Lv.\(user.level)"
        levelLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        levelLabel.textColor = .systemYellow
        levelLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        levelLabel.layer.cornerRadius = 8
        levelLabel.textAlignment = .center
        levelLabel.clipsToBounds = true
        containerView.addSubview(levelLabel)
        
        // 送出文字
        let actionLabel = UILabel()
        actionLabel.text = "送出"
        actionLabel.font = UIFont.systemFont(ofSize: 11)
        actionLabel.textColor = .systemGray
        containerView.addSubview(actionLabel)
        
        // 礼物图标
        let giftIcon = UIImageView()
        giftIcon.image = UIImage(systemName: gift.iconName)?.withTintColor(getGiftColor(gift), renderingMode: .alwaysOriginal)
        giftIcon.contentMode = .scaleAspectFit
        containerView.addSubview(giftIcon)
        
        // 礼物名称
        let giftNameLabel = UILabel()
        giftNameLabel.text = gift.name
        giftNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        giftNameLabel.textColor = getGiftColor(gift)
        containerView.addSubview(giftNameLabel)
        
        // 连击数量标签 (初始隐藏)
        let comboLabel = UILabel()
        comboLabel.text = "x1"
        comboLabel.font = UIFont.systemFont(ofSize: 20, weight: .black)
        comboLabel.textColor = .systemYellow
        comboLabel.textAlignment = .center
        comboLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        comboLabel.layer.cornerRadius = 15
        comboLabel.clipsToBounds = true
        comboLabel.isHidden = !gift.comboEnabled
        containerView.addSubview(comboLabel)
        
        // 自动布局
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(6)
        }
        
        levelLabel.snp.makeConstraints { make in
            make.leading.equalTo(nicknameLabel.snp.trailing).offset(6)
            make.centerY.equalTo(nicknameLabel)
            make.width.equalTo(35)
            make.height.equalTo(16)
        }
        
        actionLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(2)
        }
        
        giftIcon.snp.makeConstraints { make in
            make.leading.equalTo(actionLabel.snp.trailing).offset(4)
            make.centerY.equalTo(actionLabel)
            make.width.height.equalTo(16)
        }
        
        giftNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(giftIcon.snp.trailing).offset(4)
            make.centerY.equalTo(actionLabel)
        }
        
        comboLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        // 设置容器大小
        containerView.frame = CGRect(x: bounds.width, y: 0, width: 240, height: 50)
        
        return containerView
    }
    
    private func getGiftColor(_ gift: GiftModel) -> UIColor {
        switch gift.giftType {
        case .normal: return .systemBlue
        case .luxury: return .systemPurple
        case .superb: return .systemOrange
        case .exclusive: return .systemPink
        }
    }
    
    private func animateGiftEntry(_ item: GiftAnimationItem) {
        let targetX = bounds.width - item.view.frame.width - 20
        let availableSlot = findAvailableSlot()
        
        item.view.frame.origin.y = CGFloat(availableSlot) * 60
        
        // 飞入动画
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            item.view.frame.origin.x = targetX
        }
        
        // 添加入场特效
        addEntryEffect(item.view)
    }
    
    private func addEntryEffect(_ view: UIView) {
        // 发光效果
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1.0
        
        UIView.animate(withDuration: 0.8) {
            view.layer.shadowOpacity = 0.3
        }
    }
    
    private func updateCombo(for giftId: String, gift: GiftModel, user: LiveUser) {
        guard var item = activeAnimations[giftId] else { return }
        item.comboCount += 1
        // 更新连击标签
        if let comboLabel = item.view.subviews.last as? UILabel {
            comboLabel.text = "x\(item.comboCount)"
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                comboLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    comboLabel.transform = .identity
                }
            }
        }
        // 回写更新后的 item
        activeAnimations[giftId] = item
        // 重置定时器
        comboTimers[giftId]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.removeGiftAnimation(giftId)
        }
        comboTimers[giftId] = timer
    }
    
    private func findAvailableSlot() -> Int {
        let usedSlots = activeAnimations.values.map { Int($0.view.frame.origin.y / 60) }
        for slot in 0..<5 {
            if !usedSlots.contains(slot) {
                return slot
            }
        }
        return 0
    }
    
    private func removeGiftAnimation(_ giftId: String) {
        guard let item = activeAnimations[giftId] else { return }
        
        // 飞出动画
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            item.view.frame.origin.x = self.bounds.width
            item.view.alpha = 0
        } completion: { _ in
            item.view.removeFromSuperview()
        }
        
        activeAnimations.removeValue(forKey: giftId)
        comboTimers[giftId]?.invalidate()
        comboTimers.removeValue(forKey: giftId)
    }
    
    func pauseAnimations() {
        isPaused = true
        comboTimers.values.forEach { $0.invalidate() }
    }
    
    func resumeAnimations() {
        isPaused = false
    }
    
    func clearAllGifts() {
        activeAnimations.values.forEach { $0.view.removeFromSuperview() }
        activeAnimations.removeAll()
        comboTimers.values.forEach { $0.invalidate() }
        comboTimers.removeAll()
    }
}

// MARK: - 中奖特效视图
class JackpotEffectView: UIView {
    private var particleLayer: CAEmitterLayer!
    private var explosionView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEffects()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEffects()
    }
    
    private func setupEffects() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    func showJackpotEffect(at point: CGPoint, gift: GiftModel) {
        createExplosionEffect(at: point)
        createParticleEffect(at: point)
        createTextEffect(at: point, gift: gift)
        addScreenShake()
    }
    
    private func createExplosionEffect(at point: CGPoint) {
        explosionView = UIView()
        explosionView.backgroundColor = UIColor.systemYellow
        explosionView.layer.cornerRadius = 5
        explosionView.frame = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
        addSubview(explosionView)
        
        // 爆炸扩散动画
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            self.explosionView.transform = CGAffineTransform(scaleX: 15, y: 15)
            self.explosionView.alpha = 0
        } completion: { _ in
            self.explosionView.removeFromSuperview()
        }
    }
    
    private func createParticleEffect(at point: CGPoint) {
        particleLayer = CAEmitterLayer()
        particleLayer.emitterPosition = point
        particleLayer.emitterShape = .circle
        particleLayer.emitterSize = CGSize(width: 10, height: 10)
        
        let cell = CAEmitterCell()
        cell.birthRate = 100
        cell.lifetime = 2.0
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionRange = CGFloat.pi * 2
        cell.scale = 0.1
        cell.scaleRange = 0.05
        cell.color = UIColor.systemYellow.cgColor
        cell.alphaSpeed = -0.5
        cell.contents = createStarImage().cgImage
        
        particleLayer.emitterCells = [cell]
        layer.addSublayer(particleLayer)
        
        // 2秒后停止粒子效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.particleLayer?.removeFromSuperlayer()
        }
    }
    
    private func createTextEffect(at point: CGPoint, gift: GiftModel) {
        let jackpotLabel = UILabel()
        jackpotLabel.text = "🎉 中奖啦! 🎉"
        jackpotLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        jackpotLabel.textColor = .systemYellow
        jackpotLabel.textAlignment = .center
        jackpotLabel.numberOfLines = 0
        jackpotLabel.sizeToFit()
        
        jackpotLabel.center = CGPoint(x: point.x, y: point.y - 50)
        addSubview(jackpotLabel)
        
        // 文字动画
        jackpotLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        jackpotLabel.alpha = 0
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, 
                       initialSpringVelocity: 0.8, options: []) {
            jackpotLabel.transform = CGAffineTransform.identity
            jackpotLabel.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 1.0, delay: 1.0) {
                jackpotLabel.alpha = 0
                jackpotLabel.transform = CGAffineTransform(translationX: 0, y: -30)
            } completion: { _ in
                jackpotLabel.removeFromSuperview()
            }
        }
    }
    
    private func addScreenShake() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        
        window.layer.add(animation, forKey: "shake")
    }
    
    private func createStarImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - 主控制器
class SecondController: SKBaseController {
    
    private var buttons: [UIButton] = []
    private var giftRunway: LiveGiftRunwayView!
    private var jackpotEffectView: JackpotEffectView!
    private var isAnimationPaused = false
    private let currentUser = LiveUser(id: "u1", nickname: "小明", avatar: "person.fill", level: 12)
    
    // 礼物数据
    private let gifts: [GiftModel] = GiftModel.sampleGifts
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGiftSystem()
    }
  
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 跳转按钮
        view.addSubview(jumpBtn)
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
        // 功能按钮
        let titles = ["普通礼物", "顶部礼物", "中奖特效", "暂停/继续", "清除所有"]
        
        var lastBtn: UIButton?
        for (idx, title) in titles.enumerated() {
            let button = UIButton()
                .cg_setTitle(title)
                .cg_setTitleFont(UIFont.systemFont(ofSize: 14, weight: .medium))
                .cg_setTitleColor(.white)
                .cg_setTag(idx + 1)
                .cg_setBackgroundColor(getButtonColor(for: idx))
                .cg_addTarget(self, action: #selector(onActionClick))
            
            button.layer.cornerRadius = 18
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 0.2
            
            view.addSubview(button)
            
            if idx == 0 {
                button.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(20)
                    make.top.equalTo(navBar.snp.bottom).offset(20)
                    make.width.equalTo(80)
                    make.height.equalTo(36)
                }
            } else if idx < 3 {
                button.snp.makeConstraints { make in
                    make.leading.equalTo(lastBtn!.snp.trailing).offset(15)
                    make.centerY.equalTo(lastBtn!)
                    make.width.height.equalTo(lastBtn!)
                }
            } else {
                button.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(20 + (idx - 3) * 95)
                    make.top.equalTo(lastBtn!.snp.bottom).offset(15)
                    make.width.height.equalTo(lastBtn!)
                }
            }
            
            lastBtn = button
        }
    }
    
    private func setupGiftSystem() {
        // 礼物跑道
        giftRunway = LiveGiftRunwayView()
        view.addSubview(giftRunway)
        giftRunway.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview().offset(-50)
            make.height.equalTo(60)
        }
        
        // 中奖特效视图
        jackpotEffectView = JackpotEffectView()
        view.addSubview(jackpotEffectView)
        jackpotEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 添加说明标签
        let instructionLabel = UILabel()
        instructionLabel.text = "🎁 直播间礼物特效演示 🎁\n点击按钮体验不同的送礼动画效果"
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        view.addSubview(instructionLabel)
        
        instructionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(giftRunway.snp.top).offset(-30)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    private func getButtonColor(for index: Int) -> UIColor {
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed]
        return colors[index % colors.count]
    }
    
    // MARK: - 动画效果方法
    
    @objc
    func onActionClick(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            sendStandardGift(sender)
        case 2:
            sendTopEnterGift(sender)
        case 3:
            sendSpecialGift(sender)
        case 4:
            togglePauseAnimation(sender)
        case 5:
            clearAllGifts(sender)
        default:
            break
        }
    }
    
    /// 标准左侧进入动画
    @IBAction func sendStandardGift(_ sender: UIButton) {
        let randomGift = gifts.filter { !$0.isSpecial }.randomElement() ?? gifts[0]
        giftRunway.sendGift(randomGift, from: currentUser)
        print("普通礼物动画触发: \(randomGift.name)")
    }
    
    /// 顶部进入动画
    @IBAction func sendTopEnterGift(_ sender: UIButton) {
        let randomGift = gifts.randomElement() ?? gifts[1]
        createTopEnterGift(randomGift)
    }
    
    /// 特殊撞击动画
    @IBAction func sendSpecialGift(_ sender: UIButton) {
        let specialGift = gifts.filter { $0.isSpecial }.randomElement() ?? gifts[2]
        createSpecialGiftEffect(specialGift)
    }
    
    /// 暂停/恢复动画
    @IBAction func togglePauseAnimation(_ sender: UIButton) {
        isAnimationPaused.toggle()
        
        if isAnimationPaused {
            giftRunway.pauseAnimations()
            sender.setTitle("继续动画", for: .normal)
            sender.backgroundColor = .systemGreen
        } else {
            giftRunway.resumeAnimations()
            sender.setTitle("暂停动画", for: .normal)
            sender.backgroundColor = .systemPurple
        }
    }
    
    /// 清除所有礼物
    @IBAction func clearAllGifts(_ sender: UIButton) {
        giftRunway.clearAllGifts()
        
        // 添加清除动画反馈
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform.identity
            }
        }
    }
    
    // MARK: - 顶部进入礼物动画
    
    private func createTopEnterGift(_ gift: GiftModel) {
        let giftImageView = UIImageView()
        giftImageView.image = UIImage(systemName: gift.iconName)?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        giftImageView.contentMode = .scaleAspectFit
        
        let startX = CGFloat.random(in: 50...(view.bounds.width - 50))
        giftImageView.frame = CGRect(x: startX, y: -50, width: 40, height: 40)
        giftImageView.transform = CGAffineTransform(scaleX: 2.0, y: 2.0).rotated(by: CGFloat.random(in: 0...(CGFloat.pi * 2)))
        
        view.addSubview(giftImageView)
        
        // 确保布局
        view.layoutIfNeeded()
        
        // 下落动画
        let endY = giftRunway.frame.midY - 20
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5, options: []) {
            giftImageView.center = CGPoint(x: startX, y: endY)
            giftImageView.transform = CGAffineTransform.identity
            giftImageView.alpha = 0.9
        } completion: { _ in
            // 入场闪光
            self.flashAt(point: CGPoint(x: startX, y: endY))
            // 添加到跑道
            giftImageView.removeFromSuperview()
            self.giftRunway.sendGift(gift, from: self.currentUser)
            print("顶部礼物动画完成: \(gift.name)")
        }
    }
    
    // MARK: - 特殊礼物撞击效果
    
    private func createSpecialGiftEffect(_ gift: GiftModel) {
        // 礼物容器
        let giftContainer = UIView()
        giftContainer.backgroundColor = .clear
        let giftImageView = UIImageView()
        giftImageView.image = UIImage(systemName: gift.iconName)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        giftImageView.contentMode = .scaleAspectFit
        giftContainer.addSubview(giftImageView)
        
        giftImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        let startX = view.bounds.width / 2
        giftContainer.frame = CGRect(x: startX - 30, y: -100, width: 60, height: 60)
        giftContainer.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
        view.addSubview(giftContainer)
        view.layoutIfNeeded()
        
        // 下落动画（容器）
        let endY = giftRunway.frame.midY - 20
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5, options: []) {
            giftContainer.center = CGPoint(x: startX, y: endY)
            giftContainer.transform = .identity
        } completion: { _ in
            // 爆炸与震动
            self.jackpotEffectView.showJackpotEffect(at: CGPoint(x: startX, y: endY), gift: gift)
            self.impact()
            
            // 全屏豪华特效
            if gift.fullScreenEffect {
                self.showFullScreenEffect(for: gift)
            }
            
            // 添加到跑道
            giftContainer.removeFromSuperview()
            self.giftRunway.sendGift(gift, from: self.currentUser)
            print("特殊礼物动画完成: \(gift.name)")
        }
    }
    
    @objc
    func onJumpClick(_ sender: UIButton) {
        let vc = SecondController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    lazy var jumpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转  ", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 18
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    // MARK: - 全屏特效方法
    
    private func showFullScreenEffect(for gift: GiftModel) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.alpha = 0
        view.addSubview(overlay)
        
        // 大礼物图标
        let bigIcon = UIImageView(image: UIImage(systemName: gift.iconName)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal))
        bigIcon.contentMode = .scaleAspectFit
        bigIcon.frame = CGRect(x: -100, y: view.bounds.midY - 80, width: 80, height: 80)
        view.addSubview(bigIcon)
        
        // 彩带粒子
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 2)
        let cell = CAEmitterCell()
        cell.birthRate = 12
        cell.lifetime = 3.0
        cell.velocity = 180
        cell.velocityRange = 80
        cell.emissionLongitude = .pi
        cell.spinRange = 2
        cell.scale = 0.5
        cell.scaleRange = 0.3
        cell.alphaSpeed = -0.3
        cell.contents = particleImage().cgImage
        cell.color = UIColor.systemYellow.cgColor
        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        
        // 入场动画
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
        }
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6) {
            bigIcon.frame.origin.x = self.view.bounds.midX - 40
        }
        
        // 放大闪光
        UIView.animate(withDuration: 0.4, delay: 0.8, options: .curveEaseOut) {
            bigIcon.transform = CGAffineTransform(scaleX: 2.2, y: 2.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                bigIcon.alpha = 0
                overlay.alpha = 0
            } completion: { _ in
                bigIcon.removeFromSuperview()
                overlay.removeFromSuperview()
                emitter.removeFromSuperlayer()
            }
        }
    }
    
    private func particleImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.systemYellow.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func flashAt(point: CGPoint) {
        let flashView = UIView()
        flashView.backgroundColor = UIColor.white
        flashView.layer.cornerRadius = 20
        flashView.frame = CGRect(x: point.x - 20, y: point.y - 20, width: 40, height: 40)
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            flashView.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            flashView.alpha = 0
        } completion: { _ in
            flashView.removeFromSuperview()
        }
    }
    
    private func impact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerator.impactOccurred()
    }
}

// MARK: - CALayer 动画扩展
extension CALayer {
    func pauseAnimation() {
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    func resumeAnimation() {
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}
