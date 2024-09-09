//
//  GameProcessModels.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 05.09.2024.
//

import Foundation


struct GameModel: Codable {
    let isWaitingRoom: Bool
    let players: [PlayerModel]
    let lastMove: LastMoveModel?
    
    func modify(with player: PlayerModel) -> Self {
        var players = self.players
        players.append(player)
        
        return GameModel(isWaitingRoom: false, players: players, lastMove: nil)
    }
    
    func update(lastMove: LastMoveModel) -> Self {
        return GameModel(isWaitingRoom: false, players: self.players, lastMove: lastMove)
    }
}

struct PlayerModel: Codable {
    let id: String
    let ships: [[IndexPathModel]]
}

struct LastMoveModel: Codable {
    let id: String
    let move: IndexPathModel
}

struct IndexPathModel: Codable {
    let section: Int
    let item: Int
    
    init(indexPath: IndexPath) {
        self.section = indexPath.section
        self.item = indexPath.item
    }
}


