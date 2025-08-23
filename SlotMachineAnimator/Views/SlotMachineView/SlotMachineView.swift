//
//  SlotMachineView.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit
import Combine
import SnapKit

class SlotMachineView: UIView {
    
    let viewModel = SlotMachineViewModel()
    
    private let cellId = "slotMachineCell"
    private let maxSlotCount: Int = 7
    private let cellHeight: CGFloat = 60
    private let centerCellHeight: CGFloat = 80
    private let centerCellMargin: CGFloat = 0
    
    // 손으로 scroll 할때 정확히 cell 중앙에 위치하도록 설정을 위한 변수
    private var isDecelerating: Bool = false
    private var lastScrollingTime: TimeInterval?
    private var lastScrollingOffset: CGFloat?
    
    private var toCenteredSectionRow: Int?
    
    // MARK: Views
    private let tableBaseView = UIView()
    private let topTableView = UIView()
    
    private lazy var collectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }()
    private lazy var flowLayout: SlotMachineFlowLayout = {
        SlotMachineFlowLayout(delegate: self, cellHeight: cellHeight, centerCellHeight: centerCellHeight)
    }()
    
    private var cancellableBag = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        observe()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        observe()
    }
    
    private func setupView() {
        let tableBaseViewHeight = cellHeight * CGFloat(maxSlotCount - 1) + centerCellHeight
        
        addSubview(tableBaseView)
        tableBaseView.snp.makeConstraints {
            $0.leading.trailing.centerY.equalToSuperview()
            $0.height.equalTo(tableBaseViewHeight)
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(SlotMachineCollectionViewCell.self, forCellWithReuseIdentifier: self.cellId)
        tableBaseView.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isUserInteractionEnabled = false
        let outsideAlphaHeight = self.cellHeight
        let besideAlphaHeight = self.cellHeight + self.centerCellMargin
        let centerAlphaHeight = self.centerCellHeight - 2 * self.centerCellMargin
        let heights = [CGFloat](arrayLiteral: outsideAlphaHeight, outsideAlphaHeight, besideAlphaHeight, centerAlphaHeight, besideAlphaHeight, outsideAlphaHeight, outsideAlphaHeight)
        let alphas = [CGFloat](arrayLiteral: 0.9, 0.8, 0.7, 0, 0.7, 0.8, 0.9)
        for (index, alpha) in alphas.enumerated() {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            stackView.addArrangedSubview(view)
            view.heightAnchor.constraint(equalToConstant: heights[index]).isActive = true
        }
        tableBaseView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func observe() {
        viewModel.$state
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    self.collectionView.reloadData()
                    
                    self.collectionView(scrollToItemCenter: self.viewModel.startCenterIndexPath, animated: false)
                    (self.collectionView.collectionViewLayout as? SlotMachineFlowLayout)?.centeredIndexPath = self.viewModel.startCenterIndexPath
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.layoutIfNeeded()
                    
                    // collectionView.layoutIfNeeded 호출되면서 간헐적으로 scrollViewDidScroll(zero offest)이 호출되는 경우가 있다
                    // 이 경우 초기 offset 재설정
                    if self.collectionView.contentOffset.y == 0 {
                        self.collectionView(scrollToItemCenter: self.viewModel.startCenterIndexPath, animated: false)
                    }
                case .rolling(let target):
                    self.collectionView.isUserInteractionEnabled = false
                    self.isDecelerating = false
                    self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
                    self.startSlotMachine(to: target)
                default: break
                }
            }
            .store(in: &cancellableBag)
    }
    
    
    
    // MARK: Slot Machine Animation
    lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(scrollLayerScroll))
        displayLink.preferredFramesPerSecond = 60
        return displayLink
    }()
    
    var endIndexPath: IndexPath!
    var nowIndexPath: IndexPath {
        return collectionView.indexPathForItem(at: collectionView.bounds.center) ?? viewModel.startCenterIndexPath
    }
    var nowRemainRows: Int {
        getBetweenRows(from: nowIndexPath, to: endIndexPath, rowsInSection: viewModel.numberOfItems)
    }
    var startOffsetY: CGFloat!
    var endOffsetY: CGFloat!
    var nowOffsetY: CGFloat {
        return collectionView.contentOffset.y
    }
    
    let inclination: CGFloat = 10
    var slowStartOffsetY : CGFloat {
        get {
            if let endOffsetY = endOffsetY {
                return endOffsetY + 6 * cellHeight
            } else {
                return 0
            }
        }
    }
    var maxX: CGFloat = 0
    var x: CGFloat = 0
    var isSlowing: Bool = false
    var framePerSecond: Int = 1
    var slowingY: CGFloat = 0
    
    @objc func scrollLayerScroll() {
        if isSlowing {
            displayLink.preferredFramesPerSecond = framePerSecond
            framePerSecond = max(framePerSecond - 1, 1)
            
            
            if nowOffsetY <= endOffsetY {
                stopDisplayLink()
            } else {
                slowingY -= cellHeight
                print(slowingY)
                collectionView.setContentOffset(CGPoint(x: 0, y: slowingY), animated: true)
            }
        } else {
            var y: CGFloat = pow(x - maxX, 2) / inclination + endOffsetY
            y = round(y * 100) / 100 // 부동소수점 제거(소숫점 2자리 까지)
            guard !y.isNaN else {
                stopDisplayLink()
                return;
            }
            collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
            
            if nowOffsetY <= slowStartOffsetY {
                slowingY = slowStartOffsetY
                framePerSecond = 4
                isSlowing = true
            } else {
                x += 1
            }
        }
    }
    
    func startSlotMachine(to toRow: Int) {
        let minusSectionNum: Int
        switch viewModel.numberOfItems { // 돌릴 총 rows : 35 ~ 36
        case 1:             minusSectionNum = 35
        case 2:             minusSectionNum = 18
        case 3:             minusSectionNum = 12
        case 4:             minusSectionNum = 9
        case 5:             minusSectionNum = 7
        case 6:             minusSectionNum = 6
        case 7, 8:          minusSectionNum = 5
        default:            minusSectionNum = 4
        }
        
        let fromOffset = collectionView.contentOffset.y
        let toIndexPath = IndexPath(row: toRow, section: nowIndexPath.section - minusSectionNum)
        let toOffset = CGFloat((toIndexPath.section * viewModel.numberOfItems) + (toIndexPath.row) - (maxSlotCount / 2)) * cellHeight
        
        startOffsetY = fromOffset
        endIndexPath = toIndexPath
        endOffsetY = toOffset
        
        let diffOffset = fromOffset - toOffset
        maxX = sqrt(diffOffset * inclination)
        isSlowing = false
        
        displayLink.add(to: .current, forMode: .common)
    }
    func getBetweenRows(from: IndexPath, to: IndexPath, rowsInSection: Int) -> Int {
        return (to.section - from.section) * rowsInSection + (to.row - from.row)
    }
    func stopDisplayLink() {
        displayLink.invalidate()
        
//        self.viewModel.state = .rollEnded
    }
}

extension SlotMachineView: SlotMachineFlowLayoutDelegate {
    func collectionView(centerdIndexPath collectionView: UICollectionView) -> IndexPath {
        return collectionView.indexPathForItem(at: collectionView.bounds.center) ?? viewModel.startCenterIndexPath
    }
}

extension SlotMachineView {
    func collectionView(scrollToItemCenter indexPath: IndexPath, animated: Bool) {
        let numberOfItems = viewModel.numberOfItems
        let y = CGFloat(indexPath.section * numberOfItems + indexPath.row - 3) * cellHeight
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
    }
    func collectionView(scrollToOffestY y: CGFloat, animated: Bool) {
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
    }
    func collectionViewCenteredItemOffset(with indexPath: IndexPath) -> CGFloat {
        let itemNum = indexPath.section * viewModel.numberOfItems + indexPath.row - 3
        if itemNum > 0 { return CGFloat(itemNum) * cellHeight }
        return 0
    }
}

// MARK: Delegates
extension SlotMachineView: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? SlotMachineCollectionViewCell else { return UICollectionViewCell() }
        let item = viewModel.items[indexPath.row]
        cell.configure(item)
        return cell
    }
}

extension SlotMachineView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.collectionViewLayout.invalidateLayout() // cell 높이 & 위치 실시간으로 적용
        
        /*
         스와이프 모션 이후, 자동 스크롤 되고 있을 때 일정 속도 이하인 경우 강제로 cell 중앙 이동
         */
        let currentOffset = scrollView.contentOffset.y
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - (lastScrollingTime ?? 0)
        if timeDiff > 0.1 {
            let distance = currentOffset - (lastScrollingOffset ?? 0)
            
            if (abs(distance) <= 100) {
                if isDecelerating {
                    isDecelerating = false
                    var toIndexPath = nowIndexPath
                    if distance < 0 {
                        if toIndexPath.row == 0 {
                            toIndexPath.section -= 1
                            toIndexPath.row = viewModel.numberOfItems - 1
                        } else {
                            toIndexPath.row -= 1
                        }
                    } else {
                        if toIndexPath.row == viewModel.numberOfItems - 1 {
                            toIndexPath.section += 1
                            toIndexPath.row = 0
                        } else {
                            toIndexPath.row += 1
                        }
                    }
                    
                    toCenteredSectionRow = toIndexPath.row
                    collectionView(scrollToItemCenter: toIndexPath, animated: true)
                }
            }
            
            lastScrollingOffset = currentOffset
            lastScrollingTime = currentTime
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            // 무한 스크롤처럼 보이게 하기위해 사용자 스크롤 한번씩만 가능하도록 수정
            collectionView.isUserInteractionEnabled = false
        } else {
            // 스와이프 모션 없이 손을 뗐을 때 cell 중앙 이동
            collectionView(scrollToItemCenter: nowIndexPath, animated: true)
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDecelerating = false
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = true
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let row = toCenteredSectionRow else { return }
        toCenteredSectionRow = nil
        
        // 무한 스크롤처럼 보이게 하기위해 스크롤이 멈추면, 동일 row 중앙 section 으로 이동시킴
        let toIndexPath = IndexPath(row: row, section: viewModel.numberOfSections / 2)
        collectionView(scrollToItemCenter: toIndexPath, animated: false)
        (collectionView.collectionViewLayout as? SlotMachineFlowLayout)?.centeredIndexPath = toIndexPath
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        
        collectionView.isUserInteractionEnabled = true
    }
}
