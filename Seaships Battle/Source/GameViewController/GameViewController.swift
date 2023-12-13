//
//  GameViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 11.12.2023.
//

import UIKit

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
    
    private var disableUserIteraction: ((Bool) -> Void)?
    
    init(myShips: [[IndexPath]], enemyShips: [[IndexPath]]) {
        self.myShipsArray = myShips
        self.enemyShipsArray = enemyShips
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
        self.disableUserIteraction = self.rootView?.configure()
        
        self.myCellModels = self.generateItems()
        self.enemyCellModels = self.generateItems()
      
        self.myShipsArray.forEach { ship in
            ship.forEach { point in
                self.myCellModels[point.section][point.item].type = .full(.default)
            }
        }
        
        self.fillMyShips()
        self.fillEnemyShips()
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
        let model = self.selectModel(
            at: indexPath,
            shipsArray: self.enemyShipsArray,
            cellModels: &self.enemyCellModels,
            shipsDictionary: &self.enemyShipsDictionary)
        
        model.safeZone.forEach { point in
            self.enemyCellModels[point.section][point.item].type = .miss
        }
        self.fillEnemyShips()
        if !self.checkEnemyShips(), !model.shot {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.enemyActions()
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
        self.disableUserIteraction?(false)
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
                self.disableUserIteraction?(true)
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
    
    private func checkMyShips() -> Bool {
        let ships = self.myShipsDictionary.compactMap { $1 }
        if self.check(ships: ships) {
            UIAlertController.showAlert(title: "На жаль!", message: "Ви програли!", on: self) { [weak self] in
                self?.backToStartFlow()
            }
            
            return true
        }
        
        return false
    }
    
    private func checkEnemyShips() -> Bool {
        let ships = self.enemyShipsDictionary.compactMap { $1 }
        if self.check(ships: ships) {
            UIAlertController.showAlert(title: "Вітаннячка!", message: "Ви перемогли!", on: self) { [weak self] in
                self?.backToStartFlow()
            }
            
            return true
        }
        
        return false
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
