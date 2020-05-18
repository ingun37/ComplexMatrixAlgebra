//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

enum RealNumber: Equatable, FieldSet {
    static prefix func * (lhs: RealNumber) -> RealNumber {
        return lhs
    }
    
    static func ^ (lhs: RealNumber, rhs: RealNumber) -> RealNumber? {
        if case let .N(intExp) = rhs {
            return lhs^intExp
        }
        return nil
    }
    
    static func / (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        return lhs * (~rhs)
    }
    
    static prefix func ~ (lhs: RealNumber) -> RealNumber {
        switch lhs {
        case let .N(n):
            return (RealNumber.Q(Rational(1, n))).eval()
        case let .Q(q):
            return RealNumber.Q(Rational(q.denominator, q.numerator)).eval()
        case let .R(r):
            return RealNumber.R(1/r).eval()
        }
    }
    
    static prefix func - (lhs: RealNumber) -> RealNumber {
        switch lhs {
        case let .N(n): return .N(-n)
        case let .Q(q): return .Q(-q)
        case let .R(r): return .R(-r)
        }
    }
    
    static func - (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        return lhs + (-rhs)
    }
    
    static func + (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x+y))

        case let (.N(x), .Q(y)): return (RealNumber.Q(y + Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealNumber.Q(y + Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealNumber.R(y + Double(x))).eval()
        case let (.R(y), .N(x)): return (RealNumber.R(y + Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealNumber.Q(y + x)).eval()

        case let (.Q(x), .R(y)): return (RealNumber.R(x.doubleValue + y)).eval()
        case let (.R(y), .Q(x)): return (RealNumber.R(x.doubleValue + y)).eval()

        case let (.R(x), .R(y)): return (RealNumber.R(y + x)).eval()
        }
    }
    
    static var zero: RealNumber {return .N(0)}
    
    static var id: RealNumber {return .N(1)}
    
    private func eval() -> RealNumber {
        switch self {
        case .N(_): return self
        case let .Q(q):
            if let n = q.intValue { return .N(n) }
            else                  { return self }
        case let .R(r):
            if abs(r - r.rounded()) < 0.00001 { return (.N(Int(r.rounded())))}
            else                              { return self }
        }
    }
    
    static func * (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x*y))

        case let (.N(x), .Q(y)): return (RealNumber.Q(y * Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealNumber.Q(y * Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealNumber.R(y * Double(x))).eval()
        case let (.R(y), .N(x)): return (RealNumber.R(y * Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealNumber.Q(y * x)).eval()

        case let (.Q(x), .R(y)): return (RealNumber.R(x.doubleValue * y)).eval()
        case let (.R(y), .Q(x)): return (RealNumber.R(x.doubleValue * y)).eval()

        case let (.R(x), .R(y)): return (RealNumber.R(y * x)).eval()
        }
    }
    
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
}
struct RealOperatorSum:FieldOpSum {
    let op: O
    typealias A = Real
    typealias Num = RealNumber
}
//typealias Real = Field<RealNumber>
struct Real:Field {
    func same(_ to: Real) -> Bool {
        return sameField(to)
    }
    
    func eval() -> Real {
        return evalField()
    }
    
    let op: RealOperatorSum
    typealias OpSum = RealOperatorSum
    
}
