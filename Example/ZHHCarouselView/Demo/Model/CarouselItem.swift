//
//  CarouselItem.swift
//  ZHHCarouselView_Example
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 轮播单条数据模型，描述一页的展示内容
struct CarouselItem {
    /// 唯一标识
    let id: Int
    /// 页标题（展示在 Cell 中央）
    let title: String
    /// Cell 背景色
    let color: UIColor
}

/// 轮播分区数据模型，描述一组演示色卡
struct CarouselSection {
    /// 分区标题
    let title: String
    /// 分区内的条目列表
    let items: [CarouselItem]
}
