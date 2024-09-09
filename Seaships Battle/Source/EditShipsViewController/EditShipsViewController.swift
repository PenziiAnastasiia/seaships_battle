//
//  EditShipsViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 10.12.2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EditShipsViewController: UIViewController {
    
    var rootView: EditShipsView? {
        self.viewIfLoaded as? EditShipsView
    }
    
    private let shipsBuilder = ShipsBuilder()
    
    private var cellModels: [[CellModel]] = []
    private var lockedPoints: [IndexPath] = []
    private var mySelectPoints: [IndexPath] = []
    
    private var currentUser: User
    private var gameRooms: DatabaseReference {
        let databaseURL = "https://seashipbattle-default-rtdb.europe-west1.firebasedatabase.app"
        return Database.database(url: databaseURL).reference()
    }
    
    private var observer: UInt?
    private var gameID: String?
    
    deinit {
        debugPrint("deinit:", String(describing: type(of: self)))
    }
    
    init(currentUser: User) {
        self.currentUser = currentUser
        super.init(nibName: "EditShipsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.generateItems()
        self.fillView()
    }
    
    @IBAction func pressBack(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func pressClear(_ sender: UIButton) {
        self.lockedPoints = []
        self.mySelectPoints = []
        
        self.generateItems()
        self.fillView()
    }
    
    @IBAction func pressPlay(_ sender: UIButton) {
        let myShips = self.createMyShips()
        
        if self.check(ships: myShips) {
            let alert = UIAlertController(title: "З ким хочете зіграти?", message: nil, preferredStyle: .alert)
            
            let playWithComputerAction = UIAlertAction(title: "З комп'ютером оффлайн", style: .default) { [weak self] _ in
                self?.playOfflineGame(myShips: myShips)
            }
            
            let playOnlineAction = UIAlertAction(title: "З користувачами онлайн", style: .default) { [weak self] _ in
                self?.playOnlineGame(myShips: myShips)
            }
            
            let playOnlineWithFriendAction = UIAlertAction(title: "З другом", style: .default)
            
            alert.addAction(playWithComputerAction)
            alert.addAction(playOnlineAction)
            alert.addAction(playOnlineWithFriendAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func waitGameCompletion(_ sender: UIButton) {
        if let handler = self.observer, let gameID = self.gameID {
            let room = self.gameRooms.child(gameID)
            room.removeObserver(withHandle: handler)
            room.removeValue()
        }
    }
    
    //MARK:
    //MARK: - Private
    
    private func generateItems() {
        self.cellModels = (0...9).compactMap { section in
            (0...9).compactMap { item in
                return CellModel(id: IndexPath(item: item, section: section), type: .empty)
            }
        }
    }
    
    private func fillView() {
        self.rootView?.fill(with: self.cellModels, action: { [weak self] model in
            self?.didSelect(indexPath: model.id)
        })
    }
    
    private func didSelect(indexPath: IndexPath) {
        if !self.lockedPoints.contains(where: { $0.section == indexPath.section && $0.item == indexPath.item }) {
            self.selectModel(at: indexPath)
            self.fillView()
        }
    }
    
    private func createMyShips() -> [[IndexPath]] {
        var array = self.sortMyPoints()
        var myShips: [[IndexPath]] = []
        for _ in (0...9) {
            if array.isEmpty || array[0].isEmpty {
                break
            }
            var currentShip: [IndexPath] = []
            array.object(at: 0).do { section in
                section.object(at: 0).do { point in
                    currentShip.append(point)
                    array[0].remove(object: point)
                }
            }
            
            if let section = array.object(at: 0), section.isEmpty {
                array.remove(at: 0)
                self.searchVerticalShip(startIndex: 0, array: &array, currentShip: &currentShip)
            } else if let section = array.object(at: 0), section[0] == currentShip.last!.add(item: 1) {
                self.searchHorisontalShip(array: &array, currentShip: &currentShip)
            } else {
                self.searchVerticalShip(startIndex: 1, array: &array, currentShip: &currentShip)
            }
            myShips.append(currentShip)
        }
        myShips.sort { $0.count > $1.count }
        
        return myShips
    }
    
    private func sortMyPoints() -> [[IndexPath]] {
        return self.mySelectPoints.sorted { first, second in
            first.section < second.section
        }.reduce([[IndexPath]]()) { result, indexPath in
            var array = result
            if let section = result.first(where: { $0.first?.section == indexPath.section }) {
                var indexes = section
                indexes.append(indexPath)
                indexes.sort { $0.item < $1.item }
                array.firstIndex { $0.first?.section == indexPath.section }
                    .map { index in
                        array.remove(at: index)
                        array.append(indexes)
                    }
            } else {
                array.append([indexPath])
            }
            
            return array
        }
    }
    
    private func searchHorisontalShip(array: inout [[IndexPath]], currentShip: inout [IndexPath]) {
        for _ in (0...3) {
            if !array.isEmpty && array[0][0] == currentShip.last!.add(item: 1) {
                currentShip.append(array[0][0])
                array[0].remove(object: array[0][0])
                if array[0].isEmpty {
                    array.remove(at: 0)
                }
            } else {
                break
            }
        }
    }
    
    private func searchVerticalShip(startIndex: Int, array: inout [[IndexPath]], currentShip: inout [IndexPath]) {
        var j = 0
        for i in (startIndex...9) {
            if !array.isEmpty,
               let section = array.object(at: i+j),
               let point = currentShip.last,
               section.contains(point.add(section: 1))
            {
                if let indexElement = section.firstIndex(of: point.add(section: 1)) {
                    currentShip.append(point.add(section: 1))
                    array[i+j].remove(at: indexElement)
                    if array[i+j].isEmpty {
                        array.remove(at: i+j)
                        j -= 1
                    }
                }
            } else {
                break
            }
        }
    }
    
    private func check(ships: [[IndexPath]]) -> Bool {
        if ships.count != 10 {
            UIAlertController.showAlert(title: "Увага!", message: "Невірна кількість кораблів", on: self)
            return false
        }
        for i in (1...4) {
            if ships.filter({ ship in
                ship.count == (5 - i)
            }).count != i {
                UIAlertController.showAlert(title: "Увага!", message: "Невірні кораблі", on: self)
                return false
            }
        }
        
        return true
    }
    
    private func didSelectModel(at indexPath: IndexPath) -> CellModel.CellType {
        var model = self.cellModels[indexPath.section][indexPath.item]
        if model.type == .empty {
            model.type = .full(.default)
        } else {
            model.type = .empty
        }
        self.cellModels[indexPath.section][indexPath.item] = model
        return model.type
    }
    
    private func selectModel(at index: IndexPath) {
        let modelType = self.didSelectModel(at: index)
        var array = [IndexPath]()
        
        array += self.aslantLocking(at: index)
        
        if modelType == .full(.default) {
            self.lockedPoints += array
            self.mySelectPoints += [IndexPath.init(item: index.item, section: index.section)]
        } else {
            array.forEach { indexPath in
                if let lockedIndex = self.lockedPoints.firstIndex(of: indexPath) {
                    self.lockedPoints.remove(at: lockedIndex)
                }
            }
            if let selectIndex = self.mySelectPoints.firstIndex(of: index) {
                self.mySelectPoints.remove(at: selectIndex)
            }
        }
        
        self.didLockedModels(at: array)
    }
    
    private func aslantLocking(at index: IndexPath) -> [IndexPath] {
        var array = [IndexPath]()
        
        switch index.section {
        case 0:
            switch index.item {
            case 0:
                array += [index.nextItemAndSection]
            case 1...8:
                array += [index.previousItemNextSection, index.nextItemAndSection]
            case 9:
                array += [index.previousItemNextSection]
                
            default:
                return array
            }
        case 1...8:
            switch index.item {
            case 0:
                array += [index.nextItemPreviousSection, index.nextItemAndSection]
            case 1...8:
                array += index.aslantElements
            case 9:
                array += [index.previousItemAndSection, index.previousItemNextSection]
            default:
                return array
            }
        case 9:
            switch index.item {
            case 0:
                array += [index.nextItemPreviousSection]
            case 1...8:
                array += [index.previousItemAndSection, index.nextItemPreviousSection]
            case 9:
                array += [index.previousItemAndSection]
            default:
                return array
            }
        default:
            return array
        }
        return array
    }
    
    private func didLockedModels(at indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            var model = self.cellModels[indexPath.section][indexPath.item]
            if self.lockedPoints.contains(indexPath) {
                model.type = .miss
            } else {
                model.type = .empty
            }
            self.cellModels[indexPath.section][indexPath.item] = model
        }
        
    }
    
    private func convertToIndexPathModels(ships: [[IndexPath]]) -> [[IndexPathModel]] {
        return ships.compactMap { array in
            array.compactMap { indexPath in
                IndexPathModel(indexPath: indexPath)
            }
        }
    }
    
    private func convertToIndexPath(ships: [[IndexPathModel]]) -> [[IndexPath]] {
        return ships.compactMap { array in
            array.compactMap { indexPathModel in
                IndexPath(item: indexPathModel.item, section: indexPathModel.section)
            }
        }
    }
    
    private func playOfflineGame(myShips: [[IndexPath]]) {
        let enemyShips = self.shipsBuilder.createShips()
        let controller = GameViewController(myShips: myShips, enemyShips: enemyShips, currentUser: self.currentUser,
                                            isMyTurn: true, gameRoomRef: nil)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func playOnlineGame(myShips: [[IndexPath]]) {
        let existsWaitingRooms = self.gameRooms.queryOrdered(byChild: "isWaitingRoom").queryEqual(toValue: true)
        
        existsWaitingRooms.observeSingleEvent(of: .value) { [weak self] snapshot in
            self?.joinToGame(with: snapshot, myShips: myShips)
        }
    }
    
    private func joinToGame(with snapshot: DataSnapshot, myShips: [[IndexPath]]) {
        self.rootView?.waitGameView.isHidden = false
        if snapshot.exists(), let games = snapshot.value as? [String: Any] {
            if let (gameRef, gameModel) = self.joinGameSession(existsGames: games, userShips: myShips) {
                self.rootView?.waitGameView.isHidden = true
                self.goToGameViewController(gameRoomRef: gameRef, gameModel: gameModel, userShips: myShips, userTurn: false)
            }
        } else {
            let gameID = self.createGameSession(userShips: myShips)
            let gameRef = self.gameRooms.child(gameID)
            self.gameID = gameID
            
            self.observer = gameRef.observe(.value, with: { [weak self] snapshot in
                if let game: GameModel = (snapshot.value as? [String : Any])?.toModel(), !game.isWaitingRoom {
                    if let handler = self?.observer {
                        gameRef.removeObserver(withHandle: handler)
                    }
                    self?.rootView?.waitGameView.isHidden = true
                    self?.goToGameViewController(gameRoomRef: gameRef, gameModel: game, userShips: myShips, userTurn: true)
                }
            })
        }
    }
    
    private func joinGameSession(existsGames: [String : Any], userShips: [[IndexPath]]) -> (DatabaseReference, GameModel)? {
        let ships = self.convertToIndexPathModels(ships: userShips)
        
        if let game: GameModel = (existsGames.first?.value as? [String : Any])?.toModel() {
            let gameID = existsGames.first!.key as String
            let gameRef = self.gameRooms.child(gameID)
            let newGame = game.modify(with: PlayerModel(id: self.currentUser.uid, ships: ships))
            if let dictionary = newGame.dictionary {
                gameRef.updateChildValues(dictionary)
            }
            return (gameRef, newGame)
        }
        return nil
    }
    
    private func createGameSession(userShips: [[IndexPath]]) -> String {
        let ships = self.convertToIndexPathModels(ships: userShips)
        let gameID = UUID().uuidString
        let player: PlayerModel = PlayerModel(id: self.currentUser.uid, ships: ships)
        let game = GameModel(isWaitingRoom: true, players: [player], lastMove: nil)
        if let dictionary = game.dictionary {
            self.gameRooms.child(gameID).updateChildValues(dictionary)
        }
        return gameID
    }
    
    private func goToGameViewController(gameRoomRef: DatabaseReference, gameModel: GameModel,
                                        userShips: [[IndexPath]], userTurn: Bool) {
        let enemyShips = gameModel.players
            .first { model in
                return model.id != self.currentUser.uid
            }
            .flatMap { model in
                return self.convertToIndexPath(ships: model.ships)
            } ?? [[]]
        
        let controller = GameViewController(myShips: userShips, enemyShips: enemyShips, currentUser: self.currentUser,
                                            isMyTurn: userTurn, gameRoomRef: gameRoomRef)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
