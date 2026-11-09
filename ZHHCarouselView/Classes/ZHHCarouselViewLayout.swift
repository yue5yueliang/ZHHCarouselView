//
//  ZHHCarouselViewLayout.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 2025/8/31.
//  Copyright © 2025 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 布局类型

/// 循环翻页的布局类型；决定滚动中是否对 Cell 做缩放 / 旋转
public enum ZHHCarouselLayoutStyle {
    /// 普通布局（不做特殊效果，走系统 FlowLayout）
    case normal
    /// 线性布局（按距中心远近缩放 + 透明度变化）
    case linear
    /// Coverflow 布局（绕 Y 轴旋转 + 透明度变化）
    case coverflow
}

// MARK: - 布局代理协议

/// 布局变换回调；未设置时使用内置 linear / coverflow，设置后完全交给外部
protocol ZHHCarouselViewLayoutDelegate: AnyObject {
    /// 首次生成 attributes 时初始化变换（对应 `layoutAttributesForItem`）
    /// - Parameters:
    ///   - layout: 当前 Transform Layout
    ///   - attributes: 待初始化的布局属性
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, initializeTransformAttributes attributes: UICollectionViewLayoutAttributes)

    /// 滚动过程中持续应用变换（对应 `layoutAttributesForElements`）
    /// - Parameters:
    ///   - layout: 当前 Transform Layout
    ///   - attributes: 待变换的布局属性
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, applyTransformToAttributes attributes: UICollectionViewLayoutAttributes)
}

// MARK: - 页面布局配置

/// 分页布局配置；由 DataSource 提供，并同步到内部 `ZHHCarouselViewLayout`
public final class ZHHCarouselPagerLayout {

    /// 默认初始化
    public init() {}

    /// 每个 item 的尺寸（宽高需 > 0，否则轮播会视为无效布局）
    public var itemSize: CGSize = .zero
    /// item 之间的间距（映射到 FlowLayout 的 line / interitem spacing）
    public var itemSpacing: CGFloat = 0
    /// section 内边距；开启垂直 / 水平居中时会被计算值覆盖
    public var sectionInset: UIEdgeInsets = .zero
    /// 布局类型
    public var layoutType: ZHHCarouselLayoutStyle = .normal
    /// 最小缩放比例（linear 用，默认 0.8）
    public var minimumScale: CGFloat = 0.8
    /// 最小透明度（linear / coverflow 用，默认 1.0 即不透明衰减）
    public var minimumAlpha: CGFloat = 1.0
    /// 最大旋转角度百分比（coverflow 用，默认 0.2 表示约 0.2π）
    public var maximumAngle: CGFloat = 0.2
    /// 是否无限循环（与 `ZHHCarouselView.isInfiniteLoop` 同步，影响首尾居中）
    public var isInfiniteLoop: Bool = false
    /// 缩放 / 旋转随距离变化的速率（越大离中心越快衰减）
    public var rateOfChange: CGFloat = 0.4
    /// 滚动时是否用平移补偿缩放 / 旋转造成的视觉缝隙
    public var adjustSpacingWhenScrolling: Bool = true
    /// 是否垂直居中（按 pageView 高度与 itemSize 计算上下 inset）
    public var itemVerticalCenter: Bool = true
    /// 是否首尾水平居中（仅非无限循环时生效）
    public var itemHorizontalCenter: Bool = false
    /// 弱引用 pageView（通常为内部 CollectionView，用于算居中 inset）
    public weak var pageView: UIView?
}

// MARK: - Section 边距

extension ZHHCarouselPagerLayout {

    /// 仅一个 section 时的内边距（非无限循环）
    ///
    /// 水平：开启 `itemHorizontalCenter` 时左右各半剩余宽度；否则用 `sectionInset`
    /// 垂直：开启 `itemVerticalCenter` 时上下各半剩余高度
    public var onlyOneSectionInset: UIEdgeInsets {
        let left: CGFloat
        let right: CGFloat
        // 非无限 + 首尾居中：用左右等宽 padding 把唯一 section 的内容居中
        if let pageView, !isInfiniteLoop, itemHorizontalCenter {
            left = (pageView.frame.width - itemSize.width) / 2
            right = left
        } else {
            left = sectionInset.left
            right = sectionInset.right
        }

        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: left, bottom: vertical, right: right)
        }
        return UIEdgeInsets(top: sectionInset.top, left: left, bottom: sectionInset.bottom, right: right)
    }

    /// 第一个 section 的内边距（无限循环时）
    ///
    /// 左侧保留 `sectionInset.left`，右侧用 `itemSpacing` 与下一 section 衔接
    public var firstSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: sectionInset.left, bottom: vertical, right: itemSpacing)
        }
        return UIEdgeInsets(top: sectionInset.top, left: sectionInset.left, bottom: sectionInset.bottom, right: itemSpacing)
    }

    /// 最后一个 section 的内边距（无限循环时）
    ///
    /// 左侧为 0（紧接上一 section 间距），右侧保留 `sectionInset.right`
    public var lastSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: sectionInset.right)
        }
        return UIEdgeInsets(top: sectionInset.top, left: 0, bottom: sectionInset.bottom, right: sectionInset.right)
    }

    /// 中间 section 的内边距（无限循环时）
    ///
    /// 左侧为 0，右侧用 `itemSpacing`，保证虚拟 section 副本无缝拼接
    public var middleSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: itemSpacing)
        }
        return sectionInset
    }
}

// MARK: - item 位置方向

/// item 相对 collectionView 可视中心的位置，用于决定缩放 / 旋转方向与平移补偿
private enum TransformLayoutItemDirection {
    /// 在中心左侧
    case left
    /// 与中心对齐（容差 0.5pt 内）
    case center
    /// 在中心右侧
    case right
}

// MARK: - Transform Layout

/// 自定义分页轮播 FlowLayout，支持线性缩放与封面流
///
/// 尺寸 / 间距始终以 `layoutConfig` 为准；`normal` 时不额外变换，其余类型在滚动中实时改 attributes
final class ZHHCarouselViewLayout: UICollectionViewFlowLayout {

    /// 布局配置；赋值时同步到 FlowLayout 的 itemSize / spacing，并回写 pageView
    var layoutConfig: ZHHCarouselPagerLayout? {
        didSet {
            if let config = layoutConfig {
                // 供 Section inset 计算垂直 / 水平居中
                config.pageView = collectionView
                itemSize = config.itemSize
                minimumLineSpacing = config.itemSpacing
                minimumInteritemSpacing = config.itemSpacing
            }
        }
    }

    /// 自定义变换代理；为 nil 时走内置 linear / coverflow
    weak var transformDelegate: ZHHCarouselViewLayoutDelegate?

    override init() {
        super.init()
        // 轮播仅支持横向分页
        scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .horizontal
    }
}

// MARK: - 尺寸与间距

extension ZHHCarouselViewLayout {

    /// item 尺寸：优先读 `layoutConfig`，避免外部直接改 FlowLayout 导致与配置脱节
    override var itemSize: CGSize {
        get { layoutConfig?.itemSize ?? super.itemSize }
        set { super.itemSize = newValue }
    }

    /// 行间距（横向滚动时即 item 水平间距）
    override var minimumLineSpacing: CGFloat {
        get { layoutConfig?.itemSpacing ?? super.minimumLineSpacing }
        set { super.minimumLineSpacing = newValue }
    }

    /// 列间距（与 lineSpacing 同步为同一 itemSpacing）
    override var minimumInteritemSpacing: CGFloat {
        get { layoutConfig?.itemSpacing ?? super.minimumInteritemSpacing }
        set { super.minimumInteritemSpacing = newValue }
    }
}

// MARK: - 布局

extension ZHHCarouselViewLayout {

    /// bounds 变化是否强制失效布局
    ///
    /// - Parameter newBounds: 新 bounds
    /// - Returns: `normal` 跟系统默认；其它类型始终 true，保证滚动中持续刷新变换
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        layoutConfig?.layoutType == .normal ? super.shouldInvalidateLayout(forBoundsChange: newBounds) : true
    }

    /// 返回矩形内全部 attributes，并对可见项应用滚动中变换
    ///
    /// - Parameter rect: 查询矩形
    /// - Returns: 可能已拷贝并变换过的 attributes 数组
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let config = layoutConfig else {
            return super.layoutAttributesForElements(in: rect)
        }

        // normal 且无自定义代理：直接用系统结果，避免无意义的 copy
        guard transformDelegate != nil || config.layoutType != .normal else {
            return super.layoutAttributesForElements(in: rect)
        }

        // 必须 copy：系统返回的 attributes 可能被复用，原地改会污染缓存
        guard let attrsArray = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }) else {
            return nil
        }

        // 只处理与可视区相交的 item，减轻无限循环多 section 时的开销
        let visibleRect = CGRect(origin: collectionView?.contentOffset ?? .zero, size: collectionView?.bounds.size ?? .zero)
        for attrs in attrsArray where visibleRect.intersects(attrs.frame) {
            if let transformDelegate {
                transformDelegate.pagerViewTransformLayout(self, applyTransformToAttributes: attrs)
            } else {
                applyTransform(to: attrs, layoutType: config.layoutType)
            }
        }
        return attrsArray
    }

    /// 返回单个 item 的 attributes，并做首次变换初始化
    ///
    /// - Parameter indexPath: item 索引
    /// - Returns: 初始化后的 attributes；失败时回退系统实现
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attrs = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes,
              let config = layoutConfig else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        // 首次出现时用「极限值」初始化，避免入屏瞬间从 identity 跳变
        if let transformDelegate {
            transformDelegate.pagerViewTransformLayout(self, initializeTransformAttributes: attrs)
        } else if config.layoutType != .normal {
            initializeTransformAttributes(attrs, layoutType: config.layoutType)
        }
        return attrs
    }
}

// MARK: - 变换

private extension ZHHCarouselViewLayout {

    /// 根据 item 中心 x 判断相对可视中心的左 / 中 / 右
    ///
    /// - Parameter centerX: item 中心 x
    /// - Returns: 方向枚举；无 collectionView 时默认 `.right`
    func direction(with centerX: CGFloat) -> TransformLayoutItemDirection {
        guard let collectionView else { return .right }
        let contentCenterX = collectionView.contentOffset.x + collectionView.frame.width / 2
        // 0.5pt 容差：避免浮点误差导致中心 item 被判成左 / 右
        if abs(centerX - contentCenterX) < 0.5 {
            return .center
        }
        if centerX < contentCenterX {
            return .left
        }
        return .right
    }

    /// 首次生成 attributes 时写入非 normal 的初始变换（用配置中的极限 scale / angle）
    ///
    /// - Parameters:
    ///   - attributes: 布局属性
    ///   - layoutType: 布局类型
    func initializeTransformAttributes(_ attributes: UICollectionViewLayoutAttributes, layoutType: ZHHCarouselLayoutStyle) {
        guard let config = layoutConfig else { return }
        switch layoutType {
        case .linear:
            // 入屏前先落到最小缩放 / 透明度，随后由滚动回调拉回真实值
            applyLinearTransform(to: attributes, scale: config.minimumScale, alpha: config.minimumAlpha)
        case .coverflow:
            applyCoverflowTransform(to: attributes, angle: config.maximumAngle, alpha: config.minimumAlpha)
        case .normal:
            break
        }
    }

    /// 滚动中按布局类型分发变换
    ///
    /// - Parameters:
    ///   - attributes: 布局属性
    ///   - layoutType: 布局类型
    func applyTransform(to attributes: UICollectionViewLayoutAttributes, layoutType: ZHHCarouselLayoutStyle) {
        switch layoutType {
        case .linear:
            applyLinearTransform(to: attributes)
        case .coverflow:
            applyCoverflowTransform(to: attributes)
        case .normal:
            break
        }
    }

    /// Linear：按距中心距离计算本帧的 scale / alpha，再写入 attributes
    ///
    /// - Parameter attributes: 布局属性
    func applyLinearTransform(to attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView, let config = layoutConfig else { return }
        let centerX = collectionView.contentOffset.x + collectionView.frame.width / 2
        let delta = abs(attributes.center.x - centerX)
        // 距离占屏宽比例 × rateOfChange，再夹到 minimumScale / minimumAlpha
        let scale = max(1 - delta / collectionView.frame.width * config.rateOfChange, config.minimumScale)
        let alpha = max(1 - delta / collectionView.frame.width, config.minimumAlpha)
        applyLinearTransform(to: attributes, scale: scale, alpha: alpha)
    }

    /// Linear：把给定 scale / alpha 写入 transform；可选平移补偿缩放后的视觉缝隙
    ///
    /// - Parameters:
    ///   - attributes: 布局属性
    ///   - scale: 目标缩放
    ///   - alpha: 目标透明度
    func applyLinearTransform(to attributes: UICollectionViewLayoutAttributes, scale: CGFloat, alpha: CGFloat) {
        guard let config = layoutConfig else { return }
        var finalAlpha = alpha
        var finalScale = scale

        if config.adjustSpacingWhenScrolling {
            let direction = direction(with: attributes.center.x)
            var translate: CGFloat = 0
            switch direction {
            case .left:
                // 左侧 item 向右微移，填补缩小后与中心之间的空隙
                translate = 1.15 * attributes.size.width * (1 - finalScale) / 2
            case .right:
                // 右侧 item 向左微移
                translate = -1.15 * attributes.size.width * (1 - finalScale) / 2
            case .center:
                // 正中强制满尺寸、不透明，避免浮点导致中心也略缩
                finalScale = 1.0
                finalAlpha = 1.0
            }
            var transform = CGAffineTransform(scaleX: finalScale, y: finalScale)
            transform = transform.translatedBy(x: translate, y: 0)
            attributes.transform = transform
        } else {
            attributes.transform = CGAffineTransform(scaleX: finalScale, y: finalScale)
        }
        attributes.alpha = finalAlpha
    }

    /// Coverflow：按距中心距离计算本帧的 angle / alpha，再写入 attributes
    ///
    /// - Parameter attributes: 布局属性
    func applyCoverflowTransform(to attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView, let config = layoutConfig else { return }
        let centerX = collectionView.contentOffset.x + collectionView.frame.width / 2
        let delta = abs(attributes.center.x - centerX)
        // (1 - rateOfChange) 控制旋转爬升速度，再夹到 maximumAngle
        let angle = min(delta / collectionView.frame.width * (1 - config.rateOfChange), config.maximumAngle)
        let alpha = max(1 - delta / collectionView.frame.width, config.minimumAlpha)
        applyCoverflowTransform(to: attributes, angle: angle, alpha: alpha)
    }

    /// Coverflow：绕 Y 轴做 3D 旋转，并按左右方向取反角度；可选平移补偿透视缝隙
    ///
    /// - Parameters:
    ///   - attributes: 布局属性
    ///   - angle: 旋转角度比例（乘 π 后用于 `CATransform3DRotate`）
    ///   - alpha: 目标透明度
    func applyCoverflowTransform(to attributes: UICollectionViewLayoutAttributes, angle: CGFloat, alpha: CGFloat) {
        guard let config = layoutConfig else { return }
        let direction = direction(with: attributes.center.x)

        var transform3D = CATransform3DIdentity
        // 透视系数：负值产生近大远小
        transform3D.m34 = -0.002

        var finalAngle = angle
        var finalAlpha = alpha
        var translate: CGFloat = 0

        switch direction {
        case .left:
            // 用 cos 估算旋转后投影缩短量，再平移补缝
            translate = (1 - cos(angle * 1.2 * .pi)) * attributes.size.width
        case .right:
            translate = -(1 - cos(angle * 1.2 * .pi)) * attributes.size.width
            // 右侧反向旋转，形成对称封面流
            finalAngle = -angle
        case .center:
            finalAngle = 0
            finalAlpha = 1
        }

        transform3D = CATransform3DRotate(transform3D, .pi * finalAngle, 0, 1, 0)
        if config.adjustSpacingWhenScrolling {
            transform3D = CATransform3DTranslate(transform3D, translate, 0, 0)
        }
        attributes.transform3D = transform3D
        attributes.alpha = finalAlpha
    }
}
