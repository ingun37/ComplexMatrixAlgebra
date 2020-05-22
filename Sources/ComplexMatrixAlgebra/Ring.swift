//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/19.
//

import Foundation
protocol RingBasis:AbelianBasis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
extension RingBasis {
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.B == Self{
        return R(basis: .Number(self))
//        return R(op: .init(basisOp: .Number(self)))
    }
}
protocol Ring:Abelian where B:RingBasis{
    typealias RingOp = RingOperators<Self>
    init(ringOp:RingOp)
    var ringOp: RingOp? { get }
}

indirect enum RingOperators<A:Ring>:Equatable {
    case Mul(A,A)
    case Abelian(A.AbelianO)
}
extension RingOperators {
    var sum:A { return A(ringOp: self) }
}
func flatRingMul<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(l,r) = x.ringOp {
            return [l,r]
        } else {
            return []
        }
    }
}
func operateRingMul<A:Ring>(_ x:A, _ y:A)-> A {
    return associativeMerge(_objs: flatRingMul(x) + flatRingMul(y)) { (l, r) -> A? in
        if case let .Add(x, y) = l.abelianOp {
            let xr = x * r
            let yr = (y * r)
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Number(ln), .Number(rn)) = (l.basis,r.basis) {
            return (ln * rn).asNumber(A.self)
        }
        return nil
    }.reduce(*)
}
extension Ring {
    static func * (l:Self, r:Self)-> Self { return .init(ringOp: .Mul(l, r)) }
    static var Id:Self { return .init(basis: .Number(.Id)) }
    static var _Id:Self { return .init(basis: .Number(-.Id)) }
    
    func same(_ to: Self) -> Bool {
        return same(ring: to)
    }
    func same(ring:Self) -> Bool {
        switch (ringOp, ring.ringOp) {
        default:
            return same(abelian: ring)
        }
    }
    func eval() -> Self {
        return evalRing()
    }
    func evalRing() -> Self {
        switch abelianOp {
        case let .Negate(x):
            switch x.ringOp {
            case let .Mul(l, r):
                return ((-l) * r).eval()
            default: break
            }
        default: break
        }
        switch ringOp {
        case let .Mul(x, y):
            return operateRingMul(x.eval(), y.eval())
        default: break
        }
        return evalAbelian()
    }
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
}
