//
//  GameViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 11.12.2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

struct SelectModelResult {
    let safeZone: [IndexPath]
    let shot: Bool
}

class GameViewController: UIViewController {
    var rootView: GameView? {
        self.viewIfLoaded as? GameView
    }

    private var myCellModels: [[CellModel]] = []
    private var enemyCellModels: [[CellModel]] = []
    private var myShipsArray = [[IndexPath]]()
    private var myShipsDictionary: [Int : [IndexPath]] = [:]
    private var enemyShipsArray = [[IndexPath]]()
    private var enemyShipsDictionary: [Int : [IndexPath]] = [:]
    
    private var enemyBoard = BoardGenerator.generate
    private var possiblePoints: [IndexPath] = []
    private var partialShip: [IndexPath] = []
    
    private var enableUserIteraction: ((Bool) -> Void)?
    
    private var currentUser: User
    private var isMyTurn: Bool
    private var gameRoomRef: DatabaseReference?
    private var gameModel: GameModel?
    private var observer: UInt?
    private let isOnlineGame: Bool
    
    deinit {
        debugPrint("deinit:", String(describing: type(of: self)))
    }
    
    init(myShips: [[IndexPath]], enemyShips: [[IndexPath]], currentUser: User, isMyTurn: Bool,
         gameRoomRef: DatabaseReference?) {
        self.myShipsArray = myShips
        self.enemyShipsArray = enemyShips
        self.currentUser = currentUser
        self.isMyTurn = isMyTurn
        self.gameRoomRef = gameRoomRef
        self.isOnlineGame = gameRoomRef != nil
        super.init(nibName: "GameViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configure()
    }
    
    private func fillMyShips() {
        self.rootView?.fill(stack: .my, models: self.myCellModels)
    }
    
    private func fillEnemyShips() {
        self.rootView?.fill(stack: .enemy, models: self.enemyCellModels, action: { [weak self] model in
            self?.selectModel(at: model.id)
        })
    }
    
    private func configure() {
        self.enableUserIteraction = self.rootView?.configure(isOnlineGame: self.isOnlineGame) { [weak self] polygon in
            self?.completeGame(with: polygon)
        }
        
        self.myCellModels = self.generateItems()
        self.enemyCellModels = self.generateItems()
      
        self.myShipsArray.forEach { ship in
            ship.forEach { point in
                self.myCellModels[point.section][point.item].type = .full(.default)
            }
        }
        
        self.fillMyShips()
        self.fillEnemyShips()
        
        if let gameRef = self.gameRoomRef {
            gameRef.observeSingleEvent(of:.value, with: { [weak self] snapshot in
                if let game: GameModel = (snapshot.value as? [String : Any])?.toModel() {
                    self?.gameModel = game
                }
            })
        }
        
        self.enableUserIteraction?(self.isMyTurn)
        self.observeOfGameUpdates()
    }
    
    public func generateItems() -> [[CellModel]] {
        return (0...9).compactMap { section in
            (0...9).compactMap { item in
                return CellModel(id: IndexPath(item: item, section: section), type: .empty)
            }
        }
    }
    
    private func selectModel(at indexPath: IndexPath) {
        guard self.enemyCellModels[indexPath.section][indexPath.item].type == .empty else { return }
        
        let moveModel = LastMoveModel(id: self.currentUser.uid, move: IndexPathModel(indexPath: indexPath))
        if let game = self.gameModel, let roomRef = self.gameRoomRef {
            let newGameModel = game.update(lastMove: moveModel)
            if let dictionary = newGameModel.dictionary {
                roomRef.updateChildValues(dictionary)
            }
        }
        let model = self.selectModel(
            at: indexPath,
            shipsArray: self.enemyShipsArray,
            cellModels: &self.enemyCellModels,
            shipsDictionary: &self.enemyShipsDictionary)
        
        model.safeZone.forEach { point in
            self.enemyCellModels[point.section][point.item].type = .miss
        }
        self.fillEnemyShips()
        if !self.checkEnemyShips() {
            if self.isOnlineGame {
                self.enableUserIteraction?(model.shot)
            } else {
                if !model.shot {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        self?.enemyActions()
                    }
                }
            }
        }
    }
    
    private func selectModel(
        at indexPath: IndexPath,
        shipsArray: [[IndexPath]],
        cellModels: inout [[CellModel]],
        shipsDictionary: inout [Int : [IndexPath]]
    ) -> SelectModelResult
    {
        var model = cellModels[indexPath.section][indexPath.item]
        var safeZone: [IndexPath] = []
        var shot = false
        model.type = .miss
        shipsArray.enumerated().forEach { (i, ship) in
            if ship.contains(indexPath) {
                if shipsDictionary[i] == nil {
                    shipsDictionary[i] = [indexPath]
                } else {
                    shipsDictionary[i]?.append(indexPath)
                }
                model.type = .full(.damaged)
                shot = true
                if shipsDictionary[i]?.count == shipsArray[i].count {
                    model.type = .full(.destroyed)
                    shipsDictionary[i]?.forEach { point in
                        cellModels[point.section][point.item].type = .full(.destroyed)
                    }
                    safeZone = SafeZoneBuilder.createSafeZone(around: ship, state: .vertical)
                    if ship.count > 1 {
                        if ship[0].add(item: 1) == ship[1] {
                            safeZone = SafeZoneBuilder.createSafeZone(around: ship, state: .horisontal)
                        }
                    }
                }
            }
        }
        cellModels[indexPath.section][indexPath.item] = model
        
        return SelectModelResult(safeZone: safeZone, shot: shot)
    }
    
    private func enemyActions() {
        self.enableUserIteraction?(false)
        var somePoint: IndexPath?
        if self.possiblePoints.isEmpty {
            somePoint = self.enemyBoard.randomElement()
        } else {
            somePoint = self.possiblePoints.randomElement()
        }
        guard let point = somePoint else { return }
        
        self.enemyBoard.remove(object: point)
        self.possiblePoints.remove(object: point)
        let model = self.selectModel(
            at: point,
            shipsArray: self.myShipsArray,
            cellModels: &self.myCellModels,
            shipsDictionary: &self.myShipsDictionary)
        model.safeZone.forEach { point in
            self.enemyBoard.remove(object: point)
        }
        self.fillMyShips()
        if !self.checkMyShips() {
            if model.shot {
                self.partialShip.append(point)
                self.partialShip.sort { previous, next in
                    previous.item < next.item || previous.section < next.section
                }
                if !model.safeZone.isEmpty {
                    self.partialShip.removeAll()
                    self.possiblePoints.removeAll()
                }
                self.generatePossiblePoints()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.enemyActions()
                }
            } else {
                self.enableUserIteraction?(true)
            }
        }
    }
    
    private func generatePossiblePoints() {
        if let first = self.partialShip.first,
           let last = self.partialShip.last
        {
            if first == last {
                if self.possiblePoints.isEmpty {
                    self.possiblePoints = first.perpendicular.filter { indexPath in
                        self.enemyBoard.contains(indexPath)
                    }
                }
            } else {
                if first.item < last.item {
                    self.possiblePoints = [first.add(item: -1), last.add(item: 1)].filter(startIndex: 0, endIndex: 9)
                } else if first.section < last.section {
                    self.possiblePoints = [first.add(section: -1), last.add(section: 1)].filter(startIndex: 0, endIndex: 9)
                }
            }
        }
    }
    
    private func observeOfGameUpdates() {
        self.observer = self.gameRoomRef?.observe(.value, with: { [weak self] snapshot in
            self?.onlineEnemyMoves(with: snapshot)
        })
    }
    
    private func onlineEnemyMoves(with snapshot: DataSnapshot) {
        if let game: GameModel = (snapshot.value as? [String : Any])?.toModel(),
           let lastMove = game.lastMove, lastMove.id != self.currentUser.uid {
            let lastMoveIndexPath = IndexPath(item: lastMove.move.item, section: lastMove.move.section)
            let model = self.selectModel(at: lastMoveIndexPath, shipsArray: self.myShipsArray,
                                         cellModels: &self.myCellModels, shipsDictionary: &self.myShipsDictionary)
            self.fillMyShips()
            if !self.checkMyShips() {
                self.enableUserIteraction?(!model.shot)
            }
        }
    }
    
    private func checkMyShips() -> Bool {
        let ships = self.myShipsDictionary.compactMap { $1 }
        if self.check(ships: ships) {
            self.completeGame(with: .my)
            
            return true
        }
        
        return false
    }
    
    private func checkEnemyShips() -> Bool {
        let ships = self.enemyShipsDictionary.compactMap { $1 }
        if self.check(ships: ships) {
            self.completeGame(with: .enemy)
            
            return true
        }
        
        return false
    }
    
    private func completeGame(with polygon: Polygon) {
        UIAlertController.showAlert(
            title: polygon == .enemy ? "Вітаннячка!" : "На жаль!",
            message: polygon == .enemy ? "Ви перемогли!" : "Ви програли!",
            on: self
        ) { [weak self] in
            if let handler = self?.observer, let gameRef = self?.gameRoomRef {
                gameRef.removeObserver(withHandle: handler)
                gameRef.removeValue()
            }
            self?.backToStartFlow()
        }
    }
    
    private func check(ships: [[IndexPath]]) -> Bool {
        if ships.count == 10 {
            return !(1...4).compactMap { i in
                if ships.filter({ ship in
                    ship.count == (5 - i)
                }).count == i {
                    return true
                } else {
                    return false
                }
            }.contains(false)
        }
        
        return false
    }
    
    private func backToStartFlow() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
