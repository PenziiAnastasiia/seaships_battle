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
    
    private var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.startButton?.layer.cornerRadius = 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentUser = Auth.auth().currentUser
        statisticButton?.isHidden = currentUser == nil
    }

    @IBAction func pressStart(_ sender: UIButton) {
        if let user = currentUser {
            self.navigationController?.pushViewController(EditShipsViewController(currentUser: user), animated: true)
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
