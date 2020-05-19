//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/19.
//

import Foundation
protocol RingNumber:Underlying {
    static func * (l:Self, r:Self)->Self
    static func + (l:Self, r:Self)->Self
    static prefix func - (l:Self)->Self
    static var Zero:Self {get}
    static var Id:Self {get}
}
extension RingNumber {
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.OpSum.Num == Self{
        return R.OpSum.RingO.Number(self).sum.ring
    }
}
protocol Ring:Algebra where OpSum:RingOpSum{}

protocol RingOpSum:OperatorSum where A:Ring, Num:RingNumber {
    typealias RingO = RingOperators<A, Num>
    init(ringOp:RingO)
    var ringOp: RingO? { get }
}
extension RingOpSum where A.OpSum == Self{
    var ring:A {
        return A(op: self)
    }
}
indirect enum RingOperators<R:Equatable,Num:Equatable>:Equatable {
    case Add(R,R)
    case Mul(R,R)
    case Negate(R)
    case Number(Num)
}
extension RingOperators where R:Ring, R.OpSum.Num == Num {
    var sum:R.OpSum {
        return R.OpSum(ringOp: self)
    }
}
func flatRingAdd<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(l,r) = x.op.ringOp {
            return [l,r]
        } else {
            return []
        }
    }
}
func flatRingMul<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(l,r) = x.op.ringOp {
            return [l,r]
        } else {
            return []
        }
    }
}
func operateRingAdd<A:Ring>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.Zero  {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.op.ringOp,r.op.ringOp) {
            return A.OpSum(ringOp: .Number(l + r)).ring
        } else if A.OpSum.RingO.Negate(l).sum.ring.eval().sameRing(r) {
            return A.OpSum.Num.Zero.asNumber(A.self).op.ring
        } else {
            return nil
        }
    }, flatRingAdd(x) + flatRingAdd(y)).reduce { (l, r) -> A in
        A.OpSum.RingO.Add(l, r).sum.ring
    }
}
func operateRingMul<A:Ring>(_ x:A, _ y:A)-> A {
    return associativeMerge(_objs: flatRingMul(x) + flatRingMul(y)) { (l, r) -> A? in
        if case let .Add(x, y) = l.op.ringOp {
            let xr = x * r
            let yr = (y * r)
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Number(ln), .Number(rn)) = (l.op.ringOp,r.op.ringOp) {
            return A.OpSum.RingO.Number(ln * rn).sum.ring
        }
        return nil
    }.reduce(*)
}
extension Ring {
    static func * (l:Self, r:Self)-> Self {
        return OpSum.RingO.Mul(l, r).sum.ring
    }
    static func + (l:Self, r:Self)-> Self {
        return OpSum.RingO.Add(l, r).sum.ring
    }
    static prefix func - (l:Self)-> Self {
        return OpSum.RingO.Negate(l).sum.ring
    }
    static var Zero:Self {
        return OpSum.Num.Zero.asNumber(self).op.ring
    }
    static var Id:Self {
        return OpSum.Num.Id.asNumber(self).op.ring
    }
    static var _Id:Self {
        return (-OpSum.Num.Id).asNumber(self).op.ring
    }
    func sameRing(_ to:Self) -> Bool {
        switch (op.ringOp, to.op.ringOp) {
        case (.Add(_,_), .Add(_,_)):
            return commuteSame(flatRingAdd(self).all, flatRingAdd(to).all)
        default:
            return self == to
        }
    }
    func evalRing() -> Self {
        switch op.ringOp {
        case .Number(_): return self
        case let .Add(x, y):
            return operateRingAdd(x.eval(), y.eval())
        case let .Mul(x, y):
            return operateRingMul(x.eval(), y.eval())
        case let .Negate(x):
            return (Self._Id * x).eval()
        case .none:
            return self
        }
    }
}
