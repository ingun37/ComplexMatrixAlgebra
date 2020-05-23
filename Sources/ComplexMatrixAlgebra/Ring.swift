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
        return R(element: .Basis(self))
//        return R(op: .init(basisOp: .Number(self)))
    }
}
protocol Ring:Abelian where B:RingBasis{
    associatedtype MUL:AssociativeBinary where MUL.A == Self
    typealias RingOp = RingOperators<MUL>
    init(ringOp:RingOp)
    var ringOp: RingOp? { get }
}

indirect enum RingOperators<MUL:AssociativeBinary>:Operator where MUL.A:Ring {
    typealias A = MUL.A
    case Mul(MUL)
    case Abelian(A.AbelianO)
    
    func eval() -> A {
        switch self {
        case let .Mul(b):
            return operateRingMul(b.x.eval(), b.y.eval())
        case let .Abelian(abe):
            
            if case let .Negate(x) = abe, case let .Mul(b) = x.ringOp {
                return ((-b.l) * b.r).eval()
            } else {
                return abe.eval()
            }
        }
    }
}
func flatRingMul<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(b) = x.ringOp {
            return [b.l,b.r]
        } else {
            return []
        }
    }
}
func operateRingMul<A:Ring>(_ x:A, _ y:A)-> A {
    return associativeMerge(_objs: flatRingMul(x) + flatRingMul(y)) { (l, r) -> A? in
        if case let .Add(b) = l.abelianOp {
            let xr = b.l * r
            let yr = (b.r * r)
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Basis(ln), .Basis(rn)) = (l.element,r.element) {
            return (ln * rn).asNumber(A.self)
        }
        return nil
    }.reduce(*)
}
extension Ring {
    static func * (l:Self, r:Self)-> Self { return .init(ringOp: .Mul(.init(l:l, r:r))) }
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
}
