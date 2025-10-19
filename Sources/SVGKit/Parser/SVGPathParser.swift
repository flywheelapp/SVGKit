import Foundation

class SVGPathParser {
    static let shared = SVGPathParser()

    private var currentPoint: CGPoint = .zero
    private var lastControlPoint: CGPoint?
    private var pathData: SVGPath!

    private init() {}

    func parse(d: String) -> SVGPath {
        pathData = SVGPath()
        currentPoint = .zero
        lastControlPoint = nil

        let scanner = Scanner(string: d)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces.union(.init(charactersIn: ","))

        var currentCommand: Character?
        var currentValues: [Double] = []

        while !scanner.isAtEnd {
            if let value = scanner.scanDouble() {
                currentValues.append(value)
                continue
            }

            if let command = scanner.scanCharacter(), command.isLetter {
                if let currentCommand = currentCommand {
                    executeCommand(currentCommand, values: currentValues)
                }
                currentCommand = command
                currentValues = []
            }
        }

        if let currentCommand = currentCommand {
            executeCommand(currentCommand, values: currentValues)
        }

        let path = pathData!
        pathData = nil
        return path
    }

    private func executeCommand(_ command: Character, values: [Double]) {
        let isRelative = command.isLowercase

        switch command {
        case "M", "m":
            moveTo(values: values, isRelative: isRelative)
        case "L", "l":
            lineTo(values: values, isRelative: isRelative)
        case "H", "h":
            horizontalLineTo(values: values, isRelative: isRelative)
        case "V", "v":
            verticalLineTo(values: values, isRelative: isRelative)
        case "C", "c":
            cubicCurveTo(values: values, isRelative: isRelative)
        case "S", "s":
            smoothCubicCurveTo(values: values, isRelative: isRelative)
        case "Q", "q":
            quadraticCurveTo(values: values, isRelative: isRelative)
        case "T", "t":
            smoothQuadraticCurveTo(values: values, isRelative: isRelative)
        case "A", "a":
            arcTo(values: values, isRelative: isRelative)
        case "Z", "z":
            closePath()
        default:
            break
        }
    }

    private func moveTo(values: [Double], isRelative: Bool) {
        guard values.count >= 2 else { return }

        var point = CGPoint(x: values[0], y: values[1])
        if isRelative {
            point += currentPoint
        }

        currentPoint = point
        pathData.moveTo(point: point)

        lineTo(values: Array(values.dropFirst(2)), isRelative: isRelative)
    }

    private func lineTo(values: [Double], isRelative: Bool) {
        guard values.count >= 2 else { return }

        var i = 1
        while values.count > i {
            var point = CGPoint(x: values[i - 1], y: values[i])
            if isRelative {
                point += currentPoint
            }

            currentPoint = point
            pathData.lineTo(point: point)

            i += 2
        }
    }

    private func horizontalLineTo(values: [Double], isRelative: Bool) {
        for value in values {
            let y = currentPoint.y
            var x = value
            if isRelative {
                x += currentPoint.x
            }

            lineTo(values: [x, y], isRelative: false)
        }
    }

    private func verticalLineTo(values: [Double], isRelative: Bool) {
        for value in values {
            let x = currentPoint.x
            var y = value
            if isRelative {
                y += currentPoint.y
            }

            lineTo(values: [x, y], isRelative: false)
        }
    }

    private func cubicCurveTo(values: [Double], isRelative: Bool) {
        let parts = 6

        var i = parts - 1
        while values.count > i {
            var control1 = CGPoint(x: values[i - 5], y: values[i - 4])
            var control2 = CGPoint(x: values[i - 3], y: values[i - 2])
            var end = CGPoint(x: values[i - 1], y: values[i])

            if isRelative {
                control1 += currentPoint
                control2 += currentPoint
                end += currentPoint
            }

            currentPoint = end
            lastControlPoint = control2

            pathData.cubicCurveTo(control1: control1, control2: control2, end: end)

            i += parts
        }
    }

    private func smoothCubicCurveTo(values: [Double], isRelative: Bool) {
        let parts = 4

        var i = parts - 1
        while values.count > i {
            var control2 = CGPoint(x: values[i - 3], y: values[i - 2])
            var end = CGPoint(x: values[i - 1], y: values[i])

            let lastControl = lastControlPoint ?? currentPoint
            let control1 = 2 * currentPoint - lastControl

            if isRelative {
                control2 += currentPoint
                end += currentPoint
            }

            cubicCurveTo(
                values: [
                    control1.x, control1.y,
                    control2.x, control2.y,
                    end.x, end.y,
                ],
                isRelative: false
            )

            i += parts
        }
    }

    private func quadraticCurveTo(values: [Double], isRelative: Bool) {
        let parts = 4

        var i = parts - 1
        while values.count > i {
            var control = CGPoint(x: values[i - 3], y: values[i - 2])
            var end = CGPoint(x: values[i - 1], y: values[i])

            if isRelative {
                control += currentPoint
                end += currentPoint
            }

            currentPoint = end
            lastControlPoint = control

            pathData.quadraticCurveTo(control: control, end: end)

            i += parts
        }
    }

    private func smoothQuadraticCurveTo(values: [Double], isRelative: Bool) {
        let parts = 2

        var i = parts - 1
        while values.count > i {
            var end = CGPoint(x: values[i - 1], y: values[i])

            let lastControl = lastControlPoint ?? currentPoint
            let control = 2 * currentPoint - lastControl

            if isRelative {
                end += currentPoint
            }

            quadraticCurveTo(values: [control.x, control.y, end.x, end.y], isRelative: false)

            i += parts
        }
    }

    private func arcTo(values: [Double], isRelative: Bool) {
        let parts = 7

        var i = parts - 1
        while values.count > i {
            let rx = values[i - 6]
            let ry = values[i - 5]
            let xAxisRotation = values[i - 4]
            let largeArcFlag = values[i - 3] != 0
            let sweepFlag = values[i - 2] != 0

            var end = CGPoint(x: values[i - 1], y: values[i])
            if isRelative {
                end += currentPoint
            }

            currentPoint = end

            pathData.arcTo(
                rx: rx,
                ry: ry,
                xAxisRotation: xAxisRotation,
                largeArcFlag: largeArcFlag,
                sweepFlag: sweepFlag,
                end: end
            )

            i += parts
        }
    }

    private func closePath() {
        pathData.closePath()
        currentPoint = .zero
        lastControlPoint = nil
    }
}
