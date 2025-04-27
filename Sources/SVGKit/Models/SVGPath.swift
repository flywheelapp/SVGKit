import Foundation

/// Represents a segment in an SVG path
public enum SVGPathSegment: Equatable, CustomStringConvertible {
    case moveTo(point: CGPoint)
    case lineTo(point: CGPoint)
    case cubicCurveTo(control1: CGPoint, control2: CGPoint, end: CGPoint)
    case quadraticCurveTo(control: CGPoint, end: CGPoint)
    case arcTo(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, end: CGPoint)
    case closePath
    
    public var description: String {
        switch self {
        case .moveTo(point: let point):
            return "M \(point.x) \(point.y)"
        case .lineTo(point: let point):
            return "L \(point.x) \(point.y)"
        case .cubicCurveTo(control1: let control1, control2: let control2, end: let end):
            return "C \(control1.x) \(control1.y), \(control2.x) \(control2.y), \(end.x) \(end.y)"
        case .quadraticCurveTo(control: let control, end: let end):
            return "Q \(control.x) \(control.y), \(end.x) \(end.y)"
        case .arcTo(rx: let rx, ry: let ry, xAxisRotation: let r, largeArcFlag: let largeArc, sweepFlag: let sweep, end: let end):
            let isLargeArc = largeArc ? 1 : 0
            let isSweep = sweep ? 1 : 0
            return "A \(rx) \(ry) \(r) \(isLargeArc) \(isSweep) \(end.x) \(end.y)"
        case .closePath:
            return "Z"
        }
    }
    
    var endMarkerAnchor: (CGPoint, CGPoint?)? {
        switch self {
        case .moveTo(let point):
            return (point, nil)
        case .lineTo(let point):
            return (point, nil)
        case .cubicCurveTo(let control1, let control2, let end):
            return (end, control2)
        case .quadraticCurveTo(let control, let end):
            return (end, control)
        case .arcTo(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let end):
            return (end, nil)
        case .closePath:
            return nil
        }
    }
    
    var startMarkerAnchor: (CGPoint?, CGPoint?)? {
        switch self {
        case .moveTo(let point):
            return (point, nil)
        case .lineTo(let point):
            return (point, nil)
        case .cubicCurveTo(let control1, let control2, let end):
            return (nil, control1)
        case .quadraticCurveTo(let control, let end):
            return (nil, control)
        case .arcTo(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let end):
            return (nil, nil)
        case .closePath:
            return nil
        }
    }
    
    func applyTransform(_ transform: SVGTransform) -> SVGPathSegment {
        switch self {
        case .moveTo(point: let point):
            return .moveTo(point: transform.apply(to: point))
        case .lineTo(point: let point):
            return .lineTo(point: transform.apply(to: point))
        case .cubicCurveTo(control1: let control1, control2: let control2, end: let end):
            return .cubicCurveTo(
                control1: transform.apply(to: control1),
                control2: transform.apply(to: control2),
                end: transform.apply(to: end)
            )
        case .quadraticCurveTo(control: let control, end: let end):
            return .quadraticCurveTo(
                control: transform.apply(to: control),
                end: transform.apply(to: end)
            )
        case .arcTo(rx: let rx, ry: let ry, xAxisRotation: let r, largeArcFlag: let largeArc, sweepFlag: let sweep, end: let end):
            var size = CGSize(width: rx, height: ry)
            size = transform.applyScale(to: size)
            
            return .arcTo(
                rx: size.width,
                ry: size.height,
                xAxisRotation: r,
                largeArcFlag: largeArc,
                sweepFlag: sweep,
                end: transform.apply(to: end)
            )
        case .closePath:
            return self
        }
    }
}

/// Represents the data of an SVG path
public struct SVGPath: MarkerAnchorProvider {
    public private(set) var segments: [SVGPathSegment]
    
    public init(segments: [SVGPathSegment] = []) {
        self.segments = segments
    }
    
    var endMarkerAnchor: (CGPoint, CGPoint)? {
        var end: CGPoint?
        var prev: CGPoint?
        
        var items = segments
        if let (point, orient) = items.last?.endMarkerAnchor {
            end = point
            prev = orient
        }
        
        if end == nil {
            items = items.dropLast()
            guard let (point, orient) = items.last?.endMarkerAnchor else { return nil }
            end = point
            prev = orient
        }
        
        if prev == nil {
            items = items.dropLast()
            guard let (point, _) = items.last?.endMarkerAnchor else { return nil }
            prev = point
        }
        
        if let end {
            return (end, prev ?? end)
        }
        
        return nil
    }
    
    var startMarkerAnchor: (CGPoint, CGPoint)? {
        var start: CGPoint?
        var next: CGPoint?
        
        var items = segments
        if let (point, orient) = items.first?.startMarkerAnchor {
            start = point
            next = orient
        }
        
        if start == nil {
            return nil
        }
        
        if next == nil {
            guard let (point, orient) = items.dropFirst().first?.startMarkerAnchor else { return nil }
            next = point ?? orient
        }
        
        if let start, let next {
            return (start, next)
        }
        
        return nil
    }

    
    public mutating func moveTo(point: CGPoint) {
        segments.append(.moveTo(point: point))
    }
    
    public mutating func lineTo(point: CGPoint) {
        segments.append(.lineTo(point: point))
    }
    
    public mutating func cubicCurveTo(control1: CGPoint, control2: CGPoint, end: CGPoint) {
        segments.append(.cubicCurveTo(control1: control1, control2: control2, end: end))
    }
    
    public mutating func quadraticCurveTo(control: CGPoint, end: CGPoint) {
        segments.append(.quadraticCurveTo(control: control, end: end))
    }
    
    public mutating func arcTo(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, end: CGPoint) {
        segments.append(.arcTo(rx: rx, ry: ry, xAxisRotation: xAxisRotation, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, end: end))
    }
    
    public mutating func closePath() {
        segments.append(.closePath)
    }
}

/// Represents an SVG path element
public struct SVGPathElement {
    public var path: SVGPath
    public var markerElements: [SVGElement] = []
    
    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        var value = self
        for transform in transforms.reversed() {
            value.path = SVGPath(segments: value.path.segments.map({ $0.applyTransform(transform) }))
        }
        
        value.markerElements = SVGMarker.handlerMarker(
            info: info, doc: doc, transforms: transforms, anchorProvider: value.path)
        
        return .init(info: info, element: .path(value))
    }
}
