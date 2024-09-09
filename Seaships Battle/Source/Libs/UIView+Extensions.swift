//
//  UIView+Extensions.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 08.09.2024.
//

import Foundation
import UIKit

extension UIView {
    
    func addSubviewWithConstrants(_ subview: UIView) {
        self.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
}
