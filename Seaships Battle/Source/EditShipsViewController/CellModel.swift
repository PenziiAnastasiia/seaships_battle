//
//  CellModel.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 11.12.2023.
//

import Foundation

struct CellModel: Equatable {
    
    enum CellType: Equatable {
        case full(StateType)
        case empty
        case miss
    }
    
    enum StateType: Equatable {
        case `default`
        case damaged
        case destroyed
    }
    
    let id: IndexPath
    var type: CellType
}
