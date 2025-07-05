//
//  testCommon.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/29.
//
import SwiftUI
import UIKit

// MARK: - 多栈导航管理器
class CGNavigationManager: ObservableObject {
    // 单例
    static let shared = CGNavigationManager()
    
    // 存储多个导航栈
    private var navigationStacks: [String: UINavigationController] = [:]
    
    // 当前活跃的栈标识
    @Published var currentStackId: String = "default"
    
    private init() {}
    
    // MARK: - 栈管理
    /// 创建或获取导航栈
    func getOrCreateStack(id: String) -> UINavigationController? {
        if let existingStack = navigationStacks[id] {
            return existingStack
        }
        return nil
    }
    
    /// 设置导航栈
    func setNavigationStack(_ navigationController: UINavigationController, forId id: String) {
        navigationStacks[id] = navigationController
    }
    
    /// 切换当前活跃栈
    func switchToStack(id: String) {
        if navigationStacks[id] != nil {
            currentStackId = id
        }
    }
    
    /// 移除导航栈
    func removeStack(id: String) {
        navigationStacks.removeValue(forKey: id)
    }
    
    /// 获取当前活跃栈
    private var currentStack: UINavigationController? {
        return navigationStacks[currentStackId]
    }
    
    // MARK: - 导航操作
    /// 推入新页面
    func push<Content: View>(_ view: Content, animated: Bool = true, stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId)")
            return
        }
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = false
        navigationController.pushViewController(hostingController, animated: animated)
    }
    
    /// 弹出当前页面
    func pop(animated: Bool = true, stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popViewController(animated: animated)
    }
    
    /// 弹出到根页面
    func popToRoot(animated: Bool = true, stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popToRootViewController(animated: animated)
    }
    
    /// 弹出到指定类型页面
    func popTo(_ viewControllerType: AnyClass, animated: Bool = true, stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        for vc in navigationController.viewControllers.reversed() {
            if vc.isKind(of: viewControllerType) {
                navigationController.popToViewController(vc, animated: animated)
                break
            }
        }
    }
    
    /// 替换当前页面
    func replace<Content: View>(_ view: Content, animated: Bool = true, stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = false
        
        var viewControllers = navigationController.viewControllers
        if !viewControllers.isEmpty {
            viewControllers[viewControllers.count - 1] = hostingController
            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    /// 检查是否可以弹出
    func canPop(stackId: String? = nil) -> Bool {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return false }
        return navigationController.viewControllers.count > 1
    }
    
    /// 获取当前栈的页面数量
    func getStackCount(stackId: String? = nil) -> Int {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return 0 }
        return navigationController.viewControllers.count
    }
    
    /// 清空指定栈
    func clearStack(stackId: String? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        if let rootViewController = navigationController.viewControllers.first {
            navigationController.setViewControllers([rootViewController], animated: false)
        }
    }
}

// MARK: - 导航容器视图
struct CGNavigationContainer<Content: View>: View {
    let content: Content
    let stackId: String
    
    init(stackId: String = "default", @ViewBuilder content: () -> Content) {
        self.stackId = stackId
        self.content = content()
    }
    
    var body: some View {
        CGNavigationControllerWrapper(rootView: content, stackId: stackId)
            .ignoresSafeArea()
    }
}

// MARK: - UINavigationController 包装器
struct CGNavigationControllerWrapper<RootView: View>: UIViewControllerRepresentable {
    let rootView: RootView
    let stackId: String
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = UIHostingController(rootView: rootView)
        let navigationController = UINavigationController(rootViewController: hostingController)
        
        // 隐藏系统导航栏
        navigationController.setNavigationBarHidden(true, animated: false)
        
        // 启用侧滑返回
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        
        // 设置导航管理器
        CGNavigationManager.shared.setNavigationStack(navigationController, forId: stackId)
        CGNavigationManager.shared.switchToStack(id: stackId)
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(stackId: stackId)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let stackId: String
        
        init(stackId: String) {
            self.stackId = stackId
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return CGNavigationManager.shared.canPop(stackId: stackId)
        }
    }
}

// MARK: - 导航栏配置
struct CGNavigationBarConfig {
    let title: String
    let showBackButton: Bool
    let backgroundColor: Color
    let titleColor: Color
    let backButtonColor: Color
    let rightBarItems: [CGNavigationBarItem]
    let leftBarItems: [CGNavigationBarItem]
    let height: CGFloat
    let showSeparator: Bool
    let backButtonText: String
    let titleFont: Font
    let customBackAction: (() -> Void)?
    
    init(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        backButtonColor: Color = .blue,
        rightBarItems: [CGNavigationBarItem] = [],
        leftBarItems: [CGNavigationBarItem] = [],
        height: CGFloat = 44,
        showSeparator: Bool = true,
        backButtonText: String = "返回",
        titleFont: Font = .headline,
        customBackAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.backButtonColor = backButtonColor
        self.rightBarItems = rightBarItems
        self.leftBarItems = leftBarItems
        self.height = height
        self.showSeparator = showSeparator
        self.backButtonText = backButtonText
        self.titleFont = titleFont
        self.customBackAction = customBackAction
    }
}

// MARK: - 导航栏按钮项
struct CGNavigationBarItem: Identifiable {
    let id = UUID()
    let icon: String?
    let text: String?
    let color: Color
    let action: () -> Void
    
    init(icon: String, color: Color = .blue, action: @escaping () -> Void) {
        self.icon = icon
        self.text = nil
        self.color = color
        self.action = action
    }
    
    init(text: String, color: Color = .blue, action: @escaping () -> Void) {
        self.icon = nil
        self.text = text
        self.color = color
        self.action = action
    }
}

// MARK: - SwiftUI 导航栏
struct CGCustomNavigationBar: View {
    let config: CGNavigationBarConfig
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // 左侧区域
                HStack(spacing: 8) {
                    // 返回按钮
                    if config.showBackButton && navigationManager.canPop() {
                        Button(action: {
                            if let customAction = config.customBackAction {
                                customAction()
                            } else {
                                navigationManager.pop()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                Text(config.backButtonText)
                                    .font(.system(size: 17))
                            }
                            .foregroundColor(config.backButtonColor)
                        }
                    }
                    
                    // 左侧自定义按钮
                    ForEach(config.leftBarItems) { item in
                        Button(action: item.action) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                            } else if let text = item.text {
                                Text(text)
                                    .font(.system(size: 17))
                            }
                        }
                        .foregroundColor(item.color)
                    }
                }
                
                Spacer()
                
                // 标题
                Text(config.title)
                    .font(config.titleFont)
                    .fontWeight(.semibold)
                    .foregroundColor(config.titleColor)
                    .lineLimit(1)
                
                Spacer()
                
                // 右侧按钮
                HStack(spacing: 8) {
                    ForEach(config.rightBarItems) { item in
                        Button(action: item.action) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                            } else if let text = item.text {
                                Text(text)
                                    .font(.system(size: 17))
                            }
                        }
                        .foregroundColor(item.color)
                    }
                }
                .frame(minWidth: 60, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .frame(height: config.height)
            .background(config.backgroundColor)
            
            // 分割线
            if config.showSeparator {
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator))
            }
        }
    }
}

// MARK: - 导航栏修饰符
struct NavigationBarModifier: ViewModifier {
    let config: CGNavigationBarConfig
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // 状态栏占位
            Color.clear
                .frame(height: 0)
                .background(config.backgroundColor)
            
            // 自定义导航栏
            CGCustomNavigationBar(config: config)
            
            // 页面内容
            content
        }
        .background(config.backgroundColor.ignoresSafeArea(.all, edges: .top))
    }
}

// MARK: - 便捷扩展
extension View {
    /// 添加导航栏
    func navigationBar(config: CGNavigationBarConfig) -> some View {
        self.modifier(NavigationBarModifier(config: config))
    }
    
    /// 简化的导航栏配置
    func navigationBar(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        rightBarItems: [CGNavigationBarItem] = [],
        leftBarItems: [CGNavigationBarItem] = [],
        customBackAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(NavigationBarModifier(
            config: CGNavigationBarConfig(
                title: title,
                showBackButton: showBackButton,
                backgroundColor: backgroundColor,
                rightBarItems: rightBarItems,
                leftBarItems: leftBarItems,
                customBackAction: customBackAction
            )
        ))
    }
    
    /// 导航跳转
    func navigate<T: View>(
        to destination: T,
        animated: Bool = true,
        stackId: String? = nil
    ) {
        CGNavigationManager.shared.push(destination, animated: animated, stackId: stackId)
    }
}

// MARK: - 示例页面
struct HomeView: View {
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("欢迎来到首页")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    CGNavigationCard(
                        title: "用户中心",
                        icon: "person.circle",
                        color: .blue
                    ) {
                        CGNavigationManager.shared.push(CGUserCenterView())
                    }
                    
                    CGNavigationCard(
                        title: "商品列表",
                        icon: "bag",
                        color: .green
                    ) {
                        CGNavigationManager.shared.push(CGProductListView())
                    }
                    
                    CGNavigationCard(
                        title: "多栈测试",
                        icon: "square.stack.3d.up",
                        color: .purple
                    ) {
                        CGNavigationManager.shared.push(MultiStackTestView())
                    }
                    
                    CGNavigationCard(
                        title: "设置",
                        icon: "gearshape",
                        color: .orange
                    ) {
                        CGNavigationManager.shared.push(CGSettingsView())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBar(
            title: "首页",
            showBackButton: false,
            rightBarItems: [
                CGNavigationBarItem(icon: "bell", color: .red) {
                    CGNavigationManager.shared.push(CGNotificationView())
                },
                CGNavigationBarItem(icon: "magnifyingglass") {
                    showAlert = true
                }
            ]
        )
        .alert("搜索", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text("搜索功能正在开发中...")
        }
    }
}

// MARK: - 多栈测试页面
struct MultiStackTestView: View {
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("多栈导航测试")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("当前栈ID: \(navigationManager.currentStackId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Button("创建新栈 (stack2)") {
                    // 这里需要在新的容器中创建新栈
                    // 实际使用时可能需要在TabView或其他容器中实现
                }
                .buttonStyle(CGButtonStyle(color: .blue))
                
                Button("无动画跳转") {
                    navigationManager.push(CGTestAnimationView(), animated: false)
                }
                .buttonStyle(CGButtonStyle(color: .green))
                
                Button("替换当前页面") {
                    navigationManager.replace(CGReplacementView(), animated: true)
                }
                .buttonStyle(CGButtonStyle(color: .orange))
                
                Button("清空栈(保留根页面)") {
                    navigationManager.clearStack()
                }
                .buttonStyle(CGButtonStyle(color: .red))
            }
            
            Spacer()
        }
        .padding()
        .navigationBar(title: "多栈测试")
    }
}

// MARK: - 测试页面
struct CGTestAnimationView: View {
    var body: some View {
        VStack {
            Text("无动画跳转测试")
                .font(.title2)
            
            Button("返回(有动画)") {
                CGNavigationManager.shared.pop(animated: true)
            }
            .buttonStyle(CGButtonStyle(color: .blue))
            
            Button("返回(无动画)") {
                CGNavigationManager.shared.pop(animated: false)
            }
            .buttonStyle(CGButtonStyle(color: .red))
        }
        .navigationBar(title: "动画测试")
    }
}

struct CGReplacementView: View {
    var body: some View {
        VStack {
            Text("页面已被替换")
                .font(.title2)
            
            Text("这个页面替换了之前的页面")
                .foregroundColor(.secondary)
        }
        .navigationBar(title: "替换页面")
    }
}

// MARK: - 按钮样式
struct CGButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 用户中心页面
struct CGUserCenterView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户头像和信息
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("张三")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("ID: 123456789")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                
                // 功能列表
                VStack(spacing: 0) {
                    CGUserCenterRow(icon: "person", title: "个人信息") {
                        CGNavigationManager.shared.push(CGProfileView())
                    }
                    
                    CGUserCenterRow(icon: "heart", title: "我的收藏") {
                        CGNavigationManager.shared.push(CGFavoriteView())
                    }
                    
                    CGUserCenterRow(icon: "clock", title: "浏览历史") {
                        CGNavigationManager.shared.push(CGHistoryView())
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationBar(
            title: "用户中心",
            rightBarItems: [
                CGNavigationBarItem(icon: "gearshape") {
                    CGNavigationManager.shared.push(CGSettingsView())
                }
            ]
        )
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 其他页面组件
struct CGNavigationCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CGUserCenterRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 其他示例页面
struct CGProductListView: View {
    let products = (1...20).map { "商品 \($0)" }
    
    var body: some View {
        List(products, id: \.self) { product in
            Button(product) {
                CGNavigationManager.shared.push(CGProductDetailView(productName: product))
            }
            .foregroundColor(.primary)
        }
        .navigationBar(
            title: "商品列表",
            rightBarItems: [
                CGNavigationBarItem(icon: "line.3.horizontal.decrease.circle") {
                    // 筛选功能
                }
            ]
        )
    }
}

struct CGProductDetailView: View {
    let productName: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(productName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("￥199.00")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBar(title: "商品详情")
    }
}

struct CGSettingsView: View {
    var body: some View {
        List {
            Section("账户") {
                Text("修改密码")
                Text("隐私设置")
            }
            
            Section("通用") {
                Text("推送通知")
                Text("清除缓存")
            }
        }
        .navigationBar(title: "设置")
    }
}

struct CGProfileView: View {
    var body: some View {
        Form {
            Section("基本信息") {
                HStack {
                    Text("姓名")
                    Spacer()
                    Text("张三")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationBar(title: "个人信息")
    }
}

struct CGFavoriteView: View {
    var body: some View {
        Text("我的收藏")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBar(title: "我的收藏")
    }
}

struct CGHistoryView: View {
    var body: some View {
        Text("浏览历史")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBar(title: "浏览历史")
    }
}

struct CGNotificationView: View {
    var body: some View {
        Text("通知中心")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBar(title: "通知")
    }
}

// MARK: - 应用入口
struct CGKitContentView: View {
    var body: some View {
        CGNavigationContainer(stackId: "main") {
            HomeView()
        }
    }
}

#Preview {
    CGKitContentView()
}
