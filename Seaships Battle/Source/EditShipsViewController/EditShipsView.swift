//
//  EditShipsView.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 11.12.2023.
//

import UIKit

class EditShipsView: UIView {

    @IBOutlet var clearButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var backButton: UIButton!
    
    @IBOutlet var polygonView: UIView!
    @IBOutlet var stackView: UIStackView!

    private var action: ((CellModel) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.polygonView.layer.borderWidth = 1
        self.polygonView.layer.borderColor = UIColor(named: "AppBlack")?.cgColor
        self.clearButton?.layer.cornerRadius = 10
        self.playButton?.layer.cornerRadius = 15
    }
    
    public func fill(with models: [[CellModel]], action: @escaping (CellModel) -> Void) {
        self.stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        self.action = action
        self.generateHorizontalStacks(with: models)
        
    }
    
    private func generateHorizontalStacks(with models: [[CellModel]]) {
        models.forEach { section in
            let stack = UIStackView(arrangedSubviews: self.generateCells(with: section))
            stack.spacing = 1
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            self.stackView.addArrangedSubview(stack)
        }
    }
    
    private func generateCells(with section: [CellModel]) -> [PolygonCell] {
        return section.compactMap { item in
            let cell = PolygonCell.initFromNib()
            cell.fill(with: item, action: { [weak self] model in
                self?.action?(model)
            })
            
            return cell
        }
    }

}
