//
//  CarouselControlViews.swift
//  ZHHCarouselView_Example
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 开关控制行：左标题、右开关
final class CarouselSwitchRowView: UIView {

    /// 标题文案
    private let titleLabel = UILabel()
    /// 开关控件
    let toggle = UISwitch()

    /// 使用标题与初始开关状态初始化
    /// - Parameters:
    ///   - title: 左侧标题
    ///   - isOn: 初始开关状态
    ///   - target: 事件目标
    ///   - action: 开关变更回调
    init(title: String, isOn: Bool, target: Any?, action: Selector) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = isOn
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(target, action: action, for: .valueChanged)
        addSubview(titleLabel)
        addSubview(toggle)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 滑杆控制行：标题 + 当前值 + 滑杆
final class CarouselSliderRowView: UIView {

    /// 标题文案
    private let titleLabel = UILabel()
    /// 当前值文案
    let valueLabel = UILabel()
    /// 滑杆控件
    let slider = UISlider()

    /// 使用标题与初始值初始化
    /// - Parameters:
    ///   - title: 左侧标题
    ///   - value: 初始滑杆值（0...1）
    ///   - target: 事件目标
    ///   - action: 滑杆变更回调
    init(title: String, value: Float, target: Any?, action: Selector) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        valueLabel.textColor = .systemBlue
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = value
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(target, action: action, for: .valueChanged)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(slider)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 分区说明 Header：展示分组标题
final class CarouselSectionHeaderView: UIView {

    /// 标题标签
    private let titleLabel = UILabel()

    /// 使用标题文案初始化
    /// - Parameter title: 分区标题
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
