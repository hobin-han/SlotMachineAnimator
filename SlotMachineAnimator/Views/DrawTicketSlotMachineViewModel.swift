//
//  DrawTicketSlotMachineViewModel.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit
import Combine

/// Minimal item representation for the slot machine.
struct SlotItem: Equatable {
    let id: String
    let title: String
    let image: UIImage?
    let color: UIColor

    init(id: String, title: String, image: UIImage?, color: UIColor) {
        self.id = id
        self.title = title
        self.image = image
        self.color = color
    }
}

final class DrawTicketSlotMachineViewModel {
    enum State: Equatable {
        case idle
        case ready
        case rolling(targetIndex: Int)
        case rollEnded
    }

    /// Data Source
    private(set) var items: [SlotItem] = []

    /// Current state (notifies delegate on change)
    @Published private(set) var state: State = .idle

    /// Number of sections to simulate "infinite" scrolling.
    /// Keep this reasonably large so users can flick a bunch.
    var numberOfSections: Int = 50

    /// Convenience
    var numberOfItems: Int { items.count }
    var startCenterIndexPath: IndexPath {
        IndexPath(item: 0, section: max(0, numberOfSections / 2))
    }

    func setItems(_ items: [SlotItem]) {
        self.items = items
        state = .ready
    }

    /// Call to begin a roll to a particular logical item index (0..<(items.count)).
    func startRolling(to logicalIndex: Int) {
        guard items.indices.contains(logicalIndex) else { return }
        state = .rolling(targetIndex: logicalIndex)
    }

    /// Call when the roll has visually landed on the target cell.
    func finishRolling() {
        state = .rollEnded
    }
}
