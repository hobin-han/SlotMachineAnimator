//
//  SlotMachineViewConfiguration.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/23/25.
//

import Foundation

struct SlotMachineViewConfiguration {
    typealias Cell = (height: Int, alpha: Int)
    
    /// the value is must odd.
    let visibleCount: Int
    
    let centerHeight: CGFloat
    let otherHeight: CGFloat
    
    var visibleCellConfigs: [(CGFloat, CGFloat)] {
        let defaultConfig: (CGFloat, CGFloat) = (otherHeight, 0.5)
        var result = [(CGFloat, CGFloat)](repeating: defaultConfig, count: visibleCount)
        result[visibleCount / 2] = (centerHeight, 0)
        return result
    }
}
