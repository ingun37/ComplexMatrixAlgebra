//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/19.
//

import Foundation
protocol RingBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static func + (l:Self, r:Self)->Self
    static prefix func - (l:Self)->Self
    static var Zero:Self {get}
    static var Id:Self {get}
}
extension RingBasis {
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.O.B == Self{
        return R.O.RingO.Number(self).sum
    }
}
protocol Ring:Algebra where O:RingOperable{}

protocol RingOperable:Operable where A:Ring, B:RingBasis {
    typealias RingO = RingOperators<A, B>
    init(ringOp:RingO)
    var ringOp: RingO? { get }
}
extension RingOperable where A.O == Self{
    var ring:A {
        return A(op: self)
    }
}
indirect enum RingOperators<A:Ring, B:RingBasis >:Equatable, RingOperable {
    init(ringOp: RingO) {
        self = ringOp
    }
    
    var ringOp: RingO? {
        return self
    }
    
    case Add(A,A)
    case Mul(A,A)
    case Negate(A)
    case Number(B)
    case Subtract(A, A)
    case Var(String)
}
extension RingOperators where A.O.A == A, A.O.B == B {
    var sum:A {
        return A(op: A.O(ringOp: self))
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
            return A.O(ringOp: .Number(l + r)).ring
        } else if (-l).eval().same(r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatRingAdd(x) + flatRingAdd(y)).reduce { (l, r) -> A in
        A.O.RingO.Add(l, r).sum
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
            return A.O.RingO.Number(ln * rn).sum
        }
        return nil
    }.reduce(*)
}
extension Ring {
    static func * (l:Self, r:Self)-> Self {
        return O.RingO.Mul(l, r).sum
    }
    static func + (l:Self, r:Self)-> Self {
        return O.RingO.Add(l, r).sum
    }
    static func - (lhs: Self, rhs: Self) -> Self {
        return O.RingO.Subtract(lhs, rhs).sum
    }

    static prefix func - (l:Self)-> Self {
        return O.RingO.Negate(l).sum
    }
    static var Zero:Self {
        return O.B.Zero.asNumber(self).op.ring
    }
    static var Id:Self {
        return O.B.Id.asNumber(self).op.ring
    }
    static var _Id:Self {
        return (-O.B.Id).asNumber(self).op.ring
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
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Mul(x, y):
            return operateRingMul(x.eval(), y.eval())
        case let .Negate(x):
            let x = x.eval()
            if let xRingOp = x.op.ringOp {
                switch xRingOp {
                case let .Add(l, r):
                    return ((-l) + (-r)).eval()
                case let .Mul(l, r):
                    return ((-l) * r).eval()
                case let .Negate(x):
                    return x.eval()
                case let .Number(x):
                    return (-x).asNumber(Self.self)
                case let .Subtract(l, r):
                    return (r - l).eval()
                case let .Var(x):
                    return self
                }
            } else {
                
            }
//        return (Self._Id * x).eval()
        case .none:
            return self
        
        case .Var(_):
            return self
        }
        return self
    }
}
