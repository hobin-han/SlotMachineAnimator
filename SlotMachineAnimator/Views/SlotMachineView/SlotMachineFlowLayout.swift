//
//  DrawTicketFlowLayout.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

protocol SlotMachineFlowLayoutDelegate: AnyObject {
    func collectionView(centerdIndexPath collectionView: UICollectionView) -> IndexPath
}

final class SlotMachineFlowLayout: UICollectionViewFlowLayout {
    
    weak var delegate: SlotMachineFlowLayoutDelegate?
    
    private var cellHeight: CGFloat!
    private var centerCellHeight: CGFloat!
    var centeredIndexPath: IndexPath?
    
    private var cache = [UICollectionViewLayoutAttributes]()
    private var numberOfSections: Int {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.numberOfSections
    }
    private var numberOfItems: Int {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.numberOfItems(inSection: 0)
    }
    
    
    init(cellHeight: CGFloat, centerCellHeight: CGFloat) {
        super.init()
        self.cellHeight = cellHeight
        self.centerCellHeight = centerCellHeight
        
        minimumLineSpacing = 0
        scrollDirection = .vertical
        estimatedItemSize = .zero // UICollectionViewFlowLayout.automaticSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        if cache.isEmpty {
            for section in 0..<numberOfSections {
                for row in 0..<numberOfItems {
                    let indexPath = IndexPath(row: row, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    attributes.frame = originCellFrame(indexPath: indexPath)
                    cache.append(attributes)
                }
            }
        } else {
            if let centerIndexPath = centeredIndexPath {
                // centeredIndexPath 값이 있으면, 해당 쎌이 중앙에 위치한다는 가정하에 frame 설정해주기
                centeredIndexPath = nil
                cache.forEach { attributes in
                    let indexPath = attributes.indexPath
                    let width: CGFloat = collectionView?.bounds.width ?? 0
                    let itemNumberUpon = indexPath.section * numberOfItems + indexPath.row
                    let y = CGFloat(itemNumberUpon) * cellHeight
                    
                    if attributes.indexPath == centerIndexPath {
                        attributes.frame = CGRect(x: 0, y: y, width: width, height: centerCellHeight)
                    } else {
                        if indexPath < centerIndexPath {
                            attributes.frame = CGRect(x: 0, y: y, width: width, height: cellHeight)
                        } else {
                            attributes.frame = CGRect(x: 0, y: y + (centerCellHeight - cellHeight), width: width, height: cellHeight)
                        }
                    }
                }
            } else {
                cache.forEach { attributes in
                    if let updatedFrame = updateCellFrame(with: attributes.indexPath) {
                        attributes.frame = updatedFrame
                    }
                }
            }
        }
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override var collectionViewContentSize: CGSize {
        let width = collectionView?.bounds.width ?? 0
        let height = CGFloat(numberOfSections * numberOfItems) * cellHeight + (centerCellHeight - cellHeight)
        return CGSize(width: width, height: height)
    }
    
    
    private func getItemDifferenceNumber(_ indexPath: IndexPath, with centerdIndexPath: IndexPath) -> Int {
        return (indexPath.section - centerdIndexPath.section) * numberOfItems + indexPath.row - centerdIndexPath.row
    }
    
    private func updateCellFrame(with indexPath: IndexPath) -> CGRect? {
        guard let collectionView = collectionView else { return .zero }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        let width: CGFloat = collectionView.bounds.width
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
    private func originCellFrame(indexPath: IndexPath) -> CGRect {
        guard let collectionView, let delegate else { return .zero }
        let itemNumberUpon = indexPath.section * numberOfItems + indexPath.row
        let centerIndexPath = delegate.collectionView(centerdIndexPath: collectionView)
        
        let width: CGFloat = collectionView.bounds.width
        let y = CGFloat(itemNumberUpon) * cellHeight
        if indexPath == centerIndexPath {
            return CGRect(x: 0, y: y, width: width, height: centerCellHeight)
        } else if indexPath.section < centerIndexPath.section || indexPath.section == centerIndexPath.section && indexPath.row < centerIndexPath.row {
            return CGRect(x: 0, y: y, width: width, height: cellHeight)
        } else {
            return CGRect(x: 0, y: y + centerCellHeight - cellHeight, width: width, height: cellHeight)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
}


extension CGRect {
    
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
