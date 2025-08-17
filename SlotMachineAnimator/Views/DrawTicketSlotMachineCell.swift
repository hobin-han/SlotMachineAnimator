//
//  DrawTicketSlotMachineCell.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

final class DrawTicketSlotMachineCell: UICollectionViewCell {
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    private var container: UIStackView!

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
        contentView.backgroundColor = Color.background
        
        let container = UIStackView()
        container.alignment = .center
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        self.container = container
        
        let iconImageView = UIImageView()
//        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.addArrangedSubview(iconImageView)
        self.iconImageView = iconImageView

        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        container.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel
    }

    func configure(_ item: SlotItem) {
        configure(title: item.title, icon: item.image, color: item.color)
    }
    
    func configure(title: String, icon: UIImage?, color: UIColor) {
        contentView.backgroundColor = color
        titleLabel.text = title
        iconImageView.image = icon
        iconImageView.isHidden = (icon == nil)
    }
}
