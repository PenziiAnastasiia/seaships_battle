//
//  MainViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 10.12.2023.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet var startButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.startButton?.layer.cornerRadius = 15
    }

    @IBAction func pressStart(_ sender: UIButton) {
        let controller = EditShipsViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }

}
