//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

enum RealBasis: Equatable, FieldBasis {
    static prefix func * (lhs: RealBasis) -> RealBasis {
        return lhs
    }
    
    static func ^ (lhs: RealBasis, rhs: RealBasis) -> RealBasis? {
        if case let .N(intExp) = rhs {
            return lhs^intExp
        }
        return nil
    }
    
    static func / (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        return lhs * (~rhs)
    }
    
    static prefix func ~ (lhs: RealBasis) -> RealBasis {
        switch lhs {
        case let .N(n):
            return (RealBasis.Q(Rational(1, n))).eval()
        case let .Q(q):
            return RealBasis.Q(Rational(q.denominator, q.numerator)).eval()
        case let .R(r):
            return RealBasis.R(1/r).eval()
        }
    }
    
    static prefix func - (lhs: RealBasis) -> RealBasis {
        switch lhs {
        case let .N(n): return .N(-n)
        case let .Q(q): return .Q(-q)
        case let .R(r): return .R(-r)
        }
    }
    
    static func - (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
        return lhs + (-rhs)
    }
    
    static func + (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
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
    
    static var Zero: RealBasis {return .N(0)}
    
    static var Id: RealBasis {return .N(1)}
    
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
    
    static func * (lhs: RealBasis, rhs: RealBasis) -> RealBasis {
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
//typealias Real = Field<RealNumber>
struct Real:Field {
    typealias B = RealBasis

    func same(_ to: Real) -> Bool {
        return sameField(to)
    }
    
    func eval() -> Real {
        return evalField()
    }
    
    let op: FieldOperators<Self>
    
}
