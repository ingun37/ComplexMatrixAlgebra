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
    func asNumber<R:Ring>(_ a:R.Type) -> R where R.B == Self{
        return R(basisOp: .Number(self))
//        return R(op: .init(basisOp: .Number(self)))
    }
}
protocol Ring:Algebra where B:RingBasis{
    typealias RingOp = RingOperators<Self>
    init(ringOp:RingOp)
    var ringOp: RingOp? { get }
}

indirect enum RingOperators<A:Ring>:Equatable {
    case Add(A,A)
    case Mul(A,A)
    case Negate(A)
    case Subtract(A, A)
    case Algebra(A.AlgebraOp)
}
extension RingOperators {
    var sum:A { return A(ringOp: self) }
}
func flatRingAdd<A:Ring>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(l,r) = x.ringOp {
            return [l,r]
        } else {
            return []
        }
    }
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
func operateRingAdd<A:Ring>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.Zero  {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.basisOp,r.basisOp) {
            return A(basisOp: .Number(l + r))
        } else if (-l).eval().same(r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatRingAdd(x) + flatRingAdd(y)).reduce { (l, r) -> A in A(ringOp: .Add(l, r)) }
}
func operateRingMul<A:Ring>(_ x:A, _ y:A)-> A {
    return associativeMerge(_objs: flatRingMul(x) + flatRingMul(y)) { (l, r) -> A? in
        if case let .Add(x, y) = l.ringOp {
            let xr = x * r
            let yr = (y * r)
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Number(ln), .Number(rn)) = (l.basisOp,r.basisOp) {
            return (ln * rn).asNumber(A.self)
        }
        return nil
    }.reduce(*)
}
extension Ring {
    static func * (l:Self, r:Self)-> Self { return .init(ringOp: .Mul(l, r)) }
    static func + (l:Self, r:Self)-> Self { return .init(ringOp: .Add(l, r)) }
    static func - (lhs: Self, rhs: Self) -> Self { return .init(ringOp: .Subtract(lhs, rhs)) }
    static prefix func - (l:Self)-> Self { return .init(ringOp: .Negate(l)) }
    static var Zero:Self { return .init(basisOp: .Number(.Zero)) }
    static var Id:Self { return .init(basisOp: .Number(.Id)) }
    static var _Id:Self { return .init(basisOp: .Number(-.Id)) }
    
    func same(_ to: Self) -> Bool {
        return same(ring: to)
    }
    func same(ring:Self) -> Bool {
        switch (ringOp, ring.ringOp) {
        case (.Add(_,_), .Add(_,_)):
            return commuteSame(flatRingAdd(self).all, flatRingAdd(ring).all)
        default:
            return same(algebra: ring)
        }
    }
    func eval() -> Self {
        return evalRing()
    }
    func evalRing() -> Self {
        switch ringOp {
        case let .Add(x, y):
            return operateRingAdd(x.eval(), y.eval())
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Mul(x, y):
            return operateRingMul(x.eval(), y.eval())
        case let .Negate(x):
            let x = x.eval()
            
            switch x.basisOp {
            case let .Number(x):
                return (-x).asNumber(Self.self)
            default:
                break
            }
            
            switch x.ringOp {
            case let .Add(l, r):
                return ((-l) + (-r)).eval()
            case let .Mul(l, r):
                return ((-l) * r).eval()
            case let .Negate(x):
                return x.eval()
            case let .Subtract(l, r):
                return (r - l).eval()
            default: break
            }
        default: break
        }
        return evalAlgebra()
    }
    init(basisOp: BasisOperators<Self>) {
        self.init(ringOp: .Algebra(basisOp))
    }
    var basisOp: BasisOperators<Self>? {
        switch ringOp {
        case let .Algebra(b):
            return b
        default:
            return nil
        }
    }
}
