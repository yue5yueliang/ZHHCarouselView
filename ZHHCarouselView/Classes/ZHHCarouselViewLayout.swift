//
//  ZHHCarouselViewLayout.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 2025/8/31.
//  Copyright © 2025 桃色三岁. All rights reserved.
//

import UIKit

// MARK: - 布局类型

/// 循环翻页的布局类型
public enum ZHHCarouselLayoutStyle {
    /// 普通布局（不做特殊效果）
    case normal
    /// 线性布局（缩放 + 透明度变化）
    case linear
    /// Coverflow 布局（旋转 + 透明度变化）
    case coverflow
}

// MARK: - 布局代理协议

/// 布局回调；未设置时使用内置 linear / coverflow
protocol ZHHCarouselViewLayoutDelegate: AnyObject {
    /// 初始化布局属性
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, initializeTransformAttributes attributes: UICollectionViewLayoutAttributes)
    /// 应用布局变换
    func pagerViewTransformLayout(_ layout: ZHHCarouselViewLayout, applyTransformToAttributes attributes: UICollectionViewLayoutAttributes)
}

// MARK: - 页面布局配置

/// 分页布局配置
public final class ZHHCarouselPagerLayout {

    /// 默认初始化
    public init() {}

    /// 每个 item 的尺寸
    public var itemSize: CGSize = .zero
    /// item 之间的间距
    public var itemSpacing: CGFloat = 0
    /// section 内边距
    public var sectionInset: UIEdgeInsets = .zero
    /// 布局类型
    public var layoutType: ZHHCarouselLayoutStyle = .normal
    /// 最小缩放比例（默认 0.8）
    public var minimumScale: CGFloat = 0.8
    /// 最小透明度（默认 1.0）
    public var minimumAlpha: CGFloat = 1.0
    /// 最大旋转角度百分比（默认 0.2）
    public var maximumAngle: CGFloat = 0.2
    /// 是否无限循环（与 ZHHCarouselView.isInfiniteLoop 同步）
    public var isInfiniteLoop: Bool = false
    /// 缩放 / 旋转变化速率（默认 0.4）
    public var rateOfChange: CGFloat = 0.4
    /// 滚动时是否自动调整间距
    public var adjustSpacingWhenScrolling: Bool = true
    /// 是否垂直居中
    public var itemVerticalCenter: Bool = true
    /// 是否首尾水平居中（仅非无限循环）
    public var itemHorizontalCenter: Bool = false
    /// 弱引用 pageView（通常为 CollectionView）
    public weak var pageView: UIView?

    // MARK: - section 边距

    /// 仅一个 section 时的内边距
    public var onlyOneSectionInset: UIEdgeInsets {
        let left: CGFloat
        let right: CGFloat
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

    /// 第一个 section 的内边距
    public var firstSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: sectionInset.left, bottom: vertical, right: itemSpacing)
        }
        return UIEdgeInsets(top: sectionInset.top, left: sectionInset.left, bottom: sectionInset.bottom, right: itemSpacing)
    }

    /// 最后一个 section 的内边距
    public var lastSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: sectionInset.right)
        }
        return UIEdgeInsets(top: sectionInset.top, left: 0, bottom: sectionInset.bottom, right: sectionInset.right)
    }

    /// 中间 section 的内边距
    public var middleSectionInset: UIEdgeInsets {
        if itemVerticalCenter, let pageView {
            let vertical = (pageView.frame.height - itemSize.height) / 2
            return UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: itemSpacing)
        }
        return sectionInset
    }
}

// MARK: - item 位置方向

/// item 相对 collectionView 中心的位置
private enum TransformLayoutItemDirection {
    case left
    case center
    case right
}

// MARK: - Transform Layout

/// 自定义分页轮播 FlowLayout，支持线性缩放与封面流
final class ZHHCarouselViewLayout: UICollectionViewFlowLayout {

    /// 布局配置
    public var layoutConfig: ZHHCarouselPagerLayout? {
        didSet {
            if let config = layoutConfig {
                config.pageView = collectionView
                itemSize = config.itemSize
                minimumLineSpacing = config.itemSpacing
                minimumInteritemSpacing = config.itemSpacing
            }
        }
    }

    /// 自定义变换代理；为 nil 时走内置 linear / coverflow
    public weak var transformDelegate: ZHHCarouselViewLayoutDelegate?

    public override init() {
        super.init()
        scrollDirection = .horizontal
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .horizontal
    }

    // MARK: - 尺寸与间距（始终读自 layoutConfig）

    public override var itemSize: CGSize {
        get { layoutConfig?.itemSize ?? super.itemSize }
        set { super.itemSize = newValue }
    }

    public override var minimumLineSpacing: CGFloat {
        get { layoutConfig?.itemSpacing ?? super.minimumLineSpacing }
        set { super.minimumLineSpacing = newValue }
    }

    public override var minimumInteritemSpacing: CGFloat {
        get { layoutConfig?.itemSpacing ?? super.minimumInteritemSpacing }
        set { super.minimumInteritemSpacing = newValue }
    }

    // MARK: - 辅助

    /// 根据 centerX 判断左 / 中 / 右
    private func direction(with centerX: CGFloat) -> TransformLayoutItemDirection {
        guard let collectionView else { return .right }
        let contentCenterX = collectionView.contentOffset.x + collectionView.frame.width / 2
        if abs(centerX - contentCenterX) < 0.5 {
            return .center
        }
        if centerX < contentCenterX {
            return .left
        }
        return .right
    }

    // MARK: - 布局

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        layoutConfig?.layoutType == .normal ? super.shouldInvalidateLayout(forBoundsChange: newBounds) : true
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let config = layoutConfig else {
            return super.layoutAttributesForElements(in: rect)
        }

        // 仅自定义代理或非普通布局时才拷贝并变换
        guard transformDelegate != nil || config.layoutType != .normal else {
            return super.layoutAttributesForElements(in: rect)
        }

        guard let attrsArray = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }) else {
            return nil
        }

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

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attrs = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes,
              let config = layoutConfig else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        if let transformDelegate {
            transformDelegate.pagerViewTransformLayout(self, initializeTransformAttributes: attrs)
        } else if config.layoutType != .normal {
            initializeTransformAttributes(attrs, layoutType: config.layoutType)
        }
        return attrs
    }

    // MARK: - 变换

    /// 初始化非 normal 的变换属性
    private func initializeTransformAttributes(_ attributes: UICollectionViewLayoutAttributes, layoutType: ZHHCarouselLayoutStyle) {
        guard let config = layoutConfig else { return }
        switch layoutType {
        case .linear:
            applyLinearTransform(to: attributes, scale: config.minimumScale, alpha: config.minimumAlpha)
        case .coverflow:
            applyCoverflowTransform(to: attributes, angle: config.maximumAngle, alpha: config.minimumAlpha)
        case .normal:
            break
        }
    }

    /// 按类型应用滚动中变换
    private func applyTransform(to attributes: UICollectionViewLayoutAttributes, layoutType: ZHHCarouselLayoutStyle) {
        switch layoutType {
        case .linear:
            applyLinearTransform(to: attributes)
        case .coverflow:
            applyCoverflowTransform(to: attributes)
        case .normal:
            break
        }
    }

    /// Linear：按距离计算 scale / alpha
    private func applyLinearTransform(to attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView, let config = layoutConfig else { return }
        let centerX = collectionView.contentOffset.x + collectionView.frame.width / 2
        let delta = abs(attributes.center.x - centerX)
        let scale = max(1 - delta / collectionView.frame.width * config.rateOfChange, config.minimumScale)
        let alpha = max(1 - delta / collectionView.frame.width, config.minimumAlpha)
        applyLinearTransform(to: attributes, scale: scale, alpha: alpha)
    }

    /// Linear：写入 transform / alpha
    private func applyLinearTransform(to attributes: UICollectionViewLayoutAttributes, scale: CGFloat, alpha: CGFloat) {
        guard let config = layoutConfig else { return }
        var finalAlpha = alpha
        var finalScale = scale

        if config.adjustSpacingWhenScrolling {
            let direction = direction(with: attributes.center.x)
            var translate: CGFloat = 0
            switch direction {
            case .left:
                translate = 1.15 * attributes.size.width * (1 - finalScale) / 2
            case .right:
                translate = -1.15 * attributes.size.width * (1 - finalScale) / 2
            case .center:
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

    /// Coverflow：按距离计算 angle / alpha
    private func applyCoverflowTransform(to attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView, let config = layoutConfig else { return }
        let centerX = collectionView.contentOffset.x + collectionView.frame.width / 2
        let delta = abs(attributes.center.x - centerX)
        let angle = min(delta / collectionView.frame.width * (1 - config.rateOfChange), config.maximumAngle)
        let alpha = max(1 - delta / collectionView.frame.width, config.minimumAlpha)
        applyCoverflowTransform(to: attributes, angle: angle, alpha: alpha)
    }

    /// Coverflow：写入 3D transform / alpha
    private func applyCoverflowTransform(to attributes: UICollectionViewLayoutAttributes, angle: CGFloat, alpha: CGFloat) {
        guard let config = layoutConfig else { return }
        let direction = direction(with: attributes.center.x)

        var transform3D = CATransform3DIdentity
        transform3D.m34 = -0.002

        var finalAngle = angle
        var finalAlpha = alpha
        var translate: CGFloat = 0

        switch direction {
        case .left:
            translate = (1 - cos(angle * 1.2 * .pi)) * attributes.size.width
        case .right:
            translate = -(1 - cos(angle * 1.2 * .pi)) * attributes.size.width
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
