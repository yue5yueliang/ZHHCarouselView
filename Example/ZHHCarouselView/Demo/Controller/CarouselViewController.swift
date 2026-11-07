//
//  CarouselViewController.swift
//  ZHHCarouselView_Example
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit
import ZHHCarouselView

/// 轮播 Demo 页面（View 层）：演示无限循环、自动播放、三种布局与尺寸调节
final class CarouselViewController: UIViewController {

    // MARK: - 常量

    private enum Constants {
        static let pagerHeight: CGFloat = 200
        static let pageControlHeight: CGFloat = 26
        static let autoScrollInterval: CGFloat = 3
        static let edgeInset: CGFloat = 16
        static let cardRadius: CGFloat = 12
    }

    // MARK: - 属性

    /// 页面对应的 ViewModel
    private let viewModel: CarouselViewModel

    // MARK: - UI

    /// 可滚动容器
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    /// 内容容器
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 顶部说明文案
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = "支持无限循环与自动播放，可切换普通 / 线性缩放 / 封面流，并调节卡片尺寸与指示点。"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 轮播预览卡片容器
    private lazy var pagerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cardRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 轮播视图
    private lazy var pagerView: ZHHCarouselView = {
        let view = ZHHCarouselView()
        view.isInfiniteLoop = true
        view.autoScrollInterval = Constants.autoScrollInterval
        view.dataSource = self
        view.delegate = self
        view.register(CarouselCell.self, forCellWithReuseIdentifier: CarouselCell.reuseIdentifier)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 分页指示器
    private lazy var pageControl: ZHHPageControl = {
        let control = ZHHPageControl()
        control.pageIndicatorSize = CGSize(width: 6, height: 6)
        control.currentPageIndicatorSize = CGSize(width: 16, height: 6)
        control.pageIndicatorSpacing = 8
        control.indicatorCornerRadius = nil
        control.currentPageIndicatorTintColor = .systemBlue
        control.pageIndicatorTintColor = .tertiaryLabel
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    /// 当前页文案
    private lazy var pageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "当前第 1 页"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 数据分区摘要
    private lazy var sectionSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var playHeader = CarouselSectionHeaderView(title: "播放设置")
    private lazy var layoutHeader = CarouselSectionHeaderView(title: "布局样式")
    private lazy var sizeHeader = CarouselSectionHeaderView(title: "尺寸调节")

    private lazy var playCard = makeCardView()
    private lazy var layoutCard = makeCardView()
    private lazy var sizeCard = makeCardView()

    private lazy var infiniteRow = CarouselSwitchRowView(title: "无限循环", isOn: true, target: self, action: #selector(infiniteChanged(_:)))
    private lazy var autoScrollRow = CarouselSwitchRowView(title: "自动播放", isOn: true, target: self, action: #selector(autoScrollChanged(_:)))
    private lazy var centerRow = CarouselSwitchRowView(title: "首尾居中", isOn: true, target: self, action: #selector(horizontalCenterChanged(_:)))

    private lazy var layoutControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["普通", "线性缩放", "封面流"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(layoutStyleChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var itemSizeRow = CarouselSliderRowView(title: "卡片大小", value: 0.8, target: self, action: #selector(itemSizeChanged(_:)))
    private lazy var itemSpaceRow = CarouselSliderRowView(title: "卡片间距", value: 0.5, target: self, action: #selector(itemSpaceChanged(_:)))
    private lazy var pageDotRow = CarouselSliderRowView(title: "指示点大小", value: 0, target: self, action: #selector(pageDotChanged(_:)))

    /// 使用 ViewModel 初始化页面
    /// - Parameter viewModel: 轮播数据与布局配置来源
    init(viewModel: CarouselViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "轮播视图"
        view.backgroundColor = .systemGroupedBackground
        setupSubviews()
        setupConstraints()
        bindViewModel()
    }

    /// 搭建视图层级
    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [tipLabel, pagerCard, pageLabel, sectionSummaryLabel, playHeader, playCard, layoutHeader, layoutCard, sizeHeader, sizeCard].forEach {
            contentView.addSubview($0)
        }
        // 与「轮播视图」参考一致：指示器叠在轮播视图上
        pagerCard.addSubview(pagerView)
        pagerView.addSubview(pageControl)

        let playSeparator1 = makeSeparator()
        let playSeparator2 = makeSeparator()
        [infiniteRow, playSeparator1, autoScrollRow, playSeparator2, centerRow].forEach { playCard.addSubview($0) }

        layoutCard.addSubview(layoutControl)

        let sizeSeparator1 = makeSeparator()
        let sizeSeparator2 = makeSeparator()
        [itemSizeRow, sizeSeparator1, itemSpaceRow, sizeSeparator2, pageDotRow].forEach { sizeCard.addSubview($0) }

        // 记录分隔线以便约束
        playSeparator1.tag = 101
        playSeparator2.tag = 102
        sizeSeparator1.tag = 201
        sizeSeparator2.tag = 202
    }

    /// 配置 Auto Layout 约束
    private func setupConstraints() {
        let inset = Constants.edgeInset
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            tipLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            tipLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            tipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            pagerCard.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 16),
            pagerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            pagerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            pagerCard.heightAnchor.constraint(equalToConstant: Constants.pagerHeight),

            pagerView.topAnchor.constraint(equalTo: pagerCard.topAnchor),
            pagerView.leadingAnchor.constraint(equalTo: pagerCard.leadingAnchor),
            pagerView.trailingAnchor.constraint(equalTo: pagerCard.trailingAnchor),
            pagerView.bottomAnchor.constraint(equalTo: pagerCard.bottomAnchor),

            pageControl.leadingAnchor.constraint(equalTo: pagerView.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: pagerView.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: pagerView.bottomAnchor, constant: -10),
            pageControl.heightAnchor.constraint(equalToConstant: Constants.pageControlHeight),

            pageLabel.topAnchor.constraint(equalTo: pagerCard.bottomAnchor, constant: 10),
            pageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            pageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            sectionSummaryLabel.topAnchor.constraint(equalTo: pageLabel.bottomAnchor, constant: 8),
            sectionSummaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            sectionSummaryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            playHeader.topAnchor.constraint(equalTo: sectionSummaryLabel.bottomAnchor, constant: 24),
            playHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            playHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            playCard.topAnchor.constraint(equalTo: playHeader.bottomAnchor, constant: 10),
            playCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            playCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset)
        ])

        guard let playSeparator1 = playCard.viewWithTag(101), let playSeparator2 = playCard.viewWithTag(102) else { return }
        playSeparator1.translatesAutoresizingMaskIntoConstraints = false
        playSeparator2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infiniteRow.topAnchor.constraint(equalTo: playCard.topAnchor),
            infiniteRow.leadingAnchor.constraint(equalTo: playCard.leadingAnchor),
            infiniteRow.trailingAnchor.constraint(equalTo: playCard.trailingAnchor),

            playSeparator1.topAnchor.constraint(equalTo: infiniteRow.bottomAnchor),
            playSeparator1.leadingAnchor.constraint(equalTo: playCard.leadingAnchor, constant: 16),
            playSeparator1.trailingAnchor.constraint(equalTo: playCard.trailingAnchor),
            playSeparator1.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            autoScrollRow.topAnchor.constraint(equalTo: playSeparator1.bottomAnchor),
            autoScrollRow.leadingAnchor.constraint(equalTo: playCard.leadingAnchor),
            autoScrollRow.trailingAnchor.constraint(equalTo: playCard.trailingAnchor),

            playSeparator2.topAnchor.constraint(equalTo: autoScrollRow.bottomAnchor),
            playSeparator2.leadingAnchor.constraint(equalTo: playSeparator1.leadingAnchor),
            playSeparator2.trailingAnchor.constraint(equalTo: playSeparator1.trailingAnchor),
            playSeparator2.heightAnchor.constraint(equalTo: playSeparator1.heightAnchor),

            centerRow.topAnchor.constraint(equalTo: playSeparator2.bottomAnchor),
            centerRow.leadingAnchor.constraint(equalTo: playCard.leadingAnchor),
            centerRow.trailingAnchor.constraint(equalTo: playCard.trailingAnchor),
            centerRow.bottomAnchor.constraint(equalTo: playCard.bottomAnchor),

            layoutHeader.topAnchor.constraint(equalTo: playCard.bottomAnchor, constant: 24),
            layoutHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            layoutHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            layoutCard.topAnchor.constraint(equalTo: layoutHeader.bottomAnchor, constant: 10),
            layoutCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            layoutCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            layoutControl.topAnchor.constraint(equalTo: layoutCard.topAnchor, constant: 12),
            layoutControl.leadingAnchor.constraint(equalTo: layoutCard.leadingAnchor, constant: 12),
            layoutControl.trailingAnchor.constraint(equalTo: layoutCard.trailingAnchor, constant: -12),
            layoutControl.bottomAnchor.constraint(equalTo: layoutCard.bottomAnchor, constant: -12),
            layoutControl.heightAnchor.constraint(equalToConstant: 32),

            sizeHeader.topAnchor.constraint(equalTo: layoutCard.bottomAnchor, constant: 24),
            sizeHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            sizeHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            sizeCard.topAnchor.constraint(equalTo: sizeHeader.bottomAnchor, constant: 10),
            sizeCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            sizeCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            sizeCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        guard let sizeSeparator1 = sizeCard.viewWithTag(201), let sizeSeparator2 = sizeCard.viewWithTag(202) else { return }
        sizeSeparator1.translatesAutoresizingMaskIntoConstraints = false
        sizeSeparator2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemSizeRow.topAnchor.constraint(equalTo: sizeCard.topAnchor),
            itemSizeRow.leadingAnchor.constraint(equalTo: sizeCard.leadingAnchor),
            itemSizeRow.trailingAnchor.constraint(equalTo: sizeCard.trailingAnchor),

            sizeSeparator1.topAnchor.constraint(equalTo: itemSizeRow.bottomAnchor),
            sizeSeparator1.leadingAnchor.constraint(equalTo: sizeCard.leadingAnchor, constant: 16),
            sizeSeparator1.trailingAnchor.constraint(equalTo: sizeCard.trailingAnchor),
            sizeSeparator1.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            itemSpaceRow.topAnchor.constraint(equalTo: sizeSeparator1.bottomAnchor),
            itemSpaceRow.leadingAnchor.constraint(equalTo: sizeCard.leadingAnchor),
            itemSpaceRow.trailingAnchor.constraint(equalTo: sizeCard.trailingAnchor),

            sizeSeparator2.topAnchor.constraint(equalTo: itemSpaceRow.bottomAnchor),
            sizeSeparator2.leadingAnchor.constraint(equalTo: sizeSeparator1.leadingAnchor),
            sizeSeparator2.trailingAnchor.constraint(equalTo: sizeSeparator1.trailingAnchor),
            sizeSeparator2.heightAnchor.constraint(equalTo: sizeSeparator1.heightAnchor),

            pageDotRow.topAnchor.constraint(equalTo: sizeSeparator2.bottomAnchor),
            pageDotRow.leadingAnchor.constraint(equalTo: sizeCard.leadingAnchor),
            pageDotRow.trailingAnchor.constraint(equalTo: sizeCard.trailingAnchor),
            pageDotRow.bottomAnchor.constraint(equalTo: sizeCard.bottomAnchor)
        ])
    }

    /// 从 ViewModel 加载数据并刷新轮播
    private func bindViewModel() {
        viewModel.loadData()
        pageControl.numberOfPages = viewModel.allItems.count
        let summaries = (0..<viewModel.numberOfSections).compactMap { index -> String? in
            guard let section = viewModel.section(at: index) else { return nil }
            return "\(section.title)：\(section.items.count) 页"
        }
        sectionSummaryLabel.text = "数据分区（\(viewModel.numberOfSections)）：" + summaries.joined(separator: " · ")
        updateItemSizeValueLabel()
        updateItemSpaceValueLabel()
        updatePageDotValueLabel()
        pagerView.reloadData()
    }

    /// 圆角内容卡片
    /// - Returns: 卡片容器
    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = Constants.cardRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// 列表分隔线
    /// - Returns: 分隔线视图
    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// 刷新「卡片大小」右侧文案
    private func updateItemSizeValueLabel() {
        itemSizeRow.valueLabel.text = String(format: "%.0f%%", viewModel.itemSizeRatio * 100)
    }

    /// 刷新「卡片间距」右侧文案
    private func updateItemSpaceValueLabel() {
        itemSpaceRow.valueLabel.text = String(format: "%.0f pt", viewModel.itemSpacing)
    }

    /// 刷新「指示点大小」右侧文案
    private func updatePageDotValueLabel() {
        let scale = 1 + CGFloat(pageDotRow.slider.value)
        pageDotRow.valueLabel.text = String(format: "%.0f×%.0f", 16 * scale, 6 * scale)
    }
}

// MARK: - 交互

private extension CarouselViewController {

    /// 无限循环开关
    @objc func infiniteChanged(_ sender: UISwitch) {
        pagerView.isInfiniteLoop = sender.isOn
        pagerView.updateData()
    }

    /// 自动播放开关
    @objc func autoScrollChanged(_ sender: UISwitch) {
        pagerView.autoScrollInterval = sender.isOn ? Constants.autoScrollInterval : 0
    }

    /// 首尾居中开关（关闭无限循环时更明显）
    @objc func horizontalCenterChanged(_ sender: UISwitch) {
        viewModel.updateHorizontalCenter(sender.isOn)
        pagerView.layout?.itemHorizontalCenter = sender.isOn
        UIView.animate(withDuration: 0.3) {
            self.pagerView.setNeedUpdateLayout()
        }
    }

    /// 普通 / 线性缩放 / 封面流
    @objc func layoutStyleChanged(_ sender: UISegmentedControl) {
        let style: ZHHCarouselLayoutStyle
        switch sender.selectedSegmentIndex {
        case 1: style = .linear
        case 2: style = .coverflow
        default: style = .normal
        }
        viewModel.updateLayoutStyle(style)
        pagerView.layout?.layoutType = style
        pagerView.setNeedUpdateLayout()
    }

    /// 卡片大小滑杆
    @objc func itemSizeChanged(_ sender: UISlider) {
        viewModel.updateItemSizeRatio(CGFloat(sender.value))
        updateItemSizeValueLabel()
        guard pagerView.bounds.width > 0 else { return }
        pagerView.layout?.itemSize = viewModel.itemSize(for: pagerView.bounds.size)
        pagerView.setNeedUpdateLayout()
    }

    /// 卡片间距滑杆
    @objc func itemSpaceChanged(_ sender: UISlider) {
        viewModel.updateItemSpacingRatio(CGFloat(sender.value))
        updateItemSpaceValueLabel()
        pagerView.layout?.itemSpacing = viewModel.itemSpacing
        pagerView.setNeedUpdateLayout()
    }

    /// 指示点尺寸滑杆
    @objc func pageDotChanged(_ sender: UISlider) {
        let scale = 1 + CGFloat(sender.value)
        pageControl.pageIndicatorSize = CGSize(width: 6 * scale, height: 6 * scale)
        pageControl.currentPageIndicatorSize = CGSize(width: 16 * scale, height: 6 * scale)
        pageControl.pageIndicatorSpacing = 8 * scale
        pageControl.indicatorCornerRadius = nil
        updatePageDotValueLabel()
    }
}

// MARK: - ZHHCarouselViewDataSource

extension CarouselViewController: ZHHCarouselViewDataSource {

    /// 返回业务页数量
    func numberOfItems(in pagerView: ZHHCarouselView) -> Int {
        viewModel.allItems.count
    }

    /// 返回指定业务索引的 Cell
    func pagerView(_ pagerView: ZHHCarouselView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: CarouselCell.reuseIdentifier, for: index) as! CarouselCell
        if let item = viewModel.item(atFlatIndex: index) {
            cell.configure(with: item)
        }
        return cell
    }

    /// 返回布局配置
    func layout(for pagerView: ZHHCarouselView) -> ZHHCarouselPagerLayout {
        let layout = ZHHCarouselPagerLayout()
        let width = pagerView.bounds.width > 0 ? pagerView.bounds.width : UIScreen.main.bounds.width - Constants.edgeInset * 2
        let height = pagerView.bounds.height > 0 ? pagerView.bounds.height : Constants.pagerHeight
        layout.itemSize = viewModel.itemSize(for: CGSize(width: width, height: height))
        layout.itemSpacing = viewModel.itemSpacing
        layout.layoutType = viewModel.layoutStyle
        layout.itemHorizontalCenter = viewModel.isHorizontalCenter
        return layout
    }
}

// MARK: - ZHHCarouselViewDelegate

extension CarouselViewController: ZHHCarouselViewDelegate {

    /// 页索引变化时同步指示器与文案
    func pagerView(_ pagerView: ZHHCarouselView, didScrollFromIndex fromIndex: Int, toIndex: Int) {
        pageControl.currentPage = toIndex
        pageLabel.text = "当前第 \(toIndex + 1) 页"
    }

    /// 点击某一页时提示
    func pagerView(_ pagerView: ZHHCarouselView, didSelectItemCell cell: UICollectionViewCell, at index: Int) {
        let title = viewModel.item(atFlatIndex: index)?.title ?? "第 \(index + 1) 页"
        let alert = UIAlertController(title: "选中页面", message: title, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
