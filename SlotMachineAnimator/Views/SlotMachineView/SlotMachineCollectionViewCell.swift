//
//  SlotMachineCollectionViewCell.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

final class SlotMachineCollectionViewCell: UICollectionViewCell {
    
    private let backgroundImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = .black
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        backgroundImageView.contentMode = .scaleAspectFill
        contentView.addSubview(backgroundImageView)

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
    }
    
    func configure(title: String, backgroundImage: URL?, color: UIColor) {
        titleLabel.text = title
        backgroundImageView.image = nil // TODO
        contentView.backgroundColor = color
    }
}
