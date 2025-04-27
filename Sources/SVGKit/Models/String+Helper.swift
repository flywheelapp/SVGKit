//
//  String+Helper.swift
//  SVGKit
//
//  Created by maralla on 2025/4/12.
//


extension String {
    func parseNumberArray(_ splitter: Character) -> [Double]? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }
        
        var ret: [Double] = []
        for part in trimmed.split(separator: splitter) {
            let part = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if part.isEmpty {
                continue
            }
            
            if let value = Double(part) {
                ret.append(value)
            } else {
                return nil
            }
        }
        
        return ret
    }
}
