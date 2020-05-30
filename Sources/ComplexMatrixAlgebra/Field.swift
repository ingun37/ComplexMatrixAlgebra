//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation

protocol FieldBasis: RingBasis & MAbelianBasis {
    static prefix func * (lhs: Self) -> Self
    static func whole(n:Int)->Self
}


protocol Field:Ring & MAbelian where B:FieldBasis {
    var fieldOp: FieldOperators<Self>? { get }
    init(fieldOp:FieldOperators<Self>)
}

indirect enum FieldOperators<A:Field>: Operator {
    func eval() -> A {
        switch self {
        case let .Mabelian(mab):
            if case let .Monoid(.Mul(_b)) = mab {
                let l = _b.l.eval()
                let r = _b.r.eval()
                let evaledAsRing = RingOperators<A>.MMonoid(.Mul(.init(l: l, r: r))).eval()
                if A(mmonoidOp: .Mul(.init(l: l, r: r))) != evaledAsRing {
                    return evaledAsRing
                }
            }
            return mab.eval()
        case let .Abelian(abe):
            return abe.eval()

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
    
    case Mabelian(A.MAbelianO)
    case Abelian(A.AbelianO)
    case Power(base:A, exponent:A)
    case Conjugate(A)
    case Determinant(Matrix<A>)
}

/** conjugate prefix */
prefix operator *

extension Field {
    static prefix func * (lhs: Self) -> Self { return .init(fieldOp: .Conjugate(lhs)) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Power(base: lhs, exponent: rhs)) }

    var ringOp: RingOperators<Self>? {
        switch fieldOp {
        case let .Abelian(abe):
            return .Abelian(abe)
        case let .Mabelian(.Monoid(mon)):
            return .MMonoid(mon)
        default: return nil
        }
    }
    init(ringOp: RingOperators<Self>) {
        switch ringOp {
        case let .Abelian(abe):
            self.init(fieldOp: .Abelian(abe))
        case let .MMonoid(mmon):
            self.init(fieldOp: .Mabelian(.Monoid(mmon)))
        }
    }
    var mabelianOp: MAbelianO? {
        switch fieldOp {
        case let .Mabelian(mab):
            return mab
        default:
            return nil
        }
    }
    init(mabelianOp: MAbelianO) {
        self.init(fieldOp: .Mabelian(mabelianOp))
    }
    var mmonoidOp: MMonO? {
        switch fieldOp {
        case let .Mabelian(.Monoid(mon)):
            return mon
        default:
            return nil
        }
    }
    init(mmonoidOp: MMonO) {
        self.init(fieldOp: .Mabelian(.Monoid(mmonoidOp)))
    }
}
