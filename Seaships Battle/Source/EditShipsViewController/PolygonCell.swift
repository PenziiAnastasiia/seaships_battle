//
//  PolygonCell.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 11.12.2023.
//

import UIKit

class PolygonCell: UIView {
    
    @IBOutlet var button: UIButton?
    
    private var model: CellModel?
    private var action: ((CellModel) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.congigure()
    }

    public func fill(with model: CellModel, action: @escaping (CellModel) -> Void) {
        self.model = model
        self.changeColor(with: model.type)
        self.action = action
    }
    
    private func congigure() {
         self.model = nil
         self.changeColor(with: .empty)
     }
    
    private func changeColor(with type: CellModel.CellType) {
        switch type {
        case .empty:
            self.backgroundColor = UIColor.systemBackground
        case .miss:
            self.backgroundColor = UIColor(named: "AppGray")
        case .full(let deckType):
            switch deckType {
            case .default:
                self.backgroundColor = UIColor(named: "AppBlue")
            case .damaged:
                self.backgroundColor = UIColor(named: "AppPink")
            case .destroyed:
                self.backgroundColor = UIColor(named: "AppRed")
            }
        }
    }
    
    @IBAction func touch(sender: UIButton) {
        if let model = self.model {
            self.action?(model)
        }
    }

}

extension UIView {
    class func initFromNib() -> Self {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?[0] as! Self
    }
}
