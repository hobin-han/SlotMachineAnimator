//
//  DrawTicketSlotMachineCell.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

final class DrawTicketSlotMachineCell: UICollectionViewCell {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let quantityLabel = UILabel()
    private let container = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.shadowOpacity = 0
    }

    private func setup() {
        contentView.backgroundColor = .black
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1

        quantityLabel.font = .systemFont(ofSize: 14, weight: .regular)
        quantityLabel.textColor = .secondaryLabel
        quantityLabel.textAlignment = .left

        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        let labels = UIStackView(arrangedSubviews: [titleLabel, quantityLabel])
        labels.axis = .vertical
        labels.alignment = .leading
        labels.spacing = 2

        container.addArrangedSubview(iconImageView)
        container.addArrangedSubview(labels)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, icon: UIImage?, color: UIColor) {
        titleLabel.text = title
        iconImageView.image = icon
        contentView.backgroundColor = color
        iconImageView.isHidden = (icon == nil)
    }
}
