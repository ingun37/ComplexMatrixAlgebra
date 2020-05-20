//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol AbelianAddBasis:Basis {
    static func + (l:Self, r:Self)->Self
    static prefix func - (l:Self)->Self
    static var Zero:Self {get}
}
extension AbelianAddBasis {
    func asNumber<R:AbelianAdd>(_ a:R.Type) -> R where R.O.U == Self{
        return R.O.AbelianAddO.Number(self).sum.abelianAdd
    }
}
protocol AbelianAddOperable:Operable where A:AbelianAddBasis, U:AbelianAddBasis{
    typealias AbelianAddO = AbelianAddOperators<A,U>
    init(abelianAddOp:AbelianAddO)
    var abelianAddOp: AbelianAddO? { get }
}
extension AbelianAddOperable where A.O == Self {
    var abelianAdd:A {
        return A(op: self)
    }
}
protocol AbelianAdd:Algebra where O:AbelianAddOperable {}

extension AbelianAdd {
    static func + (l:Self, r:Self)-> Self {
        return O.AbelianAddO.Add(l, r).sum.abelianAdd
    }
    static func - (lhs: Self, rhs: Self) -> Self {
        return O.AbelianAddO.Subtract(lhs, rhs).sum.abelianAdd
    }

    static prefix func - (l:Self)-> Self {
        return O.AbelianAddO.Negate(l).sum.abelianAdd
    }
    static var Zero:Self {
        return O.U.Zero.asNumber(self).op.abelianAdd
    }
    func sameAbelianAdd(_ to:Self)-> Bool {
        switch (op.abelianAddOp, to.op.abelianAddOp) {
        case (.Add(_,_), .Add(_,_)):
            return commuteSame(flatAbelianAdd(self).all, flatAbelianAdd(to).all)
        default:
            return self == to
        }
    }
    func evalAbelianAdd()->Self {
        switch op.abelianAddOp {
        case .Number(_): return self
        case let .Add(x, y):
            return operateAbelianAdd(x.eval(), y.eval())
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            switch x.op.abelianAddOp {
            case let .Add(x, y):
                return ((-x) + (-y)).eval()
            case let .Negate(x):
                return x.eval()
            case let .Number(x):
                return (-x).asNumber(Self.self).op.abelianAdd
            default:
                return self
            }
        default:
            return self
        }
    }
}

indirect enum AbelianAddOperators<A:Equatable,B:Equatable>:Equatable {
    case Number(B)
    case Add(A,A)
    case Negate(A)
    case Subtract(A,A)
    case Var(String)
}

extension AbelianAddOperators where A:AbelianAdd, A.O.U == B {
    var sum:A.O {
        return A.O(abelianAddOp: self)
    }
}
func flatAbelianAdd<A:AbelianAdd>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(l,r) = x.op.abelianAddOp {
            return [l,r]
        } else {
            return []
        }
    }
}
func operateAbelianAdd<A:AbelianAdd>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.Zero  {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.op.abelianAddOp,r.op.abelianAddOp) {
            return A.O(abelianAddOp: .Number(l + r)).abelianAdd
        } else if (-l).eval().same(r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatAbelianAdd(x) + flatAbelianAdd(y)).reduce { (l, r) -> A in
        A.O.AbelianAddO.Add(l, r).sum.abelianAdd
    }
}
