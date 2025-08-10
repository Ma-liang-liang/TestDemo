//
//  ComplexUIDemo.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/8.
//

import SwiftUI

struct ComplexUIDemo: View {
    @State private var selectedTab = 0
    @State private var isShowingSettings = false
    @State private var isLiked = false
    @State private var likeCount = 243
    @State private var showAllPhotos = false
    @State private var selectedPhotoIndex = 0
    @State private var isAnimating = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 280
    
    @Environment(\.dismiss) private var dismiss

    let posts: [Post] = [
        Post(id: 1, imageName: "blue_bird", title: "🏔️ Mountain Adventure", likes: 1243, comments: 89, description: "Exploring the breathtaking peaks of the Swiss Alps. Nature at its finest!"),
        Post(id: 2, imageName: "blue_fish", title: "🌅 Golden Sunset", likes: 892, comments: 67, description: "Captured this magical moment at the beach. The colors were absolutely stunning."),
        Post(id: 3, imageName: "img001", title: "🏙️ Urban Vibes", likes: 567, comments: 34, description: "City life never sleeps. The energy here is infectious and inspiring.")
    ]
    
    let photos = ["blue_bird", "blue_fish", "img001", "recharge_diamond", "topup_bg_daimond", "bg_charm"]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 主要内容
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            // 头部个人信息区域
                            profileHeaderView()
                            
                            // 状态指示器
                            activityIndicators()
                            
                            // 照片网格区域
                            if !showAllPhotos {
                                photoGridSection()
                            } else {
                                fullPhotoSection()
                            }
                            
                            // 选项卡切换
                            tabSelectorView()
                            
                            // 动态内容
                            contentForSelectedTab()
                        }
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                        }
                    )
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                }
            }
            .navigationBar(
                title: "个人主页",
                showBackButton: false,
                rightBarItems: [
                    CGNavigationBarItem(icon: "ellipsis.circle") {
                        isShowingSettings.toggle()
                    }
                ],
                leftBarItems: [
                    CGNavigationBarItem(icon: "chevron.left", color: .blue) {
                        if CGNavigationManager.shared.canPop() {
                            CGNavigationManager.shared.pop()
                        } else {
                            dismiss()
                        }
                    }
                ]
            )
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
    
    // MARK: - 个人信息头部
    private func profileHeaderView() -> some View {
        ZStack(alignment: .bottom) {
            // 背景图片
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6),
                            Color.pink.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: headerHeight)
                .overlay(
                    // 装饰性图案
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.1))
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .offset(x: 50, y: -50)
                    }
                )
            
            VStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .gray.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .clipShape(Circle())
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                
                // 姓名和简介
                VStack(spacing: 8) {
                    Text("Alex Johnson")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("📸 数字设计师 & 摄影师")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Text("✈️ 热爱旅行，捕捉生活中的美好瞬间")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                
                // 操作按钮
                HStack(spacing: 20) {
                    // 关注按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            // 关注逻辑
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("关注")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    // 消息按钮
                    Button(action: {
                        // 消息逻辑
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "message")
                                .font(.system(size: 14, weight: .semibold))
                            Text("消息")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - 活动指示器
    private func activityIndicators() -> some View {
        HStack(spacing: 30) {
            VStack(spacing: 4) {
                Text("128")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text("帖子")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("2.4K")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text("关注者")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("892")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text("正在关注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - 照片网格部分
    private func photoGridSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("📷 照片集锦")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button("查看全部") {
                    withAnimation(.spring()) {
                        showAllPhotos = true
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            
            PhotoGridView(photos: Array(photos.prefix(6)), showAllPhotos: $showAllPhotos)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - 全屏照片部分
    private func fullPhotoSection() -> some View {
        FullPhotoView(photos: photos, selectedIndex: $selectedPhotoIndex, showAllPhotos: $showAllPhotos)
            .frame(height: 350)
            .padding(.bottom, 20)
    }
    
    // MARK: - 选项卡选择器
    private func tabSelectorView() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                let tabNames = ["📝 动态", "❤️ 喜欢", "🔖 收藏"]
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabNames[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - 选项卡内容
    private func contentForSelectedTab() -> some View {
        Group {
            if selectedTab == 0 {
                PostsView(posts: posts)
            } else if selectedTab == 1 {
                LikesView()
            } else {
                SavedView()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
}

// MARK: - 辅助结构

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 子视图

struct PhotoGridView: View {
    let photos: [String]
    @Binding var showAllPhotos: Bool
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                ForEach(photos.indices, id: \.self) { index in
                    Image(photos[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: (UIScreen.main.bounds.width - 40) / 3, height: (UIScreen.main.bounds.width - 40) / 3)
                        .clipped()
                        .onTapGesture {
                            showAllPhotos = true
                        }
                }
            }
            
            if photos.count == 6 {
                Button(action: {
                    showAllPhotos = true
                }) {
                    Text("View All Photos")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
        }
    }
}

struct FullPhotoView: View {
    let photos: [String]
    @Binding var selectedIndex: Int
    @Binding var showAllPhotos: Bool
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(photos.indices, id: \.self) { index in
                Image(photos[index])
                    .resizable()
                    .scaledToFit()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .overlay(
            Button(action: {
                showAllPhotos = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16),
            alignment: .topTrailing
        )
        .frame(height: 300)
        .background(Color.black)
    }
}

struct PostsView: View {
    let posts: [Post]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(posts) { post in
                PostView(post: post)
                    .padding(.horizontal)
            }
        }
    }
}

struct PostView: View {
    let post: Post
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image("profile")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text("Alex Johnson")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("2 hours ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            Text(post.title)
                .font(.headline)
            
            if let desc = post.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Image(post.imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                Button(action: {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(likeCount)")
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
            }
            .foregroundColor(.primary)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct LikesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
            
            Text("No Likes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When you like posts, they'll appear here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 80)
    }
}

struct SavedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("No Saved Posts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save posts to easily find them later.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 80)
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: Text("Edit Profile")) {
                        SettingRow(icon: "person", title: "Edit Profile")
                    }
                    
                    NavigationLink(destination: Text("Account Settings")) {
                        SettingRow(icon: "gear", title: "Account Settings")
                    }
                }
                
                Section {
                    NavigationLink(destination: Text("Notifications")) {
                        SettingRow(icon: "bell", title: "Notifications")
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        SettingRow(icon: "lock", title: "Privacy")
                    }
                }
                
                Section {
                    Button(action: {
                        // 登出逻辑
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        SettingRow(icon: "arrow.left.square", title: "Log Out", color: .red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(color)
        }
    }
}

// MARK: - 数据模型

struct Post: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let likes: Int
    let comments: Int
    let description: String?
    
    init(id: Int, imageName: String, title: String, likes: Int, comments: Int, description: String? = nil) {
        self.id = id
        self.imageName = imageName
        self.title = title
        self.likes = likes
        self.comments = comments
        self.description = description
    }
}

// MARK: - 预览

struct ComplexUIDemo_Previews: PreviewProvider {
    static var previews: some View {
        ComplexUIDemo()
    }
}

#Preview {
    ComplexUIDemo()
}
