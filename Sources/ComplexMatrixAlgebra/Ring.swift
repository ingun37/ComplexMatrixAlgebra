//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/19.
//

import Foundation
protocol RingBasis:AbelianBasis, MonoidMulBasis {
}
extension RingBasis {
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.B == Self{
        return R(element: .Basis(self))
//        return R(op: .init(basisOp: .Number(self)))
    }
}
protocol Ring:Abelian & MonoidMul where B:RingBasis{
    typealias RingOp = RingOperators<MUL>
    init(ringOp:RingOp)
    var ringOp: RingOp? { get }
}

indirect enum RingOperators<MUL:AssociativeBinary>:Operator where MUL.A:Ring {
    typealias A = MUL.A
    case MonoidMul(A.MonMulOp)
    case Abelian(A.AbelianO)
    
    func eval() -> A {
        switch self {
        case let .MonoidMul(mon):
            let x = mon.eval()
            if case let .Mul(b) = x.monoidMulOp {
                return associativeMerge(_objs: b.flat()) { (l, r) -> A? in
                    if case let .Add(b) = l.abelianOp {
                        let xr = b.l * r
                        let yr = (b.r * r)
                        return (xr + yr).eval()
                    } else if l == A.Zero {
                        return A.Zero
                    }
                    return nil
                }.reduce(*)
            }
            return x
        case let .Abelian(abe):
            if case let .Negate(x) = abe, case let .Mul(b) = x.monoidMulOp {
                return ((-b.l) * b.r).eval()
            } else {
                return abe.eval()
            }
        }
    }
}
func flatRingMul<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(b) = x.monoidMulOp {
            return [b.l,b.r]
        } else {
            return []
        }
    }
}
extension Ring {
    static func * (l:Self, r:Self)-> Self { return .init(monoidMulOp: .Mul(.init(l:l, r:r))) }
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
    var monoidMulOp: MonMulOp? {
        switch ringOp {
        case let .MonoidMul(m):
            return m
        default:
            return nil
        }
    }
    init(monoidMulOp: MonMulOp) {
        self.init(ringOp: .MonoidMul(monoidMulOp))
    }
}
