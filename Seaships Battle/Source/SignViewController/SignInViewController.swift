//
//  SignViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 22.08.2024.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var emailErrorLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var passwordErrorLabel: UILabel!
    @IBOutlet var signInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.layer.cornerRadius = 15
    }
    
    @IBAction func pressSignIn(_ sender: UIButton) {
        Task {
            let email = emailTextField.text ?? ""
            let password = passwordTextField.text ?? ""
            
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                print("User signed in: \(authResult.user.uid)")
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            } catch {
                print(error)
                let authResult = ErrorService.getLocalizedError(from: error)
                emailErrorLabel.text = authResult.textEmailError
                passwordErrorLabel.text = authResult.textPasswordError
            }
        }
    }

    @IBAction func pressSignUp(_ sender: UIButton) {
        let controller = SignUpViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
