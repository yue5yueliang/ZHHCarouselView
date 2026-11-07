//
//  AppDelegate.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 应用入口代理，负责应用级生命周期；窗口创建交给 SceneDelegate 处理
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 应用启动完成回调
    /// - Parameters:
    ///   - application: 当前应用实例
    ///   - launchOptions: 启动参数
    /// - Returns: 是否允许继续启动
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: - UISceneSession Lifecycle

    /// 创建新的 Scene 配置，指定使用 SceneDelegate
    /// - Parameters:
    ///   - application: 当前应用实例
    ///   - connectingSceneSession: 即将连接的 Scene 会话
    ///   - options: 连接选项
    /// - Returns: Scene 配置对象
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// 丢弃不再使用的 Scene 会话时回调，可用于清理相关资源
    /// - Parameters:
    ///   - application: 当前应用实例
    ///   - sceneSessions: 被丢弃的会话集合
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
