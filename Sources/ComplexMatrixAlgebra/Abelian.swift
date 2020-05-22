//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol AbelianBasis:Basis {
    static func + (l:Self, r:Self)->Self
    static prefix func - (l:Self)->Self
    static var Zero:Self {get}
}
indirect enum AbelianOperator<A:Abelian>:Equatable {
    case Add(A,A)
    case Subtract(A,A)
    case Negate(A)
    case Algebra(A.AlgebraOp)
}
protocol Abelian:Algebra where B:AbelianBasis {
    typealias AbelianO = AbelianOperator<Self>
    init(abelianOp:AbelianO)
    var abelianOp: AbelianO? {get}
}
extension Abelian {
    static func + (l:Self, r:Self)-> Self {
        return .init(abelianOp: .Add(l, r))
    }
    static func - (lhs: Self, rhs: Self) -> Self {
        return .init(abelianOp: .Subtract(lhs, rhs))
    }
    static prefix func - (l:Self)-> Self {
        return .init(abelianOp: .Negate(l))
    }
    static var Zero:Self {
        return .init(abelianOp: .Algebra(.Number(B.Zero)))
    }
    func same(abelian: Self) -> Bool {
        switch (abelianOp, abelian.abelianOp) {
        case (.Add(_,_), .Add(_,_)):
            return commuteSame(flatAbelianAdd(self).all, flatAbelianAdd(abelian).all)
        default:
            return same(algebra: abelian)
        }
    }
    func evalAbelian()->Self {
        switch abelianOp {
        case let .Add(x, y):
            return operateAbelianAdd(x.eval(), y.eval())
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            let x = x.eval()
            switch x.algebraOp {
            case let .Number(x):
                return .init(algebraOp: .Number(-x))
            default:
                break
            }
            switch x.abelianOp {
            case let .Add(l, r):
                return ((-l) + (-r)).eval()
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
    init(algebraOp: AlgebraOperators<Self>) {
        self.init(abelianOp: .Algebra(algebraOp))
    }
    var algebraOp: AlgebraOperators<Self>? {
        switch abelianOp {
        case let .Algebra(b):
            return b
        default:
            return nil
        }
    }
}
func flatAbelianAdd<A:Abelian>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(l,r) = x.abelianOp {
            return [l,r]
        } else {
            return []
        }
    }
}

func operateAbelianAdd<A:Abelian>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.Zero  {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.algebraOp,r.algebraOp) {
            return A(algebraOp: .Number(l + r))
        } else if (-l).eval().same(r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatAbelianAdd(x) + flatAbelianAdd(y)).reduce { (l, r) -> A in A(abelianOp: .Add(l, r)) }
}
