//
//  Literal.Extension.swift
//  Neves_Example
//
//  Created by 周健平 on 2020/10/18.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

extension Int: ExpressibleByBooleanLiteral, ExpressibleByStringLiteral {
    public init(booleanLiteral value: Bool) { self = value ? 1 : 0 }
    public init(stringLiteral value: String) { self = Int(Double(stringLiteral: value)) }
    public init(unicodeScalarLiteral value: String) { self = Int(Double(stringLiteral: value)) }
    public init(extendedGraphemeClusterLiteral value: String) { self = Int(Double(stringLiteral: value)) }
}

extension Float: ExpressibleByBooleanLiteral, ExpressibleByStringLiteral {
    public init(booleanLiteral value: Bool) { self = value ? 1 : 0 }
    public init(stringLiteral value: String) { self = Float(value) ?? 0 }
    public init(unicodeScalarLiteral value: String) { self = Float(value) ?? 0 }
    public init(extendedGraphemeClusterLiteral value: String) { self = Float(value) ?? 0 }
}

extension Double: ExpressibleByBooleanLiteral, ExpressibleByStringLiteral {
    public init(booleanLiteral value: Bool) { self = value ? 1 : 0 }
    public init(stringLiteral value: String) { self = Double(value) ?? 0 }
    public init(unicodeScalarLiteral value: String) { self = Double(value) ?? 0 }
    public init(extendedGraphemeClusterLiteral value: String) { self = Double(value) ?? 0 }
}

extension Bool: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) { self = value > 0 }
    public init(floatLiteral value: Double) { self = value > 0 }
}

extension CGPoint: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        if elements.count == 2 {
            self = .init(x: elements[0], y: elements[1])
        } else {
            self = .zero
        }
    }
}

extension CGPoint {
    public var exchange: CGPoint { CGPoint(x: y, y: x) }
}

extension CGSize: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        if elements.count == 2 {
            self = .init(width: elements[0], height: elements[1])
        } else {
            self = .zero
        }
    }
}

extension CGSize {
    public var exchange: CGSize { CGSize(width: height, height: width) }
}

extension CGRect: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        if elements.count == 4 {
            self = .init(x: elements[0], y: elements[1], width: elements[2], height: elements[3])
        } else {
            self = .zero
        }
    }
}
