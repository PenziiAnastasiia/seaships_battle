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
    
    @IBOutlet var timerView: UIView!
    @IBOutlet var timerLabel: UILabel!
    
    private var timer: Timer?
    private var seconds = 60
    
    private var isOnlineGame = false
    private var timerComplete: ((Polygon) -> ())?

    private var action: ((CellModel) -> Void)?
    private var stack: Polygon = .my
    
    public func configure(isOnlineGame: Bool, timerHandler: @escaping (Polygon) -> ()) -> (Bool) -> Void {
        self.isOnlineGame = isOnlineGame
        self.timerComplete = timerHandler

        [self.myPolygonView, self.enemyPolygonView].forEach { view in
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.appBlack.cgColor
        }
        
        return self.myTurn(value:)
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
    
    //MARK:
    //MARK: - Private
    
    private func myTurn(value: Bool) {
        self.enemyStackView.isUserInteractionEnabled = value
        self.stopTimer()
        if self.isOnlineGame { self.startTimer(isMyTurn: value) }
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
    
    private func startTimer(isMyTurn: Bool) {
        self.seconds = isMyTurn ? 60 : 65
        let timeInterval = isMyTurn ? 1.0 : Double(self.seconds)
        self.timerView.isHidden = !isMyTurn
        
        self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: isMyTurn, block: { [weak self] _ in
            isMyTurn ? self?.updateLabel() : self?.timerComplete?(.enemy)
        })
    }
    
    private func updateLabel() {
        self.seconds -= 1
        let secondsRemaining = self.seconds % 60
        self.timerLabel.text = String(format: "%02d:%02d", self.seconds / 60, secondsRemaining)
        self.timerLabel.textColor = secondsRemaining > 5 ? .black: .red
        
        if self.seconds == 0 {
            self.stopTimer()
            self.timerComplete?(.my)
        }
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
        self.timerView.isHidden = true
        self.timerLabel.text = "01:00"
    }
}
