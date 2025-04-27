// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class SVGKit {
    private let parser: SVGParser
    
    public init() {
        self.parser = SVGParser()
    }
    
//    public func parse(data: Data) throws -> SVGDocument {
//        return try parser.parse(data: data)
//    }
    
//    public func parse(string: String) throws -> SVGDocument {
//        guard let data = string.data(using: .utf8) else {
//            throw NSError(domain: "SVGKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
//        }
//        return try parse(data: data)
//    }
    
//    public func parse(fileURL: URL) throws -> SVGDocument {
//        let data = try Data(contentsOf: fileURL)
//        return try parse(data: data)
//    }
}

// Example usage:
/*
let svgString = """
<svg width="100" height="100" viewBox="0 0 100 100">
    <rect x="10" y="10" width="80" height="80" fill="blue"/>
    <circle cx="50" cy="50" r="30" fill="red"/>
    <path d="M10 10 L90 90" stroke="green" stroke-width="2"/>
</svg>
"""

do {
    let svgKit = SVGKit()
    let document = try svgKit.parse(string: svgString)
    
    // Access the parsed elements
    for element in document.elements {
        switch element {
        case let rect as SVGRect:
            print("Found rectangle at (\(rect.x), \(rect.y)) with size \(rect.width)x\(rect.height)")
        case let circle as SVGCircle:
            print("Found circle at (\(circle.cx), \(circle.cy)) with radius \(circle.r)")
        case let path as SVGPath:
            print("Found path with \(path.pathData.segments.count) segments")
            // Example of accessing path segments
            for (index, segment) in path.pathData.segments.enumerated() {
                switch segment {
                case .moveTo(let point, let isRelative):
                    print("  Segment \(index): Move to (\(point.x), \(point.y)), relative: \(isRelative)")
                case .lineTo(let point, let isRelative):
                    print("  Segment \(index): Line to (\(point.x), \(point.y)), relative: \(isRelative)")
                case .closePath:
                    print("  Segment \(index): Close path")
                default:
                    print("  Segment \(index): Other command")
                }
            }
        default:
            break
        }
    }
} catch {
    print("Error parsing SVG: \(error)")
}
*/
