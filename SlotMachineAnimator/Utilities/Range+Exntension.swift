//
//  Range+Exntension.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/24/25.
//

extension Range where Bound == Int {
    
    var random: Int {
        return Int.random(in: self)
    }
}
