//
//  CarouselCell.swift
//  ZHHCarouselView_Example
//
//  Created by 桃色三岁 on 11/07/2026.
//  Copyright (c) 2026 桃色三岁. All rights reserved.
//

import UIKit

/// 轮播示例 Cell：色块底 + 居中标题
final class CarouselCell: UICollectionViewCell {

    /// Cell 复用标识
    static let reuseIdentifier = "CarouselCell"

    /// 居中标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 使用条目模型配置 Cell
    /// - Parameter item: 轮播条目
    func configure(with item: CarouselItem) {
        contentView.backgroundColor = item.color
        titleLabel.text = item.title
    }
}
