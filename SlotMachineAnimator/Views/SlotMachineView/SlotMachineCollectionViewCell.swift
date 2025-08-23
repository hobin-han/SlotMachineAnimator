//
//  SlotMachineCollectionViewCell.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit
import SDWebImage
import SnapKit

protocol SlotMachineCellConfiguration {
    var foregroundTitle: String? { get }
    var backgroundImageURL: URL? { get }
    var backgroundColor: UIColor? { get }
}

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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.sd_cancelCurrentImageLoad()
        backgroundImageView.image = nil
    }

    private func setup() {
        contentView.backgroundColor = .black
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        backgroundImageView.clipsToBounds = true
        backgroundImageView.contentMode = .scaleAspectFill
        contentView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func configure(_ data: SlotMachineCellConfiguration) {
        contentView.backgroundColor = data.backgroundColor
        
        titleLabel.text = data.foregroundTitle
        backgroundImageView.sd_setImage(with: data.backgroundImageURL)
    }
}
