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
    static func whole(n:Int)->Self
}


protocol Field:Ring where B:FieldBasis, MUL: CommutativeMultiplication {
    var fieldOp: FieldOperators<Self>? { get }
    init(fieldOp:FieldOperators<Self>)
}

indirect enum FieldOperators<A:Field>: Operator {
    func eval() -> A {
        
        switch self {
        case let .Ring(ring):
            if case let .MMonoid(.Mul(_b)) = ring {
                let b = _b.eachEvaled
                let cases1 = b.caseMultiplicationWithZero() ?? b.caseMultiplicationWithId() ?? b.caseBothBasis()
                let cases2 = cases1 ?? b.caseDistributive()
                let cases3 = cases2 ?? b.caseAssociative()
                let cases4 = cases3 ?? b.caseCommutative()
                return cases4 ?? b.l * b.r
            }
            return ring.eval()
        case let .Quotient(l, r): return (l * ~r).eval()
        
        case let .Inverse(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(number):
                return .init(element: .Basis(~number))
            default: break
            }
            
            switch x.fieldOp {
            case let .Quotient(numer, denom):
                return A(fieldOp: .Quotient(denom, numer)).eval()
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
            return .init(fieldOp: .Power(base: base, exponent: exponent))
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.element {
            case let .Basis(n):
                return .init(element: .Basis(*n))
            default: break
            }
            return .init(fieldOp: .Conjugate(x))
        case let .Determinant(m):
            let m = m.eval()
            if case let .e(.Basis(m)) = m.c {
                if let d = m.determinant {
                    return d
                }
            }
            return .init(fieldOp: .Determinant(m))
        }
    }
    
    case Quotient(A, A)
    case Inverse(A)
    case Power(base:A, exponent:A)
    case Conjugate(A)
    case Ring(A.RingOp)
    case Determinant(Matrix<A>)
}

/** conjugate prefix */
prefix operator *

extension Field {
    static prefix func ~ (lhs: Self) -> Self {
        return .init(fieldOp: .Inverse(lhs))
    }
    static prefix func * (lhs: Self) -> Self { return .init(fieldOp: .Conjugate(lhs)) }
    static func / (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Quotient(lhs, rhs)) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Power(base: lhs, exponent: rhs)) }

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
