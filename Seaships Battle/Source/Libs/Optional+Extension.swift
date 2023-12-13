//
//  Optional+Extension.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 19.05.2023.
//

import Foundation

extension Optional {
    func `do`(_ value: (Wrapped) -> ()) {
        _ = self.map(value)
    }
    
    func `do`(_ value: ((Wrapped) -> ())?) {
        value.do(self.do)
    }
}
