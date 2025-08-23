//
//  SlotItemDTO.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/23/25.
//

import UIKit

struct SlotItemDTO {
    let id: Int
    let title: String
    let imageUrl: String
    
    
    static func getItems() -> [Self] {
        // reference: - https://www.clipartmax.com/
        let images = [
            "https://www.clipartmax.com/png/middle/121-1218040_waves-aesthetic-transparent-tumblr-flower.png",
            "https://www.clipartmax.com/png/middle/278-2783664_publicat-de-eu-ciresica-la-flowers-orange-aesthetic-png.png",
            "https://www.clipartmax.com/png/middle/170-1705283_aesthetic-aesthetictumblr-pink-flower-png-sticker-tumbl-aesthetic-png.png",
            "https://www.clipartmax.com/png/middle/287-2872990_rose-clipart-aesthetic-flower-aesthetic-transparent.png",
            "https://www.clipartmax.com/png/middle/176-1761766_flower-white-whiteflower-tumblr-aesthetic-white-flowers-transparent.png",
            "https://www.clipartmax.com/png/middle/193-1932652_beautiful-flowers-blue-aesthetic-tumblr-transparent.png",
            "https://www.clipartmax.com/png/middle/277-2770784_transparent-transparent-gif-pink-aesthetic-flower-aesthetic-flower-bouquet.png",
        ]
        
        return images.enumerated().map {
            SlotItemDTO(id: $0.offset, title: "Ticket \(String($0.offset + 1))", imageUrl: $0.element)
        }
    }
}

extension SlotItemDTO: SlotMachineCellConfiguration {
    var foregroundTitle: String? {
        title
    }
    
    var backgroundImageURL: URL? {
        URL(string: imageUrl)
    }
    
    var backgroundColor: UIColor? {
        nil
    }
}
