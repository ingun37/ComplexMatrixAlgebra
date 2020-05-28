//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/19.
//

import Foundation
protocol RingBasis:AbelianBasis, MMonoidBasis {
}
extension RingBasis {
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.B == Self{
        return R(element: .Basis(self))
//        return R(op: .init(basisOp: .Number(self)))
    }
}
protocol Ring:Abelian & MMonoid where B:RingBasis{
    typealias RingOp = RingOperators<MUL>
    init(ringOp:RingOp)
    var ringOp: RingOp? { get }
}

indirect enum RingOperators<MUL:AssociativeBinary>:Operator where MUL.A:Ring {
    typealias A = MUL.A
    case MMonoid(A.MMonO)
    case Abelian(A.AbelianO)
    
    func eval() -> A {
        switch self {
        case let .MMonoid(mon):
            if case let .Mul(_b) = mon {
                let b = _b.eachEvaled
                return b.caseMultiplicationWithZero() ?? b.caseMultiplicationWithId() ?? b.caseBothBasis() ?? b.caseDistributive() ?? b.caseAssociative() ?? b.l * b.r
            }
            return mon.eval()
        case let .Abelian(abe):
            return abe.eval()
        }
    }
}
func flatRingMul<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(b) = x.mmonoidOp {
            return [b.l,b.r]
        } else {
            return []
        }
    }
}
extension Ring {
    static func * (l:Self, r:Self)-> Self { return .init(mmonoidOp: .Mul(.init(l:l, r:r))) }
    static var Id:Self { return .init(element: .Basis(.Id)) }
    static var _Id:Self { return .init(element: .Basis(-.Id)) }
    
    init(abelianOp: AbelianO) {
        self.init(ringOp: .Abelian(abelianOp))
    }
    var abelianOp: AbelianO? {
        switch ringOp {
        case let .Abelian(a):
            return a
        default:
            return nil
        }
    }
    var mmonoidOp: MMonO? {
        switch ringOp {
        case let .MMonoid(m):
            return m
        default:
            return nil
        }
    }
    init(mmonoidOp: MMonO) {
        self.init(ringOp: .MMonoid(mmonoidOp))
    }
}
