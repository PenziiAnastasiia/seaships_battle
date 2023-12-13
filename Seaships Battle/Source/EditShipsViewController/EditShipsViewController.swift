//
//  EditShipsViewController.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 10.12.2023.
//

import UIKit

class EditShipsViewController: UIViewController {
    
    var rootView: EditShipsView? {
        self.viewIfLoaded as? EditShipsView
    }
    
    private let shipsBuilder = ShipsBuilder()
    
    private var cellModels: [[CellModel]] = []
    private var lockedPoints: [IndexPath] = []
    private var mySelectPoints: [IndexPath] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.generateItems()
        self.fillView()
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
            let enemyShips = self.shipsBuilder.createShips()
            let controller = GameViewController(myShips: myShips, enemyShips: enemyShips)
            self.navigationController?.pushViewController(controller, animated: true)
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
    
    //MARK:
    //MARK: - NSCollectionViewDataSource
    
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return self.cellModels.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.cellModels[section].count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let model = self.cellModels[indexPath.section][indexPath.item]
//        let item = collectionView.dequeueReusableCell(withReuseIdentifier: "PolygonCell", for: indexPath) as! PolygonCell
//        item.fill(with: model)
//        
//        return item
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if !self.lockedPoints.contains(where: { $0.section == indexPath.section && $0.item == indexPath.item }) {
//            self.selectModel(at: indexPath)
//            collectionView.reloadData()
//        }
//    }
    
    
    
}
