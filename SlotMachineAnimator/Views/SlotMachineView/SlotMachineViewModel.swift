//
//  SlotMachineViewModel.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import Foundation
import Combine

final class SlotMachineViewModel {
    
    enum State: Equatable {
        case idle
        case ready
        case rolling(targetIndex: Int)
        case rollEnded(finalIndex: Int)
    }
    
    @Published var state: State = .idle

    /// Data Source
    private(set) var items: [SlotMachineCellConfiguration] = []


    /// Number of sections to simulate "infinite" scrolling.
    /// Keep this reasonably large so users can flick a bunch.
    let numberOfSections: Int = 50

    var numberOfItems: Int {
        items.count
    }
    
    var startCenterIndexPath: IndexPath {
        IndexPath(item: 0, section: max(0, numberOfSections / 2))
    }

    func setItems(_ items: [SlotMachineCellConfiguration]) {
        self.items = items
        state = .ready
    }

    /// Call to begin a roll to a particular logical item index (0..<(items.count)).
    func startRolling(to logicalIndex: Int) {
        guard items.indices.contains(logicalIndex) else { return }
        state = .rolling(targetIndex: logicalIndex)
    }

    /// Call when the roll has visually landed on the target cell.
    func finishRolling(at logicalIndex: Int) {
        guard items.indices.contains(logicalIndex) else { return }
        state = .rollEnded(finalIndex: logicalIndex)
    }
}
