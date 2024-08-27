//
//  MainViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 10.12.2023.
//

import UIKit
import FirebaseAuth

class MainViewController: UIViewController {
    
    @IBOutlet var statisticButton: UIButton?
    @IBOutlet var startButton: UIButton?
    
    var isUserLoggedIn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.startButton?.layer.cornerRadius = 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        isUserLoggedIn = Auth.auth().currentUser != nil
        statisticButton?.isHidden = !isUserLoggedIn
    }

    @IBAction func pressStart(_ sender: UIButton) {
        if isUserLoggedIn {
            self.navigationController?.pushViewController(EditShipsViewController(), animated: true)
        } else {
            let controller = UINavigationController(rootViewController: SignInViewController())
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
        }
    }
    
    @IBAction func pressStatistic(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error)
        }
    }

}
