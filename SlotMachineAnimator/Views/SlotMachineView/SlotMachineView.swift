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
    
    private var animator: SlotMachineAnimator?
    private lazy var animationDisplayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(scrollLayerScroll))
        displayLink.preferredFramesPerSecond = 60
        return displayLink
    }()
    
    private var centerIndexPath: IndexPath {
        collectionView.indexPathForItem(at: collectionView.bounds.center) ?? viewModel.startCenterIndexPath
    }
    
    private var isDecelerating: Bool = false
    
    // 손으로 scroll 할때 정확히 cell 중앙에 위치하도록 설정을 위한 변수
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
        visibleCellConfigs.forEach { (height, alpha) in
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            stackView.addArrangedSubview(view)
            view.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        stackView.isUserInteractionEnabled = false
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
                case .idle: break
                case .ready:
                    strongSelf.updateCollectionView()
                case .rolling(let target):
                    strongSelf.animateSlotMachine(to: target)
                case .rollEnded(let target):
                    let item = strongSelf.viewModel.items[target]
                    print("finish 🎉 \(item)") // TODO: show view
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
}

// MARK: - Slot Machine Animation
extension SlotMachineView {
    
    private func animateSlotMachine(to row: Int) {
        collectionView.isUserInteractionEnabled = false
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        
        let fromOffset = collectionView.contentOffset.y
        let minusSectionNum = max(1, 40 / viewModel.numberOfItems)
        let toIndexPath = IndexPath(row: row, section: centerIndexPath.section - minusSectionNum)
        let itemAboveNum = toIndexPath.section * viewModel.numberOfItems + toIndexPath.row - config.visibleCount / 2
        let toOffset = CGFloat(itemAboveNum) * cellHeight
        animator = SlotMachineAnimator(cellHeight: cellHeight, startOffsetY: fromOffset, endOffsetY: toOffset, endIndexPath: toIndexPath)
        isDecelerating = false
        
        animationDisplayLink.add(to: .current, forMode: .common)
    }
    
    @objc private func scrollLayerScroll() {
        guard let animator else { return }
        animator.slowingY == 0 ? animateScollViewFastly(animator) : animateScrollViewSlowly(animator)
    }
    
    private func animateScollViewFastly(_ animator: SlotMachineAnimator) {
        let y = round(animator.y * 100) / 100 // 부동소수점 제거(소숫점 2자리 까지)
        
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
        
        if collectionView.contentOffset.y <= animator.slowStartOffsetY {
            animator.slowingY = animator.slowStartOffsetY
            animator.framePerSecond = 4
        } else {
            animator.plusX()
        }
    }
    
    private func animateScrollViewSlowly(_ animator: SlotMachineAnimator) {
        animationDisplayLink.preferredFramesPerSecond = animator.framePerSecond
        animator.framePerSecond = max(animator.framePerSecond - 1, 1)
        
        
        if collectionView.contentOffset.y <= animator.endOffsetY {
            stopDisplayLink()
        } else {
            animator.slowingY -= cellHeight
            collectionView.setContentOffset(CGPoint(x: 0, y: animator.slowingY), animated: true)
        }
    }
    
    private func stopDisplayLink() {
        animationDisplayLink.invalidate()
        viewModel.finishRolling(at: centerIndexPath.row)
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
        viewModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
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
            if abs(distance) <= 100 && isDecelerating {
                isDecelerating = false
                var toIndexPath = centerIndexPath
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
            
            lastScrollingOffset = currentOffset
            lastScrollingTime = currentTime
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDecelerating = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            // 무한 스크롤처럼 보이게 하기위해 사용자 스크롤 한번씩만 가능하도록 수정
            collectionView.isUserInteractionEnabled = false
        } else {
            collectionView(scrollToItemCenter: centerIndexPath, animated: true)
        }
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
