//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

enum RealNumber: Equatable {
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
}
struct RealBinary: AlgebraBinaryOperator {
    let l: Real
    let r: Real
}
indirect enum Real:Algebra {
    static func == (lhs: Real, rhs: Real) -> Bool {
        switch lhs {
        case let .Number(l):
            guard case let .Number(r) = rhs else { return false }
            return l == r
        case let .Add(l):
            guard case let .Add(r) = rhs else { return false }
            return l.eq(r)
        case let .Mul(l):
            guard case let .Mul(r) = rhs else { return false }
            return l.eq(r)
        case let .Subtract(l):
            guard case let .Mul(r) = rhs else { return false }
            return l.eq(r)
        }
    }
    
    case Number(RealNumber)
    case Add(RealBinary)
    case Mul(RealBinary)
    case Subtract(RealBinary)
    
    func eval() -> Real {
        switch self {
        case let .Number(number):
            switch number {
            case .N(_): return self
            case let .Q(q):
                if let n = q.intValue { return .Number(.N(n)) }
                else                  { return self }
            case let .R(r):
                if abs(r - r.rounded()) < 0.00001 { return .Number(.N(Int(r.rounded())))}
                else                              { return self }
            }
        case let .Add(lr):
            let l = lr.l.eval()
            let r = lr.r.eval()
            if case let .Number(l) = l {
                if case let .Number(r) = r {
                    switch (l,r) {
                    case let (.N(x), .N(y)): return Real.Number(.N(x+y))
                        
                    case let (.N(x), .Q(y)): return Real.Number(.Q(y + Rational<Int>(x))).eval()
                    case let (.Q(y), .N(x)): return Real.Number(.Q(y + Rational<Int>(x))).eval()

                    case let (.N(x), .R(y)): return Real.Number(.R(y + Double(x))).eval()
                    case let (.R(y), .N(x)): return Real.Number(.R(y + Double(x))).eval()

                    case let (.Q(x), .Q(y)): return Real.Number(.Q(y + x)).eval()

                    case let (.Q(x), .R(y)): return Real.Number(.R(x.doubleValue + y)).eval()
                    case let (.R(y), .Q(x)): return Real.Number(.R(x.doubleValue + y)).eval()

                    case let (.R(x), .R(y)): return Real.Number(.R(y + x)).eval()
                    }
                }
            }
            return .Add(RealBinary(l: l, r: r))
        case let .Mul(lr):
            let l = lr.l.eval()
            let r = lr.r.eval()
            if case let .Number(l) = l {
                if case let .Number(r) = r {
                    switch (l,r) {
                    case let (.N(x), .N(y)): return Real.Number(.N(x*y))
                        
                    case let (.N(x), .Q(y)): return Real.Number(.Q(y * Rational<Int>(x))).eval()
                    case let (.Q(y), .N(x)): return Real.Number(.Q(y * Rational<Int>(x))).eval()
                        
                    case let (.N(x), .R(y)): return Real.Number(.R(y * Double(x))).eval()
                    case let (.R(y), .N(x)): return Real.Number(.R(y * Double(x))).eval()
                        
                    case let (.Q(x), .Q(y)): return Real.Number(.Q(y * x)).eval()
                        
                    case let (.Q(x), .R(y)): return Real.Number(.R(x.doubleValue * y)).eval()
                    case let (.R(y), .Q(x)): return Real.Number(.R(x.doubleValue * y)).eval()
                        
                    case let (.R(x), .R(y)): return Real.Number(.R(y * x)).eval()
                    }
                }
            }
            return .Mul(RealBinary(l: l, r: r))
        case let .Subtract(b):
            return Real.Add(RealBinary(l: b.l, r: .Mul(RealBinary(l: .Number(.N(-1)), r: b.r)))).eval()
        }
    }
    
    func iso(_ to: Real) -> Bool {
        switch self {
        case let .Number(me):
            guard case let .Number(to) = to else { return false }
            return me == to
        case let .Add(me):
            guard case let .Add(to) = to else { return false }
            return me.commutativeIso(to)
        case let .Mul(me):
            guard case let .Mul(to) = to else { return false }
            return me.commutativeIso(to)
        case let .Subtract(x):
            guard case let .Mul(y) = to else { return false }
            return x.commutativeIso(y)
        }
    }
    
}
