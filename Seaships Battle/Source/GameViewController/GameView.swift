//
//  GameView.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 13.12.2023.
//

import UIKit

enum Polygon {
    case my
    case enemy
}

class GameView: UIView {

    @IBOutlet var myPolygonView: UIView!
    @IBOutlet var myStackView: UIStackView!
    
    @IBOutlet var enemyPolygonView: UIView!
    @IBOutlet var enemyStackView: UIStackView!

    private var action: ((CellModel) -> Void)?
    private var stack: Polygon = .my
    
    public func configure() -> (Bool) -> Void {
        [self.myPolygonView, self.enemyPolygonView].forEach { view in
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor(named: "AppBlack")?.cgColor
        }
        
        return { [weak self] value in
            self?.enemyStackView.isUserInteractionEnabled = value
        }
    }
    
    public func fill(stack: Polygon, models: [[CellModel]], action: ((CellModel) -> Void)? = nil) {
        self.stack = stack
        switch stack {
        case .my:
            self.fill(stack: self.myStackView, with: models)
        case .enemy:
            self.action = action
            self.fill(stack: self.enemyStackView, with: models)
        }
    }
    
    private func fill(stack: UIStackView, with models: [[CellModel]]) {
        stack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        self.generateHorizontalStacks(stackView: stack, with: models)
        
    }
    
    private func generateHorizontalStacks(stackView: UIStackView, with models: [[CellModel]]) {
        models.forEach { section in
            let stack = UIStackView(arrangedSubviews: self.generateCells(with: section))
            stack.spacing = 1
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stackView.addArrangedSubview(stack)
        }
    }
    
    private func generateCells(with section: [CellModel]) -> [PolygonCell] {
        return section.compactMap { item in
            let cell = PolygonCell.initFromNib()
            switch self.stack {
            case .my:
                cell.fill(with: item, action: { _ in })
            case .enemy:
                cell.fill(with: item, action: { [weak self] model in
                    self?.action?(model)
                })
            }
            
            return cell
        }
    }
}
