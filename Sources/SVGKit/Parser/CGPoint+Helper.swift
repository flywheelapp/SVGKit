//
//  CGPoint+Helper.swift
//  SVGKit
//
//  Created by maralla on 2025/4/7.
//

import CoreGraphics

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (factor: Double, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: factor * rhs.x, y: factor * rhs.y)
    }
}
