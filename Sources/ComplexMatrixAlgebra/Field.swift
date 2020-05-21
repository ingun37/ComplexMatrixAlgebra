//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation

protocol FieldBasis: RingBasis {
    static func / (lhs: Self, rhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    static prefix func * (lhs: Self) -> Self
    static func ^ (lhs: Self, rhs: Self) -> Self?
}
extension FieldBasis {
    static func ^ (lhs: Self, rhs: Int) -> Self {
        if rhs == 0 {
            return Id
        } else if rhs < 0 {
            let inv = ~lhs
            return (rhs+1..<0).map({_ in inv}).reduce(inv, *)
        } else {
            return (1..<rhs).map({_ in lhs}).reduce(lhs, *)
        }
    }
}

protocol Field:Ring where B:FieldBasis {
    var fieldOp: FieldOperators<Self> { get }
    init(fieldOp:FieldOperators<Self>)
}

indirect enum FieldOperators<A:Field>: Equatable {
    case Quotient(A, A)
    case Inverse(A)
    case Power(base:A, exponent:A)
    case Conjugate(A)
    case Ring(A.RingOp)
}

/** conjugate prefix */
prefix operator *

extension Field {
    func same(_ to: Self) -> Bool {
        return same(field: to)
    }
    func same(field: Self) -> Bool {
        switch (ringOp, field.ringOp) {
        case let (.Mul(_, _),.Mul(_, _)): // because multiplication becomes commutative in field
            return commuteSame(flatMul(self).all, flatMul(field).all)
        default:
            return same(ring: field)
        }
    }
    static prefix func ~ (lhs: Self) -> Self {
        return .init(fieldOp: .Inverse(lhs))
    }
    static prefix func * (lhs: Self) -> Self { return .init(fieldOp: .Conjugate(lhs)) }
    static func / (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Quotient(lhs, rhs)) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Power(base: lhs, exponent: rhs)) }
    func eval() -> Self {
        return evalField()
    }
    func evalField() -> Self {
        switch ringOp {
        case let .Mul(x, y):
            return operateFieldMul(x.eval(), y.eval()) // because multiplication becomes commutative in field
        default: break
        }
        
        switch fieldOp {
        case let .Quotient(l, r): return (l * ~r).eval()
        
        case let .Inverse(x):
            let x = x.eval()
            switch x.basisOp {
            case let .Number(number):
                return .init(basisOp: .Number(~number))
            default: break
            }
            
            switch x.fieldOp {
            case let .Quotient(numer, denom):
                return Self(fieldOp: .Quotient(denom, numer)).eval()
            case let .Inverse(x):
                return x.eval()
            default: break
            }
            return .init(fieldOp: .Inverse(x))
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            if exponent == .Zero {
                return .Id
            } else if exponent == .Id {
                return base
            } else if exponent == ._Id {
                return ~base
            }
            
            switch (base.basisOp, exponent.basisOp) {
            case let (.Number(numBase), .Number(numExp)):
                if let evaled = numBase^numExp {
                    return evaled.asNumber(Self.self)
                }
            default: break
            }
            return .init(fieldOp: .Power(base: base, exponent: exponent))
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.basisOp {
            case let .Number(n):
                return .init(basisOp: .Number(*n))
            default: break
            }
            return .init(fieldOp: .Conjugate(x))
        default:
            break
        }
        return evalRing()
    }
    init(ringOp: RingOp) {
        self.init(fieldOp: .Ring(ringOp))
    }
    var ringOp: RingOp? {
        switch fieldOp {
        case let .Ring(r):
            return r
        default:
            return nil
        }
    }
}


func operateFieldMul<A:Field>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if case let .Add(x, y) = l.abelianOp {
            let xr = x * r
            let yr = y * r
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Number(ln), .Number(rn)) = (l.basisOp,r.basisOp) {
            return (ln * rn).asNumber(A.self)
        }
        switch (l.fieldOp,r.fieldOp) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.same(rbase) {
                return A(fieldOp: .Power(base: lbase, exponent: lexp + rexp)).eval()
            }
        default:
            return nil
        }
        return nil
    }, flatMul(x) + flatMul(y)).reduce(*)
}


