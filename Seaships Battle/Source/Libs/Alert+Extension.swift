//
//  NSAlert+Extension.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 21.05.2023.
//

import UIKit
import Foundation

extension UIAlertController {
    public static func showAlert(
        title: String,
        message: String,
        okButtonName: String = "OK",
        on controller: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: okButtonName, style: .default) { _ in
            completion?()
        }
        alert.addAction(action)
        controller.present(alert, animated: true)
    }
}
