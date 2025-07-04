//
//  testCommon.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/29.
//
import SwiftUI
import UIKit

import SwiftUI

// MARK: - 导航管理器
class CGNavigationManager: ObservableObject {
//    static let shared = CGNavigationManager()
    private static var navigationController: UINavigationController?
    
    private init() {}
    
   static func setNavigationController(_ nc: UINavigationController) {
        self.navigationController = nc
    }
    
    static func push<Content: View>(_ view: Content) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.hidesBottomBarWhenPushed = false
        CGNavigationManager.navigationController?.pushViewController(hostingController, animated: true)
    }
    
    static func pop() {
        navigationController?.popViewController(animated: true)
    }
    
    static func popToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    static func popTo(_ viewControllerType: AnyClass) {
        guard let navigationController = navigationController else { return }
        for vc in navigationController.viewControllers.reversed() {
            if vc.isKind(of: viewControllerType) {
                navigationController.popToViewController(vc, animated: true)
                break
            }
        }
    }
    
    static var canPop: Bool {
        guard let nc = navigationController else { return false }
        return nc.viewControllers.count > 1
    }
}

// MARK: - 导航容器视图
struct CGNavigationContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        CGNavigationControllerWrapper(rootView: content)
            .ignoresSafeArea()
    }
}

// MARK: - UINavigationController 包装器
struct CGNavigationControllerWrapper<RootView: View>: UIViewControllerRepresentable {
    let rootView: RootView
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = UIHostingController(rootView: rootView)
        let navigationController = UINavigationController(rootViewController: hostingController)
        
        // 隐藏系统导航栏
        navigationController.setNavigationBarHidden(true, animated: false)
        
        // 启用侧滑返回
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        
        // 设置导航管理器
        CGNavigationManager.setNavigationController(navigationController)
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return CGNavigationManager.canPop
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
    let height: CGFloat
    let showSeparator: Bool
    
    init(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        backButtonColor: Color = .blue,
        rightBarItems: [CGNavigationBarItem] = [],
        height: CGFloat = 44,
        showSeparator: Bool = true
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.backButtonColor = backButtonColor
        self.rightBarItems = rightBarItems
        self.height = height
        self.showSeparator = showSeparator
    }
}

// MARK: - 导航栏按钮项
struct CGNavigationBarItem: Identifiable {
    let id = UUID()
    let icon: String?
    let text: String?
    let action: () -> Void
    
    init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.text = nil
        self.action = action
    }
    
    init(text: String, action: @escaping () -> Void) {
        self.icon = nil
        self.text = text
        self.action = action
    }
}

// MARK: - SwiftUI 导航栏
struct CGCustomNavigationBar: View {
    let config: CGNavigationBarConfig
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // 返回按钮
                if config.showBackButton && CGNavigationManager.canPop {
                    Button(action: {
                        CGNavigationManager.pop()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                            Text("返回")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(config.backButtonColor)
                    }
                } else if config.showBackButton {
                    // 占位符，保持布局一致
                    Color.clear.frame(width: 60, height: 30)
                }
                
                Spacer()
                
                // 标题
                Text(config.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(config.titleColor)
                
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
                        .foregroundColor(.blue)
                    }
                }
                .frame(minWidth: config.showBackButton ? 60 : 0, alignment: .trailing)
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

// MARK: - 页面基础视图
struct CGBasePage<Content: View>: View {
    let config: CGNavigationBarConfig
    let content: Content
    
    init(
        config: CGNavigationBarConfig,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.content = content()
    }
    
    var body: some View {
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
    func navigationPage(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        rightBarItems: [CGNavigationBarItem] = []
    ) -> some View {
        CGBasePage(
            config: CGNavigationBarConfig(
                title: title,
                showBackButton: showBackButton,
                backgroundColor: backgroundColor,
                rightBarItems: rightBarItems
            )
        ) {
            self
        }
    }
    
    func navigate<T: View>(to destination: T) {
        CGNavigationManager.push(destination)
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
                        CGNavigationManager.push(CGUserCenterView())
                    }
                    
                    CGNavigationCard(
                        title: "商品列表",
                        icon: "bag",
                        color: .green
                    ) {
                        CGNavigationManager.push(CGProductListView())
                    }
                    
                    CGNavigationCard(
                        title: "订单管理",
                        icon: "doc.text",
                        color: .orange
                    ) {
                        CGNavigationManager.push(CGOrderListView())
                    }
                    
                    CGNavigationCard(
                        title: "设置",
                        icon: "gearshape",
                        color: .purple
                    ) {
                        CGNavigationManager.push(CGSettingsView())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationPage(
            title: "首页",
            showBackButton: false,
            rightBarItems: [
                CGNavigationBarItem(icon: "bell") {
                    CGNavigationManager.push(CGNotificationView())
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

// MARK: - 导航卡片组件
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

// MARK: - 用户中心
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
                        CGNavigationManager.push(CGProfileView())
                    }
                    
                    CGUserCenterRow(icon: "heart", title: "我的收藏") {
                        CGNavigationManager.push(CGFavoriteView())
                    }
                    
                    CGUserCenterRow(icon: "clock", title: "浏览历史") {
                        CGNavigationManager.push(CGHistoryView())
                    }
                    
                    CGUserCenterRow(icon: "questionmark.circle", title: "帮助中心") {
                        CGNavigationManager.push(CGHelpView())
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationPage(title: "用户中心")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            print("CGUserCenterView-----onAppear")
        }
        .onDisappear {
            print("CGUserCenterView-----onDisappear")
        }
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

// MARK: - 商品列表
struct CGProductListView: View {
    let products = (1...20).map { "商品 \($0)" }
    
    var body: some View {
        List(products, id: \.self) { product in
            Button(product) {
                CGNavigationManager.push(CGProductDetailView(productName: product))
            }
            .foregroundColor(.primary)
        }
        .navigationPage(
            title: "商品列表",
            rightBarItems: [
                CGNavigationBarItem(icon: "line.3.horizontal.decrease.circle") {
                    // 筛选功能
                }
            ]
        )
    }
}

// MARK: - 商品详情
struct CGProductDetailView: View {
    let productName: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 商品图片占位
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
                    
                    Text("这是商品的详细描述信息...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button("加入购物车") {
                        // 加入购物车逻辑
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("立即购买") {
                        CGNavigationManager.push(CGCheckoutView(productName: productName))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationPage(
            title: "商品详情",
            rightBarItems: [
                CGNavigationBarItem(icon: "heart") {
                    // 收藏功能
                },
                CGNavigationBarItem(icon: "square.and.arrow.up") {
                    // 分享功能
                }
            ]
        )
    }
}

// MARK: - 其他示例页面
struct CGOrderListView: View {
    var body: some View {
        List(1...10, id: \.self) { index in
            Text("订单 #\(index)")
        }
        .navigationPage(title: "订单管理")
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
        .navigationPage(title: "设置")
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
                
                HStack {
                    Text("手机号")
                    Spacer()
                    Text("138****1234")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationPage(title: "个人信息")
    }
}

struct CGFavoriteView: View {
    var body: some View {
        Text("我的收藏")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationPage(title: "我的收藏")
    }
}

struct CGHistoryView: View {
    var body: some View {
        Text("浏览历史")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationPage(title: "浏览历史")
    }
}

struct CGHelpView: View {
    var body: some View {
        Text("帮助中心")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationPage(title: "帮助中心")
    }
}

struct CGNotificationView: View {
    var body: some View {
        Text("通知中心")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationPage(title: "通知")
    }
}

struct CGCheckoutView: View {
    let productName: String
    
    var body: some View {
        VStack {
            Text("结算页面")
                .font(.title2)
            
            Text("商品: \(productName)")
                .padding()
            
            Spacer()
            
            Button("返回首页") {
                CGNavigationManager.popToRoot()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationPage(title: "结算")
    }
}

// MARK: - 应用入口
struct CGKitContentView: View {
    var body: some View {
        CGNavigationContainer {
            HomeView()
        }
    }
}

#Preview {
    CGKitContentView()
}
