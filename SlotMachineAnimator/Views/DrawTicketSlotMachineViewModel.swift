//
//  DrawTicketSlotMachineViewModel.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit
import Combine

/// Minimal item representation for the slot machine.
public struct SlotItem: Equatable {
    public let id: String
    public let title: String
    public let image: UIImage?
    public let color: UIColor

    public init(id: String, title: String, image: UIImage?, color: UIColor) {
        self.id = id
        self.title = title
        self.image = image
        self.color = color
    }
}

public final class DrawTicketSlotMachineViewModel {
    public enum State: Equatable {
        case idle
        case ready
        case rolling(targetIndex: Int)
        case rollEnded(finalIndex: Int)
    }

    /// Data Source
    public private(set) var items: [SlotItem] = []

    /// Current state (notifies delegate on change)
    @Published public var state: State = .idle

    /// Number of sections to simulate "infinite" scrolling.
    /// Keep this reasonably large so users can flick a bunch.
    public var numberOfSections: Int = 50

    /// Convenience
    public var numberOfItems: Int { items.count }
    public var startCenterIndexPath: IndexPath {
        IndexPath(item: 0, section: max(0, numberOfSections / 2))
    }

    public init() {}

    public func setItems(_ items: [SlotItem]) {
        self.items = items
        state = .ready
    }

    /// Call to begin a roll to a particular logical item index (0..<(items.count)).
    public func startRolling(to logicalIndex: Int) {
        guard items.indices.contains(logicalIndex) else { return }
        state = .rolling(targetIndex: logicalIndex)
    }

    /// Call when the roll has visually landed on the target cell.
    public func finishRolling(at logicalIndex: Int) {
        guard items.indices.contains(logicalIndex) else { return }
        state = .rollEnded(finalIndex: logicalIndex)
    }
}
