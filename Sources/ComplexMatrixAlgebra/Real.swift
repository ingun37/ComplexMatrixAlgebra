//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

public enum RealBasis: FieldBasis {
    public static func whole(n: Int) -> RealBasis {
        return .N(n)
    }
    
    public static prefix func * (lhs: RealBasis) -> RealBasis {
        return lhs
    }
    
    static func / (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        return lhs * (~rhs)
    }
    
    public static prefix func ~ (lhs: RealBasis) -> RealBasis {
        switch lhs {
        case let .N(n):
            return (RealBasis.Q(Rational(1, n))).eval()
        case let .Q(q):
            return RealBasis.Q(Rational(q.denominator, q.numerator)).eval()
        case let .R(r):
            return RealBasis.R(1/r).eval()
        }
    }
    
    public static prefix func - (lhs: RealBasis) -> RealBasis {
        switch lhs {
        case let .N(n): return .N(-n)
        case let .Q(q): return .Q(-q)
        case let .R(r): return .R(-r)
        }
    }
    
    static func - (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        return lhs + (-rhs)
    }
    
    public static func + (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x+y))

        case let (.N(x), .Q(y)): return (RealBasis.Q(y + Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealBasis.Q(y + Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealBasis.R(y + Double(x))).eval()
        case let (.R(y), .N(x)): return (RealBasis.R(y + Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealBasis.Q(y + x)).eval()

        case let (.Q(x), .R(y)): return (RealBasis.R(x.doubleValue + y)).eval()
        case let (.R(y), .Q(x)): return (RealBasis.R(x.doubleValue + y)).eval()

        case let (.R(x), .R(y)): return (RealBasis.R(y + x)).eval()
        }
    }
    
    public static var Zero: RealBasis {return .N(0)}
    
    public static var Id: RealBasis {return .N(1)}
    
    private func eval() -> RealBasis {
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
    
    public static func * (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x*y))

        case let (.N(x), .Q(y)): return (RealBasis.Q(y * Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealBasis.Q(y * Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealBasis.R(y * Double(x))).eval()
        case let (.R(y), .N(x)): return (RealBasis.R(y * Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealBasis.Q(y * x)).eval()

        case let (.Q(x), .R(y)): return (RealBasis.R(x.doubleValue * y)).eval()
        case let (.R(y), .Q(x)): return (RealBasis.R(x.doubleValue * y)).eval()

        case let (.R(x), .R(y)): return (RealBasis.R(y * x)).eval()
        }
    }
    
    var less0:Bool {
        switch self {
        case let .N(n):
            return n < 0
        case let .Q(q):
            return q < 0
        case let .R(d):
            return d < 0
        }
    }
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
}
public indirect enum RealOperator:Operator {
    public func eval() -> Real {
        
        if case let .f(.Power(base: base, exponent: exponent)) = self {
            let exponent = exponent.eval()
            if case let .Basis(.N(intExp)) = exponent.element {
                let base = base.eval()
                if let mul = (0..<abs(intExp)).decompose()?.fmap({_ in base}).reduce(*) {
                    if intExp < 0 {
                        return Real(mabelianOp: .Inverse(mul)).eval()
                    } else {
                        return mul.eval()
                    }
                } else { // exponent is 0
                    return Real.Id
                }
            }
        }
        
        switch self {
        case let .f(f): return f.eval()
        }
    }
    
    public typealias A = Real
    
    case f(FieldOperators<Real>)
    
}
public struct RealMultiplication:CommutativeMultiplication {
    public let l: Real
    public let r: Real
    public typealias A = Real
    public init(l ll:Real, r rr:Real) {
        l = ll
        r = rr
    }
}
public struct RealAddition:CommutativeAddition {
    public let l: Real
    public let r: Real
    public typealias A = Real
    public init(l ll:Real, r rr:Real) {
        l = ll
        r = rr
    }
}
//typealias Real = Field<RealNumber>
public struct Real:Field {
    public static var cache:Dictionary<Int, Real>? = .init()
    
    public typealias ADD = RealAddition
    public typealias MUL = RealMultiplication
    public var fieldOp: FieldOperators<Real>? {
        switch c {
        case let .o(.f(f)): return f
        default: return nil
        }
    }
    
    public init(_ c: Construction<Real>) {
        self.c = c
    }
    
    public let c: Construction<Real>
    
    public typealias O = RealOperator
    
    public init(fieldOp: FieldOperators<Real>) {
        c = .o(.f(fieldOp))
    }
    public typealias B = RealBasis
}
