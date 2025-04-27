# SVGKit

SVGKit is a pure Swift implementation of an SVG parser for macOS. It provides a simple and efficient way to parse SVG files and access their elements programmatically.

## Features

- Parse SVG files from strings, data, or file URLs
- Support for common SVG elements:
  - Paths (with structured path data representation)
  - Rectangles
  - Circles
  - Lines and text elements
  - Basic transformations
  - Styles and attributes
- Pure Swift implementation with no external dependencies
- macOS 13.0+ support

## Installation

### Swift Package Manager

Add SVGKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SVGKit.git", from: "1.0.0")
]
```

## Usage

### Basic Parsing

```swift
import SVGKit

// Parse from a string
let svgString = """
<svg width="100" height="100">
    <rect x="10" y="10" width="80" height="80" fill="blue"/>
</svg>
"""

let svgKit = SVGKit()
do {
    let document = try svgKit.parse(string: svgString)
    // Work with the parsed document
} catch {
    print("Error parsing SVG: \(error)")
}

// Parse from a file
let fileURL = URL(fileURLWithPath: "path/to/your.svg")
do {
    let document = try svgKit.parse(fileURL: fileURL)
    // Work with the parsed document
} catch {
    print("Error parsing SVG: \(error)")
}
```

### Working with Elements

```swift
// Access elements from the parsed document
for element in document.elements {
    switch element {
    case let rect as SVGRect:
        print("Rectangle: x=\(rect.x), y=\(rect.y), width=\(rect.width), height=\(rect.height)")
    case let circle as SVGCircle:
        print("Circle: cx=\(circle.cx), cy=\(circle.cy), r=\(circle.r)")
    case let path as SVGPath:
        print("Path with \(path.pathData.segments.count) segments")
        // Access individual path segments
        for segment in path.pathData.segments {
            switch segment {
            case .moveTo(let point, _):
                print("  Move to: (\(point.x), \(point.y))")
            case .lineTo(let point, _):
                print("  Line to: (\(point.x), \(point.y))")
            case .closePath:
                print("  Close path")
            default:
                break
            }
        }
    default:
        break
    }
}
```

### Accessing Attributes

All SVG elements support common attributes:

```swift
element.id           // Element ID
element.className   // CSS class name
element.style       // Style attributes as dictionary
element.transform   // Transform matrix
```

## Supported SVG Features

- Basic shapes (rect, circle, line, polygon)
- Text elements and foreign objects
- Paths with commands:
  - Move (M, m)
  - Line (L, l)
  - Horizontal line (H, h)
  - Vertical line (V, v)
  - Cubic Bézier curve (C, c)
  - Smooth cubic Bézier curve (S, s)
  - Quadratic Bézier curve (Q, q)
  - Smooth quadratic Bézier curve (T, t)
  - Arc (A, a)
  - Close path (Z, z)
- Transformations:
  - Translate
  - Scale
  - Rotate
- CSS styling and attributes
- Group elements and hierarchical structure

## Requirements

- macOS 13.0+
- Swift 5.9+

## License

SVGKit is available under the MIT license. See the LICENSE file for more info. 
