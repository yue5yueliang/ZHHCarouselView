//
//  ZHHPageControl.swift
//  ZHHCarouselView
//
//  Created by 桃色三岁 on 2025/8/31.
//  Copyright © 2025 桃色三岁. All rights reserved.
//

import UIKit

/// 自定义分页控件：当前页可拉长为胶囊，切换时带尺寸 / 颜色动画
public final class ZHHPageControl: UIControl {

    // MARK: - Public Properties

    /// 页数，默认 0
    public var numberOfPages: Int = 0 {
        didSet {
            guard numberOfPages != oldValue else { return }
            if currentPage >= numberOfPages {
                currentPage = 0
            }
            updateIndicatorViews()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 当前页（范围 0 ..< numberOfPages）
    public var currentPage: Int = 0 {
        didSet {
            guard currentPage != oldValue, currentPage < indicatorViews.count else { return }
            updateIndicatorViewsBehavior()
            if !suppressesLayoutOnPageChange {
                setNeedsLayout()
            }
            if isUserInteractionEnabled {
                sendActions(for: .valueChanged)
            }
        }
    }

    /// 如果只有一页，是否隐藏指示器
    public var hidesForSinglePage: Bool = false {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 指示器间距，默认 8
    public var pageIndicatorSpacing: CGFloat = 8 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 内边距（控制整体偏移）
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 未选中页的颜色（无图片时生效）
    public var pageIndicatorTintColor: UIColor = UIColor(white: 0.5, alpha: 1) {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 当前页颜色（无图片时生效）
    public var currentPageIndicatorTintColor: UIColor = .white {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 未选中页图片（优先于颜色）
    public var pageIndicatorImage: UIImage? {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 当前页图片（优先于颜色）
    public var currentPageIndicatorImage: UIImage? {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 图片内容模式，默认 `.center`
    public var indicatorImageContentMode: UIView.ContentMode = .center {
        didSet { updateIndicatorViewsBehavior() }
    }

    /// 普通指示器大小，默认 8×8（略大于系统圆点）
    public var pageIndicatorSize: CGSize = CGSize(width: 8, height: 8) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 当前页指示器大小，默认 18×8（胶囊形，与普通页不同才会有伸缩动画）
    public var currentPageIndicatorSize: CGSize = CGSize(width: 18, height: 8) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 指示器圆角；`nil` 时按短边一半自动圆角（圆点 / 胶囊），设为 `0` 则为直角色块
    public var indicatorCornerRadius: CGFloat? = nil {
        didSet { setNeedsLayout() }
    }

    /// 页面切换动画时长
    public var animateDuration: TimeInterval = 0.25

    /// 控件的内容大小（按「当前页用 currentSize、其余用 pageSize」估算最大宽度）
    public var contentSize: CGSize {
        let count = max(indicatorViews.count, numberOfPages)
        guard count > 0 else { return .zero }
        // 预留当前页拉长后的最大占位，避免切页时 intrinsic 抖动
        let normalCount = CGFloat(max(count - 1, 0))
        let width = normalCount * pageIndicatorSize.width
            + currentPageIndicatorSize.width
            + normalCount * pageIndicatorSpacing
            + contentInset.left
            + contentInset.right
        let height = max(pageIndicatorSize.height, currentPageIndicatorSize.height)
            + contentInset.top
            + contentInset.bottom
        return CGSize(width: width, height: height)
    }

    /// Auto Layout 依赖此值；未实现时仅有 centerX/height 约束会得到宽度 0
    public override var intrinsicContentSize: CGSize { contentSize }

    // MARK: - Private Properties

    /// 存放指示器视图
    private var indicatorViews: [UIImageView] = []

    /// 为 true 时 `currentPage` 变更不立刻 `setNeedsLayout`，改由动画块内 `layoutSubviews` 驱动
    private var suppressesLayoutOnPageChange = false

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
    }

    // MARK: - Public Methods

    /// 设置当前页，可选择是否启用胶囊伸缩动画
    ///
    /// - Parameters:
    ///   - page: 目标页
    ///   - animated: 是否动画（仅当当前页与普通页尺寸不同时视觉差异明显）
    func setCurrentPage(_ page: Int, animated: Bool) {
        guard page >= 0, page < numberOfPages, page != currentPage else { return }

        if animated, window != nil {
            // 先改状态与颜色，再在动画块里改 frame，避免布局提前刷掉导致无动画
            suppressesLayoutOnPageChange = true
            currentPage = page
            suppressesLayoutOnPageChange = false
            UIView.animate(
                withDuration: animateDuration,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
            ) {
                self.layoutSubviews()
            }
        } else {
            currentPage = page
        }
    }

    // MARK: - Private Update Methods

    /// 更新指示器数量
    private func updateIndicatorViews() {
        indicatorViews.forEach { $0.removeFromSuperview() }
        indicatorViews.removeAll()

        for _ in 0..<numberOfPages {
            let indicator = UIImageView()
            indicator.contentMode = indicatorImageContentMode
            indicator.clipsToBounds = true
            addSubview(indicator)
            indicatorViews.append(indicator)
        }

        updateIndicatorViewsBehavior()
    }

    /// 更新指示器样式（颜色/图片/隐藏逻辑）
    private func updateIndicatorViewsBehavior() {
        guard !indicatorViews.isEmpty else { return }

        if hidesForSinglePage && indicatorViews.count == 1 {
            indicatorViews.first?.isHidden = true
            return
        }

        for (index, indicator) in indicatorViews.enumerated() {
            indicator.isHidden = false
            let isCurrent = index == currentPage
            if let image = pageIndicatorImage {
                indicator.image = isCurrent ? (currentPageIndicatorImage ?? image) : image
                indicator.contentMode = indicatorImageContentMode
                indicator.backgroundColor = .clear
            } else {
                indicator.image = nil
                indicator.backgroundColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor
            }
        }
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard !indicatorViews.isEmpty else { return }

        var originX: CGFloat = 0
        var spacing = pageIndicatorSpacing

        switch contentHorizontalAlignment {
        case .center:
            originX = (bounds.width - contentSize.width) / 2 + contentInset.left
        case .left, .leading:
            originX = contentInset.left
        case .right, .trailing:
            originX = bounds.width - contentSize.width + contentInset.left
        case .fill:
            if numberOfPages > 1 {
                let totalDotWidth = CGFloat(numberOfPages - 1) * pageIndicatorSize.width + currentPageIndicatorSize.width
                spacing = (bounds.width - contentInset.left - contentInset.right - totalDotWidth) / CGFloat(numberOfPages - 1)
            }
            originX = contentInset.left
        @unknown default:
            break
        }

        var centerY = bounds.midY
        switch contentVerticalAlignment {
        case .top:
            centerY = contentInset.top + currentPageIndicatorSize.height / 2
        case .bottom:
            centerY = bounds.height - contentInset.bottom - currentPageIndicatorSize.height / 2
        case .fill:
            centerY = (bounds.height - contentInset.top - contentInset.bottom) / 2 + contentInset.top
        case .center:
            fallthrough
        @unknown default:
            centerY = bounds.midY
        }

        for (index, indicator) in indicatorViews.enumerated() {
            let size = index == currentPage ? currentPageIndicatorSize : pageIndicatorSize
            // nil：圆点 / 胶囊；显式赋值：直角或小圆角色块
            indicator.layer.cornerRadius = indicatorCornerRadius ?? min(size.width, size.height) / 2
            indicator.frame = CGRect(x: originX, y: centerY - size.height / 2, width: size.width, height: size.height)
            originX += size.width + spacing
        }
    }
}
