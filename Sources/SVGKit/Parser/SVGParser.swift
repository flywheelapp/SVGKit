import Foundation
import CoreGraphics

public class SVGParser: NSObject, XMLParserDelegate {
    class StackElement {
        var element: SVGElement
        
        init(_ element: SVGElement) {
            self.element = element
        }
        
        func append(_ element: SVGElement) {
            switch self.element.element {
            case .group(var group):
                group.elements.append(element)
                self.element = .init(info: self.element.info, element: .group(group))
            case .svg(var document):
                document.elements.append(element)
                self.element = .init(info: self.element.info, element: .svg(document))
            case .foreignobject(var object):
                object.elements.append(element)
                self.element = .init(info: self.element.info, element: .foreignobject(object))
            case .unknown(var object):
                object.elements.append(element)
                self.element = .init(info: self.element.info, element: .unknown(object))
            case .marker(var marker):
                marker.elements.append(element)
                self.element = .init(info: self.element.info, element: .marker(marker))
            case .gradient(var value):
                value.elements.append(element)
                self.element = .init(info: self.element.info, element: .gradient(value))
            case .text(var text):
                text.elements.append(element)
                self.element = .init(info: self.element.info, element: .text(text))
            case .switchElement(var value):
                value.elements.append(element)
                self.element = .init(info: self.element.info, element: .switchElement(value))
            default:
                break
            }
        }
        
        var frame: CGRect? {
            switch self.element.element {
            case .svg(let document):
                return document.viewBox
            default:
                return nil
            }
        }
    }
    
//    private var currentElement: SVGElement?
    private var currentAttributes: [String: String] = [:]
    private var document: SVGElement?
    private var elementStack: [StackElement] = []
    private var pathParser: SVGPathParser
    private var currentText = ""
    private var styleRules: CSSStylesheet?
//    private var isParsingStyle = false
//    private var viewportGroup: SVGGroup?
//    private var foreignObjectContent: String?
    
    public override init() {
        self.pathParser = SVGPathParser()
        super.init()
    }
    
    private func sanitizeForXML(_ input: Data) -> Data {
        let pattern = "<br(\\s*)>"
        guard let stringData = String(data: input, encoding: .utf8) else { return input }
        let sanitized = stringData.replacingOccurrences(of: pattern, with: "<br/>", options: .regularExpression)
        guard let output = sanitized.data(using: .utf8) else { return input }
        return output
    }
    
    public func parse(data: Data) throws -> SVGElement? {
        let parser = XMLParser(data: sanitizeForXML(data))
        parser.delegate = self
        
        if parser.parse(), let doc = document, case .svg(var document) = doc.element {
            document.applyStyle(styleRules, info: doc.info)
            let svg = SVGElement(info: doc.info, element: .svg(document))
            return svg.applyTransform([], doc: svg, info: svg.info)
        } else if let error = parser.parserError {
            throw error
        } else {
            throw NSError(domain: "SVGKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown parsing error"])
        }
    }
    
    // MARK: - XMLParserDelegate
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentAttributes = attributeDict
        
        let elementName = elementName.lowercased()
        
//        if elementName != "foreignobject" && elementName != "div" && elementName != "span" {
            currentText = ""
//        }
        
        var attributeDict = attributeDict
        attributeDict["tagName"] = elementName
        
        let element: SVGElement
        switch elementName {
        case "svg":
            element = createSVGDocument(from: attributeDict)
        case "g":
            element = createSVGGroup(from: attributeDict)
        case "path":
            element = createSVGPath(from: attributeDict)
        case "rect":
            element = createSVGRect(from: attributeDict)
        case "circle":
            element = createSVGCircle(from: attributeDict)
        case "ellipse":
            element = createSVGEllipse(from: attributeDict)
        case "line":
            element = createSVGLine(from: attributeDict)
        case "text":
            element = createSVGText(from: attributeDict)
        case "polygon":
            element = createSVGPolygon(from: attributeDict)
        case "polyline":
            element = createSVGPolyline(from: attributeDict)
        case "foreignobject":
            element = createSVGForeignObject(from: attributeDict)
        case "marker":
            element = createSVGMarker(from: attributeDict)
        case "switch":
            element = createSVGSwitch(from: attributeDict)
        case "lineargradient":
            element = createSVGLinearGradient(from: attributeDict)
//        case "radialgradient":
//            element = createSVGRadialGradient(from: attributeDict)
//        case "stop":
//            // Handle gradient stops
//            if let gradientElement = elementStack.last as? SVGGradient,
//               let offset = parseCGFloat(from: attributeDict["offset"]) {
//                let color = attributeDict["stop-color"] ?? attributeDict["style"]?.components(separatedBy: ";")
//                    .first(where: { $0.contains("stop-color") })?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "#000000"
//                let opacity = parseCGFloat(from: attributeDict["stop-opacity"])
//                
//                gradientElement.addStop(offset: offset, color: color, opacity: opacity)
//            }
//            element = nil
//        case "pattern":
//            element = createSVGPattern(from: attributeDict)
//        case "image":
//            element = createSVGImage(from: attributeDict)
//        case "symbol":
//            element = createSVGSymbol(from: attributeDict)
//        case "use":
//            element = createSVGUse(from: attributeDict)
//        case "style":
//            // Parse style rules
//            element = nil
//            isParsingStyle = true
//        case "div", "span":
//            // Special handling for HTML content inside foreignObject
//            if elementStack.last is SVGForeignObject {
//                element = nil
//            } else {
//                element = nil
//            }
//        case "tspan":
//            element = handleTspan(from: attributeDict)
        default:
            element = createUnknownElement(tag: elementName, from: attributeDict)
        }
        
        elementStack.append(.init(element))
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
        
        // Handle characters inside foreignObject
//        if let _ = elementStack.last as? SVGForeignObject {
//            foreignObjectContent = (foreignObjectContent ?? "") + string
//        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let elementName = elementName.lowercased()

        if elementName == "style" {
            if let css = try? CSSParser(input: currentText).parse() {
                styleRules = css
            }
        }
        
//        // Handle text content for text elements
//        if elementName == "text" {
//            if let textElement = currentElement as? SVGText {
//                textElement.content = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        }
//        
//        // Handle tspan within text
//        if elementName == "tspan" {
//            if let textElement = elementStack.last as? SVGText {
//                textElement.content += currentText.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        }
//        
//        // Handle foreignObject content
//        if elementName == "foreignobject" {
//            if let foreignObject = currentElement as? SVGForeignObject, let content = foreignObjectContent {
//                foreignObject.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//            foreignObjectContent = nil
//        }
        
        if !elementStack.isEmpty {
            let element = elementStack.removeLast()
            
            switch element.element.element {
            case .text(var text):
                text.content += currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                element.element = .init(info: element.element.info, element: .text(text))
            case .unknown(var object):
                object.text += currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                element.element = .init(info: element.element.info, element: .unknown(object))
            default:
                break
            }
            
            currentText = ""
            
            if let last = elementStack.last {
                last.append(element.element)
            } else {
                document = element.element
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createSVGDocument(from attributes: [String: String]) -> SVGElement {
        let width = parseCGFloat(from: attributes["width"])
        let height = parseCGFloat(from: attributes["height"])
        let viewBox = parseViewBox(from: attributes["viewBox"])
        var element = SVGDocument(width: width, height: height, viewBox: viewBox)
        let info = parseElementInfo(from: attributes)
        return .init(info: info, element: .svg(element))
    }
    
    private func createUnknownElement(tag: String, from attributes: [String: String]) -> SVGElement {
        var element = SVGUnknownElement(tag: tag)
        let info = parseElementInfo(from: attributes)
        return .init(info: info, element: .unknown(element))
    }
    
    private func createSVGSwitch(from attributes: [String: String]) -> SVGElement {
        return .init(info: parseElementInfo(from: attributes), element: .switchElement(SVGSwitch()))
    }
    
    private func createSVGLinearGradient(from attributes: [String: String]) -> SVGElement {
        var element = SVGGradient()
        element.x1 = attributes["x1"]
        element.y1 = attributes["y1"]
        element.x2 = attributes["x2"]
        element.y2 = attributes["y2"]
        return .init(info: parseElementInfo(from: attributes), element: .gradient(element))
    }
    
    private func createSVGMarker(from attributes: [String: String]) -> SVGElement {
        var element = SVGMarker()
        if let value = attributes["markerUnits"] {
            element.markerUnits = value
        }
        
        if let orient = attributes["orient"] {
            element.orient = orient
        }
        
        if let refX = attributes["refX"] {
            element.refX = refX
        }
        
        if let refY = attributes["refY"] {
            element.refY = refY
        }
        
        if let value = parseCGFloat(from: attributes["markerHeight"]) {
            element.markerHeight = value
        }
        
        if let value = parseCGFloat(from: attributes["markerWidth"]) {
            element.markerWidth = value
        }
        
        element.viewBox = parseViewBox(from: attributes["viewBox"])
        
        return .init(info: parseElementInfo(from: attributes), element: .marker(element))
    }
    
    private func createSVGPath(from attributes: [String: String]) -> SVGElement {
        let pathDataString = attributes["d"] ?? ""
        var path = SVGPathElement(path: pathParser.parse(d: pathDataString))
        let info = parseElementInfo(from: attributes)
        return .init(info: info, element: .path(path))
    }
    
    private func createSVGRect(from attributes: [String: String]) -> SVGElement {
        let x = parseCGFloat(from: attributes["x"]) ?? 0
        let y = parseCGFloat(from: attributes["y"]) ?? 0
        let width = parseCGFloat(from: attributes["width"]) ?? 0
        let height = parseCGFloat(from: attributes["height"]) ?? 0
        let rx = parseCGFloat(from: attributes["rx"])
        let ry = parseCGFloat(from: attributes["ry"])
        
        var rect = SVGRect(x: x, y: y, width: width, height: height, rx: rx, ry: ry)
        let info = parseElementInfo(from: attributes)
        
        return .init(info: info, element: .rect(rect))
    }
    
    private func createSVGCircle(from attributes: [String: String]) -> SVGElement {
        let cx = parseCGFloat(from: attributes["cx"]) ?? 0
        let cy = parseCGFloat(from: attributes["cy"]) ?? 0
        let r = parseCGFloat(from: attributes["r"]) ?? 0
        
        var circle = SVGCircle(cx: cx, cy: cy, r: r)
        let info = parseElementInfo(from: attributes)
        
        return .init(info: info, element: .circle(circle))
    }
    
    private func createSVGEllipse(from attributes: [String: String]) -> SVGElement {
        let cx = parseCGFloat(from: attributes["cx"]) ?? 0
        let cy = parseCGFloat(from: attributes["cy"]) ?? 0
        let rx = parseCGFloat(from: attributes["rx"]) ?? 0
        let ry = parseCGFloat(from: attributes["ry"]) ?? 0
        
        var ellipse = SVGEllipse(cx: cx, cy: cy, rx: rx, ry: ry)
        let info = parseElementInfo(from: attributes)
        
        return .init(info: info, element: .ellipse(ellipse))
    }
    
    private func createSVGLine(from attributes: [String: String]) -> SVGElement {
        let x1 = parseCGFloat(from: attributes["x1"]) ?? 0
        let y1 = parseCGFloat(from: attributes["y1"]) ?? 0
        let x2 = parseCGFloat(from: attributes["x2"]) ?? 0
        let y2 = parseCGFloat(from: attributes["y2"]) ?? 0
        
        var line = SVGLine(x1: x1, y1: y1, x2: x2, y2: y2)
        let info = parseElementInfo(from: attributes)
                
        return .init(info: info, element: .line(line))
    }
    
    private func createSVGText(from attributes: [String: String]) -> SVGElement {
        let x = attributes["x"] ?? "0"
        let y = attributes["y"] ?? "0"
        
        var text = SVGText()
        text.x = x
        text.y = y
        let info = parseElementInfo(from: attributes)
        text.dx = attributes["dx"]
        text.dy = attributes["dy"]
        
        return .init(info: info, element: .text(text))
    }
    
    private func createSVGForeignObject(from attributes: [String: String]) -> SVGElement {
        let x = parseCGFloat(from: attributes["x"]) ?? 0
        let y = parseCGFloat(from: attributes["y"]) ?? 0
        let height = parseCGFloat(from: attributes["height"])
        let width = parseCGFloat(from: attributes["width"])
        
        var object = SVGForeignObject(x: x, y: y, height: height, width: width)
        return .init(info: parseElementInfo(from: attributes), element: .foreignobject(object))
    }
    
    private func handleTspan(from attributes: [String: String]) -> SVGElement {
        let info = parseElementInfo(from: attributes)
        let retElement = SVGElement.Element.unknown(.init(tag: "tspan"))
        
        guard
            let last = elementStack.last,
            case .text(var text) = last.element.element
        else { return .init(info: info, element: retElement) }
        
        let element = last.element
        
        let x = attributes["x"] ?? text.x
        let y = attributes["y"] ?? text.y
        let dx = attributes["dx"] ?? text.dx
        let dy = attributes["dy"] ?? text.dy
        
        text.x = x
        text.y = y
        text.dx = dx
        text.dy = dy
        last.element = .init(info: element.info, element: .text(text))
        
        return .init(info: info, element: retElement)
    }
    
    private func createSVGPolygon(from attributes: [String: String]) -> SVGElement {
        let points = attributes["points"] ?? ""
        
        var polygon = SVGPolygon(points: parsePoints(points))
        let info = parseElementInfo(from: attributes)
        return .init(info: info, element: .polygon(polygon))
    }
    
    private func createSVGPolyline(from attributes: [String: String]) -> SVGElement {
        let points = attributes["points"] ?? ""
        
        var polyline = SVGPolyline(points: parsePoints(points))
        let info = parseElementInfo(from: attributes)
        
        return .init(info: info, element: .polyline(polyline))
    }
    
    private func parsePoints(_ data: String) -> [CGPoint] {
        let scanner = Scanner(string: data)
        
        var points: [CGPoint] = []
        var values: [Double] = []
        while !scanner.isAtEnd {
            if let value = scanner.scanDouble() {
                values.append(value)
            } else {
                _ = scanner.scanCharacter()
            }
            
            if values.count == 2 {
                points.append(.init(x: values[0], y: values[1]))
                values = []
            }
        }
        
        return points
    }
    
//    private func createSVGForeignObject(from attributes: [String: String]) -> SVGForeignObject {
//        let x = parseCGFloat(from: attributes["x"]) ?? 0
//        let y = parseCGFloat(from: attributes["y"]) ?? 0
//        let width = parseCGFloat(from: attributes["width"]) ?? 0
//        let height = parseCGFloat(from: attributes["height"]) ?? 0
//        
//        let foreignObject = SVGForeignObject(x: x, y: y, width: width, height: height, content: "")
//        
//        // Apply common attributes
//        var element: SVGElement = foreignObject
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return foreignObject
//    }
    
    private func createSVGGroup(from attributes: [String: String]) -> SVGElement {
        var group = SVGGroup(elements: [])
        let info = parseElementInfo(from: attributes)
        return .init(info: info, element: .group(group))
    }
    
//    private func parseStyleRules(_ text: String) -> [String: [String: String]] {
//        var rules: [String: [String: String]] = [:]
//        
//        let lines = text.components(separatedBy: .newlines)
//        var currentSelector: String?
//        var currentProperties: [String: String] = [:]
//        
//        for line in lines {
//            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
//            
//            if trimmedLine.isEmpty {
//                continue
//            }
//            
//            if trimmedLine.contains("{") {
//                let selectorPart = trimmedLine.components(separatedBy: "{")[0].trimmingCharacters(in: .whitespaces)
//                currentSelector = selectorPart
//                currentProperties = [:]
//            } else if trimmedLine.contains("}") {
//                if let selector = currentSelector {
//                    rules[selector] = currentProperties
//                }
//                currentSelector = nil
//                currentProperties = [:]
//            } else if let colonIndex = trimmedLine.firstIndex(of: ":") {
//                let propertyName = String(trimmedLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
//                var propertyValue = String(trimmedLine[trimmedLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
//                
//                if propertyValue.hasSuffix(";") {
//                    propertyValue.removeLast()
//                }
//                
//                currentProperties[propertyName] = propertyValue
//            }
//        }
//        
//        return rules
//    }
//    
//    private func parseStyle(_ styleString: String) -> [String: String] {
//        var style: [String: String] = [:]
//        
//        let stylePairs = styleString.components(separatedBy: ";")
//        for pair in stylePairs {
//            let components = pair.components(separatedBy: ":")
//            if components.count == 2 {
//                let key = components[0].trimmingCharacters(in: .whitespaces)
//                let value = components[1].trimmingCharacters(in: .whitespaces)
//                style[key] = value
//            }
//        }
//        
//        return style
//    }
    
    private func parseViewBox(from string: String?) -> CGRect? {
        guard let string = string else { return nil }
        
        let components = string.components(separatedBy: .whitespaces)
        if components.count == 4,
           let x = Double(components[0]),
           let y = Double(components[1]),
           let width = Double(components[2]),
           let height = Double(components[3]) {
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        return nil
    }
    
    private func parseCGFloat(from string: String?) -> Double? {
        guard let string = string else { return nil }
        
        // Handle percentage values
        if string.hasSuffix("%") {
            guard
                let document = elementStack.first,
                let frame = document.frame
            else { return nil }
            
            if let value = Double(string.dropLast()) {
                return CGFloat(value) / 100.0
            }
        }
        
        return Double(string)
    }
    
    private func parseElementInfo(from attributes: [String: String]) -> ElementInfo {
        var info = ElementInfo(tag: attributes["tagName"]!)
        
        // Handle class names
        if let className = attributes["class"] {
            info.className = className
            info.style["class"] = className
        }
        
        // Handle ID
        if let id = attributes["id"] {
            info.id = id
        }
        
        // Handle transform
        if let transformStr = attributes["transform"] {
            info.transform = parseTransform(transformStr)
            info.style["transform"] = transformStr
        }
        
        // Handle presentation attributes - SVG allows style properties as direct attributes
        let presentationAttributes = [
            "x", "y", "dx", "dy",
            "marker-start", "marker-end", "marker-mid", "stop-color", "offset"
        ] + ElementInfo.attributes
        
        for attr in presentationAttributes {
            if let value = attributes[attr] {
                info.properties[attr] = value
            }
        }
        
        // Handle style attribute
        if let style = attributes["style"] {
            let parser = CSSParser(input: "a{\(style)}")
            if let sheet = try? parser.parse() {
                for rule in sheet.rules {
                    for decl in rule.declarations {
                        info.style[decl.property] = decl.value
                    }
                }
            }
        }
        
        return info
    }
    
    private func parseTransform(_ transform: String) -> SVGTransform? {
        // Handle multiple transformations (space or comma-separated)
        let transformString = transform.trimmingCharacters(in: .whitespaces)
        
        // Return nil for empty transform
        if transformString.isEmpty {
            return nil
        }
        
        // Parse individual transforms
        let pattern = #"(\w+)\s*\(\s*([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?(?:,\s*|\s*)?)+\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let matches = regex.matches(in: transformString, range: NSRange(transformString.startIndex..., in: transformString))
        
        var transforms: [SVGTransform.Transform] = []
        // For simplicity, we'll just support common transforms and convert to a matrix
        var resultMatrix = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0] // Identity matrix
        for match in matches {
            guard let typeRange = Range(match.range(at: 1), in: transformString),
                  let valuesRange = Range(match.range, in: transformString) else {
                continue
            }
            
            let type = String(transformString[typeRange])
            let fullMatch = String(transformString[valuesRange])
            
            // Extract only the values part from inside the parentheses
            guard let openParenIndex = fullMatch.firstIndex(of: "("),
                  let closeParenIndex = fullMatch.lastIndex(of: ")") else {
                continue
            }
            
            let valuesString = fullMatch[fullMatch.index(after: openParenIndex)..<closeParenIndex]
                .trimmingCharacters(in: .whitespaces)
            
            // Split values by commas or whitespace
            let valueComponents = valuesString.components(separatedBy: CharacterSet(charactersIn: ", "))
                .filter { !$0.isEmpty }
                .compactMap { Double($0) ?? 0 }
            
            switch type.lowercased() {
            case "matrix":
                if valueComponents.count == 6 {
                    transforms.append(.matrix(
                        a: valueComponents[0],
                        b: valueComponents[1],
                        c: valueComponents[2],
                        d: valueComponents[3],
                        e: valueComponents[4],
                        f: valueComponents[5]
                    ))
                }
            case "translate":
                if valueComponents.count >= 1 {
                    let tx = valueComponents[0]
                    let ty = valueComponents.count >= 2 ? valueComponents[1] : 0.0
                    transforms.append(.translate(x: tx, y: ty))
                }
            case "scale":
                if valueComponents.count >= 1 {
                    let sx = valueComponents[0]
                    let sy = valueComponents.count >= 2 ? valueComponents[1] : sx
                    transforms.append(.scale(x: sx, y: sy))
                }
            case "rotate":
                if valueComponents.count >= 1 {
                    let angle = valueComponents[0] * .pi / 180.0 // Convert to radians
                    
                    var cx = 0.0
                    var cy = 0.0
                    if valueComponents.count >= 3 {
                        cx = valueComponents[1]
                        cy = valueComponents[2]
                    }
                    
                    transforms.append(.rotate(degree: angle, x: cx, y: cy))
                }
            case "skewx":
                if valueComponents.count >= 1 {
                    transforms.append(.skewX(valueComponents[0]))
                }
            case "skewy":
                if valueComponents.count >= 1 {
                    transforms.append(.skewY(valueComponents[0]))
                }
            default:
                continue
            }
        }
        
        return SVGTransform(transforms: transforms)
    }
    
    private func multiplyMatrices(_ a: [Double], _ b: [Double]) -> [Double] {
        // Multiply 2D transformation matrices (3x3 in the form [a c e; b d f; 0 0 1])
        // We only store the 6 components [a, b, c, d, e, f]
        
        let a1 = a[0], b1 = a[1], c1 = a[2], d1 = a[3], e1 = a[4], f1 = a[5]
        let a2 = b[0], b2 = b[1], c2 = b[2], d2 = b[3], e2 = b[4], f2 = b[5]
        
        return [
            a1 * a2 + c1 * b2,          // a = a1*a2 + c1*b2
            b1 * a2 + d1 * b2,          // b = b1*a2 + d1*b2
            a1 * c2 + c1 * d2,          // c = a1*c2 + c1*d2
            b1 * c2 + d1 * d2,          // d = b1*c2 + d1*d2
            a1 * e2 + c1 * f2 + e1,     // e = a1*e2 + c1*f2 + e1
            b1 * e2 + d1 * f2 + f1      // f = b1*e2 + d1*f2 + f1
        ]
    }
    
//    private func createSVGLinearGradient(from attributes: [String: String]) -> SVGLinearGradient {
//        let x1 = parseCGFloat(from: attributes["x1"])
//        let y1 = parseCGFloat(from: attributes["y1"])
//        let x2 = parseCGFloat(from: attributes["x2"])
//        let y2 = parseCGFloat(from: attributes["y2"])
//        let gradientUnits = attributes["gradientUnits"]
//        let spreadMethod = attributes["spreadMethod"]
//        
//        let gradient = SVGLinearGradient(
//            x1: x1, y1: y1, x2: x2, y2: y2,
//            gradientUnits: gradientUnits, spreadMethod: spreadMethod
//        )
//        
//        // Apply common attributes
//        var element: SVGElement = gradient
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return gradient
//    }
//    
//    private func createSVGRadialGradient(from attributes: [String: String]) -> SVGRadialGradient {
//        let cx = parseCGFloat(from: attributes["cx"])
//        let cy = parseCGFloat(from: attributes["cy"])
//        let r = parseCGFloat(from: attributes["r"])
//        let fx = parseCGFloat(from: attributes["fx"])
//        let fy = parseCGFloat(from: attributes["fy"])
//        let fr = parseCGFloat(from: attributes["fr"])
//        let gradientUnits = attributes["gradientUnits"]
//        let spreadMethod = attributes["spreadMethod"]
//        
//        let gradient = SVGRadialGradient(
//            cx: cx, cy: cy, r: r, fx: fx, fy: fy, fr: fr,
//            gradientUnits: gradientUnits, spreadMethod: spreadMethod
//        )
//        
//        // Apply common attributes
//        var element: SVGElement = gradient
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return gradient
//    }
//    
//    private func createSVGPattern(from attributes: [String: String]) -> SVGPattern {
//        let x = parseCGFloat(from: attributes["x"])
//        let y = parseCGFloat(from: attributes["y"])
//        let width = parseCGFloat(from: attributes["width"])
//        let height = parseCGFloat(from: attributes["height"])
//        let patternUnits = attributes["patternUnits"]
//        let patternContentUnits = attributes["patternContentUnits"]
//        
//        let pattern = SVGPattern(
//            x: x, y: y, width: width, height: height,
//            patternUnits: patternUnits, patternContentUnits: patternContentUnits
//        )
//        
//        // Apply common attributes
//        var element: SVGElement = pattern
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return pattern
//    }
//    
//    private func createSVGImage(from attributes: [String: String]) -> SVGImage {
//        let x = parseCGFloat(from: attributes["x"]) ?? 0
//        let y = parseCGFloat(from: attributes["y"]) ?? 0
//        let width = parseCGFloat(from: attributes["width"]) ?? 0
//        let height = parseCGFloat(from: attributes["height"]) ?? 0
//        let href = attributes["href"] ?? attributes["xlink:href"] ?? ""
//        
//        let image = SVGImage(x: x, y: y, width: width, height: height, href: href)
//        
//        // Apply common attributes
//        var element: SVGElement = image
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return image
//    }
//    
//    private func createSVGSymbol(from attributes: [String: String]) -> SVGSymbol {
//        let viewBox = parseViewBox(from: attributes["viewBox"])
//        
//        let symbol = SVGSymbol(viewBox: viewBox)
//        
//        // Apply common attributes
//        var element: SVGElement = symbol
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return symbol
//    }
//    
//    private func createSVGUse(from attributes: [String: String]) -> SVGUse {
//        let x = parseCGFloat(from: attributes["x"])
//        let y = parseCGFloat(from: attributes["y"])
//        let width = parseCGFloat(from: attributes["width"])
//        let height = parseCGFloat(from: attributes["height"])
//        let href = attributes["href"] ?? attributes["xlink:href"] ?? ""
//        
//        let use = SVGUse(x: x, y: y, width: width, height: height, href: href)
//        
//        // Apply common attributes
//        var element: SVGElement = use
//        applyCommonAttributes(to: &element, from: attributes)
//        
//        return use
//    }
} 
