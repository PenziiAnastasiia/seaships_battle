//
//  Codable+Extension.swift
//  Seaships Battle
//
//  Created by Анастасія Пензій on 01.09.2024.
//

import Foundation

extension Encodable {
    var dictionary: [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            return dict as? [String: Any]
        } catch {
            debugPrint(error)
            
            return nil
        }
    }
}

extension Dictionary {
    func toModel<T: Decodable>() -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self)
            let model = try JSONDecoder().decode(T.self, from: data)
            
            return model
        } catch {
            debugPrint(error)
            
            return nil
        }
    }
}
