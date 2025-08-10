//
//  RouterManager.swift
//  TestDemo
//
//  Created by Kiro on 2025/8/6.
//

import UIKit
import SwiftUI

protocol Routable {
    var title: String { get }
    func createViewController() -> UIViewController
}

enum PageType: String, CaseIterable, Routable {
    case home = "HomeController"
    case second = "SecondController"
    case third = "ThirdController"
    case web1 = "WebViewController"
    case swiftui_one = "ComplexUIDemo"
    case tabScroll = "TabScrollViewController"
    case videoDemo = "VideoDemoController"
    case iconFont = "IconFontController"
    case storeBox = "StoreBoxController"
    case theme = "SKThemeSetController"
    case liveBroadcast = "ALLiveBroadcastController"
    case homeSwiftUI = "HomeListPage"
    case pagingTable = "PagingTableViewController"
    case collection = "ALCollectionController"
    case liveGift = "ALLiveViewController"
    
    var title: String {
        return rawValue
    }
    
    func createViewController() -> UIViewController {
        switch self {
        case .home:
            return HomeController()
        case .second:
            return SecondController()
        case .third:
            return ThirdController()
        case .web1:
            return WebViewController(url: "https://www.baidu.com/")
        case .swiftui_one:
            return UIHostingController(rootView: ComplexUIDemo())
        case .tabScroll:
            return TabScrollViewController()
        case .videoDemo:
            return VideoDemoController()
        case .iconFont:
            return IconFontController()
        case .storeBox:
            return StoreBoxController()
        case .theme:
            return SKThemeSetController()
        case .liveBroadcast:
            return ALLiveBroadcastController()
        case .homeSwiftUI:
            return UIHostingController(rootView: HomeListPage())
        case .pagingTable:
            return PagingTableViewController()
        case .collection:
            return ALCollectionController()
        case .liveGift:
            return ALLiveGiftController()
        }
    }
}

class RouterManager {
    static let shared = RouterManager()
    private init() {}
    
    func navigate(to page: PageType, from navigationController: UINavigationController?) {
        let viewController = page.createViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}