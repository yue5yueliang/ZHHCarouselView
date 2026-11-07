//
//  ZHHCarouselView.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 2025/8/31.
//  Copyright © 2025 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 索引段结构体

/// 业务 index + 虚拟 section；无限循环靠多 section 副本实现，避免到边界再跳回
public struct ZHHIndexSection {
    /// 业务页索引（0 ..< numberOfItems）
    public var index: Int
    /// 虚拟副本所在 section（无限循环时使用）
    public var section: Int

    /// 用业务 index 与虚拟 section 构造索引段
    ///
    /// - Parameters:
    ///   - index: 业务页索引
    ///   - section: 虚拟 section
    public init(index: Int, section: Int) {
        self.index = index
        self.section = section
    }
}

// MARK: - 滚动方向

/// 相邻页滚动方向（自动滚 / 手势吸附共用）
public enum ZHHPagerScrollDirection {
    /// 向左（上一页）
    case left
    /// 向右（下一页）
    case right
}

// MARK: - 常量

/// 无限循环虚拟 section 上限；越大越不易摸到边界，内存与布局成本也更高
public let kPagerViewMaxSectionCount = 200
/// 安全区下限：当前 section 靠近 0 或上限时无感回收到中间，防止闪跳
public let kPagerViewMinSectionCount = 18

/// 判断两个索引段是否完全相同（index + section）
///
/// - Parameters:
///   - indexSection1: 左侧索引段
///   - indexSection2: 右侧索引段
/// - Returns: 两者 index 与 section 均相等时为 true
public func ZHHEqualIndexSection(_ indexSection1: ZHHIndexSection, _ indexSection2: ZHHIndexSection) -> Bool {
    indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section
}

/// 构造索引段的便捷方法
///
/// - Parameters:
///   - index: 业务页索引
///   - section: 虚拟 section
/// - Returns: 新的 `ZHHIndexSection`
public func ZHHMakeIndexSection(_ index: Int, _ section: Int) -> ZHHIndexSection {
    ZHHIndexSection(index: index, section: section)
}

// MARK: - 数据源协议

/// 轮播数据源：条数、Cell、布局配置
public protocol ZHHCarouselViewDataSource: AnyObject {
    /// 返回业务页数量（非虚拟 section 数）
    ///
    /// - Parameter pagerView: 当前轮播视图
    /// - Returns: item 数量
    func numberOfItems(in pagerView: ZHHCarouselView) -> Int

    /// 返回指定业务索引的 Cell；内部会映射到当前 dequeue 的虚拟 section
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - index: 业务页索引
    /// - Returns: 配置好的 Cell
    func pagerView(_ pagerView: ZHHCarouselView, cellForItemAt index: Int) -> UICollectionViewCell

    /// 返回布局配置；`reloadData` 会清空缓存后重新索取，`updateData` 保留已有配置
    ///
    /// - Parameter pagerView: 当前轮播视图
    /// - Returns: `ZHHCarouselPagerLayout` 配置对象
    func layout(for pagerView: ZHHCarouselView) -> ZHHCarouselPagerLayout
}

// MARK: - 代理协议

/// 轮播代理：选中、页切换、滚动生命周期；均有默认空实现
public protocol ZHHCarouselViewDelegate: AnyObject {
    /// 业务页索引发生变化时回调（同一页内细微滚动不触发）
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - fromIndex: 滚动前业务索引
    ///   - toIndex: 滚动后业务索引
    func pagerView(_ pagerView: ZHHCarouselView, didScrollFromIndex fromIndex: Int, toIndex: Int)

    /// 点击选中某一页（只带业务索引）
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - cell: 被点中的 Cell
    ///   - index: 业务页索引
    func pagerView(_ pagerView: ZHHCarouselView, didSelectItemCell cell: UICollectionViewCell, at index: Int)

    /// 点击选中某一页（带虚拟 section，便于调试无限循环位置）
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - cell: 被点中的 Cell
    ///   - indexSection: 含虚拟 section 的索引段
    func pagerView(_ pagerView: ZHHCarouselView, didSelectItemCell cell: UICollectionViewCell, at indexSection: ZHHIndexSection)

    /// 自定义变换：初始化 attributes（须同时打开 `prefersCustomTransform`）
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - attributes: 待初始化的布局属性
    func pagerView(_ pagerView: ZHHCarouselView, initializeTransformAttributes attributes: UICollectionViewLayoutAttributes)

    /// 自定义变换：滚动中持续应用（须同时打开 `prefersCustomTransform`）
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - attributes: 待变换的布局属性
    func pagerView(_ pagerView: ZHHCarouselView, applyTransformToAttributes attributes: UICollectionViewLayoutAttributes)

    /// 内容偏移变化（含页内细滚）
    func pagerViewDidScroll(_ pagerView: ZHHCarouselView)
    /// 用户即将开始拖拽
    func pagerViewWillBeginDragging(_ pagerView: ZHHCarouselView)
    /// 用户结束拖拽
    ///
    /// - Parameters:
    ///   - pagerView: 当前轮播视图
    ///   - decelerate: 松手后是否继续减速滚动
    func pagerViewDidEndDragging(_ pagerView: ZHHCarouselView, willDecelerate decelerate: Bool)
    /// 即将开始减速
    func pagerViewWillBeginDecelerating(_ pagerView: ZHHCarouselView)
    /// 减速结束（此时可能触发 section 回收）
    func pagerViewDidEndDecelerating(_ pagerView: ZHHCarouselView)
    /// 即将开始程序性滚动动画
    func pagerViewWillBeginScrollingAnimation(_ pagerView: ZHHCarouselView)
    /// 程序性滚动动画结束（此时可能触发 section 回收）
    func pagerViewDidEndScrollingAnimation(_ pagerView: ZHHCarouselView)
}

public extension ZHHCarouselViewDelegate {
    /// 默认空实现：页索引变化
    func pagerView(_ pagerView: ZHHCarouselView, didScrollFromIndex fromIndex: Int, toIndex: Int) {}
    /// 默认空实现：选中（业务索引）
    func pagerView(_ pagerView: ZHHCarouselView, didSelectItemCell cell: UICollectionViewCell, at index: Int) {}
    /// 默认空实现：选中（索引段）
    func pagerView(_ pagerView: ZHHCarouselView, didSelectItemCell cell: UICollectionViewCell, at indexSection: ZHHIndexSection) {}
    /// 默认空实现：自定义初始化变换
    func pagerView(_ pagerView: ZHHCarouselView, initializeTransformAttributes attributes: UICollectionViewLayoutAttributes) {}
    /// 默认空实现：自定义应用变换
    func pagerView(_ pagerView: ZHHCarouselView, applyTransformToAttributes attributes: UICollectionViewLayoutAttributes) {}
    /// 默认空实现：滚动中
    func pagerViewDidScroll(_ pagerView: ZHHCarouselView) {}
    /// 默认空实现：开始拖拽
    func pagerViewWillBeginDragging(_ pagerView: ZHHCarouselView) {}
    /// 默认空实现：结束拖拽
    func pagerViewDidEndDragging(_ pagerView: ZHHCarouselView, willDecelerate decelerate: Bool) {}
    /// 默认空实现：开始减速
    func pagerViewWillBeginDecelerating(_ pagerView: ZHHCarouselView) {}
    /// 默认空实现：减速结束
    func pagerViewDidEndDecelerating(_ pagerView: ZHHCarouselView) {}
    /// 默认空实现：开始滚动动画
    func pagerViewWillBeginScrollingAnimation(_ pagerView: ZHHCarouselView) {}
    /// 默认空实现：滚动动画结束
    func pagerViewDidEndScrollingAnimation(_ pagerView: ZHHCarouselView) {}
}

// MARK: - ZHHCarouselView

/// 无限循环 / 自动滚动分页视图
public final class ZHHCarouselView: UIView {

    // MARK: - 对外属性

    /// 背景视图，直接映射到内部 CollectionView.backgroundView
    public var backgroundView: UIView? {
        get { collectionView?.backgroundView }
        set { collectionView?.backgroundView = newValue }
    }

    /// 数据源（条数 / Cell / 布局配置）
    public weak var dataSource: ZHHCarouselViewDataSource?

    /// 代理；变更时同步是否挂自定义 Transform 代理
    public weak var delegate: ZHHCarouselViewDelegate? {
        didSet { updateTransformLayoutDelegate() }
    }

    /// 为 true 时走代理自定义变换；为 false 时用 Layout 内置 linear / coverflow
    public var prefersCustomTransform: Bool = false {
        didSet { updateTransformLayoutDelegate() }
    }

    /// 内部 CollectionView；勿改其 dataSource / delegate
    public private(set) weak var collectionView: UICollectionView?

    /// 当前布局配置（由 DataSource 提供，reload 会清空后重取）
    public private(set) var layout: ZHHCarouselPagerLayout?

    /// 是否无限循环；默认开启
    public var isInfiniteLoop: Bool = true

    /// 自动滚动间隔（秒）；<=0 关闭；变更时重建 Timer
    public var autoScrollInterval: CGFloat = 0 {
        didSet {
            removeTimer()
            if autoScrollInterval > 0, superview != nil {
                addTimer()
            }
        }
    }

    /// `reloadData` 后是否强制回到第 0 页（配合内部 `needResetIndex`）
    public var reloadDataNeedResetIndex: Bool = false

    /// 当前业务页索引（来自 `indexSection.index`）
    public var curIndex: Int { indexSection.index }

    /// 当前索引段（含虚拟 section）；未布局完成前为 (-1, -1)
    public private(set) var indexSection = ZHHIndexSection(index: -1, section: -1)

    /// 当前内容偏移
    public var contentOffset: CGPoint { collectionView?.contentOffset ?? .zero }

    /// 是否正在跟踪手势（手指仍在屏幕上）
    public var tracking: Bool { collectionView?.isTracking ?? false }

    /// 是否正在拖拽
    public var dragging: Bool { collectionView?.isDragging ?? false }

    /// 是否正在减速
    public var decelerating: Bool { collectionView?.isDecelerating ?? false }

    // MARK: - 私有状态

    /// 自动滚动 Timer；拖拽期间会移除，松手后再加回
    private var timer: Timer?
    /// 业务 item 数量缓存
    private var numberOfItems: Int = 0
    /// `cellForItem` 时记录的虚拟 section，供 `dequeueReusableCell` 拼 IndexPath
    private var dequeueSection: Int = 0
    /// 开始拖拽时的索引段，用于判断松手吸附方向
    private var beginDragIndexSection = ZHHIndexSection(index: 0, section: 0)
    /// 布局未完成前调用 `scrollToItem` 时暂存的目标索引；-1 表示无
    private var firstScrollIndex: Int = -1
    /// 是否在下次 `clearLayout` 时丢弃 layout 缓存
    private var needClearLayout: Bool = false
    /// 是否已执行过 `reloadData`（用于首帧布局判定）
    private var didReloadData: Bool = false
    /// 是否已完成至少一次有效布局
    private var didLayout: Bool = false
    /// `reloadData` 标记的待重置索引；是否真正归零还看 `reloadDataNeedResetIndex`
    private var needResetIndex: Bool = false

    // MARK: - 初始化

    /// 代码初始化：配置默认值并创建内部 CollectionView
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureProperty()
        addCollectionView()
    }

    /// Storyboard / XIB 初始化
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureProperty()
        addCollectionView()
    }

    /// 断开 Layout / CollectionView 代理，避免销毁后回调野指针；停掉 Timer
    deinit {
        if let layout = collectionView?.collectionViewLayout as? ZHHCarouselViewLayout {
            layout.transformDelegate = nil
        }
        collectionView?.delegate = nil
        collectionView?.dataSource = nil
        removeTimer()
    }

    /// 移出父视图时停 Timer；重新挂上且开启自动滚时再启动
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        removeTimer()
        if newSuperview != nil, autoScrollInterval > 0 {
            addTimer()
        }
    }

    /// 同步 CollectionView 尺寸；首帧或 bounds 变化时刷新布局并复位到当前页
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let collectionView else { return }

        let needUpdateLayout = !collectionView.frame.equalTo(bounds)
        collectionView.frame = bounds

        // 尚未定位到有效 section，或尺寸变了，才强制刷布局
        if (indexSection.section < 0 || needUpdateLayout), (numberOfItems > 0 || didReloadData) {
            didLayout = true
            setNeedUpdateLayout()
        }
    }
}

// MARK: - 对外方法

extension ZHHCarouselView {

    /// 重新加载：清空 layout 缓存，再向 DataSource 重取配置与数据
    public func reloadData() {
        didReloadData = true
        needResetIndex = true
        setNeedClearLayout()
        clearLayout()
        updateData()
    }

    /// 更新数据：保留现有 layout，只刷新条数与内容位置
    public func updateData() {
        updateLayout()
        numberOfItems = dataSource?.numberOfItems(in: self) ?? 0
        collectionView?.reloadData()

        // 首次有有效 frame 时标记已布局，后续 scroll 回调才生效
        if !didLayout, let collectionView, !collectionView.frame.isEmpty, indexSection.index < 0 {
            didLayout = true
        }

        let shouldReset = needResetIndex && reloadDataNeedResetIndex
        needResetIndex = false

        // 强制归零时短暂停 Timer，避免复位过程中自动翻页
        if shouldReset {
            removeTimer()
        }

        let targetIndex = ((indexSection.index < 0 && !(collectionView?.frame.isEmpty ?? true)) || shouldReset) ? 0 : indexSection.index
        resetPagerView(at: targetIndex)

        if shouldReset {
            addTimer()
        }
    }

    /// 仅刷新布局（itemSize / 间距 / layoutType 等变更后调用），不重取 DataSource layout
    ///
    /// 连续调节 itemSize / 间距时：保留当前虚拟 section，并关闭隐式动画，避免每次都 `resetPagerView` 跳到中间副本造成闪烁
    public func setNeedUpdateLayout() {
        guard layout != nil else { return }
        clearLayout()
        updateLayout()

        // 已有有效页则留在当前虚拟 section；尚未定位时落到中间副本（与 resetPagerView 首屏策略一致）
        let target: ZHHIndexSection
        if indexSection.index >= 0 {
            target = indexSection
        } else {
            target = ZHHMakeIndexSection(0, isInfiniteLoop ? kPagerViewMaxSectionCount / 3 : 0)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            collectionView?.collectionViewLayout.invalidateLayout()
            collectionView?.layoutIfNeeded()
            scrollToItem(at: target, animate: false)
            collectionView?.layoutIfNeeded()
        }
        CATransaction.commit()
    }

    /// 标记下次 `clearLayout` 需丢弃 layout，通常由 `reloadData` 调用
    public func setNeedClearLayout() {
        needClearLayout = true
    }

    /// 当前业务页对应的 Cell（可能因未可见而为 nil）
    ///
    /// - Returns: 当前页 Cell
    public func curIndexCell() -> UICollectionViewCell? {
        collectionView?.cellForItem(at: IndexPath(item: indexSection.index, section: indexSection.section))
    }

    /// 当前可见的全部 Cell
    ///
    /// - Returns: 可见 Cell 数组
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView?.visibleCells ?? []
    }

    /// 当前可见的业务索引列表（多 section 时可能出现重复 index）
    ///
    /// - Returns: 业务 item 索引数组
    public func visibleIndexs() -> [Int] {
        (collectionView?.indexPathsForVisibleItems ?? []).map(\.item)
    }

    /// 滚动到指定业务索引；无限循环时按相对当前位置选择虚拟 section，避免反向大跳
    ///
    /// - Parameters:
    ///   - index: 业务页索引
    ///   - animate: 是否动画
    public func scrollToItem(at index: Int, animate: Bool) {
        // 布局未完成时先记下目标，等 reset 时再落地
        if !didLayout, didReloadData {
            firstScrollIndex = index
        } else {
            firstScrollIndex = -1
        }

        if !isInfiniteLoop {
            scrollToItem(at: ZHHMakeIndexSection(index, 0), animate: animate)
            return
        }

        // 目标 index >= 当前：同 section 前进；否则跳下一副本，保证始终正向滚动感
        let section = index >= curIndex ? indexSection.section : indexSection.section + 1
        scrollToItem(at: ZHHMakeIndexSection(index, section), animate: animate)
    }

    /// 滚动到指定索引段（含虚拟 section）
    ///
    /// - Parameters:
    ///   - indexSection: 目标索引段
    ///   - animate: 是否动画
    public func scrollToItem(at indexSection: ZHHIndexSection, animate: Bool) {
        guard numberOfItems > 0, isValidIndexSection(indexSection), let collectionView else { return }

        if animate {
            delegate?.pagerViewWillBeginScrollingAnimation(self)
        }

        let offsetX = calculateOffsetX(at: indexSection)
        collectionView.setContentOffset(CGPoint(x: offsetX, y: collectionView.contentOffset.y), animated: animate)
    }

    /// 按方向滚到相邻页（自动滚 Timer 默认向右）
    ///
    /// - Parameters:
    ///   - direction: 左 / 右
    ///   - animate: 是否动画
    public func scrollToNearlyItem(at direction: ZHHPagerScrollDirection, animate: Bool) {
        let next = nearlyIndexPath(at: direction)
        scrollToItem(at: next, animate: animate)
    }

    /// 注册 Cell 类
    ///
    /// - Parameters:
    ///   - cellClass: Cell 类型
    ///   - identifier: 复用标识
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        collectionView?.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /// 注册 Cell Nib
    ///
    /// - Parameters:
    ///   - nib: Nib
    ///   - identifier: 复用标识
    public func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        collectionView?.register(nib, forCellWithReuseIdentifier: identifier)
    }

    /// 从重用池取出 Cell；section 使用当前 `dequeueSection`，与 DataSource 回调对齐
    ///
    /// - Parameters:
    ///   - identifier: 复用标识
    ///   - index: 业务页索引（作为 item）
    /// - Returns: 可配置的 Cell
    public func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        guard let collectionView else {
            fatalError("ZHHCarouselView: collectionView is nil")
        }
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: IndexPath(item: index, section: dequeueSection)
        )
    }
}

// MARK: - 初始化与 CollectionView

private extension ZHHCarouselView {

    /// 写入初始状态（默认无限循环，关闭自动滚）
    func configureProperty() {
        needResetIndex = false
        didReloadData = false
        didLayout = false
        autoScrollInterval = 0
        isInfiniteLoop = true
        beginDragIndexSection = ZHHMakeIndexSection(0, 0)
        indexSection = ZHHMakeIndexSection(-1, -1)
        firstScrollIndex = -1
    }

    /// 创建水平 CollectionView：关闭系统 paging，用自定义减速与偏移吸附
    func addCollectionView() {
        let transformLayout = ZHHCarouselViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: transformLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        // 略高于系统默认减速，手感更接近分页吸附
        collectionView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 1 - 0.0076)
        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        addSubview(collectionView)
        self.collectionView = collectionView
        updateTransformLayoutDelegate()
    }

    /// 仅在 `prefersCustomTransform` 时挂 Layout 代理，否则走内置 linear / coverflow
    func updateTransformLayoutDelegate() {
        guard let transformLayout = collectionView?.collectionViewLayout as? ZHHCarouselViewLayout else { return }
        transformLayout.transformDelegate = prefersCustomTransform ? self : nil
    }
}

// MARK: - Timer

private extension ZHHCarouselView {

    /// 启动自动滚动；已存在或间隔无效时直接返回
    func addTimer() {
        guard timer == nil, autoScrollInterval > 0 else { return }
        let timer = Timer(timeInterval: TimeInterval(autoScrollInterval), repeats: true) { [weak self] _ in
            self?.timerFired()
        }
        // CommonModes：滚动跟踪时 Timer 仍能触发
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// 停止并释放自动滚动 Timer
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Timer 触发：视图在窗且未手势跟踪时向右翻一页
    func timerFired() {
        guard superview != nil, window != nil, numberOfItems > 0, !tracking else { return }
        scrollToNearlyItem(at: .right, animate: true)
    }
}

// MARK: - Layout 管理

private extension ZHHCarouselView {

    /// 解析 layout 并同步 `isInfiniteLoop` 到 TransformLayout
    func updateLayout() {
        guard let layout = resolvedLayout() else { return }
        layout.isInfiniteLoop = isInfiniteLoop
        self.layout = layout

        guard let transformLayout = collectionView?.collectionViewLayout as? ZHHCarouselViewLayout else { return }
        transformLayout.layoutConfig = layout
    }

    /// 懒加载布局：已有缓存直接返回；否则问 DataSource，itemSize 非法则视为无效
    ///
    /// - Returns: 可用的布局配置，失败为 nil
    func resolvedLayout() -> ZHHCarouselPagerLayout? {
        if let layout {
            return layout
        }
        guard let dataSource else { return nil }
        let layout = dataSource.layout(for: self)
        layout.isInfiniteLoop = isInfiniteLoop
        if layout.itemSize.width <= 0 || layout.itemSize.height <= 0 {
            return nil
        }
        self.layout = layout
        return layout
    }

    /// 仅当 `needClearLayout` 为 true 时丢弃 layout，供 reload 与 update 区分
    func clearLayout() {
        guard needClearLayout else { return }
        layout = nil
        needClearLayout = false
    }
}

// MARK: - 索引与偏移计算

private extension ZHHCarouselView {

    /// 校验索引段是否落在合法业务 index 与虚拟 section 范围
    ///
    /// - Parameter indexSection: 待校验索引段
    /// - Returns: 是否可用
    func isValidIndexSection(_ indexSection: ZHHIndexSection) -> Bool {
        indexSection.index >= 0
            && indexSection.index < numberOfItems
            && indexSection.section >= 0
            && indexSection.section < kPagerViewMaxSectionCount
    }

    /// 基于当前页计算相邻索引段
    ///
    /// - Parameter direction: 滚动方向
    /// - Returns: 目标索引段
    func nearlyIndexPath(at direction: ZHHPagerScrollDirection) -> ZHHIndexSection {
        nearlyIndexPath(for: indexSection, direction: direction)
    }

    /// 按是否无限循环，计算给定索引段在指定方向上的下一位置
    ///
    /// - Parameters:
    ///   - indexSection: 基准索引段
    ///   - direction: 左 / 右
    /// - Returns: 相邻索引段；越界且未开自动滚时可能原样返回
    func nearlyIndexPath(for indexSection: ZHHIndexSection, direction: ZHHPagerScrollDirection) -> ZHHIndexSection {
        guard indexSection.index >= 0, indexSection.index < numberOfItems else {
            return indexSection
        }

        // 非无限：首尾在开启自动滚时可回绕，否则停住
        if !isInfiniteLoop {
            if direction == .right {
                if indexSection.index == numberOfItems - 1 {
                    return autoScrollInterval > 0 ? ZHHMakeIndexSection(0, 0) : indexSection
                }
                return ZHHMakeIndexSection(indexSection.index + 1, 0)
            }
            if indexSection.index == 0 {
                return autoScrollInterval > 0 ? ZHHMakeIndexSection(numberOfItems - 1, 0) : indexSection
            }
            return ZHHMakeIndexSection(indexSection.index - 1, 0)
        }

        // 无限：同 section 内前进；到末项则进入下一虚拟 section 的第 0 项
        if direction == .right {
            if indexSection.index < numberOfItems - 1 {
                return ZHHMakeIndexSection(indexSection.index + 1, indexSection.section)
            }
            if indexSection.section >= kPagerViewMaxSectionCount - 1 {
                return ZHHMakeIndexSection(indexSection.index, kPagerViewMaxSectionCount - 1)
            }
            return ZHHMakeIndexSection(0, indexSection.section + 1)
        }

        if indexSection.index > 0 {
            return ZHHMakeIndexSection(indexSection.index - 1, indexSection.section)
        }
        if indexSection.section <= 0 {
            return ZHHMakeIndexSection(indexSection.index, 0)
        }
        return ZHHMakeIndexSection(numberOfItems - 1, indexSection.section - 1)
    }

    /// 用可视区域中线反算当前索引段
    ///
    /// - Parameter offsetX: 横向 contentOffset
    /// - Returns: 对应的索引段
    func calculateIndexSection(withOffsetX offsetX: CGFloat) -> ZHHIndexSection {
        guard numberOfItems > 0, let collectionView, let layout else {
            return ZHHMakeIndexSection(0, 0)
        }

        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let leftEdge = isInfiniteLoop ? layout.sectionInset.left : layout.onlyOneSectionInset.left
        let width = collectionView.frame.width
        let middleOffset = offsetX + width / 2
        let itemWidth = (flowLayout?.itemSize.width ?? layout.itemSize.width)
            + (flowLayout?.minimumInteritemSpacing ?? layout.itemSpacing)

        var curIndex = 0
        var curSection = 0

        if middleOffset - leftEdge >= 0 {
            var itemIndex = Int((middleOffset - leftEdge + (flowLayout?.minimumInteritemSpacing ?? layout.itemSpacing) / 2) / itemWidth)
            if itemIndex < 0 {
                itemIndex = 0
            } else if itemIndex >= numberOfItems * kPagerViewMaxSectionCount {
                itemIndex = numberOfItems * kPagerViewMaxSectionCount - 1
            }
            // 线性 itemIndex 拆回业务 index + 虚拟 section
            curIndex = itemIndex % numberOfItems
            curSection = itemIndex / numberOfItems
        }

        return ZHHMakeIndexSection(curIndex, curSection)
    }

    /// 计算让目标页水平居中（或末项贴右）所需的 offsetX
    ///
    /// - Parameter indexSection: 目标索引段
    /// - Returns: 横向偏移，至少为 0
    func calculateOffsetX(at indexSection: ZHHIndexSection) -> CGFloat {
        guard numberOfItems > 0, let collectionView, let layout else { return 0 }

        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let edge = isInfiniteLoop ? layout.sectionInset : layout.onlyOneSectionInset
        let leftEdge = edge.left
        let rightEdge = edge.right
        let width = collectionView.frame.width
        let interitem = flowLayout?.minimumInteritemSpacing ?? layout.itemSpacing
        let itemWidth = (flowLayout?.itemSize.width ?? layout.itemSize.width) + interitem

        let offsetX: CGFloat
        // 非无限且未水平居中时，最后一页贴右，避免右侧留白过大
        if !isInfiniteLoop, !layout.itemHorizontalCenter, indexSection.index == numberOfItems - 1 {
            offsetX = leftEdge
                + itemWidth * CGFloat(indexSection.index + indexSection.section * numberOfItems)
                - (width - itemWidth)
                - interitem
                + rightEdge
        } else {
            offsetX = leftEdge
                + itemWidth * CGFloat(indexSection.index + indexSection.section * numberOfItems)
                - interitem / 2
                - (width - itemWidth) / 2
        }
        return max(offsetX, 0)
    }

    /// 无动画跳到指定业务页；无限循环落在中间 1/3 section，方便双向滑动
    ///
    /// - Parameter index: 业务页索引
    func resetPagerView(at index: Int) {
        var targetIndex = index
        // 布局完成后兑现此前暂存的 firstScrollIndex
        if didLayout, firstScrollIndex >= 0 {
            targetIndex = firstScrollIndex
            firstScrollIndex = -1
        }
        guard targetIndex >= 0 else { return }
        if targetIndex >= numberOfItems {
            targetIndex = 0
        }

        let section = isInfiniteLoop ? kPagerViewMaxSectionCount / 3 : 0
        scrollToItem(at: ZHHMakeIndexSection(targetIndex, section), animate: false)

        // 非无限且尚未有有效 index 时，手动推一次 didScroll 以同步代理
        if !isInfiniteLoop, indexSection.index < 0, let collectionView {
            scrollViewDidScroll(collectionView)
        }
    }

    /// 当前虚拟 section 贴近两端时，无动画拉回中间安全区，防止滚穿边界闪跳
    func recyclePagerViewIfNeed() {
        guard isInfiniteLoop else { return }
        if indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount
            || indexSection.section < kPagerViewMinSectionCount {
            resetPagerView(at: indexSection.index)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ZHHCarouselView: UICollectionViewDataSource {

    /// 无限循环返回最大 section 数，否则仅 1 个 section
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        isInfiniteLoop ? kPagerViewMaxSectionCount : 1
    }

    /// 每个 section 的 item 数等于业务条数，并刷新缓存
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfItems = dataSource?.numberOfItems(in: self) ?? 0
        return numberOfItems
    }

    /// 记录 dequeueSection 后转发给 DataSource（业务 index = item）
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        dequeueSection = indexPath.section
        guard let dataSource else {
            assertionFailure("ZHHCarouselView: dataSource is nil")
            return UICollectionViewCell()
        }
        return dataSource.pagerView(self, cellForItemAt: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ZHHCarouselView: UICollectionViewDelegateFlowLayout {

    /// 按首 / 中 / 尾 section 返回不同 inset，保证无限循环接缝对齐
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let layout else { return .zero }
        if !isInfiniteLoop {
            return layout.onlyOneSectionInset
        }
        if section == 0 {
            return layout.firstSectionInset
        }
        if section == kPagerViewMaxSectionCount - 1 {
            return layout.lastSectionInset
        }
        return layout.middleSectionInset
    }

    /// 点击转发业务索引与完整索引段两套回调
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) ?? UICollectionViewCell()
        delegate?.pagerView(self, didSelectItemCell: cell, at: indexPath.item)
        delegate?.pagerView(self, didSelectItemCell: cell, at: ZHHMakeIndexSection(indexPath.item, indexPath.section))
    }
}

// MARK: - UIScrollViewDelegate

extension ZHHCarouselView {

    /// 根据偏移更新 `indexSection`，并在业务页变化时通知代理
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard didLayout else { return }

        let newIndexSection = calculateIndexSection(withOffsetX: scrollView.contentOffset.x)
        guard numberOfItems > 0, isValidIndexSection(newIndexSection) else { return }

        let previous = indexSection
        indexSection = newIndexSection

        delegate?.pagerViewDidScroll(self)

        if !ZHHEqualIndexSection(indexSection, previous) {
            delegate?.pagerView(self, didScrollFromIndex: max(previous.index, 0), toIndex: indexSection.index)
        }
    }

    /// 开始拖拽：停自动滚，并记录起始索引段供松手吸附判断
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScrollInterval > 0 {
            removeTimer()
        }
        beginDragIndexSection = calculateIndexSection(withOffsetX: scrollView.contentOffset.x)
        delegate?.pagerViewWillBeginDragging(self)
    }

    /// 松手吸附：速度过小或已跨页则停在当前页；否则按速度方向滚到相邻页
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // 速度不足，或拖拽过程中 index 已变：吸附回当前页中心
        if abs(velocity.x) < 0.35 || !ZHHEqualIndexSection(beginDragIndexSection, indexSection) {
            targetContentOffset.pointee.x = calculateOffsetX(at: indexSection)
            return
        }

        var direction: ZHHPagerScrollDirection = .right
        if (scrollView.contentOffset.x < 0 && targetContentOffset.pointee.x <= 0)
            || (targetContentOffset.pointee.x < scrollView.contentOffset.x
                && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width) {
            direction = .left
        }

        let next = nearlyIndexPath(for: indexSection, direction: direction)
        targetContentOffset.pointee.x = calculateOffsetX(at: next)
    }

    /// 结束拖拽：恢复自动滚 Timer
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScrollInterval > 0 {
            addTimer()
        }
        delegate?.pagerViewDidEndDragging(self, willDecelerate: decelerate)
    }

    /// 即将减速
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.pagerViewWillBeginDecelerating(self)
    }

    /// 减速结束：必要时回收虚拟 section
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recyclePagerViewIfNeed()
        delegate?.pagerViewDidEndDecelerating(self)
    }

    /// 滚动动画结束：必要时回收虚拟 section
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        recyclePagerViewIfNeed()
        delegate?.pagerViewDidEndScrollingAnimation(self)
    }
}

// MARK: - ZHHCarouselViewLayoutDelegate

extension ZHHCarouselView: ZHHCarouselViewLayoutDelegate {

    /// 把 Layout 的初始化变换转发给业务代理
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, initializeTransformAttributes attributes: UICollectionViewLayoutAttributes) {
        delegate?.pagerView(self, initializeTransformAttributes: attributes)
    }

    /// 把 Layout 的滚动中变换转发给业务代理
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, applyTransformToAttributes attributes: UICollectionViewLayoutAttributes) {
        delegate?.pagerView(self, applyTransformToAttributes: attributes)
    }
}
