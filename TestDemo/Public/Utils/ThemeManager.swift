import UIKit

// MARK: - 主题类型枚举
enum ThemeMode: Int, CaseIterable {
    case light = 0
    case dark = 1
    case system = 2
    
    var displayName: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }
}

// MARK: - 主题变化通知协议
protocol ThemeChangeDelegate: AnyObject {
    func themeDidChange(to theme: ThemeMode)
}

// MARK: - 主题管理器
class ThemeManager {
    
    // MARK: - 单例
    static let shared = ThemeManager()
    private init() {
        setupSystemThemeObserver()
        loadSavedTheme()
    }
    
    // MARK: - 属性
    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme_mode"
    private weak var delegates: NSHashTable<AnyObject>? = NSHashTable.weakObjects()
    
    // 当前主题模式
    private(set) var currentTheme: ThemeMode = .system {
        didSet {
            if oldValue != currentTheme {
                applyTheme()
                notifyThemeChange()
            }
        }
    }
    
    // MARK: - 公共方法
    
    /// 设置主题模式
    /// - Parameter theme: 主题模式
    func setTheme(_ theme: ThemeMode) {
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
        userDefaults.synchronize()
    }
    
    /// 添加主题变化监听器
    /// - Parameter delegate: 监听器
    func addThemeChangeDelegate(_ delegate: ThemeChangeDelegate) {
        delegates?.add(delegate)
    }
    
    /// 移除主题变化监听器
    /// - Parameter delegate: 监听器
    func removeThemeChangeDelegate(_ delegate: ThemeChangeDelegate) {
        delegates?.remove(delegate)
    }
    
    /// 获取当前实际显示的主题（考虑系统模式）
    var actualTheme: ThemeMode {
        if currentTheme == .system {
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
        return currentTheme
    }
    
    // MARK: - 私有方法
    
    /// 加载保存的主题设置
    private func loadSavedTheme() {
        let savedTheme = userDefaults.integer(forKey: themeKey)
        currentTheme = ThemeMode(rawValue: savedTheme) ?? .system
        applyTheme()
    }
    
    /// 应用主题
    private func applyTheme() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            
            for window in windows {
                switch self.currentTheme {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
    
    /// 设置系统主题变化监听
    private func setupSystemThemeObserver() {
        // 监听 trait collection 变化（iOS 13+）
        if #available(iOS 13.0, *) {
            // 通过监听根窗口的 trait collection 变化
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(systemThemeChanged),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
        
        // 更好的方式：在每个 ViewController 或 View 中重写 traitCollectionDidChange
        // 这里提供一个全局监听的补充方案
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                self.observeTraitChanges(for: window)
            }
        }
    }
    
    /// 监听特定窗口的 trait 变化
    @MainActor private func observeTraitChanges(for window: UIWindow) {
        if #available(iOS 17.0, *) {
            // iOS 17+ 使用新的 trait observation API
            window.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (traitEnvironment: UITraitEnvironment, previousTraitCollection: UITraitCollection) in
                self?.handleSystemThemeChange()
            }
        }
    }
    
    /// 系统主题变化处理
    @objc private func systemThemeChanged() {
        handleSystemThemeChange()
    }
    
    /// 处理系统主题变化
    private func handleSystemThemeChange() {
        if currentTheme == .system {
            DispatchQueue.main.async { [weak self] in
                self?.notifyThemeChange()
            }
        }
    }
    
    /// 通知主题变化（内部使用）
    internal func notifyThemeChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let delegates = self.delegates else { return }
            delegates.allObjects.forEach { delegate in
                if let themeDelegate = delegate as? ThemeChangeDelegate {
                    themeDelegate.themeDidChange(to: self.currentTheme)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 主题颜色扩展
extension ThemeManager {
    
    /// 获取主题颜色
    /// - Parameters:
    ///   - lightColor: 浅色模式颜色
    ///   - darkColor: 深色模式颜色
    /// - Returns: 动态颜色
    func color(light lightColor: UIColor, dark darkColor: UIColor) -> UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return darkColor
            case .light, .unspecified:
                return lightColor
            @unknown default:
                return lightColor
            }
        }
    }
    
    /// 获取主题图片
    /// - Parameters:
    ///   - lightImage: 浅色模式图片名
    ///   - darkImage: 深色模式图片名
    /// - Returns: 动态图片
    func image(light lightImage: String, dark darkImage: String) -> UIImage? {
        guard let lightImg = UIImage(named: lightImage),
              let darkImg = UIImage(named: darkImage) else {
            return UIImage(named: lightImage)
        }
        return nil
        
        // 创建动态图片
//        if #available(iOS 13.0, *) {
//            
//        }
//        let dynamicImage = UIImage { traitCollection in
//            switch traitCollection.userInterfaceStyle {
//            case .dark:
//                return darkImg
//            case .light, .unspecified:
//                return lightImg
//            @unknown default:
//                return lightImg
//            }
//        }
//        
//        return dynamicImage
    }
}

// MARK: - 预定义主题色彩
extension ThemeManager {
    
    /// 主背景色
    var backgroundColor: UIColor {
        return color(light: .systemBackground, dark: .systemBackground)
    }
    
    /// 次要背景色
    var secondaryBackgroundColor: UIColor {
        return color(light: .secondarySystemBackground, dark: .secondarySystemBackground)
    }
    
    /// 主要文字色
    var primaryTextColor: UIColor {
        return color(light: .label, dark: .label)
    }
    
    /// 次要文字色
    var secondaryTextColor: UIColor {
        return color(light: .secondaryLabel, dark: .secondaryLabel)
    }
    
    /// 分隔线颜色
    var separatorColor: UIColor {
        return color(light: .separator, dark: .separator)
    }
    
    /// 主题色
    var tintColor: UIColor {
        return color(light: .systemBlue, dark: .systemBlue)
    }
}

// MARK: - UIView 主题扩展
extension UIView {
    
    /// 应用主题背景色
    func applyThemeBackground() {
        backgroundColor = ThemeManager.shared.backgroundColor
    }
    
    /// 应用次要背景色
    func applySecondaryThemeBackground() {
        backgroundColor = ThemeManager.shared.secondaryBackgroundColor
    }
}

// MARK: - UILabel 主题扩展
extension UILabel {
    
    /// 应用主要文字主题
    func applyPrimaryTextTheme() {
        textColor = ThemeManager.shared.primaryTextColor
    }
    
    /// 应用次要文字主题
    func applySecondaryTextTheme() {
        textColor = ThemeManager.shared.secondaryTextColor
    }
}

// MARK: - UIImageView 主题扩展
extension UIImageView {
    
    /// 设置主题图片
    /// - Parameters:
    ///   - lightImageName: 浅色模式图片名
    ///   - darkImageName: 深色模式图片名
    func setThemeImage(light lightImageName: String, dark darkImageName: String) {
        image = ThemeManager.shared.image(light: lightImageName, dark: darkImageName)
    }
}

// MARK: - 主题感知基类 ViewController
class ThemeAwareViewController: UIViewController, ThemeChangeDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ThemeManager.shared.addThemeChangeDelegate(self)
        applyTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // 检查用户界面样式是否发生变化
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // 只有在跟随系统模式时才响应系统变化
                if ThemeManager.shared.currentTheme == .system {
                    ThemeManager.shared.notifyThemeChange()
                }
            }
        }
    }
    
    // MARK: - ThemeChangeDelegate
    func themeDidChange(to theme: ThemeMode) {
        applyTheme()
    }
    
    /// 子类重写此方法来应用主题
    func applyTheme() {
        // 子类实现具体的主题应用逻辑
        view.applyThemeBackground()
    }
    
    deinit {
        ThemeManager.shared.removeThemeChangeDelegate(self)
    }
}

// MARK: - 使用示例
class ExampleViewController: ThemeAwareViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 设置主题切换按钮
        let themeButton = UIBarButtonItem(
            title: "主题",
            style: .plain,
            target: self,
            action: #selector(showThemeOptions)
        )
        navigationItem.rightBarButtonItem = themeButton
    }
    
    @objc private func showThemeOptions() {
        let alertController = UIAlertController(title: "选择主题", message: nil, preferredStyle: .actionSheet)
        
        for theme in ThemeMode.allCases {
            let action = UIAlertAction(title: theme.displayName, style: .default) { _ in
                ThemeManager.shared.setTheme(theme)
            }
            
            // 标记当前选中的主题
            if theme == ThemeManager.shared.currentTheme {
                action.setValue(true, forKey: "checked")
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad 适配
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - 重写主题应用方法
    override func applyTheme() {
        super.applyTheme()
        
        // 应用背景主题
        backgroundView.applySecondaryThemeBackground()
        
        // 应用文字主题
        titleLabel.applyPrimaryTextTheme()
        
        // 应用图片主题
        iconImageView.setThemeImage(light: "icon_light", dark: "icon_dark")
        
        // 更新导航栏
        navigationController?.navigationBar.tintColor = ThemeManager.shared.tintColor
    }
}
