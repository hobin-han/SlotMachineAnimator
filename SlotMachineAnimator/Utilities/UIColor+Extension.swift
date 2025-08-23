//
//  UIColor+Extension.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/23/25.
//

import UIKit

extension UIColor {
    
    static var random: UIColor {
        UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
