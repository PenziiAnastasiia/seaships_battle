//
//  SignViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 22.08.2024.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    @IBOutlet var signLabel: UILabel!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var emailErrorLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var passwordErrorLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signUpButton.layer.cornerRadius = 15
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func pressSignUp(_ sender: UIButton) {
        Task {
            let email = emailTextField.text ?? ""
            let password = passwordTextField.text ?? ""
            let name = nameTextField.text ?? email.components(separatedBy: "@").first
            
            do {
                let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
                
                print("User signed up: \(authResult.user.uid)")
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            } catch {
                let authResult = ErrorService.getLocalizedError(from: error)
                emailErrorLabel.text = authResult.textEmailError
                passwordErrorLabel.text = authResult.textPasswordError
            }
        }
    }
}
