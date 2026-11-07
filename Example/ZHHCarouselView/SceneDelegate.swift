//
//  SceneDelegate.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// Scene 生命周期代理，负责创建窗口并组装 MVVM 根页面
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// 当前 Scene 对应的主窗口
    var window: UIWindow?

    /// Scene 即将连接时创建窗口，并以轮播 Demo 作为根控制器
    /// - Parameters:
    ///   - scene: 当前 Scene
    ///   - session: Scene 会话
    ///   - connectionOptions: 连接选项
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 组装 MVVM：ViewModel -> ViewController -> NavigationController
        let viewModel = CarouselViewModel()
        let rootViewController = CarouselViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: rootViewController)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
