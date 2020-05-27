//
//  File.swift
//
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol MAbelianBasis:MMonoidBasis {
    static prefix func ~ (l:Self)->Self
}

indirect enum MAbelianOperator<A:MAbelian>:Operator {
    case Monoid(A.MMonO)
    case Quotient(A,A)
    case Inverse(A)
    
    func eval() -> A {
        switch self {
        case let .Monoid(mon):
            if case let .Mul(_b) = mon {
                let b = _b.eachEvaled
                let cases1 = b.caseMultiplicationWithId() ?? b.caseMultiplicationWithInverse() ?? b.caseBothBasis()
                return cases1 ?? b.caseAssociative() ?? b.caseCommutative() ?? b.l * b.r
            }
            return mon.eval()
        case let .Quotient(l, r):
            return (l * ~r).eval()
        case let .Inverse(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(x): return .init(element: .Basis(~x))
            default: break
            }
            switch x.mmonoidOp {
            case let .Mul(bin): return ((~bin.l) * (~bin.r)).eval()
            default: break
            }
            switch x.mabelianOp {
            case let .Inverse(x):
                return x.eval()
            case let .Quotient(l, r):
                return (r / l).eval()
            default: break
            }
        default: break
        }
        return .init(mabelianOp: self)
    }
}
protocol MAbelian:MMonoid where B:MAbelianBasis, MUL:CommutativeMultiplication {
    typealias MAbelianO = MAbelianOperator<Self>
    init(mabelianOp:MAbelianO)
    var mabelianOp: MAbelianO? {get}
}
extension MAbelian {
    static func / (lhs: Self, rhs: Self) -> Self {
        return .init(mabelianOp: .Quotient(lhs, rhs))
    }
    static prefix func ~ (l:Self)-> Self {
        return .init(mabelianOp: .Inverse(l))
    }
    var mmonoidOp: MMonO? {
        switch mabelianOp {
        case let .Monoid(m): return m
        default: return nil
        }
    }
    init(mmonoidOp: MMonO) {
        self.init(mabelianOp: .Monoid(mmonoidOp))
    }
}
func flatMAbelianMul<A:MAbelian>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(bin) = x.mmonoidOp {
            return [bin.l,bin.r]
        } else {
            return []
        }
    }
}
