//
//  AppDelegate.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IconFontManager.registerFont()
        ALThemeManager.shared.setAppTheme(.dark)
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.makeKeyAndVisible()
////        let storyboard = UIStoryboard(name: "Main", bundle: nil) // "Main"是你的storyboard文件名，不包括扩展名
//
//        let rootVC = ViewController()
//        let nav = UINavigationController(rootViewController: rootVC)
//        window?.rootViewController = nav
////        if let rootVC = storyboard.instantiateViewController(withIdentifier: "first") as? ViewController {
////           
////        }
        return true
    }


}

