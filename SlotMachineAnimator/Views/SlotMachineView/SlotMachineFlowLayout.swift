//
//  DrawTicketFlowLayout.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

protocol SlotMachineFlowLayoutDelegate: AnyObject {
    var cellHeight: CGFloat { get }
    var centerCellHeight: CGFloat { get }
    var centeredIndexPath: IndexPath { get }
}

final class SlotMachineFlowLayout: UICollectionViewFlowLayout {
    
    weak var delegate: SlotMachineFlowLayoutDelegate?
    
    var centeredIndexPath: IndexPath?
    
    private var cache = [UICollectionViewLayoutAttributes]()
    
    private var cellHeight: CGFloat {
        delegate?.cellHeight ?? 0
    }
    private var centerCellHeight: CGFloat {
        delegate?.centerCellHeight ?? 0
    }
    private var numberOfSections: Int {
        collectionView?.numberOfSections ?? 0
    }
    private var numberOfItems: Int {
        collectionView?.numberOfItems(inSection: 0) ?? 0
    }
    
    override var collectionViewContentSize: CGSize {
        let width = collectionView?.bounds.width ?? 0
        let height = CGFloat(numberOfSections * numberOfItems - 1) * cellHeight + centerCellHeight
        return CGSize(width: width, height: height)
    }
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter { $0.frame.intersects(rect) }
    }
    
    override func prepare() {
        super.prepare()
        cache.isEmpty ? initCache() : updateCache()
    }
    
    private func setup() {
        minimumLineSpacing = 0
        scrollDirection = .vertical
        estimatedItemSize = .zero // UICollectionViewFlowLayout.automaticSize
    }
    
    private func initCache() {
        for section in 0..<numberOfSections {
            for row in 0..<numberOfItems {
                let indexPath = IndexPath(row: row, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                cache.append(attributes)
            }
        }
    }
    
    private func updateCache() {
        if let centerIndexPath = centeredIndexPath {
            centeredIndexPath = nil
            cache.forEach { attributes in
                attributes.frame = cellRect(indexPath: attributes.indexPath, centerIndexPath: centerIndexPath)
            }
        } else {
            cache.forEach { attributes in
                if let updatedFrame = updateCellFrame(with: attributes.indexPath) {
                    attributes.frame = updatedFrame
                }
            }
        }
    }
    
    private func cellRect(indexPath: IndexPath, centerIndexPath: IndexPath) -> CGRect {
        guard let collectionView else { return .zero }
        let itemsAboveCount = indexPath.section * numberOfItems + indexPath.row
        
        let y = indexPath <= centerIndexPath ? CGFloat(itemsAboveCount) * cellHeight : CGFloat(itemsAboveCount - 1) * cellHeight + centerCellHeight
        let width = collectionView.bounds.width
        let height = indexPath == centerIndexPath ? centerCellHeight : cellHeight
        
        return CGRect(x: 0, y: y, width: width, height: height)
    }
    
    private func updateCellFrame(with indexPath: IndexPath) -> CGRect? {
        guard let collectionView else { return .zero }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        let width = collectionView.bounds.width
        
        let cellY = cell.convert(cell.bounds, to: collectionView).center.y
        let distance = cellY - collectionView.bounds.center.y
        if distance == 0 { return nil }
        if abs(distance) < (cellHeight + centerCellHeight) / 2 {
            // 중앙 배치, cellHeight ~ centerCellHeight
            let fromHeight = cell.bounds.height
            let inclination: CGFloat = (cellHeight - centerCellHeight) / ((centerCellHeight + cellHeight) / 2.0)
            let toHeight = max(cellHeight, abs(distance) * inclination + centerCellHeight)
            let fromY = cellY - fromHeight / 2
            var toY = fromY
            
            if fromHeight < toHeight {
                if distance > 0 {
                    toY -= (toHeight - fromHeight)
                } else if distance < 0 {
                    // pass
                }
            } else if fromHeight > toHeight {
                if distance > 0 {
                    toY += (fromHeight - toHeight)
                } else if distance < 0 {
                    // pass
                }
            }
            return CGRect(x: 0, y: toY, width: width, height: toHeight)
        } else {
            let itemNumberUpon = indexPath.section * numberOfItems + indexPath.row
            let y = CGFloat(itemNumberUpon) * cellHeight
            if distance < 0 {
                // 상단 배치, cellHeight
                return CGRect(x: 0, y: y, width: width, height: cellHeight)
            } else {
                // 하단 배치, cellHeight
                return CGRect(x: 0, y: y + centerCellHeight - cellHeight, width: width, height: cellHeight)
            }
        }
    }
}
