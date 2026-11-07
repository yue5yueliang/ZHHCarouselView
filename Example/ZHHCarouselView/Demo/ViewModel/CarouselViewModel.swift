//
//  CarouselViewModel.swift
//  ZHHCarouselView_Example
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import ZHHCarouselView

/// 轮播 Demo 的 ViewModel：生成示例数据，并向 View 层提供查询与可调参数
final class CarouselViewModel {

    /// 分区数据源，外部只读
    private(set) var sections: [CarouselSection] = []
    /// 当前布局样式
    private(set) var layoutStyle: ZHHCarouselLayoutStyle = .normal
    /// 卡片相对轮播区域的宽高比例（默认 0.8）
    private(set) var itemSizeRatio: CGFloat = 0.8
    /// 间距比例；实际间距 = 30 × 比例
    private(set) var itemSpacingRatio: CGFloat = 0.5
    /// 非无限循环时是否首尾水平居中
    private(set) var isHorizontalCenter: Bool = true

    /// 分区数量
    var numberOfSections: Int {
        sections.count
    }

    /// 展平后的全部条目（轮播 DataSource 使用）
    var allItems: [CarouselItem] {
        sections.flatMap { $0.items }
    }

    /// 当前卡片间距（pt）
    var itemSpacing: CGFloat {
        30 * itemSpacingRatio
    }

    /// 返回指定分区的条目数量
    /// - Parameter section: 分区索引
    /// - Returns: 条目数量；索引非法时返回 0
    func numberOfItems(in section: Int) -> Int {
        guard sections.indices.contains(section) else { return 0 }
        return sections[section].items.count
    }

    /// 返回指定分区模型
    /// - Parameter index: 分区索引
    /// - Returns: 分区模型；索引非法时返回 nil
    func section(at index: Int) -> CarouselSection? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    /// 返回指定位置的条目模型
    /// - Parameter indexPath: 条目索引
    /// - Returns: 条目模型；索引非法时返回 nil
    func item(at indexPath: IndexPath) -> CarouselItem? {
        guard let section = section(at: indexPath.section), section.items.indices.contains(indexPath.item) else {
            return nil
        }
        return section.items[indexPath.item]
    }

    /// 返回展平后指定业务索引的条目
    /// - Parameter index: 业务页索引
    /// - Returns: 条目模型；索引非法时返回 nil
    func item(atFlatIndex index: Int) -> CarouselItem? {
        guard allItems.indices.contains(index) else { return nil }
        return allItems[index]
    }

    /// 根据比例计算卡片尺寸
    /// - Parameter bounds: 轮播视图 bounds
    /// - Returns: itemSize
    func itemSize(for bounds: CGSize) -> CGSize {
        CGSize(width: bounds.width * itemSizeRatio, height: bounds.height * itemSizeRatio)
    }

    /// 加载 Demo 示例数据（冷色 / 暖色两个分区）
    func loadData() {
        sections = [
            makeSection(title: "冷色系", startId: 1, colors: [
                UIColor.systemBlue, UIColor.systemTeal, UIColor.systemIndigo, UIColor.systemCyan
            ]),
            makeSection(title: "暖色系", startId: 100, colors: [
                UIColor.systemOrange, UIColor.systemPink, UIColor.systemRed, UIColor.systemYellow
            ])
        ]
    }

    /// 更新布局样式
    /// - Parameter style: 普通 / 线性缩放 / 封面流
    func updateLayoutStyle(_ style: ZHHCarouselLayoutStyle) {
        layoutStyle = style
    }

    /// 更新卡片大小比例（0...1）
    /// - Parameter ratio: 宽高相对轮播区域的比例
    func updateItemSizeRatio(_ ratio: CGFloat) {
        itemSizeRatio = min(max(ratio, 0.01), 1)
    }

    /// 更新间距比例（0...1）
    /// - Parameter ratio: 间距比例
    func updateItemSpacingRatio(_ ratio: CGFloat) {
        itemSpacingRatio = min(max(ratio, 0), 1)
    }

    /// 更新首尾居中开关
    /// - Parameter enabled: 是否首尾水平居中
    func updateHorizontalCenter(_ enabled: Bool) {
        isHorizontalCenter = enabled
    }

    // MARK: - Private

    /// 构造一个分区的示例色卡
    /// - Parameters:
    ///   - title: 分区标题
    ///   - startId: 条目起始 id
    ///   - colors: 色板
    /// - Returns: 分区模型
    private func makeSection(title: String, startId: Int, colors: [UIColor]) -> CarouselSection {
        let items = colors.enumerated().map { offset, color in
            CarouselItem(id: startId + offset, title: "第 \(offset + 1) 页 · \(title)", color: color.withAlphaComponent(0.9))
        }
        return CarouselSection(title: title, items: items)
    }
}
