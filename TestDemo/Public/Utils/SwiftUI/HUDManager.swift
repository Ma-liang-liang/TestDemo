//
//  HUDManager.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/4.
//
import SwiftUI

import SwiftUI

// MARK: - HUD 类型定义
enum HUDType {
    case loading(message: String?)
    case success(message: String)
    case error(message: String)
    case info(message: String)
}

// MARK: - HUD 管理类（全局单例）
class HUDManager: ObservableObject {
    static let shared = HUDManager()

    @Published var isVisible = false
    @Published var hudType: HUDType = .loading(message: nil)
    @Published var message: String = ""
    
    @Published var disabled = false

    private init() {}

    func showLoading(message: String? = nil) {
        DispatchQueue.main.async {
            self.hudType = .loading(message: message)
            self.message = message ?? ""
            self.isVisible = true
            self.disabled = true
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.isVisible = false
            self.disabled = false
        }
    }

    func showSuccess(message: String) {
        DispatchQueue.main.async {
            self.hudType = .success(message: message)
            self.message = message
            self.isVisible = true
            self.hideAfter(seconds: 1.5)
        }
    }

    func showError(message: String) {
        DispatchQueue.main.async {
            self.hudType = .error(message: message)
            self.message = message
            self.isVisible = true
            self.hideAfter(seconds: 2.0)
        }
    }

    func showInfo(message: String) {
        DispatchQueue.main.async {
            self.hudType = .info(message: message)
            self.message = message
            self.isVisible = true
            self.hideAfter(seconds: 1.5)
        }
    }

    private func hideAfter(seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.isVisible = false
        }
    }
}

// MARK: - HUD View 定义
struct HUDView: View {
    @ObservedObject var manager = HUDManager.shared

    var body: some View {
        Group {
            switch manager.hudType {
            case .loading(let message):
                LoadingHUDView(message: message)
            case .success(let message):
                IconHUDView(icon: "checkmark.circle.fill", color: .green, message: message)
            case .error(let message):
                IconHUDView(icon: "xmark.octagon.fill", color: .red, message: message)
            case .info(let message):
                IconHUDView(icon: "info.circle.fill", color: .blue, message: message)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .foregroundColor(.white)
        .opacity(manager.isVisible ? 1 : 0)
        .transition(.opacity)
        .animation(.easeInOut, value: manager.isVisible)
    }
}

private struct LoadingHUDView: View {
    var message: String?

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            if let message = message, !message.isEmpty {
                Text(message).font(.system(size: 14))
            }
        }
    }
}

private struct IconHUDView: View {
    var icon: String
    var color: Color
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 局部 HUD 包裹器（用于按钮等局部视图）
struct LocalHUD<Content: View>: View {
    @ObservedObject var manager = HUDManager.shared
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // 主内容（比如按钮）
            content

            // HUD 显示在内容之上，并居中
            if manager.isVisible {
                HUDView()
                    .zIndex(1)
            }
        }
        .disabled(manager.isVisible) // 防止重复点击
        .opacity(manager.isVisible ? 0.7 : 1) // 可选遮罩效果
    }
}

extension View {
   
    func hudView() -> some View {
        self.overlay (
            HUDView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
    
}
