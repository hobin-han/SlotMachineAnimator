//
//  SlotMachineAnimator.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/24/25.
//

import UIKit

class SlotMachineAnimator {
    
    private let inclination: CGFloat = 10
    private let cellHeight: CGFloat
    private let startOffsetY: CGFloat
    let endOffsetY: CGFloat
    let endIndexPath: IndexPath
    
    let slowStartOffsetY: CGFloat
    var slowingY: CGFloat = 0
    
    var framePerSecond: Int = 1
    
    private var x: CGFloat = 0
    var y: CGFloat {
        pow(x - maxX, 2) / inclination + endOffsetY
    }
    
    
    var maxX: CGFloat {
        let diffOffset = startOffsetY - endOffsetY
        return sqrt(diffOffset * inclination)
    }
    
    init(cellHeight: CGFloat, startOffsetY: CGFloat, endOffsetY: CGFloat, endIndexPath: IndexPath) {
        self.cellHeight = cellHeight
        self.startOffsetY = startOffsetY
        self.endOffsetY = endOffsetY
        self.endIndexPath = endIndexPath
        self.slowStartOffsetY = endOffsetY + 6 * cellHeight
    }
    
    func plusX() {
        x += 1
    }
}
