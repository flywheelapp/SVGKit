import AppKit
import CoreGraphics
import Foundation

public struct ElementInfo {
    static let attributes = [
        "fill", "fill-opacity", "fill-rule",
        "stroke", "stroke-width", "stroke-linecap",
        "stroke-linejoin", "stroke-miterlimit", "stroke-dasharray",
        "stroke-dashoffset", "stroke-opacity",
        "opacity", "color", "font-family",
        "font-size", "font-style", "font-weight", "text-anchor",
        "visibility", "display", "dominant-baseline",
    ]

    public var tag: String
    public var id: String?
    public var className: String?
    public var style: [String: String] = [:]
    public var properties: [String: String] = [:]
    public var transform: SVGTransform?
    public var secondaryStyle: StyleAttributes = .init()
    public var rotation: Double?
    public var dyFunc: ((Double) -> (Double))? = nil
    public let uuid = UUID()

    private func sanitizeValue(value: String) -> String {
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let important = "!important"

        if value.hasSuffix(important) {
            let dropped = value.dropLast(important.count).trimmingCharacters(in: .whitespacesAndNewlines)
            value = String(dropped)
        }

        return value
    }

    public func sizePropertyValue(_ name: String, in document: SVGElement, baseSize: Double) -> Double? {
        guard var value = property(name, in: document) else { return nil }

        if value.hasSuffix("em") {
            guard let v = Double(value.dropLast(2)) else { return nil }
            return v * baseSize
        }

        return Double(value)
    }

    public func property(_ name: String, in document: SVGElement) -> String? {
        if let value = properties[name] {
            return sanitizeValue(value: value)
        }

        var styleMap = StyleAttributes()
        if case .svg(let svgDocument) = document.element, let map = svgDocument.styleMap[uuid] {
            styleMap = map
        }

        if let value = styleMap.specific[name] {
            return sanitizeValue(value: value)
        }

        if let value = styleMap.inherited[name] {
            return sanitizeValue(value: value)
        }

        return nil
    }

    public func strokeWidth(in document: SVGElement) -> Double? {
        guard var strokeWidth = style("stroke-width", in: document) else { return nil }
        if strokeWidth.hasSuffix("px") {
            return Double(strokeWidth.dropLast(2))
        }

        return Double(strokeWidth)
    }

    public func maxWidth(in document: SVGElement) -> Double? {
        guard var width = style("max-width", in: document) else { return nil }

        if width.hasSuffix("px") {
            return Double(width.dropLast(2))
        }

        return Double(width)
    }

    public func style(_ name: String, in document: SVGElement) -> String? {
        if let value = style[name] {
            return sanitizeValue(value: value)
        }

        var styleMap = StyleAttributes()
        if case .svg(let svgDocument) = document.element, let map = svgDocument.styleMap[uuid] {
            styleMap = map
        }

        if let value = styleMap.specific[name] {
            return sanitizeValue(value: value)
        }

        if let value = secondaryStyle.specific[name] {
            return sanitizeValue(value: value)
        }

        if let value = properties[name] {
            return sanitizeValue(value: value)
        }

        if let value = styleMap.inherited[name] {
            return sanitizeValue(value: value)
        }

        if let value = secondaryStyle.inherited[name] {
            return sanitizeValue(value: value)
        }

        return nil
    }

    public func strokeDashArray(in document: SVGElement) -> [NSNumber]? {
        guard
            let strokeDasharray = style("stroke-dasharray", in: document),
            !strokeDasharray.isEmpty
        else { return nil }

        var array = strokeDasharray.parseNumberArray(" ")
        if array == nil {
            array = strokeDasharray.parseNumberArray(",")
        }

        guard
            let array,
            !array.isEmpty,
            array.reduce(0, { $0 + $1 }) != 0
        else { return nil }

        return array.map { NSNumber(floatLiteral: $0) }
    }

    var classes: [String] {
        guard let className else { return [] }
        return className.components(separatedBy: .whitespaces)
    }

    func match(_ component: CSSSelectorComponent) -> Bool {
        let selector = component.selector
        if let id = selector.id, id != self.id {
            return false
        }

        if !selector.classes.isEmpty, !Set(classes).isSuperset(of: selector.classes) {
            return false
        }

        if let tag = selector.tag, tag != self.tag {
            return false
        }

        return true
    }

    mutating func mergeInfo(from info: ElementInfo) {
        var properties = info.properties
        var style = info.style

        for (k, v) in self.properties {
            properties[k] = v
        }

        for (k, v) in self.style {
            style[k] = v
        }

        self.properties = properties
        self.style = style
    }
}

public struct SVGElement {
    public enum Element {
        case svg(SVGDocument)
        case rect(SVGRect)
        case circle(SVGCircle)
        case group(SVGGroup)
        case line(SVGLine)
        case text(SVGText)
        case polygon(SVGPolygon)
        case ellipse(SVGEllipse)
        case polyline(SVGPolyline)
        case path(SVGPathElement)
        case foreignobject(SVGForeignObject)
        case marker(SVGMarker)
        case gradient(SVGGradient)
        case switchElement(SVGSwitch)
        case unknown(SVGUnknownElement)

        public var description: String {
            switch self {
            case .svg(let document):
                return "\(document)"
            case .rect(let sVGRect):
                return "\(sVGRect)"
            case .circle(let sVGCircle):
                return "\(sVGCircle)"
            case .group(let sVGGroup):
                return "\(sVGGroup)"
            case .line(let sVGLine):
                return "\(sVGLine)"
            case .text(let sVGText):
                return "\(sVGText)"
            case .polygon(let sVGPolygon):
                return "\(sVGPolygon)"
            case .ellipse(let sVGEllipse):
                return "\(sVGEllipse)"
            case .polyline(let sVGPolyline):
                return "\(sVGPolyline)"
            case .path(let sVGPathElement):
                return "\(sVGPathElement)"
            case .foreignobject(let value):
                return "\(value)"
            case .marker(let value):
                return "\(value)"
            case .gradient(let value):
                return "\(value)"
            case .switchElement(let element):
                return "\(element)"
            case .unknown(let element):
                return "\(element)"
            }
        }
    }

    public var info: ElementInfo
    public var element: Element

    public init(info: ElementInfo, element: Element) {
        self.info = info
        self.element = element
    }

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        switch element {
        case .svg(let document):
            return document.applyTransform(transform, doc: doc, info: info)
        case .rect(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .circle(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .group(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .line(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .text(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .polygon(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .ellipse(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .polyline(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .path(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .foreignobject(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .marker(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .gradient(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .switchElement(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        case .unknown(let value):
            return value.applyTransform(transform, doc: doc, info: info)
        }
    }

    var children: [SVGElement] {
        switch element {
        case .svg(let value):
            return value.elements
        case .group(let value):
            return value.elements
        case .foreignobject(let value):
            return value.elements
        case .unknown(let value):
            return value.elements
        case .marker(let value):
            return value.elements
        case .text(let value):
            return value.elements
        case .switchElement(let value):
            return value.elements
        case .gradient(let value):
            return value.elements
        default:
            return []
        }
    }

    func marker(_ id: String) -> SVGMarker? {
        guard case .svg(let document) = element else { return nil }
        return document.markerMap[id]
    }

    public func gradient(_ id: String) -> SVGGradient? {
        guard case .svg(let document) = element else { return nil }
        return document.gradientMap[id]
    }

    func mergeStyleForMarker(to info: ElementInfo, from source: ElementInfo) -> ElementInfo {
        var target = info
        var style = source.style
        style.removeValue(forKey: "fill")
        var properties: [String: String] = [:]

        for (k, v) in source.properties {
            if ElementInfo.attributes.firstIndex(of: k) == nil {
                continue
            }

            properties[k] = v
        }

        for (k, v) in target.properties {
            properties[k] = v
        }

        target.properties = properties

        guard case .svg(let document) = element else { return target }
        let sourceStyle = document.styleMap[source.uuid] ?? .init()
        //        target.secondaryStyle = sourceStyle

        let targetStyle = document.styleMap[target.uuid] ?? .init()

        for (k, v) in targetStyle.specific {
            style[k] = v
        }

        for (k, v) in target.style {
            style[k] = v
        }

        target.style = style

        return target
    }
}

public struct SVGUnknownElement {
    public var tag: String
    public var text: String = ""
    public var elements: [SVGElement] = []

    func applyTransform(_ transforms: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var transforms = transforms
        if let t = info.transform {
            transforms.append(t)
        }

        var value = self
        let elements = value.elements.map({ $0.applyTransform(transforms, doc: doc, info: $0.info) })

        value.elements = elements
        return .init(info: info, element: .unknown(value))
    }
}

public struct SVGSwitch {
    public var elements: [SVGElement] = []
    func applyTransform(_ transforms: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var transforms = transforms
        if let t = info.transform {
            transforms.append(t)
        }

        var value = self
        let elements = value.elements.map({ $0.applyTransform(transforms, doc: doc, info: $0.info) })

        value.elements = elements
        return .init(info: info, element: .switchElement(value))
    }

    public func determine() -> SVGElement? {
        guard !elements.isEmpty else { return nil }

        for element in elements {
            if case .text = element.element {
                return element
            }
        }

        return elements.first
    }
}

public struct SVGGradient {
    public enum PositionValue {
        case percent(Double)
        case absolute(Double)
    }

    public struct Gradient {
        public var x1: PositionValue
        public var y1: PositionValue
        public var x2: PositionValue
        public var y2: PositionValue

        public var locations: [Double]
        public var colors: [String]
    }

    public var x1: String?
    public var x2: String?
    public var y1: String?
    public var y2: String?

    public var elements: [SVGElement] = []

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        return .init(info: info, element: .gradient(self))
    }

    public var gradient: Gradient? {
        var start: CGPoint = .zero

        guard
            let x1 = convertValue(x1),
            let y1 = convertValue(y1),
            let x2 = convertValue(x2),
            let y2 = convertValue(y2)
        else { return nil }
        var locations: [Double] = []
        var colors: [String] = []

        for element in elements {
            let info = element.info
            guard
                info.tag == "stop",
                case .percent(let offset) = convertValue(info.properties["offset"]),
                let color = info.properties["stop-color"]
            else { return nil }

            locations.append(offset)
            colors.append(color)
        }
        return .init(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            locations: locations,
            colors: colors
        )
    }

    private func convertValue(_ value: String?) -> PositionValue? {
        var ret: PositionValue

        if let value = value {
            if value.hasSuffix("%") {
                guard let value = Double(value.dropLast()) else { return nil }
                ret = .percent(value / 100)
            } else {
                guard let value = Double(value) else { return nil }
                ret = .absolute(value)
            }
        } else {
            ret = .absolute(0)
        }

        return ret
    }
}

protocol MarkerAnchorProvider {
    var endMarkerAnchor: (CGPoint, CGPoint)? { get }
    var startMarkerAnchor: (CGPoint, CGPoint)? { get }
}

public struct SVGMarker {
    public var markerUnits = "strokeWidth"
    public var markerHeight = 3.0
    public var markerWidth = 3.0
    public var orient = "0"
    public var refX = "0"
    public var refY = "0"
    public var viewBox: CGRect?
    public var elements: [SVGElement] = []

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        return .init(info: info, element: .marker(self))
    }

    static func handlerMarker(
        info: ElementInfo,
        doc: SVGElement,
        transforms: [SVGTransform],
        anchorProvider: MarkerAnchorProvider
    ) -> [SVGElement] {
        var markers: [SVGElement] = []

        if let markerEnd = info.style("marker-end", in: doc), let endMarker = doc.marker(markerEnd) {
            if let (point, orient) = anchorProvider.endMarkerAnchor {
                let refx = Double(endMarker.refX) ?? 0
                let refy = Double(endMarker.refY) ?? 0

                var size = CGSize(width: refx, height: refy)
                for transform in transforms {
                    size = transform.applyScale(to: size)
                }

                let translate = SVGTransform(transforms: [.translate(x: point.x - size.width, y: point.y - size.height)]
                )
                let trs = transforms.map({
                    var value = $0
                    value.transforms = value.transforms.map({ $0.scaleAndRotate })
                    return value
                })

                let dx = point.x - orient.x
                let dy = point.y - orient.y
                let rotation = atan2(dy, dx)
                let rotate = SVGTransform(transforms: [.rotate(degree: rotation, x: size.width, y: size.height)])

                let elements = endMarker.elements.map({
                    return $0.applyTransform(
                        [translate, rotate] + trs,
                        doc: doc,
                        info: doc.mergeStyleForMarker(to: $0.info, from: info)
                    )
                })
                markers = elements
            }
        }

        if let markerStart = info.style("marker-start", in: doc), let startMarker = doc.marker(markerStart) {
            if let (point, orient) = anchorProvider.startMarkerAnchor {
                let refx = Double(startMarker.refX) ?? 0
                let refy = Double(startMarker.refY) ?? 0

                var offset = point
                var size = CGSize(width: refx, height: refy)
                var markerSize = CGSize(width: startMarker.markerWidth, height: startMarker.markerHeight)
                for transform in transforms {
                    size = transform.applyScale(to: size)
                    markerSize = transform.applyScale(to: markerSize)
                }

                let translate = SVGTransform(transforms: [
                    .translate(x: offset.x - size.width, y: offset.y - size.height)
                ])
                let trs = transforms.map({
                    var value = $0
                    value.transforms = value.transforms.map({ $0.scaleAndRotate })
                    return value
                })

                let dx = orient.x - point.x
                let dy = orient.y - point.y
                let rotation = atan2(dy, dx)
                let rotate = SVGTransform(transforms: [.rotate(degree: rotation, x: size.width, y: size.height)])

                let elements = startMarker.elements.map({
                    $0.applyTransform(
                        [translate, rotate] + trs,
                        doc: doc,
                        info: doc.mergeStyleForMarker(to: $0.info, from: info)
                    )
                })

                markers.append(contentsOf: elements)
            }
        }

        return markers
    }
}

/// Represents an SVG transform
public struct SVGTransform {
    public enum Transform {
        case matrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
        case translate(x: Double, y: Double)
        case scale(x: Double, y: Double)
        case rotate(degree: Double, x: Double, y: Double)
        case skewX(Double)
        case skewY(Double)

        var cg: CGAffineTransform {
            switch self {
            case .matrix(a: let a, b: let b, c: let c, d: let d, e: let e, f: let f):
                return CGAffineTransform(a, b, c, d, e, f)
            case .translate(x: let x, y: let y):
                return CGAffineTransform(translationX: x, y: y)
            case .scale(x: let x, y: let y):
                return CGAffineTransform(scaleX: x, y: y)
            case .rotate(degree: let degree, x: let x, y: let y):
                return SVGTransform.rotateAround(degree: degree, x: x, y: y)
            case .skewX(let x):
                let angle = x * (.pi / 180)
                let skewX = tan(angle)
                return CGAffineTransform(a: 1, b: 0, c: skewX, d: 1, tx: 0, ty: 0)
            case .skewY(let x):
                let angle = x * (.pi / 180)
                let skewY = tan(angle)
                return CGAffineTransform(a: 1, b: skewY, c: 0, d: 1, tx: 0, ty: 0)
            }
        }

        var scaleAndRotate: Transform {
            switch self {
            case .matrix(a: let a, b: let b, c: let c, d: let d, e: let e, f: let f):
                return .matrix(a: a, b: b, c: c, d: d, e: 0, f: 0)
            case .translate(x: let x, y: let y):
                return .translate(x: 0, y: 0)
            case .scale, .rotate, .skewX, .skewY:
                return self
            }
        }

        var rotation: Double {
            switch self {
            case .matrix(a: let a, b: let b, _, _, _, _):
                return atan2(b, a)
            case .rotate(degree: let degree, _, _):
                return degree
            default:
                return 0
            }
        }
    }

    public var transforms: [Transform]

    public init(transforms: [Transform]) {
        self.transforms = transforms
    }

    static func rotateAround(degree: Double, x: Double, y: Double) -> CGAffineTransform {
        return CGAffineTransform.identity
            .translatedBy(x: x, y: y)
            .rotated(by: degree)
            .translatedBy(x: -x, y: -y)
    }

    var rotation: Double {
        transforms.reduce(0.0, { $0 + $1.rotation })
    }

    func applyRotateAndTranslation(to point: CGPoint) -> CGPoint {
        var point = point
        for transform in transforms.reversed() {
            var tr: CGAffineTransform
            switch transform {
            case .matrix(a: let a, b: let b, c: let c, d: let d, e: let e, f: let f):
                tr = CGAffineTransform(a, b, c, d, e, f)
                let scaleX = sqrt(a * a + c * c)
                let scaleY = sqrt(b * b + d * d)

                // Avoid division by zero
                if scaleX != 0, scaleY != 0 {
                    tr = CGAffineTransform(
                        a: a / scaleX,
                        b: b / scaleY,
                        c: c / scaleX,
                        d: d / scaleY,
                        tx: e,
                        ty: f
                    )
                }
            case .translate(x: let x, y: let y):
                tr = CGAffineTransform(translationX: x, y: y)
            case .scale(x: let x, y: let y):
                tr = .identity
            //                tr = CGAffineTransform(scaleX: x, y: y)
            case .rotate(degree: let degree, x: let x, y: let y):
                tr = SVGTransform.rotateAround(degree: degree, x: x, y: y)
            case .skewX(let x):
                let angle = x * (.pi / 180)
                let skewX = tan(angle)
                tr = CGAffineTransform(a: 1, b: 0, c: skewX, d: 1, tx: 0, ty: 0)
            case .skewY(let x):
                let angle = x * (.pi / 180)
                let skewY = tan(angle)
                tr = CGAffineTransform(a: 1, b: skewY, c: 0, d: 1, tx: 0, ty: 0)
            }
        }
        return point
    }

    func apply(to point: CGPoint) -> CGPoint {
        var point = point
        for transform in transforms.reversed() {
            point = point.applying(transform.cg)
        }
        return point
    }

    func applyScale(to size: CGSize) -> CGSize {
        var value = size
        for transform in transforms {
            switch transform {
            case .scale(let x, let y):
                value.width *= x
                value.height *= y
            case .matrix(a: let a, b: let b, c: let c, d: let d, _, _):
                let scaleX = sqrt(a * a + c * c)
                let scaleY = sqrt(b * b + d * d)
                value.width *= scaleX
                value.height *= scaleY
            default:
                break
            }
        }
        return value
    }

    func applyScale(value: Double) -> Double {
        var value = value
        for transform in transforms {
            switch transform {
            case .scale(let x, let y):
                value *= min(x, y)
            case .matrix(a: let a, b: let b, c: let c, d: let d, _, _):
                let scaleX = sqrt(a * a + c * c)
                let scaleY = sqrt(b * b + d * d)
                value *= min(scaleX, scaleY)
            default:
                break
            }
        }
        return value
    }

    var scale: (Double, Double) {
        var scaleX = 1.0
        var scaleY = 1.0

        for transform in transforms {
            switch transform {
            case .scale(let x, let y):
                scaleX *= x
                scaleY *= y
            case .matrix(a: let a, b: let b, c: let c, d: let d, _, _):
                scaleX *= sqrt(a * a + c * c)
                scaleY *= sqrt(b * b + d * d)
            default:
                break
            }
        }
        return (scaleX, scaleY)
    }
}

public struct SVGRect {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rx: Double?
    public var ry: Double?

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var info = info

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        var rx = rx
        var ry = ry
        var size = CGSize(width: width, height: height)
        var center = CGPoint(x: x + width / 2, y: y + height / 2)
        var rotation = info.rotation ?? 0
        for transform in transforms.reversed() {
            center = transform.apply(to: center)
            size = transform.applyScale(to: size)

            if let v = rx {
                rx = transform.applyScale(value: v)
            }

            if let v = ry {
                ry = transform.applyScale(value: v)
            }

            rotation += transform.rotation
        }

        value.rx = rx
        value.ry = ry
        value.x = center.x - size.width / 2
        value.y = center.y - size.height / 2
        value.height = size.height
        value.width = size.width
        info.rotation = rotation

        return .init(info: info, element: .rect(value))
    }
}

public struct SVGCircle: CustomStringConvertible {
    public var cx: Double
    public var cy: Double
    public var r: Double

    public var description: String {
        return "<circle \(cx) \(cy) \(r)>"
    }

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var info = info

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        var center = CGPoint(x: cx, y: cy)
        for transform in transforms.reversed() {
            center = transform.apply(to: center)
            value.r = transform.applyScale(value: value.r)
        }

        value.cx = center.x
        value.cy = center.y

        return .init(info: info, element: .circle(value))
    }
}

/// Represents an SVG line element - commonly used in Mermaid diagrams
public struct SVGLine: MarkerAnchorProvider {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double

    public var markerElements: [SVGElement] = []

    var startMarkerAnchor: (CGPoint, CGPoint)? {
        (CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y2))
    }

    var endMarkerAnchor: (CGPoint, CGPoint)? {
        (CGPoint(x: x2, y: y2), CGPoint(x: x1, y: y1))
    }

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var info = info

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        var point1 = CGPoint(x: x1, y: y1)
        var point2 = CGPoint(x: x2, y: y2)
        for transform in transforms.reversed() {
            point1 = transform.apply(to: point1)
            point2 = transform.apply(to: point2)
        }

        value.x1 = point1.x
        value.y1 = point1.y
        value.x2 = point2.x
        value.y2 = point2.y

        value.markerElements = SVGMarker.handlerMarker(
            info: info,
            doc: doc,
            transforms: transforms,
            anchorProvider: value
        )

        return .init(info: info, element: .line(value))
    }
}

public struct TextElement {
    public var info: ElementInfo
    public var start: CGPoint
    public var text: String
    public var fontSize: Double?
    public var fill: String?
    public var color: String?
    public var frameSize: CGSize = .zero
}

public struct SVGForeignObject {
    public var x: Double
    public var y: Double
    public var height: Double?
    public var width: Double?

    public var elements: [SVGElement] = []

    var transforms: [SVGTransform] = []

    public func textInfo(doc: SVGElement, foreignInfo: ElementInfo) -> TextElement? {
        var items = self.elements
        var info = ElementInfo(tag: "")
        var targetUnkown: SVGUnknownElement?
        while !items.isEmpty {
            var next: [SVGElement] = []
            for element in items {
                guard case .unknown(let object) = element.element else { continue }

                if object.text == "" {
                    next.append(contentsOf: object.elements)
                    continue
                }

                next = []
                targetUnkown = object
                info = element.info
                break
            }
            items = next
        }

        guard let element = targetUnkown else { return nil }
        let (point, rotation) = doTransform(info: foreignInfo)
        info.rotation = rotation
        let fontSize = scaleFontSize(doc: doc, info: foreignInfo)
        return .init(
            info: info,
            start: point,
            text: element.text,
            fontSize: fontSize,
            fill: info.style("background-color", in: doc),
            color: info.style("color", in: doc)
        )
    }

    private func doTransform(info: ElementInfo) -> (CGPoint, Double) {
        let height = self.height ?? 0
        let width = self.width ?? 0

        var size = CGSize(width: width, height: height)
        var center = CGPoint(x: x + width / 2, y: y + height / 2)

        var rotation = info.rotation ?? 0
        for transform in transforms.reversed() {
            center = transform.apply(to: center)
            size = transform.applyScale(to: size)

            rotation += transform.rotation
        }

        let point = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)

        return (point, rotation)
    }

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        value.transforms = transforms

        return .init(info: info, element: .foreignobject(value))
    }

    private func scaleFontSize(doc: SVGElement, info: ElementInfo) -> Double? {
        var fontSize: Double? = nil
        if let size = info.style("font-size", in: doc) {
            if size.hasSuffix("px"), let parsed = Double(size.dropLast(2)) {
                fontSize = parsed
            }

            if fontSize == nil {
                fontSize = Double(size)
            }
        }

        for transform in transforms.reversed() {
            if let size = fontSize {
                fontSize = transform.applyScale(value: size)
            }
        }

        return fontSize
    }
}

/// Represents an SVG text element - commonly used in Mermaid diagrams
public struct SVGText {
    private let defaultFontSize = 13.0

    public var x: String = ""
    public var y: String = ""
    public var content: String = ""
    public var transforms: [SVGTransform] = []
    public var fontSize: Double?
    public var dx: String?
    public var dy: String?
    public var start: CGPoint = .zero

    private var _textElement: TextElement? = nil

    public func textElement(document: SVGElement, info: ElementInfo) -> TextElement? {
        if let element = _textElement {
            return element
        }

        let fontSize = scaledFontSize(doc: document, info: info)
        let point = parseXY(x: info.properties["x"] ?? "", y: info.properties["y"] ?? "", fontSize: fontSize)
        return .init(info: info, start: point, text: content, fontSize: fontSize)
    }

    public var elements: [SVGElement] = []

    private func parseXY(x: String, y: String, fontSize: Double? = nil) -> CGPoint {
        let currentFontSize = fontSize ?? self.fontSize ?? defaultFontSize

        var xValue: Double
        if x.hasSuffix("em") {
            xValue = (Double(x.dropLast(2)) ?? 0) * currentFontSize
        } else {
            xValue = Double(x) ?? 0
        }

        var yValue: Double
        if y.hasSuffix("em") {
            yValue = (Double(y.dropLast(2)) ?? 0) * currentFontSize
        } else {
            yValue = Double(y) ?? 0
        }

        return CGPoint(x: xValue, y: yValue)
    }

    public func xxxx(
        element: SVGElement,
        in document: SVGElement,
        textInfo: ElementInfo,
        stack: inout [TextElement]
    ) -> [TextElement] {
        guard case .unknown(let value) = element.element else { return [] }

        let info = element.info

        var fontSize = self.fontSize
        if let value = scaledFontSize(doc: document, info: info) {
            fontSize = value
        }

        let x = info.properties["x"] ?? ""
        let y = info.property("y", in: document) ?? ""

        var isPushed = false
        let point = parseXY(x: x, y: y, fontSize: fontSize)
        if info.properties["x"] != nil || info.properties["y"] != nil {
            stack.append(.init(info: info, start: point, text: value.text, fontSize: fontSize))
            isPushed = true
        } else if var last = stack.last {
            var text = last.text
            if text.isEmpty {
                text = value.text
            } else {
                text += " " + value.text
            }
            last.text = text
            stack[stack.count - 1] = last
        }

        var childResult: [TextElement] = []
        for child in value.elements {
            childResult.append(contentsOf: xxxx(element: child, in: document, textInfo: child.info, stack: &stack))
        }

        if isPushed, let last = stack.popLast() {
            return [last] + childResult
        }

        return childResult
    }

    public func walkElements(in document: SVGElement, textInfo: ElementInfo) -> [SVGElement] {
        var elementStack: [TextElement] = []

        var result: [TextElement] = []
        for el in elements {
            result.append(contentsOf: xxxx(element: el, in: document, textInfo: el.info, stack: &elementStack))
        }

        var currentDy = { (base: Double) in 0.0 }
        return result.map({
            var info = $0.info
            let dy = info.property("dy", in: document)

            var base = currentDy
            if info.property("y", in: document) != nil {
                base = { (base: Double) in 0.0 }
            }

            currentDy = genDyFunc(baseFunc: base, v2: dy)
            info.dyFunc = currentDy

            let text = SVGText(transforms: transforms, _textElement: $0)
            return .init(info: info, element: .text(text))
        })
    }

    private func genDyFunc(baseFunc: @escaping (Double) -> (Double), v2: String?) -> (Double) -> (Double) {
        return { base in
            guard let v2 else { return baseFunc(base) }

            var value = 0.0
            if v2.hasSuffix("em") {
                guard let value2 = Double(v2.dropLast(2)) else { return baseFunc(base) }
                value = value2 * base
            } else {
                guard let value2 = Double(v2) else { return baseFunc(base) }
                value = value2
            }

            return baseFunc(base) + value
        }
    }

    public func transform(document: SVGElement, boundSize: CGSize, font: NSFont, text: TextElement) -> SVGElement {
        var value = self
        var info = text.info

        var textAnchor = info.style("text-anchor", in: document) ?? ""
        var dominantBaseline = info.style("dominant-baseline", in: document) ?? ""

        var start = text.start
        value.start = start

        var scaleX = 1.0
        var scaleY = 1.0

        for transform in transforms.reversed() {
            let (x, y) = transform.scale
            scaleX *= x
            scaleY *= y
        }

        switch textAnchor {
        case "start":
            break
        case "end":
            start.x -= boundSize.width / scaleX
        case "middle":
            start.x -= boundSize.width / scaleX / 2
        default:
            break
        }

        switch dominantBaseline {
        case "middle":
            let height = font.ascender + font.descender
            start.y = start.y + font.descender - (font.ascender + font.descender) / 2
        case "hanging":
            start.y = start.y + font.descender
        case "text-before-edge":
            start.y = start.y + font.descender + font.leading
        case "text-after-edge":
            start.y -= boundSize.height
        default:
            start.y -= font.ascender / scaleY
        }

        var boundSize = boundSize
        var center = CGPoint(x: start.x + boundSize.width / scaleX / 2, y: start.y + boundSize.height / scaleY / 2)
        var rotation = info.rotation ?? 0
        for transform in transforms.reversed() {
            center = transform.apply(to: center)
            rotation += transform.rotation
        }

        value.start = CGPoint(x: center.x - boundSize.width / 2, y: center.y - boundSize.height / 2)
        info.rotation = rotation

        return .init(info: info, element: .text(value))
    }

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        value.transforms = transforms

        return .init(info: info, element: .text(value))
    }

    public func scaleFontSize(doc: SVGElement, info: ElementInfo) -> SVGText {
        var value = self

        var fontSize: Double? = nil
        if let size = info.style("font-size", in: doc) {
            if size.hasSuffix("px"), let parsed = Double(size.dropLast(2)) {
                fontSize = parsed
            }

            if fontSize == nil {
                fontSize = Double(size)
            }
        }

        for transform in transforms.reversed() {
            if let size = fontSize {
                fontSize = transform.applyScale(value: size)
            }
        }

        if let fontSize {
            value.fontSize = fontSize
        }

        return value
    }

    private func scaledFontSize(doc: SVGElement, info: ElementInfo) -> Double? {
        var fontSize: Double? = nil
        if let size = info.style("font-size", in: doc) {
            if size.hasSuffix("px"), let parsed = Double(size.dropLast(2)) {
                fontSize = parsed
            }

            if fontSize == nil {
                fontSize = Double(size)
            }
        }

        for transform in transforms.reversed() {
            if let size = fontSize {
                fontSize = transform.applyScale(value: size)
            }
        }

        return fontSize
    }
}

/// Represents an SVG foreign object - used in Mermaid diagrams for text
//public class SVGForeignObject: BaseSVGElement {
//    public var x: CGFloat
//    public var y: CGFloat
//    public var width: CGFloat
//    public var height: CGFloat
//    public var content: String
//
//    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, content: String, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.x = x
//        self.y = y
//        self.width = width
//        self.height = height
//        self.content = content
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//}

/// Represents an SVG polygon element - used in Mermaid diagrams for certain shapes
public struct SVGPolygon {
    public var points: [CGPoint]

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        for transform in transforms.reversed() {
            value.points = value.points.map({ transform.apply(to: $0) })
        }

        return .init(info: info, element: .polygon(value))
    }
}

/// Represents an SVG group element
public struct SVGGroup {
    public var elements: [SVGElement]

    func applyTransform(_ transforms: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var transforms = transforms
        if let t = info.transform {
            transforms.append(t)
        }

        var value = self
        let elements = value.elements.map({ $0.applyTransform(transforms, doc: doc, info: $0.info) })

        value.elements = elements
        return .init(info: info, element: .group(value))
    }
}

public struct StyleAttributes {
    var inherited: [String: String] = [:]
    var specific: [String: String] = [:]
}

/// Represents an SVG document
public struct SVGDocument {
    public var width: Double?
    public var height: Double?
    public var viewBox: CGRect?
    public var elements: [SVGElement] = []
    public var styleRules: [String: [String: String]] = [:]
    public var styleMap: [UUID: StyleAttributes] = [:]
    public var markerMap: [String: SVGMarker] = [:]
    public var gradientMap: [String: SVGGradient] = [:]

    func applyTransform(_ transforms: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        let elements = value.elements.map({ $0.applyTransform(transforms, doc: doc, info: $0.info) })
        value.elements = elements
        return .init(info: info, element: .svg(value))
    }

    mutating func applyStyle(_ style: CSSStylesheet?, info: ElementInfo) -> SVGDocument {
        collectItems()

        guard let style else { return self }

        for rule in style.rules {
            matchRule(rule, info: info)
        }

        propagateProperties(info: info)

        return self
    }

    private mutating func collectItems() {
        var items = elements
        var next: [SVGElement] = []

        while !items.isEmpty {
            next = []
            for element in items {
                switch element.element {
                case .marker(let marker):
                    if let id = element.info.id {
                        markerMap["url(#\(id))"] = marker
                    }

                    continue
                case .gradient(let gradient):
                    if let id = element.info.id {
                        gradientMap["url(#\(id))"] = gradient
                    }
                    continue
                default:
                    break
                }

                next.append(contentsOf: element.children)
            }

            items = next
        }
    }

    private mutating func propagateProperties(info: ElementInfo) {
        distributeOneElement(element: .init(info: info, element: .svg(self)), info: info)
    }

    private mutating func distributeOneElement(element: SVGElement, info: ElementInfo) {
        let children = element.children
        guard !children.isEmpty else { return }

        let style = info.style
        let properties = info.properties

        for child in children {
            var styles = styleMap[child.info.uuid] ?? .init()
            for (k, v) in properties {
                styles.inherited[k] = v
            }
            for (k, v) in style {
                styles.inherited[k] = v
            }
            styleMap[child.info.uuid] = styles

            distributeOneElement(element: child, info: info)
            distributeOneElement(element: child, info: child.info)
        }
    }

    private mutating func matchRule(_ rule: CSSRule, info: ElementInfo) {
        let group = CSSSelectorGroup(rule.selector.value)

        var target: [SVGElement] = []
        var elements: [SVGElement] = [.init(info: info, element: .svg(self))]
        for component in group.components {
            if component.selector.tag == "tspan" {
                break
            }

            target = selectElements(component: component, in: elements)
            elements = target.flatMap({ $0.children })
        }

        applyRule(elements: target, rule: rule, level: 0)
    }

    private mutating func applyRule(elements: [SVGElement], rule: CSSRule, level: Int) {
        var level = level

        for element in elements {
            let uuid = element.info.uuid
            var map = styleMap[uuid] ?? .init()

            for (k, v) in rule.properties {
                if level == 0 {
                    map.specific[k] = v
                } else {
                    map.inherited[k] = v
                }
            }

            styleMap[uuid] = map

            applyRule(elements: element.children, rule: rule, level: level + 1)
        }
    }

    private func selectElements(component: CSSSelectorComponent, in elements: [SVGElement]) -> [SVGElement] {
        var ret: [SVGElement] = []

        for element in elements {
            let info = element.info

            if info.match(component) {
                ret.append(element)
                continue
            }

            ret.append(contentsOf: selectElements(component: component, in: element.children))
        }

        return ret
    }
}

/// Represents an SVG ellipse element
public struct SVGEllipse {
    public var info: ElementInfo?
    public var cx: CGFloat
    public var cy: CGFloat
    public var rx: CGFloat
    public var ry: CGFloat

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var info = info

        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        var center = CGPoint(x: cx, y: cy)
        var size = CGSize(width: rx, height: ry)
        var rotation = info.rotation ?? 0
        for transform in transforms.reversed() {
            center = transform.apply(to: center)
            size = transform.applyScale(to: size)
            rotation += transform.rotation
        }

        value.cx = center.x
        value.cy = center.y
        value.rx = size.width
        value.ry = size.height
        info.rotation = rotation
        return .init(info: info, element: .ellipse(value))
    }
}

/// Represents an SVG polyline element
public struct SVGPolyline {
    public var info: ElementInfo?
    public var points: [CGPoint]

    func applyTransform(_ transform: [SVGTransform], doc: SVGElement, info: ElementInfo) -> SVGElement {
        var value = self
        var transforms = transform
        if let t = info.transform {
            transforms.append(t)
        }

        for transform in transforms.reversed() {
            value.points = value.points.map({ transform.apply(to: $0) })
        }

        return .init(info: info, element: .polyline(value))
    }
}

/// A color stop in a gradient
public struct SVGGradientStop {
    public var offset: CGFloat
    public var color: String
    public var opacity: CGFloat?

    public init(offset: CGFloat, color: String, opacity: CGFloat? = nil) {
        self.offset = offset
        self.color = color
        self.opacity = opacity
    }
}

/// Base class for SVG gradient elements
//public class SVGGradient: BaseSVGElement {
//    public var stops: [SVGGradientStop]
//    public var gradientUnits: String?
//    public var spreadMethod: String?
//
//    public init(stops: [SVGGradientStop] = [], gradientUnits: String? = nil, spreadMethod: String? = nil, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.stops = stops
//        self.gradientUnits = gradientUnits
//        self.spreadMethod = spreadMethod
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//
//    public func addStop(offset: CGFloat, color: String, opacity: CGFloat? = nil) {
//        stops.append(SVGGradientStop(offset: offset, color: color, opacity: opacity))
//    }
//}

/// Represents an SVG linear gradient element
//public class SVGLinearGradient: SVGGradient {
//    public var x1: CGFloat?
//    public var y1: CGFloat?
//    public var x2: CGFloat?
//    public var y2: CGFloat?
//
//    public init(x1: CGFloat? = nil, y1: CGFloat? = nil, x2: CGFloat? = nil, y2: CGFloat? = nil, stops: [SVGGradientStop] = [], gradientUnits: String? = nil, spreadMethod: String? = nil, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.x1 = x1
//        self.y1 = y1
//        self.x2 = x2
//        self.y2 = y2
//        super.init(stops: stops, gradientUnits: gradientUnits, spreadMethod: spreadMethod, id: id, className: className, style: style, transform: transform)
//    }
//}

/// Represents an SVG radial gradient element
//public class SVGRadialGradient: SVGGradient {
//    public var cx: CGFloat?
//    public var cy: CGFloat?
//    public var r: CGFloat?
//    public var fx: CGFloat?
//    public var fy: CGFloat?
//    public var fr: CGFloat?
//
//    public init(cx: CGFloat? = nil, cy: CGFloat? = nil, r: CGFloat? = nil, fx: CGFloat? = nil, fy: CGFloat? = nil, fr: CGFloat? = nil, stops: [SVGGradientStop] = [], gradientUnits: String? = nil, spreadMethod: String? = nil, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.cx = cx
//        self.cy = cy
//        self.r = r
//        self.fx = fx
//        self.fy = fy
//        self.fr = fr
//        super.init(stops: stops, gradientUnits: gradientUnits, spreadMethod: spreadMethod, id: id, className: className, style: style, transform: transform)
//    }
//}

/// Represents an SVG pattern element
//public class SVGPattern: BaseSVGElement {
//    public var x: CGFloat?
//    public var y: CGFloat?
//    public var width: CGFloat?
//    public var height: CGFloat?
//    public var patternUnits: String?
//    public var patternContentUnits: String?
//    public var elements: [SVGElement]
//
//    public init(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil, patternUnits: String? = nil, patternContentUnits: String? = nil, elements: [SVGElement] = [], id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.x = x
//        self.y = y
//        self.width = width
//        self.height = height
//        self.patternUnits = patternUnits
//        self.patternContentUnits = patternContentUnits
//        self.elements = elements
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//
//    public func addElement(_ element: SVGElement) {
//        elements.append(element)
//    }
//}

/// Represents an SVG image element
//public class SVGImage: BaseSVGElement {
//    public var x: CGFloat
//    public var y: CGFloat
//    public var width: CGFloat
//    public var height: CGFloat
//    public var href: String
//
//    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, href: String, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.x = x
//        self.y = y
//        self.width = width
//        self.height = height
//        self.href = href
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//}

/// Represents an SVG symbol element
//public class SVGSymbol: BaseSVGElement {
//    public var viewBox: CGRect?
//    public var elements: [SVGElement]
//
//    public init(viewBox: CGRect? = nil, elements: [SVGElement] = [], id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.viewBox = viewBox
//        self.elements = elements
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//
//    public func addElement(_ element: SVGElement) {
//        elements.append(element)
//    }
//}

/// Represents an SVG use element
//public class SVGUse: BaseSVGElement {
//    public var x: CGFloat?
//    public var y: CGFloat?
//    public var width: CGFloat?
//    public var height: CGFloat?
//    public var href: String
//
//    public init(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil, href: String, id: String? = nil, className: String? = nil, style: [String: String] = [:], transform: SVGTransform? = nil) {
//        self.x = x
//        self.y = y
//        self.width = width
//        self.height = height
//        self.href = href
//        super.init(id: id, className: className, style: style, transform: transform)
//    }
//}
