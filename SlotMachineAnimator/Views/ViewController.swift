//
//  ViewController.swift
//  SlotMachineAnimator
//
//  Created by Hobin Han on 8/17/25.
//

import UIKit

class ViewController: UIViewController {
    
    private let slotMachineView = DrawTicketSlotMachineView()
    private let spinButton = UIButton()
    
    private let dummyItems = SlotItemDTO.getItems()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        slotMachineView.viewModel.setItems(dummyItems)
        slotMachineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slotMachineView)
        NSLayoutConstraint.activate([
            slotMachineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            slotMachineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            slotMachineView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        spinButton.setTitle("Spin", for: .normal)
        spinButton.backgroundColor = .systemBlue
        spinButton.addTarget(self, action: #selector(spinButtonTapped), for: .touchUpInside)
        spinButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinButton)
        NSLayoutConstraint.activate([
            spinButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            spinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinButton.widthAnchor.constraint(equalToConstant: 80),
            spinButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc private func spinButtonTapped(_ button: UIButton) {
        button.isEnabled = false
        button.backgroundColor = .systemGray
        slotMachineView.viewModel.startRolling(to: 0)
    }
}
