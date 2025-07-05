//
//  testCommon.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/29.
//
import SwiftUI
import UIKit

// MARK: - 导航栈标识符
enum CGStackIdentifier: String, CaseIterable {
    case main = "mainStack"
    case explore = "exploreStack"
    case profile = "profileStack"
}

// MARK: - 运行时关联 Key
private struct AssociatedKeys {
    // 使用一个静态变量的地址作为唯一的 key，保证安全
    static var swiftUIViewTypeNameKey: UInt8 = 0
}

// MARK: - 多栈导航管理器
class CGNavigationManager: ObservableObject {
    // 单例
    static let shared = CGNavigationManager()
    
    // 存储多个导航栈
    private var navigationStacks: [CGStackIdentifier: UINavigationController] = [:]
    
    // 当前活跃的栈标识
    @Published var currentStackId: CGStackIdentifier = .main
    
    private init() {}
    
    // MARK: - 栈管理
    /// 获取或创建导航栈
    func getOrCreateStack(id: CGStackIdentifier) -> UINavigationController? {
        if let existingStack = navigationStacks[id] {
            return existingStack
        }
        return nil
    }
    
    /// 设置导航栈
    func setNavigationStack(_ navigationController: UINavigationController, forId id: CGStackIdentifier) {
        navigationStacks[id] = navigationController
    }
    
    /// 切换当前活跃栈
    func switchToStack(id: CGStackIdentifier) {
        if navigationStacks[id] != nil {
            currentStackId = id
        }
    }
    
    /// 移除导航栈
    func removeStack(id: CGStackIdentifier) {
        navigationStacks.removeValue(forKey: id)
    }
    
    /// 获取当前活跃栈
    private var currentStack: UINavigationController? {
        return navigationStacks[currentStackId]
    }
    
    // MARK: - 导航操作
    /// 推入新页面
    func push<Content: View>(_ view: Content, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        // 使用标准的 UIHostingController
        let hostingController = UIHostingController(rootView: view)
        
        // 【核心】通过运行时将 SwiftUI 视图的类型名称字符串关联到 controller 实例上
        let typeName = String(describing: Content.self)
        objc_setAssociatedObject(hostingController, &AssociatedKeys.swiftUIViewTypeNameKey, typeName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        hostingController.hidesBottomBarWhenPushed = false
        navigationController.pushViewController(hostingController, animated: animated)
    }
    
    /// 弹出当前页面
    func pop(animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popViewController(animated: animated)
    }
    
    /// 弹出到根页面
    func popToRoot(animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popToRootViewController(animated: animated)
    }
    
    /// 弹出到指定 SwiftUI 页面类型
    func popTo<T: View>(pageType: T.Type, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        let targetTypeName = String(describing: pageType)
        
        // 从后往前遍历寻找目标 VC
        for vc in navigationController.viewControllers.reversed() {
            // 【核心】通过运行时获取之前关联的类型名称字符串
            if let storedTypeName = objc_getAssociatedObject(vc, &AssociatedKeys.swiftUIViewTypeNameKey) as? String {
                // 如果名称匹配，就弹出到这个 vc
                if storedTypeName == targetTypeName {
                    navigationController.popToViewController(vc, animated: animated)
                    return // 找到后立即返回
                }
            }
        }
        
        print("Could not find a page of type \(targetTypeName) in the navigation stack.")
    }
    
    /// 替换当前页面
    func replace<Content: View>(_ view: Content, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        let hostingController = UIHostingController(rootView: view)
        
        // 同样需要关联类型名称
        let typeName = String(describing: Content.self)
        objc_setAssociatedObject(hostingController, &AssociatedKeys.swiftUIViewTypeNameKey, typeName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        hostingController.hidesBottomBarWhenPushed = false
        
        var viewControllers = navigationController.viewControllers
        if !viewControllers.isEmpty {
            viewControllers[viewControllers.count - 1] = hostingController
            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    /// 检查是否可以弹出
    func canPop(stackId: CGStackIdentifier? = nil) -> Bool {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return false }
        return navigationController.viewControllers.count > 1
    }
    
    /// 获取当前栈的页面数量
    func getStackCount(stackId: CGStackIdentifier? = nil) -> Int {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return 0 }
        return navigationController.viewControllers.count
    }
    
    /// 清空指定栈
    func clearStack(stackId: CGStackIdentifier? = nil) {
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
    let stackId: CGStackIdentifier
    
    init(stackId: CGStackIdentifier = .main, @ViewBuilder content: () -> Content) {
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
    let stackId: CGStackIdentifier
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = UIHostingController(rootView: rootView)
        
        // 【核心】根视图控制器也需要关联类型名称
        let typeName = String(describing: RootView.self)
        objc_setAssociatedObject(hostingController, &AssociatedKeys.swiftUIViewTypeNameKey, typeName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        let navigationController = UINavigationController(rootViewController: hostingController)
        
        navigationController.setNavigationBarHidden(true, animated: false)
        
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        
        CGNavigationManager.shared.setNavigationStack(navigationController, forId: stackId)
        
        // 只有当 manager 里还没有活跃栈时，才切换到当前创建的栈
        if CGNavigationManager.shared.getOrCreateStack(id: CGNavigationManager.shared.currentStackId) == nil {
            CGNavigationManager.shared.switchToStack(id: stackId)
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(stackId: stackId)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let stackId: CGStackIdentifier
        
        init(stackId: CGStackIdentifier) {
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

// MARK: - SwiftUI 导航栏 (可复用组件)
struct CGCustomNavigationBar: View {
    let config: CGNavigationBarConfig
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    leftItems()
                   
                    Spacer()
                    
                    rightItems()
                }
                titleView()
            }
            .padding(.horizontal, 16)
            .frame(height: config.height)
            .background(config.backgroundColor)
            
            if config.showSeparator {
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator))
            }
        }
    }
    
    
    private func titleView() -> some View {
        Text(config.title)
            .font(config.titleFont)
            .fontWeight(.semibold)
            .foregroundColor(config.titleColor)
            .lineLimit(1)
    }
    
    private func leftItems() -> some View {
        // 左侧区域
        HStack(spacing: 8) {
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
            
            ForEach(config.leftBarItems) { item in
                Button(action: item.action) {
                    if let icon = item.icon {
                        Image(systemName: icon).font(.system(size: 18))
                    } else if let text = item.text {
                        Text(text).font(.system(size: 17))
                    }
                }
                .foregroundColor(item.color)
            }
        }
    }
    
    private func rightItems() -> some View {
        HStack(spacing: 8) {
            ForEach(config.rightBarItems) { item in
                Button(action: item.action) {
                    if let icon = item.icon {
                        Image(systemName: icon).font(.system(size: 18))
                    } else if let text = item.text {
                        Text(text).font(.system(size: 17))
                    }
                }
                .foregroundColor(item.color)
            }
        }
        .frame(minWidth: 60, alignment: .trailing)
    }
    
    
}

// MARK: - 导航栏修饰符
struct CGNavigationBarModifier: ViewModifier {
    let config: CGNavigationBarConfig
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CGCustomNavigationBar(config: config)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(config.backgroundColor.edgesIgnoringSafeArea(.top))
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - 便捷扩展
extension View {
    /// 添加自定义导航栏 (完整配置)
    func navigationBar(config: CGNavigationBarConfig) -> some View {
        self.modifier(CGNavigationBarModifier(config: config))
    }
    
    /// 添加自定义导航栏 (简化配置)
    func navigationBar(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        rightBarItems: [CGNavigationBarItem] = [],
        leftBarItems: [CGNavigationBarItem] = [],
        customBackAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(CGNavigationBarModifier(
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
}

// MARK: - 示例页面
struct CGHomePage: View {
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("欢迎来到首页")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    CGNavigationCard(title: "用户中心", icon: "person.circle", color: .blue) {
                        CGNavigationManager.shared.push(CGUserCenterPage())
                    }
                    CGNavigationCard(title: "商品列表", icon: "bag", color: .green) {
                        CGNavigationManager.shared.push(CGProductListPage())
                    }
                    CGNavigationCard(title: "多栈测试", icon: "square.stack.3d.up", color: .purple) {
                        CGNavigationManager.shared.push(CGMultiStackTestPage())
                    }
                    CGNavigationCard(title: "无导航栏页面", icon: "eye.slash", color: .gray) {
                        CGNavigationManager.shared.push(CGNoNavBarPage())
                    }
                    CGNavigationCard(title: "自定义布局导航栏", icon: "wand.and.stars", color: .yellow) {
                        CGNavigationManager.shared.push(CGCustomLayoutPage())
                    }
                    CGNavigationCard(title: "设置", icon: "gearshape", color: .orange) {
                        CGNavigationManager.shared.push(CGSettingsPage())
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
                    CGNavigationManager.shared.push(CGNotificationPage())
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

// MARK: - 其他页面实现 (Page后缀)

// MARK: 多栈测试
struct CGMultiStackTestPage: View {
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("多栈导航测试").font(.title2).fontWeight(.bold)
            Text("当前栈ID: \(navigationManager.currentStackId.rawValue)").font(.caption).foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Button("切换到 'explore' 栈") {
                    CGNavigationManager.shared.push(Text("在'explore'栈的页面"), stackId: .explore)
                }.buttonStyle(CGButtonStyle(color: .purple))
                
                Button("无动画跳转") {
                    navigationManager.push(CGTestAnimationPage(), animated: false)
                }.buttonStyle(CGButtonStyle(color: .green))
                
                Button("替换当前页面") {
                    navigationManager.replace(CGReplacementPage(), animated: true)
                }.buttonStyle(CGButtonStyle(color: .orange))
                
                Button("清空栈(保留根页面)") {
                    navigationManager.clearStack()
                }.buttonStyle(CGButtonStyle(color: .red))
            }
            
            Spacer()
        }
        .padding()
        .navigationBar(title: "多栈测试")
    }
}

// MARK: 无导航栏页面示例
struct CGNoNavBarPage: View {
    var body: some View {
        ZStack {
            Color.mint.ignoresSafeArea()
            VStack {
                Text("这是一个没有使用\n`.navigationBar` 修饰符的页面")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: { CGNavigationManager.shared.pop() }) {
                    Text("手动返回").padding().background(.white).foregroundColor(.black).cornerRadius(10)
                }
            }
        }
    }
}

// MARK: 自定义布局导航栏示例
struct CGCustomLayoutPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("这是一个广告Banner").frame(maxWidth: .infinity).padding().background(Color.yellow)
            CGCustomNavigationBar(
                config: .init(
                    title: "自定义布局",
                    backgroundColor: .mint,
                    rightBarItems: [.init(icon: "star.fill", action: {})]
                )
            )
            List {
                Text("内容1")
                Text("内容2")
            }
        }
    }
}

struct CGTestAnimationPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("无动画跳转测试").font(.title2)
            Button("返回(有动画)") {
                CGNavigationManager.shared.pop(animated: true)
            }.buttonStyle(CGButtonStyle(color: .blue))
            Button("返回(无动画)") {
                CGNavigationManager.shared.pop(animated: false)
            }.buttonStyle(CGButtonStyle(color: .red))
        }
        .navigationBar(title: "动画测试")
    }
}

struct CGReplacementPage: View {
    var body: some View {
        VStack {
            Text("页面已被替换").font(.title2)
            Text("这个页面替换了之前的页面").foregroundColor(.secondary)
        }
        .navigationBar(title: "替换页面")
    }
}

struct CGUserCenterPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill").font(.system(size: 80)).foregroundColor(.blue)
                    Text("张三").font(.title2).fontWeight(.semibold)
                    Text("ID: 123456789").font(.caption).foregroundColor(.secondary)
                }.padding(.vertical, 20)
                
                VStack(spacing: 0) {
                    CGUserCenterRow(icon: "person", title: "个人信息") { CGNavigationManager.shared.push(CGProfilePage()) }
                    CGUserCenterRow(icon: "heart", title: "我的收藏") { CGNavigationManager.shared.push(CGFavoritePage()) }
                    CGUserCenterRow(icon: "clock", title: "浏览历史") { CGNavigationManager.shared.push(CGHistoryPage()) }
                }
                .background(Color(.systemBackground)).cornerRadius(12)
            }.padding()
        }
        .navigationBar(
            title: "用户中心",
            rightBarItems: [CGNavigationBarItem(icon: "gearshape") { CGNavigationManager.shared.push(CGSettingsPage()) }]
        )
        .background(Color(.systemGroupedBackground))
    }
}

struct CGProductListPage: View {
    let products = (1...20).map { "商品 \($0)" }
    var body: some View {
        List(products, id: \.self) { product in
            Button(product) {
                CGNavigationManager.shared.push(CGProductDetailPage(productName: product))
            }
            .foregroundColor(.primary)
        }
        .navigationBar(
            title: "商品列表",
            rightBarItems: [CGNavigationBarItem(icon: "line.3.horizontal.decrease.circle") {}]
        )
    }
}

struct CGProductDetailPage: View {
    let productName: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200).cornerRadius(8)
                VStack(alignment: .leading, spacing: 8) {
                    Text(productName).font(.title2).fontWeight(.bold)
                    Text("￥199.00").font(.title3).foregroundColor(.red)
                }
                VStack(spacing: 12) {
                    Button("再 Push 一个商品列表页") {
                        CGNavigationManager.shared.push(CGProductListPage())
                    }.buttonStyle(CGButtonStyle(color: .purple))
                    
                    Button("返回到上一个商品列表页 (popTo pageType)") {
                        CGNavigationManager.shared.popTo(pageType: CGProductListPage.self)
                    }.buttonStyle(CGButtonStyle(color: .blue))
                    
                    Button("返回首页 (popToRoot)") {
                        CGNavigationManager.shared.popToRoot()
                    }.buttonStyle(CGButtonStyle(color: .green))
                }
                .padding(.top, 30)
                Spacer()
            }.padding()
        }
        .navigationBar(title: productName)
    }
}

struct CGSettingsPage: View {
    
    @State private var showSheet = false
    
    var body: some View {
        VStack {
            List {
                Section("账户") { Text("修改密码"); Text("隐私设置") }
                Section("通用") { Text("推送通知"); Text("清除缓存") }
            }
            
            Spacer()
            
            Button("清空栈(保留根页面)") {
                showSheet.toggle()
            }
            .buttonStyle(CGButtonStyle(color: .red))
            .padding(.horizontal, 16)
            
            Spacer(minLength: UIScreen.safeAreaBottomHeight + 16)
        }
        .navigationBar(title: "设置")
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("License Agreement")
                    .font(.title)
                    .padding(50)
                Text("Terms and conditions go here.")
                .padding(50)
                Button("Dismiss",
                       action: {
                    showSheet.toggle()
                })
            }
        }
    }
}

struct CGProfilePage: View {
    var body: some View {
        Form {
            Section("基本信息") { HStack { Text("姓名"); Spacer(); Text("张三").foregroundColor(.secondary) } }
        }
        .navigationBar(title: "个人信息")
    }
}

struct CGFavoritePage: View {
    var body: some View {
        Text("我的收藏").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "我的收藏")
    }
}

struct CGHistoryPage: View {
    var body: some View {
        Text("浏览历史").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "浏览历史")
    }
}

struct CGNotificationPage: View {
    var body: some View {
        Text("通知中心").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "通知")
    }
}

// MARK: - 辅助视图
struct CGNavigationCard: View {
    let title: String, icon: String, color: Color, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 32)).foregroundColor(color)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CGUserCenterRow: View {
    let icon: String, title: String, action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.blue).frame(width: 24)
                Text(title).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CGButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white).padding().frame(maxWidth: .infinity)
            .background(color).cornerRadius(8).scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 应用入口
struct CGKitContentView: View {
    var body: some View {
        CGNavigationContainer(stackId: .main) {
            CGHomePage()
        }
    }
}

#Preview {
    CGKitContentView()
}
