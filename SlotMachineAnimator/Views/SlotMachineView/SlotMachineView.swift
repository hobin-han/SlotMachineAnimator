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
    
    private let cellId = "SlotMachineCollectionViewCell"
    private let config: SlotMachineViewConfiguration
    
    // 손으로 scroll 할때 정확히 cell 중앙에 위치하도록 설정을 위한 변수
    private var isDecelerating: Bool = false
    private var lastScrollingTime: TimeInterval?
    private var lastScrollingOffset: CGFloat?
    private var toCenteredSectionRow: Int?
    
    // MARK: Views
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SlotMachineFlowLayout())
    private var flowLayout: SlotMachineFlowLayout {
        collectionView.collectionViewLayout as! SlotMachineFlowLayout
    }
    
    private var cancellableBag = Set<AnyCancellable>()
    
    init(_ config: SlotMachineViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        setupView()
        observe()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        flowLayout.delegate = self
        
        let visibleCellConfigs = config.visibleCellConfigs
        let visibleHeight = visibleCellConfigs.reduce(0) { $0 + $1.0 }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(SlotMachineCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(visibleHeight)
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isUserInteractionEnabled = false
        visibleCellConfigs.forEach { (height, alpha) in
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            stackView.addArrangedSubview(view)
            view.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.invalidateLayout()
    }
    
    private func observe() {
        viewModel.$state
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let strongSelf = self else { return }
                switch state {
                case .ready:
                    strongSelf.updateCollectionView()
                case .rolling(let target):
                    strongSelf.collectionView.isUserInteractionEnabled = false
                    strongSelf.isDecelerating = false
                    strongSelf.collectionView.setContentOffset(strongSelf.collectionView.contentOffset, animated: false)
                    strongSelf.startSlotMachine(to: target)
                default: break
                }
            }
            .store(in: &cancellableBag)
    }
    
    private func updateCollectionView() {
        collectionView.reloadData()
        
        let toIndexPath = viewModel.startCenterIndexPath
        
        collectionView(scrollToItemCenter: toIndexPath, animated: false)
        flowLayout.centeredIndexPath = toIndexPath
        flowLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        
        // collectionView.layoutIfNeeded 호출되면서 간헐적으로 scrollViewDidScroll(zero offest)이 호출되는 경우가 있다
        // 이 경우 초기 offset 재설정
        if collectionView.contentOffset.y == 0 {
            collectionView(scrollToItemCenter: toIndexPath, animated: false)
        }
    }
    
    func collectionView(scrollToItemCenter indexPath: IndexPath, animated: Bool) {
        let numberOfItems = viewModel.numberOfItems
        let itemsAboveNum = indexPath.section * numberOfItems + indexPath.row - config.visibleCount / 2
        let y = CGFloat(itemsAboveNum) * cellHeight
        
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
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
        let toOffset = CGFloat((toIndexPath.section * viewModel.numberOfItems) + (toIndexPath.row) - (config.visibleCount / 2)) * cellHeight
        
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

// MARK: - SlotMachineFlowLayoutDelegate
extension SlotMachineView: SlotMachineFlowLayoutDelegate {
    var cellHeight: CGFloat {
        config.otherHeight
    }
    
    var centerCellHeight: CGFloat {
        config.centerHeight
    }
    
    var centeredIndexPath: IndexPath {
        collectionView.indexPathForItem(at: collectionView.bounds.center) ?? viewModel.startCenterIndexPath
    }
}

// MARK: - UICollectionView Delegate & DataSource
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

// MARK: - UIScrollView Delegate
extension SlotMachineView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        flowLayout.invalidateLayout() // cell 높이 & 위치 실시간으로 적용
        
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
        flowLayout.centeredIndexPath = toIndexPath
        flowLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        
        collectionView.isUserInteractionEnabled = true
    }
}
