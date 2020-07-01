//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/07/01.
//

import Foundation
import NumberKit

public enum AlgebraError: Error {
    case DivisionByZero
}
public struct Rational: Hashable {
    public let r:NumberKit.Rational<Int>
    public init(_ numer: Int, _ denom:Int) throws {
        guard denom != 0 else {
            throw AlgebraError.DivisionByZero
        }
        r = NumberKit.Rational(numer, denom)
    }
    public init(_ r:NumberKit.Rational<Int>) { self.r = r}
    public init(_ integral: Int) {
        r = NumberKit.Rational(integral)
    }
    static func < (_ a:Rational, _ b:Int)-> Bool {
        return a.r < NumberKit.Rational(b)
    }
    public var doubleValue:Double { return r.doubleValue }
    static func * (_ a:Rational, _ b:Rational)-> Rational {
        return (a.r * b.r).rat()
    }
    static func + (_ a:Rational, _ b:Rational)-> Rational {
        return (a.r + b.r).rat()
    }
    static prefix func - (_ r:Rational) -> Rational {
        return .init(-r.r)
    }
}
extension NumberKit.Rational where T == Int {
    func rat() -> Rational  {
        return Rational(self)
    }
}
